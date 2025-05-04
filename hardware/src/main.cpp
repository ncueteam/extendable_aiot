#include <Arduino.h>
#include <U8g2lib.h>
#include <Wire.h>
#include <WiFi.h>
#include <DHT.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include "time.h"
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include "ConfigManager.h" // 引入配置管理器
#include "LED.h" // 加入LED控制類的頭文件

// 前向宣告
bool connectToWiFi(bool useStored);
void handleWiFiCredentials(const char* message);

// 定義BLE的UUID常量
#define SERVICE_UUID           "91bad492-b950-4226-aa2b-4ede9fa42f59"
#define WIFI_CRED_CHAR_UUID    "0b30ac1c-1c8a-4770-9914-d2abe8351512"
#define STATUS_CHAR_UUID       "d2936523-52bf-4b76-a873-727d83e2b357"

// BLE相關定義
BLEServer* pServer = NULL;
BLECharacteristic* pWiFiCredentialChar = NULL;
BLECharacteristic* pStatusChar = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;
bool wifiCredentialsReceived = false;

// 創建ConfigManager實例
ConfigManager configManager("wifi_cred");

// WiFi設定 - 從ConfigManager中獲取
char saved_ssid[33] = "";       // 使用字符數組代替String
char saved_password[65] = "";   // 使用字符數組代替String
bool useStoredCredentials = true; // 使用儲存的憑證

// FreeRTOS相關定義
#define CORE_0 0  // 通訊核心
#define CORE_1 1  // 顯示核心
#define TASK_STACK_SIZE 4096  // 減少到4KB以節省內存
#define MQTT_PRIORITY 1
#define DISPLAY_PRIORITY 2
#define DHT_PRIORITY 1

// 互斥鎖用於保護共享數據
SemaphoreHandle_t mutex = NULL;

// 任務句柄
TaskHandle_t mqttTaskHandle = NULL;
TaskHandle_t displayTaskHandle = NULL;
TaskHandle_t dhtTaskHandle = NULL; 

// 共享數據結構
struct SharedData {
  float temperature;
  float humidity;
  bool isMqttConnected;
  bool isMqttTransmitting;
  unsigned long mqttIconBlinkMillis;
} sharedData;

// NTP服務器設定
const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = 28800;  // GMT+8 (台灣時區)
const int   daylightOffset_sec = 0;

// MQTT設定
const char* mqtt_server = "broker.emqx.io";
const int mqtt_port = 1883;
const char* mqtt_topic = "esp32/sensors";
const char* client_id = "ESP32_Client_";
const long mqttIconBlinkInterval = 500;

// MQTT客戶端設定
WiFiClient espClient;
PubSubClient mqtt_client(espClient);
unsigned long lastMqttReconnectAttempt = 0;
const long mqttReconnectInterval = 5000;
unsigned long lastMqttPublish = 0;
const long mqttPublishInterval = 5000;

// DHT11 設定
#define DHTPIN 14
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

// LED Pin定義
const int LED_PIN = 2;
const int LEDC_CHANNEL = 0;
const int LEDC_TIMER_BIT = 8;
const int LEDC_BASE_FREQ = 5000;

// 創建LED控制器物件
LEDController ledController(LED_PIN, LEDC_CHANNEL, LEDC_TIMER_BIT, LEDC_BASE_FREQ);

// 時間間隔設定
unsigned long previousMillis = 0;
unsigned long displayMillis = 0;
unsigned long dhtMillis = 0;
const long interval = 5;
const long displayInterval = 1000;
const long dhtInterval = 2000;

// 創建U8g2顯示器物件 (使用硬體I2C)
U8G2_SH1106_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, /* reset=*/U8X8_PIN_NONE);

// 創建BLE伺服器回調類
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      // 更新狀態消息
      if(pStatusChar != nullptr) {
        String status = "Connected to ESP32 BLE";
        pStatusChar->setValue(status.c_str());
        pStatusChar->notify();
      }
    }

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      // 重新廣播
      pServer->getAdvertising()->start();
    }
};

// 創建BLE特性回調類
class WiFiCredentialsCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();
      
      if (value.length() > 0) {
        // 將收到的BLE數據轉換為C風格字符串處理
        handleWiFiCredentials(value.c_str());
        
        if (wifiCredentialsReceived) {
          wifiCredentialsReceived = false;
          bool connected = connectToWiFi(true); // 使用存儲的憑證連接
          
          // 發送連接結果通知
          if(pStatusChar != nullptr) {
            String statusMsg;
            if (connected) {
              statusMsg = "WIFI_CONNECTED:" + WiFi.localIP().toString();
            } else {
              statusMsg = "WIFI_FAILED";
            }
            pStatusChar->setValue(statusMsg.c_str());
            pStatusChar->notify();
          }
        }
      }
    }
};

// 設置BLE服務
void setupBLE() {
  // 初始化BLE裝置
  BLEDevice::init("ESP32_AIOT_BLE");
  
  // 創建BLE伺服器
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  
  // 創建BLE服務
  BLEService *pService = pServer->createService(SERVICE_UUID);
  
  // 創建BLE特性 - WiFi憑證接收
  pWiFiCredentialChar = pService->createCharacteristic(
                          WIFI_CRED_CHAR_UUID,
                          BLECharacteristic::PROPERTY_WRITE
                        );
  pWiFiCredentialChar->setCallbacks(new WiFiCredentialsCallbacks());
  
  // 創建BLE特性 - 狀態通知
  pStatusChar = pService->createCharacteristic(
                  STATUS_CHAR_UUID,
                  BLECharacteristic::PROPERTY_READ |
                  BLECharacteristic::PROPERTY_NOTIFY
                );
  pStatusChar->addDescriptor(new BLE2902());
  
  // 啟動服務
  pService->start();
  
  // 啟動廣播
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  // 修正：只設置一次參數
  pAdvertising->setMinInterval(0x20);   // 添加間隔以改善發現性
  pAdvertising->setMaxInterval(0x40);
  BLEDevice::startAdvertising();
  
  Serial.println("BLE服務已啟動，等待連接...");
}

// 處理WiFi憑證
void handleWiFiCredentials(const char* message) {
  if (strncmp(message, "WIFI:", 5) == 0) {
    char* ssidPtr = strstr(message, "SSID=");
    char* passPtr = strstr(message, "PASS=");
    
    if (ssidPtr && passPtr) {
      ssidPtr += 5; // 跳過"SSID="
      char* ssidEnd = strchr(ssidPtr, ';');
      
      if (ssidEnd) {
        int ssidLen = ssidEnd - ssidPtr;
        if (ssidLen < 33) {
          strncpy(saved_ssid, ssidPtr, ssidLen);
          saved_ssid[ssidLen] = '\0';
          
          passPtr += 5; // 跳過"PASS="
          char* passEnd = strchr(passPtr, ';');
          
          if (passEnd) {
            int passLen = passEnd - passPtr;
            if (passLen < 65) {
              strncpy(saved_password, passPtr, passLen);
              saved_password[passLen] = '\0';
              
              // 使用ConfigManager存儲WiFi憑證
              configManager.saveWiFiCredentials(saved_ssid, saved_password);
              
              // 設置標誌重新連接WiFi
              wifiCredentialsReceived = true;
            }
          }
        }
      }
    }
  }
}

// 加載存儲的WiFi憑證
void loadWiFiCredentials() {
  // 使用ConfigManager加載WiFi憑證
  configManager.loadWiFiCredentials(saved_ssid, sizeof(saved_ssid), saved_password, sizeof(saved_password));
}

// 使用WiFi憑證連接
bool connectToWiFi(bool useStored = false) {
  // 移除對舊變數的引用，只使用存儲的憑證
  if (strlen(saved_ssid) == 0 || strlen(saved_password) == 0) {
    Serial.println("無可用的WiFi憑證，等待藍牙設定");
    
    u8g2.clearBuffer();
    u8g2.setFont(u8g2_font_ncenB08_tr);
    u8g2.setCursor(0, 20);
    u8g2.print("No WiFi Credentials");
    u8g2.setCursor(0, 35);
    u8g2.print("Please use BLE app");
    u8g2.setCursor(0, 50);
    u8g2.print("to setup WiFi");
    u8g2.sendBuffer();
    
    return false; // 沒有存儲的憑證
  }
  
  WiFi.disconnect();
  WiFi.begin(saved_ssid, saved_password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    u8g2.clearBuffer();
    u8g2.setFont(u8g2_font_ncenB08_tr);
    u8g2.setCursor(0, 20);
    u8g2.print("Connecting to WiFi");
    u8g2.setCursor(0, 35);
    u8g2.print("SSID: ");
    u8g2.print(saved_ssid);
    u8g2.setCursor(0, 50);
    u8g2.print("Attempt: ");
    u8g2.print(attempts + 1);
    u8g2.sendBuffer();
    
    delay(500);
    attempts++;
  }
  
  u8g2.clearBuffer();
  if (WiFi.status() == WL_CONNECTED) {
    u8g2.setCursor(0, 20);
    u8g2.print("WiFi Connected!");
    u8g2.setCursor(0, 35);
    u8g2.print("SSID: ");
    u8g2.print(saved_ssid);
    u8g2.setCursor(0, 50);
    u8g2.print(WiFi.localIP().toString());
    u8g2.sendBuffer();
    
    return true;
  } else {
    u8g2.setCursor(0, 20);
    u8g2.print("WiFi Connection");
    u8g2.setCursor(0, 35);
    u8g2.print("Failed!");
    u8g2.setCursor(0, 50);
    u8g2.print("Check credentials");
    u8g2.sendBuffer();
    
    return false;
  }
}

// 獲取格式化時間字串
String getFormattedTime() {
  struct tm timeinfo;
  if(!getLocalTime(&timeinfo)){
    return "Failed to get time";
  }
  char timeString[20];
  strftime(timeString, sizeof(timeString), "%H:%M:%S", &timeinfo);
  return String(timeString);
}

// 獲取格式化日期字串
String getFormattedDate() {
  struct tm timeinfo;
  if(!getLocalTime(&timeinfo)){
    return "Failed to get date";
  }
  char dateString[20];
  strftime(dateString, sizeof(dateString), "%Y-%m-%d", &timeinfo);
  return String(dateString);
}

// MQTT回調函數
void mqtt_callback(char* topic, byte* payload, unsigned int length) {
  // 簡化處理方式，減少內存使用
  if (length > 0) {
    // 可以在這裡處理來自Flutter的命令
    // 實際處理邏輯減少複雜性
  }
}

bool mqtt_connect() {
  if (!mqtt_client.connected()) {
    // 生成唯一的客戶端ID - 減少String操作
    char uniqueClientId[20];
    sprintf(uniqueClientId, "%s%04X", client_id, random(0xffff));
    
    // 設置遺囑消息
    const char* willTopic = "esp32/status";
    const char* willMessage = "offline";
    bool willRetain = true;
    
    if (mqtt_client.connect(uniqueClientId, NULL, NULL, willTopic, 0, willRetain, willMessage)) {
      mqtt_client.subscribe("esp32/commands");
      mqtt_client.publish("esp32/status", "online", true);
      return true;
    }
    return false;
  }
  return true;
}

// MQTT通訊任務
void mqttTask(void *parameter) {
  while (true) {
    unsigned long currentMillis = millis();
    
    // MQTT連接檢查和數據發送
    if (!mqtt_client.connected()) {
      if (currentMillis - lastMqttReconnectAttempt >= mqttReconnectInterval) {
        lastMqttReconnectAttempt = currentMillis;
        if (mqtt_connect()) {
          lastMqttReconnectAttempt = 0;
          xSemaphoreTake(mutex, portMAX_DELAY);
          sharedData.isMqttConnected = true;
          xSemaphoreGive(mutex);
        }
      }
    } else {
      mqtt_client.loop();
      
      if (currentMillis - lastMqttPublish >= mqttPublishInterval) {
        lastMqttPublish = currentMillis;
        
        xSemaphoreTake(mutex, portMAX_DELAY);
        float temp = sharedData.temperature;
        float humid = sharedData.humidity;
        sharedData.isMqttTransmitting = true;
        sharedData.mqttIconBlinkMillis = currentMillis;
        xSemaphoreGive(mutex);
        
        // 使用較小的JSON文檔
        StaticJsonDocument<100> doc;
        doc["temp"] = temp;
        doc["humid"] = humid;
        
        char jsonBuffer[100];
        serializeJson(doc, jsonBuffer);
        
        mqtt_client.publish(mqtt_topic, jsonBuffer);
      }
    }
    
    vTaskDelay(10 / portTICK_PERIOD_MS);
  }
}

// DHT11讀取任務
void dhtTask(void *parameter) {
  const int maxRetries = 2; // 減少重試次數以節省代碼空間
  
  vTaskDelay(2000 / portTICK_PERIOD_MS);

  while (true) {
    int retryCount = 0;
    float newTemp, newHum;
    bool readSuccess = false;

    while (retryCount < maxRetries && !readSuccess) {
      newTemp = dht.readTemperature();
      newHum = dht.readHumidity();
      
      if (!isnan(newTemp) && !isnan(newHum)) {
        readSuccess = true;
        
        xSemaphoreTake(mutex, portMAX_DELAY);
        sharedData.temperature = newTemp;
        sharedData.humidity = newHum;
        xSemaphoreGive(mutex);
      } else {
        retryCount++;
        vTaskDelay(500 / portTICK_PERIOD_MS);
      }
    }
    
    vTaskDelay(3000 / portTICK_PERIOD_MS);
  }
}

// 顯示更新函數
void updateDisplay() {
  xSemaphoreTake(mutex, portMAX_DELAY);
  u8g2.clearBuffer();
  
  // 顯示標題
  u8g2.setFont(u8g2_font_ncenB10_tr);
  u8g2.setCursor(0, 12);
  u8g2.print("ESP32 AIOT");
  
  // 顯示傳輸圖示
  if (sharedData.isMqttTransmitting) {
    u8g2.setFont(u8g2_font_open_iconic_embedded_1x_t);
    u8g2.drawGlyph(115, 12, 64);
    
    if (millis() - sharedData.mqttIconBlinkMillis >= mqttIconBlinkInterval) {
      sharedData.isMqttTransmitting = false;
    }
  }
  
  // 顯示時間和溫濕度
  u8g2.setFont(u8g2_font_ncenB08_tr);
  u8g2.setCursor(0, 25);
  u8g2.print(getFormattedTime());
  
  u8g2.setCursor(0, 38);
  u8g2.print("T:");
  u8g2.print(sharedData.temperature, 1);
  u8g2.print("C H:");
  u8g2.print(sharedData.humidity, 1);
  u8g2.print("%");
  
  // 顯示WiFi和MQTT狀態
  u8g2.setCursor(0, 51);
  u8g2.print("WiFi:");
  u8g2.print(WiFi.status() == WL_CONNECTED ? "OK" : "X");
  u8g2.print(" MQTT:");
  u8g2.print(sharedData.isMqttConnected ? "OK" : "X");
  
  // 顯示BLE狀態
  u8g2.setCursor(0, 64);
  u8g2.print("BLE:");
  u8g2.print(deviceConnected ? "OK" : "X");
  
  xSemaphoreGive(mutex);
  u8g2.sendBuffer();
}

// 顯示更新任務
void displayTask(void *parameter) {
  while (true) {
    updateDisplay();
    vTaskDelay(displayInterval / portTICK_PERIOD_MS);
  }
}

void setup() {
  // 初始化序列通訊
  Serial.begin(115200);
  
  // 創建互斥鎖
  mutex = xSemaphoreCreateMutex();
  
  // 初始化共享數據
  memset(&sharedData, 0, sizeof(sharedData));
  
  // DHT11 初始化
  pinMode(DHTPIN, INPUT);
  dht.begin();
  
  // LED控制器初始化
  ledController.begin();
  ledController.setBreathing(true);
  
  // 初始化OLED
  u8g2.begin();
  u8g2.setFont(u8g2_font_ncenB08_tr);
  
  // 加載存儲的WiFi憑證
  loadWiFiCredentials();
  
  // 嘗試連接WiFi
  bool connected = false;
  if (useStoredCredentials && strlen(saved_ssid) > 0) {
    connected = connectToWiFi(true);
  }
  
  if (!connected) {
    connectToWiFi(false);
  }
  
  // 配置時間
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
  
  // 初始化MQTT
  mqtt_client.setServer(mqtt_server, mqtt_port);
  mqtt_client.setCallback(mqtt_callback);
  
  // 初始化BLE
  setupBLE();
  
  // 創建任務
  xTaskCreatePinnedToCore(
    mqttTask,
    "MQTTTask",
    TASK_STACK_SIZE,
    NULL,
    MQTT_PRIORITY,
    &mqttTaskHandle,
    CORE_0
  );
  
  xTaskCreatePinnedToCore(
    displayTask,
    "DisplayTask",
    TASK_STACK_SIZE,
    NULL,
    DISPLAY_PRIORITY,
    &displayTaskHandle,
    CORE_1
  );
  
  xTaskCreatePinnedToCore(
    dhtTask,
    "DHTTask",
    TASK_STACK_SIZE,
    NULL,
    DHT_PRIORITY,
    &dhtTaskHandle,
    CORE_0
  );
}

void loop() {
  // 處理BLE連接狀態變化
  if (deviceConnected != oldDeviceConnected) {
    if (deviceConnected) {
      // 新建立的連接
      Serial.println("BLE裝置已連接");
    } else {
      // 連接中斷
      Serial.println("BLE裝置已斷開");
      delay(500); // 給客戶端時間接收斷開通知
    }
    oldDeviceConnected = deviceConnected;
  }
  
  // 更新LED呼吸效果
  ledController.updateBreathing();
  
  // 主任務由FreeRTOS處理
  delay(10);
}