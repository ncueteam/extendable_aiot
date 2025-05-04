#include <Arduino.h>
#include <Wire.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include "time.h"
#include <Preferences.h>
<<<<<<< HEAD
#include "LED.h" // 加入LED控制類的頭文件
=======
#include "DHT11Sensor.h"   // DHT11 传感器模块
#include "LCDDisplay.h"    // LCD 显示模块
#include "BLEManager.h"    // BLE 管理器模块
#include "DataManager.h"   // 数据管理模块
#include "LEDManager.h"    // LED 管理模块
>>>>>>> origin/main

// 前向宣告
bool connectToWiFi(bool useStored);
void handleWiFiCredentials(const char* message);

// Preferences實例 - 用於存儲WiFi憑證
Preferences preferences;

// WiFi設定 - 從Preferences中獲取
char saved_ssid[33] = "";       // 使用字符數組代替String
char saved_password[65] = "";   // 使用字符數組代替String
const char* preference_namespace = "wifi_cred";
bool useStoredCredentials = true; // 使用儲存的憑證
bool wifiCredentialsReceived = false;

// FreeRTOS相關定義
#define CORE_0 0  // 通訊核心
#define CORE_1 1  // 顯示核心
#define TASK_STACK_SIZE 4096  // 減少到4KB以節省內存
#define MQTT_PRIORITY 1
#define DISPLAY_PRIORITY 2
#define DHT_PRIORITY 1

// 任務句柄
TaskHandle_t mqttTaskHandle = NULL;
TaskHandle_t displayTaskHandle = NULL;
TaskHandle_t dhtTaskHandle = NULL; 

// NTP服務器設定
const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = 28800;  // GMT+8 (台灣時區)
const int   daylightOffset_sec = 0;

// MQTT設定
const char* mqtt_server = "broker.emqx.io";
const int mqtt_port = 1883;
const char* mqtt_topic = "esp32/sensors";
const char* mqtt_dht11_topic = "esp32/sensors/dht11"; // 添加DHT11特定主題
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
// 使用我們的新DHT11Sensor類
DHT11Sensor dhtSensor(DHTPIN);

// 创建LCD显示对象
LCDDisplay lcdDisplay;

// 创建BLE管理器对象
BLEManager bleManager;

// 创建数据管理器对象
DataManager dataManager(mqttIconBlinkInterval);

// 创建LED管理器对象
#define LED_PIN 2
LEDManager ledManager(LED_PIN);

// 創建LED控制器物件
LEDController ledController(LED_PIN, LEDC_CHANNEL, LEDC_TIMER_BIT, LEDC_BASE_FREQ);

// 時間間隔設定
unsigned long displayMillis = 0;
unsigned long dhtMillis = 0;
const long displayInterval = 1000;
const long dhtInterval = 2000;

<<<<<<< HEAD
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
              
              // 存儲WiFi憑證
              preferences.begin(preference_namespace, false);
              preferences.putString("ssid", saved_ssid);
              preferences.putString("password", saved_password);
              preferences.end();
              
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
  preferences.begin(preference_namespace, true);
  String temp_ssid = preferences.getString("ssid", "");
  String temp_pass = preferences.getString("password", "");
  preferences.end();
  
  if (temp_ssid.length() < 33 && temp_pass.length() < 65) {
    strcpy(saved_ssid, temp_ssid.c_str());
    strcpy(saved_password, temp_pass.c_str());
  }
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

=======
>>>>>>> origin/main
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

// 使用WiFi憑證連接
bool connectToWiFi(bool useStored) {
  // 检查WiFi凭证是否可用
  if (strlen(saved_ssid) == 0 || strlen(saved_password) == 0) {
    Serial.println("無可用的WiFi憑證，等待藍牙設定");
    
    // 使用 LCD 显示模块显示无凭证信息
    lcdDisplay.displayNoWiFiCredentials();
    
    return false; // 沒有存儲的憑證
  }
  
  WiFi.disconnect();
  WiFi.begin(saved_ssid, saved_password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    // 使用 LCD 显示模块显示连接进度
    lcdDisplay.displayWiFiConnecting(saved_ssid, attempts + 1);
    
    delay(500);
    attempts++;
  }
  
  // 使用 LCD 显示模块显示连接结果
  if (WiFi.status() == WL_CONNECTED) {
    lcdDisplay.displayWiFiResult(true, saved_ssid, WiFi.localIP().toString());
    return true;
  } else {
    lcdDisplay.displayWiFiResult(false, saved_ssid, "");
    return false;
  }
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
          dataManager.setMqttConnected(true);
        }
      }
    } else {
      mqtt_client.loop();
      
      if (currentMillis - lastMqttPublish >= mqttPublishInterval) {
        lastMqttPublish = currentMillis;
        
        float temp = dataManager.getTemperature();
        float humid = dataManager.getHumidity();
        dataManager.setMqttTransmitting(true);  // 修正: 删除额外的参数
        
        // 取得當前時間字符串
        char timeStr[24];
        struct tm timeinfo;
        if (getLocalTime(&timeinfo)) {
          strftime(timeStr, sizeof(timeStr), "%Y-%m-%d %H:%M:%S", &timeinfo);
        } else {
          sprintf(timeStr, "%lu", millis());
        }
        
        // 使用與 SensorData 模型匹配的 JSON 格式
        StaticJsonDocument<200> doc;
        doc["temperature"] = temp;
        doc["humidity"] = humid;
        doc["timestamp"] = timeStr;
        
        char jsonBuffer[200];
        serializeJson(doc, jsonBuffer);
        
        mqtt_client.publish(mqtt_topic, jsonBuffer);
        mqtt_client.publish(mqtt_dht11_topic, jsonBuffer); // 發布到DHT11特定主題
        
        Serial.print("DHT11 數據已發送: ");
        Serial.println(jsonBuffer);
      }
    }
    
    vTaskDelay(10 / portTICK_PERIOD_MS);
  }
}

// DHT11讀取任務
void dhtTask(void *parameter) {
  // 初始化 DHT11 感測器
  dhtSensor.begin();
  vTaskDelay(2000 / portTICK_PERIOD_MS); // 等待感測器穩定
  
  while (true) {
    // 使用模組化的 DHT11Sensor 類讀取數據
    if (dhtSensor.read()) {
      // 讀取成功，更新共享數據
      dataManager.setTemperature(dhtSensor.getTemperature());
      dataManager.setHumidity(dhtSensor.getHumidity());
    }
    
    // 等待下一次讀取時間
    vTaskDelay(3000 / portTICK_PERIOD_MS);
  }
}

// 顯示更新任務
void displayTask(void *parameter) {
  // 初始化显示
  lcdDisplay.begin();
  
  while (true) {
    // 更新 LCDDisplay 对象的数据状态
    lcdDisplay.setTemperature(dataManager.getTemperature());
    lcdDisplay.setHumidity(dataManager.getHumidity());
    lcdDisplay.setMqttConnected(dataManager.getMqttConnected());
    lcdDisplay.setWiFiConnected(WiFi.status() == WL_CONNECTED);
    lcdDisplay.setBleConnected(bleManager.isConnected());
    
    // 处理 MQTT 传输图标闪烁
    if(dataManager.getMqttTransmitting()) {
      lcdDisplay.setMqttTransmitting(true);
      dataManager.updateMqttTransmittingStatus(); // 使用更新方法替代直接修改
    }
    
    // 刷新显示
    lcdDisplay.updateDisplay();
    
    vTaskDelay(displayInterval / portTICK_PERIOD_MS);
  }
}

// 从 Preferences 读取存储的 WiFi 凭证
void loadWiFiCredentials() {
  preferences.begin(preference_namespace, true); // 只读模式
  
  String ssid = preferences.getString("ssid", "");
  String password = preferences.getString("password", "");
  
  ssid.toCharArray(saved_ssid, sizeof(saved_ssid));
  password.toCharArray(saved_password, sizeof(saved_password));
  
  preferences.end();
  
  Serial.print("已加载存储的 WiFi 凭证，SSID: ");
  Serial.println(saved_ssid);
}

// 处理从 BLE 接收到的 WiFi 凭证
void handleWiFiCredentials(const char* message) {
  // 解析格式: "WIFI:SSID=xxx;PASSWORD=xxx;"
  String msg = String(message);
  
  if (msg.startsWith("WIFI:")) {
    int ssidStart = msg.indexOf("SSID=");
    int ssidEnd = msg.indexOf(";", ssidStart);
    int passwordStart = msg.indexOf("PASSWORD=");
    int passwordEnd = msg.indexOf(";", passwordStart);
    
    if (ssidStart != -1 && ssidEnd != -1 && passwordStart != -1 && passwordEnd != -1) {
      String ssid = msg.substring(ssidStart + 5, ssidEnd);
      String password = msg.substring(passwordStart + 9, passwordEnd);
      
      // 检查长度以避免缓冲区溢出
      if (ssid.length() < sizeof(saved_ssid) && password.length() < sizeof(saved_password)) {
        // 存储到 Preferences
        preferences.begin(preference_namespace, false); // 读写模式
        preferences.putString("ssid", ssid);
        preferences.putString("password", password);
        preferences.end();
        
        // 更新当前的 WiFi 凭证
        ssid.toCharArray(saved_ssid, sizeof(saved_ssid));
        password.toCharArray(saved_password, sizeof(saved_password));
        
        wifiCredentialsReceived = true;
        
        Serial.println("已接收并存储新的 WiFi 凭证");
      } else {
        Serial.println("WiFi 凭证太长，无法存储");
      }
    }
  }
}

// BLE 凭证回调处理函数
void onWiFiCredentialReceived(const char* value) {
  handleWiFiCredentials(value);
  
  if (wifiCredentialsReceived) {
    wifiCredentialsReceived = false;
    bool connected = connectToWiFi(true); // 使用存储的凭证连接
    
    // 发送连接结果通知
    if (connected) {
      bleManager.sendWiFiConnectedStatus(WiFi.localIP().toString());
    } else {
      bleManager.sendWiFiFailedStatus();
    }
  }
}

void setup() {
  // 初始化序列通訊
  Serial.begin(115200);
  
  // 初始化共享數據管理器
  dataManager.begin();
  
  // 初始化 LED 管理器
  ledManager.begin();
  
<<<<<<< HEAD
  // DHT11 初始化
  pinMode(DHTPIN, INPUT);
  dht.begin();
  
  // LED控制器初始化
  ledController.begin();
  ledController.setBreathing(true);
  
  // 初始化OLED
  u8g2.begin();
  u8g2.setFont(u8g2_font_ncenB08_tr);
=======
  // 初始化 LCD 显示模块 (在 displayTask 中执行 begin 方法)
>>>>>>> origin/main
  
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
  bleManager.begin();
  bleManager.setOnCredentialCallback(onWiFiCredentialReceived); // 使用正确的方法名
  
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
<<<<<<< HEAD
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
=======
  // 主任務由FreeRTOS處理，這裡只處理BLE管理器的更新
  bleManager.checkConnection(); // 使用正确的方法名
  ledManager.update(); // 更新 LED 管理器状态
>>>>>>> origin/main
  delay(10);
}