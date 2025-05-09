#include <Arduino.h>
#include <U8g2lib.h>
#include <Wire.h>
#include <DHT.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include "ConfigManager.h" // 引入配置管理器
#include "LED.h" // LED控制類
#include "BLEManager.h" // BLE管理器
#include "WiFiManager.h" // WiFi管理器
#include "DisplayManager.h" // 顯示管理器
#include "TimeManager.h" // 時間管理器
#include "IRManager.h" // IR管理器
#include "MQTTManager.h" // MQTT管理器

// 前向宣告
void handleWiFiCredentials(const char* message);
void onBLEStatusChange(bool connected, const String& message);
void onWiFiStatusChange(bool connected, const String& message);
void onWiFiDisplayUpdate(const String& message, int progress);

// 創建BLEManager實例
BLEManager bleManager("ESP32_AIOT_BLE");
bool wifiCredentialsReceived = false;

// 創建ConfigManager實例
ConfigManager configManager("wifi_cred");

// 創建WiFiManager實例
WiFiManager wifiManager(&configManager);

// 創建TimeManager實例
TimeManager timeManager("pool.ntp.org", 28800, 0, &wifiManager);

// IR引腳定義
#define IR_LED_PIN 32  // ESP32 GPIO32作為IR發射引腳
#define IR_RECV_PIN 23  // ESP32 GPIO23作為IR接收引腳

// 創建IRManager實例
IRManager irManager(IR_LED_PIN, IR_RECV_PIN);

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
} sharedData;

// 設備ID
String deviceId = "";

// MQTT設定
const char* mqtt_server = "broker.emqx.io";
const int mqtt_port = 1883;
const char* mqtt_topic = "esp32/sensors";
const char* client_id = "ESP32_Client_";
const long mqttIconBlinkInterval = 500;

// MQTT客戶端設定
WiFiClient espClient;
// 創建MQTTManager實例
MQTTManager mqttManager(&espClient, &wifiManager, &mutex, mqtt_server, mqtt_port, mqtt_topic, client_id, 5000, 5000, mqttIconBlinkInterval);

// MQTT 主題設定 - 在全局添加
String mqttTopic = "esp32/device/";   // 將附加 deviceId/dht11

// DHT11 設定
#define DHTPIN 14
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

// LED Pin定義

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

// 創建DisplayManager實例
DisplayManager displayManager(&u8g2, &wifiManager, &bleManager, &timeManager, &mutex, mqttIconBlinkInterval);

// BLE狀態改變回調
void onBLEStatusChange(bool connected, const String& message) {
  // 可在此處理BLE連接狀態變更
  // 例如更新UI或其他操作
}

// WiFi狀態改變回調
void onWiFiStatusChange(bool connected, const String& message) {
  Serial.println(message);
}

// WiFi顯示更新回調
void onWiFiDisplayUpdate(const String& message, int progress) {
  // 使用DisplayManager顯示WiFi連接狀態
  displayManager.showWiFiStatus(message, progress);
}

// 處理WiFi憑證
void handleWiFiCredentials(const char* message) {
  if (wifiManager.parseCredentials(message)) {
    wifiCredentialsReceived = true;
    
    // 嘗試連接WiFi
    bool connected = wifiManager.connect();
    
    // 透過BLE發送連接結果通知
    String statusMsg;
    if (connected) {
      // 如果設置了房間ID，則在連接成功訊息中也返回房間ID
      if (wifiManager.hasRoomID()) {
        statusMsg = "WIFI_CONNECTED:" + wifiManager.getIPAddress() + "|ROOM:" + wifiManager.getRoomID();
      } else {
        statusMsg = "WIFI_CONNECTED:" + wifiManager.getIPAddress();
      }
    } else {
      statusMsg = "WIFI_FAILED";
    }
    bleManager.sendStatusNotification(statusMsg);
  }
}

// MQTT回調函數
void mqtt_callback(const char* topic, byte* payload, unsigned int length) {
  // 簡化處理方式，減少內存使用
  if (length > 0) {
    // 將 payload 轉換為 null 結尾的字串
    payload[length] = '\0';
    String payloadStr = String((char*)payload);
    
    // 嘗試使用IRManager處理消息
    if (irManager.handleMQTTMessage(topic, payloadStr.c_str())) {
      // 如果IRManager已處理，則返回
      return;
    }
    
    // 可以在這裡處理來自Flutter的其他命令
  }
}

// MQTT通訊任務
void mqttTask(void *parameter) {
  while (true) {    // 使用MQTTManager處理連接和消息循環
    mqttManager.loop();
    
    // 獲取當前傳感器數據
    xSemaphoreTake(mutex, portMAX_DELAY);
    float temp = sharedData.temperature;
    float humid = sharedData.humidity;
    xSemaphoreGive(mutex);
    
    // 發布傳感器數據
    mqttManager.publishSensorData(temp, humid);
    
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

// 顯示更新任務
void displayTask(void *parameter) {
  static bool showingIrData = false;
  static unsigned long irDisplayStartTime = 0;
  
  while (true) {
  // 使用DisplayManager更新主畫面或顯示IR數據
    xSemaphoreTake(mutex, portMAX_DELAY);
    float temp = sharedData.temperature;
    float humid = sharedData.humidity;
    bool isMqttConnected = mqttManager.isConnected();
    bool isMqttTransmitting = mqttManager.isTransmitting();
    unsigned long mqttIconBlinkMillis = mqttManager.getIconBlinkMillis();
    xSemaphoreGive(mutex);
    
    // 優先顯示IR數據，如果有的話
    bool hasIrData = displayManager.showIRData();
    
    // 如果沒有IR數據要顯示，則顯示主畫面
    if (!hasIrData) {
      displayManager.updateMainScreen(temp, humid, isMqttConnected, isMqttTransmitting, mqttIconBlinkMillis);
    }
    
    vTaskDelay(displayInterval / portTICK_PERIOD_MS);
  }
}

void setup() {
  // 初始化序列通訊
  Serial.begin(115200);
  
  // 初始化設備ID（使用MAC地址）
  deviceId = WiFi.macAddress();
  deviceId.replace(":", ""); // 移除冒號使其更簡潔
  Serial.println("裝置ID: " + deviceId);
  
  // 創建互斥鎖
  mutex = xSemaphoreCreateMutex();
  
  // 初始化共享數據
  memset(&sharedData, 0, sizeof(sharedData));
  // DHT11 初始化
  pinMode(DHTPIN, INPUT);
  dht.begin();
    // 初始化紅外線發射器
  irManager.setDisplayManager(&displayManager);  // 連接顯示管理器
  irManager.begin();
  
  // LED控制器初始化
  ledController.begin();
  ledController.setBreathing(true);
  
  // 初始化BLE並設置回調
  bleManager.setCredentialCallback(handleWiFiCredentials);
  bleManager.setStatusCallback(onBLEStatusChange);
  bleManager.begin();
  
  // 初始化WiFi
  wifiManager.setStatusCallback(onWiFiStatusChange);
  wifiManager.setDisplayCallback(onWiFiDisplayUpdate);
  wifiManager.begin();
  
  // 嘗試連接WiFi
  wifiManager.connect();
  
  // 初始化顯示管理器
  displayManager.begin();
    // 初始化時間管理器
  if (wifiManager.isConnected()) {
    timeManager.begin();
  }
  
  // 初始化MQTT管理器
  mqttManager.begin(deviceId);
  mqttManager.setCallback(mqtt_callback);
  
  // 訂閱必要的主題
  if (mqttManager.isConnected()) {
    mqttManager.subscribe("esp32/commands");
    mqttManager.subscribe(irManager.getIRControlTopic());
    mqttManager.publish(irManager.getIRReceiveTopic(), "IR接收器已啟動", true);
  }
  
  // 啟動IR接收任務
  irManager.startReceiverTask(&mqttManager);
  
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
  bleManager.handleConnection();
  
  // 更新LED呼吸效果
  ledController.updateBreathing();
  
  // 主任務由FreeRTOS處理
  delay(10);
}