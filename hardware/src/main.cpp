#include <Arduino.h>
#include <U8g2lib.h>
#include <Wire.h>
#include <WiFi.h>
#include <DHT.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include "time.h"

// FreeRTOS相關定義
#define CORE_0 0  // 通訊核心
#define CORE_1 1  // 顯示核心
#define TASK_STACK_SIZE 8192  // 增加到8KB
#define MQTT_PRIORITY 1
#define DISPLAY_PRIORITY 2
#define DHT_PRIORITY 1

// 看門狗超時時間設定
#define WATCHDOG_TIMEOUT_MS 10000  // 10秒

// 互斥鎖用於保護共享數據
SemaphoreHandle_t mutex = NULL;

// 任務句柄
TaskHandle_t mqttTaskHandle = NULL;
TaskHandle_t displayTaskHandle = NULL;
TaskHandle_t dhtTaskHandle = NULL;  // 添加DHT任務句柄

// 共享數據結構
struct SharedData {
  float temperature;
  float humidity;
  bool isMqttConnected;
  bool isMqttTransmitting;
  unsigned long mqttIconBlinkMillis;
} sharedData;

// WiFi設定
const char* ssid = "Yun";
const char* password = "0937565253";

// NTP服務器設定
const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = 28800;  // GMT+8 (台灣時區)
const int   daylightOffset_sec = 0;

// MQTT設定
const char* mqtt_server = "broker.emqx.io";  // 改用 EMQX 的公共 broker
const int mqtt_port = 1883;
const char* mqtt_topic = "esp32/sensors";
const char* client_id = "ESP32_Client_";  // 將在連接時加上隨機數
const long mqttIconBlinkInterval = 500;    // MQTT圖示閃爍間隔(毫秒)

// MQTT客戶端設定
WiFiClient espClient;
PubSubClient mqtt_client(espClient);
unsigned long lastMqttReconnectAttempt = 0;
const long mqttReconnectInterval = 5000;  // 重連間隔5秒
unsigned long lastMqttPublish = 0;
const long mqttPublishInterval = 5000;    // 發布間隔5秒

// DHT11 設定
#define DHTPIN 14     // 確認這是您的接線腳位
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

// LED Pin定義
const int LED_PIN = 2;  // 使用ESP32內建的LED
const int LEDC_CHANNEL = 0;  // 使用LEDC通道0
const int LEDC_TIMER_BIT = 8;  // 8位元解析度
const int LEDC_BASE_FREQ = 5000;  // 5KHz頻率

// 時間間隔設定
unsigned long previousMillis = 0;     // 用於LED更新
unsigned long displayMillis = 0;      // 用於顯示更新
unsigned long dhtMillis = 0;         // 用於DHT11更新
const long interval = 5;              // LED更新間隔(毫秒)
const long displayInterval = 1000;    // 顯示更新間隔(毫秒)
const long dhtInterval = 2000;       // DHT11讀取間隔(毫秒)

// LED呼吸燈變數
int breatheValue = 0;
bool increasing = true;

// 顯示更新標誌
bool displayNeedsUpdate = false;

// 創建U8g2顯示器物件 (使用硬體I2C)
U8G2_SH1106_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, /* reset=*/U8X8_PIN_NONE);

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

void connectToWiFi() {
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    u8g2.clearBuffer();
    u8g2.setFont(u8g2_font_ncenB08_tr);
    u8g2.setCursor(0, 20);
    u8g2.print("Connecting to WiFi");
    u8g2.setCursor(0, 35);
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
    u8g2.print("IP: ");
    u8g2.setCursor(0, 50);
    u8g2.print(WiFi.localIP().toString());
  } else {
    u8g2.setCursor(0, 20);
    u8g2.print("WiFi Connection");
    u8g2.setCursor(0, 35);
    u8g2.print("Failed!");
  }
  u8g2.sendBuffer();
  delay(2000);
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
  // 處理接收到的訊息
  String message;
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  
  // 可以在這裡處理來自Flutter的命令
  // TODO: 實作命令處理邏輯
}

bool mqtt_connect() {
  if (!mqtt_client.connected()) {
    Serial.println("嘗試連接到 MQTT...");
    
    // 生成唯一的客戶端ID
    String uniqueClientId = String(client_id) + String(random(0xffff), HEX);
    
    Serial.printf("Broker: %s:%d\n", mqtt_server, mqtt_port);
    Serial.printf("Client ID: %s\n", uniqueClientId.c_str());
    
    // 設置遺囑消息
    const char* willTopic = "esp32/status";
    const char* willMessage = "offline";
    bool willRetain = true;
    
    if (mqtt_client.connect(uniqueClientId.c_str(), NULL, NULL, willTopic, 0, willRetain, willMessage)) {
      Serial.println("MQTT 連接成功！");
      mqtt_client.subscribe("esp32/commands");
      mqtt_client.publish("esp32/status", "online", true);
      return true;
    } else {
      int state = mqtt_client.state();
      Serial.printf("MQTT 連接失敗，錯誤碼=%d\n", state);
      switch (state) {
        case -4: Serial.println("MQTT_CONNECTION_TIMEOUT"); break;
        case -3: Serial.println("MQTT_CONNECTION_LOST"); break;
        case -2: Serial.println("MQTT_CONNECT_FAILED"); break;
        case -1: Serial.println("MQTT_DISCONNECTED"); break;
        case 1: Serial.println("MQTT_CONNECT_BAD_PROTOCOL"); break;
        case 2: Serial.println("MQTT_CONNECT_BAD_CLIENT_ID"); break;
        case 3: Serial.println("MQTT_CONNECT_UNAVAILABLE"); break;
        case 4: Serial.println("MQTT_CONNECT_BAD_CREDENTIALS"); break;
        case 5: Serial.println("MQTT_CONNECT_UNAUTHORIZED"); break;
      }
      return false;
    }
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
        // 創建JSON文件
        StaticJsonDocument<200> doc;
        doc["temperature"] = sharedData.temperature;
        doc["humidity"] = sharedData.humidity;
        doc["timestamp"] = getFormattedTime();
        
        // 序列化JSON
        char jsonBuffer[200];
        serializeJson(doc, jsonBuffer);
        
        // 設置傳輸指示
        sharedData.isMqttTransmitting = true;
        sharedData.mqttIconBlinkMillis = currentMillis;
        xSemaphoreGive(mutex);
        
        // 發布數據
        mqtt_client.publish(mqtt_topic, jsonBuffer);
      }
    }
    
    // 給其他任務一些執行時間
    vTaskDelay(10 / portTICK_PERIOD_MS);
  }
}

// DHT11讀取任務
void dhtTask(void *parameter) {
  const int maxRetries = 3;
  const int retryDelay = 1000; // 1秒
  
  // 等待DHT11穩定
  vTaskDelay(2000 / portTICK_PERIOD_MS);

  while (true) {
    int retryCount = 0;
    float newTemp, newHum;
    bool readSuccess = false;

    while (retryCount < maxRetries && !readSuccess) {
      newTemp = dht.readTemperature();
      newHum = dht.readHumidity();
      
      if (!isnan(newTemp) && !isnan(newHum) && newTemp != 0 && newHum != 0) {
        readSuccess = true;
        Serial.printf("DHT11讀取成功 - 溫度: %.1f°C, 濕度: %.1f%%\n", newTemp, newHum);
        
        xSemaphoreTake(mutex, portMAX_DELAY);
        sharedData.temperature = newTemp;
        sharedData.humidity = newHum;
        xSemaphoreGive(mutex);
      } else {
        retryCount++;
        Serial.printf("DHT11讀取失敗 #%d - 溫度: %.1f, 濕度: %.1f\n", 
                     retryCount, newTemp, newHum);
        if (retryCount < maxRetries) {
          vTaskDelay(retryDelay / portTICK_PERIOD_MS);
        }
      }
    }
    
    if (!readSuccess) {
      Serial.println("DHT11連續讀取失敗，但繼續執行");
    }
    
    // 增加讀取間隔，避免過於頻繁讀取
    vTaskDelay(3000 / portTICK_PERIOD_MS);
  }
}

// 函數前向宣告
void updateDisplay();

// 顯示更新任務
void displayTask(void *parameter) {
  while (true) {
    updateDisplay();
    vTaskDelay(displayInterval / portTICK_PERIOD_MS);
  }
}

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
  
  // 顯示日期和時間
  u8g2.setFont(u8g2_font_ncenB08_tr);
  u8g2.setCursor(0, 25);
  u8g2.print(getFormattedTime());
  
  // 顯示溫濕度
  u8g2.setCursor(0, 38);
  u8g2.print("Temp: ");
  u8g2.print(sharedData.temperature, 1);
  u8g2.print("C");
  
  u8g2.setCursor(0, 51);
  u8g2.print("Humid: ");
  u8g2.print(sharedData.humidity, 1);
  u8g2.print("%");
  
  // 顯示WiFi和MQTT狀態
  u8g2.setCursor(0, 64);
  u8g2.print("WiFi:");
  u8g2.print(WiFi.status() == WL_CONNECTED ? "OK" : "X");
  u8g2.print(" MQTT:");
  u8g2.print(sharedData.isMqttConnected ? "OK" : "X");
  
  xSemaphoreGive(mutex);
  u8g2.sendBuffer();
}

void setup() {
  // 初始化序列通訊，用於調試
  Serial.begin(115200);
  Serial.println("ESP32 啟動");
  
  // 創建互斥鎖
  mutex = xSemaphoreCreateMutex();
  
  // 初始化共享數據
  sharedData.temperature = 0;
  sharedData.humidity = 0;
  sharedData.isMqttConnected = false;
  sharedData.isMqttTransmitting = false;
  
  // DHT11 初始化
  pinMode(DHTPIN, INPUT);
  dht.begin();
  Serial.println("DHT11 初始化完成");
  
  // 配置硬體
  ledcSetup(LEDC_CHANNEL, LEDC_BASE_FREQ, LEDC_TIMER_BIT);
  ledcAttachPin(LED_PIN, LEDC_CHANNEL);
  
  // 初始化OLED
  u8g2.begin();
  u8g2.setFont(u8g2_font_ncenB08_tr);
  u8g2.enableUTF8Print();
  
  // 連接WiFi
  connectToWiFi();
  
  // 配置時間
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
  
  // 初始化MQTT
  mqtt_client.setServer(mqtt_server, mqtt_port);
  mqtt_client.setCallback(mqtt_callback);
  
  // 創建任務
  xTaskCreatePinnedToCore(
    mqttTask,        // 任務函數
    "MQTTTask",      // 任務名稱
    TASK_STACK_SIZE, // 堆疊大小
    NULL,            // 參數
    MQTT_PRIORITY,   // 優先級
    &mqttTaskHandle, // 任務句柄
    CORE_0          // 執行核心
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
    1,
    &dhtTaskHandle,
    CORE_0
  );
}

void loop() {
  // 主循環現在可以空著
  vTaskDelete(NULL);  // 刪除setup/loop任務
}