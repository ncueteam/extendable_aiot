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
    hasIRData = false;
    irDisplayTimeout = 0;
    irValue = 0;
    irBits = 0;
    irProtocol = "";
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

// 更新紅外線接收資料
void DisplayManager::updateIRData(const String& protocol, uint32_t value, uint16_t bits) {
    Serial.println("DisplayManager: 收到IR信號更新請求");
    Serial.printf("協議: %s, 值: 0x%08X, 位元數: %d\n", protocol.c_str(), value, bits);
    
    this->irProtocol = protocol;
    this->irValue = value;
    this->irBits = bits;
    this->irDisplayTimeout = millis() + 10000;  // 延長顯示時間至10秒
    this->hasIRData = true;
    
    Serial.printf("設置顯示超時至: %lu ms\n", this->irDisplayTimeout);
}

// 顯示紅外線接收資料畫面
bool DisplayManager::showIRData() {
    // 檢查是否有IR資料要顯示以及是否過期
    unsigned long currentTime = millis();
    if (!hasIRData) {
        return false;
    }
    
    if (currentTime > irDisplayTimeout) {
        Serial.println("DisplayManager: IR顯示超時，停止顯示IR數據");
        hasIRData = false;
        return false;
    }
    
    // 顯示剩餘時間
    int remainingTime = (irDisplayTimeout - currentTime) / 1000;
    if (remainingTime % 2 == 0) { // 每2秒輸出一次日誌
        Serial.printf("DisplayManager: 顯示IR數據中，剩餘 %d 秒\n", remainingTime);
    }

    if (*mutex != NULL) {
        xSemaphoreTake(*mutex, portMAX_DELAY);
    }
    
    display->clearBuffer();
    
    // 顯示標題
    display->setFont(u8g2_font_ncenB10_tr);
    display->setCursor(0, 12);
    display->print("IR Received");
    
    // 顯示IR詳細信息
    display->setFont(u8g2_font_ncenB08_tr);
    
    // 顯示協議類型
    display->setCursor(0, 28);
    display->print("Protocol: ");
    display->print(irProtocol);
    
    // 顯示接收到的值 (十六進制)
    display->setCursor(0, 40);
    char hexValue[12];
    sprintf(hexValue, "0x%08X", irValue);
    display->print("Value: ");
    display->print(hexValue);
    
    // 顯示位元數
    display->setCursor(0, 52);
    display->print("Bits: ");
    display->print(irBits);
      // 顯示倒數計時
    int remaining = (irDisplayTimeout - millis()) / 1000 + 1;
    display->setCursor(100, 64);
    display->print(remaining);
    display->print("s");
    
    if (*mutex != NULL) {
        xSemaphoreGive(*mutex);
    }
    
    display->sendBuffer();
    return true;
}