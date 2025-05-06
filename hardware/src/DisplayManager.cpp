#include "DisplayManager.h"

// 建構函數
DisplayManager::DisplayManager(
    U8G2_SH1106_128X64_NONAME_F_HW_I2C* displayPtr, 
    WiFiManager* wifiManagerPtr, 
    BLEManager* bleManagerPtr,
    TimeManager* timeManagerPtr,
    SemaphoreHandle_t* mutexPtr,
    long blinkInterval
) : display(displayPtr), 
    wifiManager(wifiManagerPtr), 
    bleManager(bleManagerPtr),
    timeManager(timeManagerPtr),
    mutex(mutexPtr),
    mqttIconBlinkInterval(blinkInterval) {
}

// 初始化顯示器
void DisplayManager::begin() {
    display->begin();
    display->setFont(u8g2_font_ncenB08_tr);
}

// 顯示主畫面 (溫度、濕度、連線狀態等)
void DisplayManager::updateMainScreen(float temperature, float humidity, bool isMqttConnected, 
                                      bool isMqttTransmitting, unsigned long mqttIconBlinkMillis) {
    if (*mutex != NULL) {
        xSemaphoreTake(*mutex, portMAX_DELAY);
    }
    
    display->clearBuffer();
    
    // 顯示標題
    display->setFont(u8g2_font_ncenB10_tr);
    display->setCursor(0, 12);
    display->print("ESP32 AIOT");
    
    // 顯示傳輸圖示
    if (isMqttTransmitting) {
        display->setFont(u8g2_font_open_iconic_embedded_1x_t);
        display->drawGlyph(115, 12, 64);
        
        if (millis() - mqttIconBlinkMillis >= this->mqttIconBlinkInterval) {
            // 在主函數中將其設為false
        }
    }
    
    // 顯示時間和溫濕度
    display->setFont(u8g2_font_ncenB08_tr);
    display->setCursor(0, 25);
    display->print(timeManager->getFormattedTime());
    
    display->setCursor(0, 38);
    display->print("T:");
    display->print(temperature, 1);
    display->print("C H:");
    display->print(humidity, 1);
    display->print("%");
    
    // 顯示WiFi和MQTT狀態
    display->setCursor(0, 51);
    display->print("WiFi:");
    display->print(wifiManager->isConnected() ? "OK" : "X");
    display->print(" MQTT:");
    display->print(isMqttConnected ? "OK" : "X");
    
    // 顯示BLE狀態
    display->setCursor(0, 64);
    display->print("BLE:");
    display->print(bleManager->isServiceActive() ? "ON" : "OFF");
    
    // 如果BLE服務啟動但有設備連接，則添加連接指示
    if (bleManager->isServiceActive() && bleManager->isDeviceConnected()) {
        display->print(" [連接]");
    }
    
    if (*mutex != NULL) {
        xSemaphoreGive(*mutex);
    }
    
    display->sendBuffer();
}

// 顯示WiFi連接狀態畫面
void DisplayManager::showWiFiStatus(const String& message, int progress) {
    display->clearBuffer();
    display->setFont(u8g2_font_ncenB08_tr);
    
    // 將消息拆分為多行顯示
    int yPos = 20;
    int lineHeight = 15;
    String line;
    
    for (int i = 0; i < message.length(); i++) {
        if (message[i] == '\n' || i == message.length() - 1) {
            if (i == message.length() - 1) {
                line += message[i];
            }
            display->setCursor(0, yPos);
            display->print(line);
            line = "";
            yPos += lineHeight;
        } else {
            line += message[i];
        }
    }
    
    // 如果提供了進度值，顯示進度條
    if (progress >= 0) {
        int barWidth = 100;
        int barHeight = 8;
        int x = (128 - barWidth) / 2;
        int y = 60;
        
        // 繪製進度條框
        display->drawFrame(x, y, barWidth, barHeight);
        
        // 繪製進度
        int fillWidth = (progress * barWidth) / 100;
        display->drawBox(x, y, fillWidth, barHeight);
    }
    
    display->sendBuffer();
}

// 顯示訊息畫面
void DisplayManager::showMessage(const String& title, const String& message) {
    display->clearBuffer();
    
    // 顯示標題
    display->setFont(u8g2_font_ncenB10_tr);
    display->setCursor(0, 12);
    display->print(title);
    
    // 顯示訊息
    display->setFont(u8g2_font_ncenB08_tr);
    
    // 將消息拆分為多行顯示
    int yPos = 30;
    int lineHeight = 10;
    String line;
    
    for (int i = 0; i < message.length(); i++) {
        if (message[i] == '\n' || i == message.length() - 1) {
            if (i == message.length() - 1) {
                line += message[i];
            }
            display->setCursor(0, yPos);
            display->print(line);
            line = "";
            yPos += lineHeight;
        } else {
            line += message[i];
        }
    }
    
    display->sendBuffer();
}