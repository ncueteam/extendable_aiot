#ifndef DISPLAY_MANAGER_H
#define DISPLAY_MANAGER_H

#include <Arduino.h>
#include <U8g2lib.h>
#include "WiFiManager.h"
#include "BLEManager.h"
#include "TimeManager.h"

// DisplayManager 類別 - 用於處理OLED顯示相關功能
class DisplayManager {
private:
    U8G2_SH1106_128X64_NONAME_F_HW_I2C* display; // U8G2顯示器指標
    WiFiManager* wifiManager;                    // WiFi管理器指標
    BLEManager* bleManager;                      // BLE管理器指標
    TimeManager* timeManager;                    // 時間管理器指標
    SemaphoreHandle_t* mutex;                    // 互斥鎖指標
    const long mqttIconBlinkInterval;            // MQTT傳輸圖示閃爍間隔
    
    // 紅外線接收資料顯示相關參數
    String irProtocol;                           // 紅外線協議類型
    uint32_t irValue;                            // 紅外線接收到的值
    uint16_t irBits;                             // 紅外線位元數
    unsigned long irDisplayTimeout;              // 紅外線資料顯示超時時間
    bool hasIRData;                              // 是否有紅外線資料

public:
    // 建構函數
    DisplayManager(
        U8G2_SH1106_128X64_NONAME_F_HW_I2C* displayPtr, 
        WiFiManager* wifiManagerPtr, 
        BLEManager* bleManagerPtr,
        TimeManager* timeManagerPtr,
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
    
    // 更新紅外線接收資料
    void updateIRData(const String& protocol, uint32_t value, uint16_t bits);
      // 顯示紅外線接收資料畫面
    bool showIRData();
};

#endif // DISPLAY_MANAGER_H