#ifndef DISPLAY_MANAGER_H
#define DISPLAY_MANAGER_H

#include <Arduino.h>
#include <U8g2lib.h>
#include "WiFiManager.h"
#include "BLEManager.h"
#include "time.h"

// DisplayManager 類別 - 用於處理OLED顯示相關功能
class DisplayManager {
private:
    U8G2_SH1106_128X64_NONAME_F_HW_I2C* display; // U8G2顯示器指標
    WiFiManager* wifiManager;                    // WiFi管理器指標
    BLEManager* bleManager;                      // BLE管理器指標
    SemaphoreHandle_t* mutex;                    // 互斥鎖指標
    const long mqttIconBlinkInterval;            // MQTT傳輸圖示閃爍間隔

    // 獲取格式化時間字串
    String getFormattedTime();

    // 獲取格式化日期字串
    String getFormattedDate();

public:
    // 建構函數
    DisplayManager(
        U8G2_SH1106_128X64_NONAME_F_HW_I2C* displayPtr, 
        WiFiManager* wifiManagerPtr, 
        BLEManager* bleManagerPtr,
        SemaphoreHandle_t* mutexPtr,
        long blinkInterval = 500
    );

    // 初始化顯示器
    void begin();

    // 顯示主畫面 (溫度、濕度、連線狀態等)
    void updateMainScreen(float temperature, float humidity, bool isMqttConnected, 
                          bool isMqttTransmitting, unsigned long mqttIconBlinkMillis);

    // 顯示WiFi連接狀態畫面
    void showWiFiStatus(const String& message, int progress = -1);

    // 顯示訊息畫面
    void showMessage(const String& title, const String& message);
};

#endif // DISPLAY_MANAGER_H