#include <Arduino.h>
#include <U8g2lib.h>
#include <Wire.h>
#include <WiFi.h>
#include "time.h"

// WiFi設定
const char* ssid = "Yun";
const char* password = "0937565253";

// NTP服務器設定
const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = 28800;  // GMT+8 (台灣時區)
const int   daylightOffset_sec = 0;

// LED Pin定義
const int LED_PIN = 2;  // 使用ESP32內建的LED
const int LEDC_CHANNEL = 0;  // 使用LEDC通道0
const int LEDC_TIMER_BIT = 8;  // 8位元解析度
const int LEDC_BASE_FREQ = 5000;  // 5KHz頻率

// 時間間隔設定
unsigned long previousMillis = 0;     // 用於LED更新
unsigned long displayMillis = 0;      // 用於顯示更新
const long interval = 5;              // LED更新間隔(毫秒)
const long displayInterval = 1000;    // 顯示更新間隔(毫秒)

// LED呼吸燈變數
int breatheValue = 0;
bool increasing = true;

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

void updateDisplay() {
  u8g2.clearBuffer();
  
  // 顯示標題
  u8g2.setFont(u8g2_font_ncenB10_tr);
  u8g2.setCursor(0, 12);
  u8g2.print("ESP32 AIOT");
  
  // 顯示日期和時間
  u8g2.setFont(u8g2_font_ncenB08_tr);
  u8g2.setCursor(0, 28);
  u8g2.print(getFormattedDate());
  u8g2.setCursor(0, 40);
  u8g2.print(getFormattedTime());
  
  // 顯示WiFi狀態
  u8g2.setCursor(0, 55);
  if (WiFi.status() == WL_CONNECTED) {
    u8g2.print("WiFi: ");
    u8g2.print(WiFi.localIP().toString());
  } else {
    u8g2.print("WiFi: Disconnected");
  }
  
  u8g2.sendBuffer();
}

void setup() {
  // 配置LEDC
  ledcSetup(LEDC_CHANNEL, LEDC_BASE_FREQ, LEDC_TIMER_BIT);
  ledcAttachPin(LED_PIN, LEDC_CHANNEL);
  
  // 初始化OLED
  u8g2.begin();
  u8g2.setFont(u8g2_font_ncenB08_tr); // 設置字體
  u8g2.enableUTF8Print();  // 啟用UTF8支援
  
  // 連接WiFi
  connectToWiFi();
  
  // 配置時間
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
}

void loop() {
  unsigned long currentMillis = millis();
  
  // 更新LED呼吸效果
  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis;
    updateLEDBreathing();
  }
  
  // 更新顯示
  if (currentMillis - displayMillis >= displayInterval) {
    displayMillis = currentMillis;
    updateDisplay();
  }
  
  // 檢查WiFi連接狀態
  if (WiFi.status() != WL_CONNECTED) {
    connectToWiFi();  // 如果斷線就嘗試重新連接
  }
}