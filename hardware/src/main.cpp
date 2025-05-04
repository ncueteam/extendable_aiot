#include <Arduino.h>
#include <Wire.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include "time.h"
#include <Preferences.h>
#include "DHT11Sensor.h"  // DHT11 传感器模块
#include "LCDDisplay.h"   // LCD 显示模块
#include "BLEManager.h"   // BLE 管理器模块

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

// LED Pin定義
const int LED_PIN = 2;
const int LEDC_CHANNEL = 0;
const int LEDC_TIMER_BIT = 8;
const int LEDC_BASE_FREQ = 5000;

// 時間間隔設定
unsigned long previousMillis = 0;
unsigned long displayMillis = 0;
unsigned long dhtMillis = 0;
const long interval = 5;
const long displayInterval = 1000;
const long dhtInterval = 2000;

// LED呼吸燈變數
int breatheValue = 0;
bool increasing = true;

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

void updateLEDBreathing() {
  if (increasing) {
    breatheValue++;
    if (breatheValue >= 255) {
      increasing = false;
    }
  } else {
    breatheValue--;
    if (breatheValue <= 0) {
      increasing = true;
    }
  }
  ledcWrite(LEDC_CHANNEL, breatheValue);
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
      xSemaphoreTake(mutex, portMAX_DELAY);
      sharedData.temperature = dhtSensor.getTemperature();
      sharedData.humidity = dhtSensor.getHumidity();
      xSemaphoreGive(mutex);
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
    xSemaphoreTake(mutex, portMAX_DELAY);
    lcdDisplay.setTemperature(sharedData.temperature);
    lcdDisplay.setHumidity(sharedData.humidity);
    lcdDisplay.setMqttConnected(sharedData.isMqttConnected);
    lcdDisplay.setWiFiConnected(WiFi.status() == WL_CONNECTED);
    lcdDisplay.setBleConnected(bleManager.isConnected());  // 修正为正确的方法名
    
    // 处理 MQTT 传输图标闪烁
    if(sharedData.isMqttTransmitting) {
      lcdDisplay.setMqttTransmitting(true);
      if (millis() - sharedData.mqttIconBlinkMillis >= mqttIconBlinkInterval) {
        sharedData.isMqttTransmitting = false;
      }
    }
    xSemaphoreGive(mutex);
    
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
  
  // 創建互斥鎖
  mutex = xSemaphoreCreateMutex();
  
  // 初始化共享數據
  memset(&sharedData, 0, sizeof(sharedData));
  
  // 配置硬體
  ledcSetup(LEDC_CHANNEL, LEDC_BASE_FREQ, LEDC_TIMER_BIT);
  ledcAttachPin(LED_PIN, LEDC_CHANNEL);
  
  // 初始化 LCD 显示模块 (在 displayTask 中执行 begin 方法)
  
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
  // 主任務由FreeRTOS處理，這裡只處理BLE管理器的更新
  bleManager.checkConnection(); // 使用正确的方法名
  delay(10);
}