#include "../include/LCDDisplay.h"
#include "time.h"
#include <Wire.h>

LCDDisplay::LCDDisplay() : 
    u8g2(U8G2_R0, U8X8_PIN_NONE),
    temperature(0),
    humidity(0),
    isMqttConnected(false),
    isMqttTransmitting(false),
    isWiFiConnected(false),
    isBleConnected(false),
    mqttIconBlinkMillis(0),
    mqttIconBlinkInterval(500) {
}

// 扫描I2C设备的辅助函数
void scanI2CDevices() {
    Serial.println("扫描I2C设备...");
    byte error, address;
    int deviceCount = 0;
    
    for(address = 1; address < 127; address++) {
        Wire.beginTransmission(address);
        error = Wire.endTransmission();
        
        if (error == 0) {
            Serial.print("I2C设备找到，地址: 0x");
            if (address < 16) {
                Serial.print("0");
            }
            Serial.println(address, HEX);
            deviceCount++;
        } else if (error == 4) {
            Serial.print("地址0x");
            if (address < 16) {
                Serial.print("0");
            }
            Serial.print(address, HEX);
            Serial.println("出现未知错误");
        }
    }
    
    if (deviceCount == 0) {
        Serial.println("未找到I2C设备，请检查连线");
    } else {
        Serial.print("找到");
        Serial.print(deviceCount);
        Serial.println("个I2C设备");
    }
}

// 添加一个测试显示屏的函数
void LCDDisplay::testDisplay() {
    // 测试1：全屏填充
    u8g2.clearBuffer();
    u8g2.drawBox(0, 0, 128, 64);
    u8g2.sendBuffer();
    delay(500);
    
    // 测试2：水平线
    u8g2.clearBuffer();
    for(int i = 0; i < 64; i += 8) {
        u8g2.drawHLine(0, i, 128);
    }
    u8g2.sendBuffer();
    delay(500);
    
    // 测试3：垂直线
    u8g2.clearBuffer();
    for(int i = 0; i < 128; i += 8) {
        u8g2.drawVLine(i, 0, 64);
    }
    u8g2.sendBuffer();
    delay(500);
    
    // 清屏
    u8g2.clearBuffer();
    u8g2.sendBuffer();
}

void LCDDisplay::begin() {
    Wire.begin();
    scanI2CDevices();
    Serial.println("尝试初始化OLED显示器...");
    bool initSuccess = u8g2.begin();
    
    if (initSuccess) {
        Serial.println("OLED显示器初始化成功!");
    } else {
        Serial.println("OLED显示器初始化失败! 请检查连接或尝试不同的I2C地址");
        delay(1000);
        u8g2.initDisplay();
        if (u8g2.getU8x8()->display_cb != 0) {
            Serial.println("第二次尝试成功");
            u8g2.setPowerSave(0);
        } else {
            Serial.println("第二次尝试也失败，可能是硬件问题");
        }
    }
    
    u8g2.setFont(u8g2_font_ncenB08_tr);
    
    u8g2.clearBuffer();
    u8g2.setCursor(0, 20);
    u8g2.print("LCD Test");
    u8g2.setCursor(0, 40);
    u8g2.print("Initializing...");
    u8g2.sendBuffer();
    delay(1000);
    
    testDisplay();
}

void LCDDisplay::updateDisplay() {
    u8g2.clearBuffer();
    
    // 显示标题
    u8g2.setFont(u8g2_font_ncenB10_tr);
    u8g2.setCursor(0, 12);
    u8g2.print("ESP32 AIOT");
    
    // 显示传输图标
    if (isMqttTransmitting) {
        u8g2.setFont(u8g2_font_open_iconic_embedded_1x_t);
        u8g2.drawGlyph(115, 12, 64);
        
        if (millis() - mqttIconBlinkMillis >= mqttIconBlinkInterval) {
            isMqttTransmitting = false;
        }
    }
    
    // 显示时间和温湿度
    u8g2.setFont(u8g2_font_ncenB08_tr);
    u8g2.setCursor(0, 25);
    u8g2.print(getFormattedTime());
    
    u8g2.setCursor(0, 38);
    u8g2.print("T:");
    u8g2.print(temperature, 1);
    u8g2.print("C H:");
    u8g2.print(humidity, 1);
    u8g2.print("%");
    
    // 显示WiFi和MQTT状态
    u8g2.setCursor(0, 51);
    u8g2.print("WiFi:");
    u8g2.print(isWiFiConnected ? "OK" : "X");
    u8g2.print(" MQTT:");
    u8g2.print(isMqttConnected ? "OK" : "X");
    
    // 显示BLE状态
    u8g2.setCursor(0, 64);
    u8g2.print("BLE:");
    u8g2.print(isBleConnected ? "OK" : "X");
    
    u8g2.sendBuffer();
}

void LCDDisplay::setTemperature(float temp) {
    temperature = temp;
}

void LCDDisplay::setHumidity(float humid) {
    humidity = humid;
}

void LCDDisplay::setMqttConnected(bool connected) {
    isMqttConnected = connected;
}

void LCDDisplay::setWiFiConnected(bool connected) {
    isWiFiConnected = connected;
}

void LCDDisplay::setBleConnected(bool connected) {
    isBleConnected = connected;
}

void LCDDisplay::setMqttTransmitting(bool transmitting) {
    if (transmitting) {
        isMqttTransmitting = true;
        mqttIconBlinkMillis = millis();
    } else {
        isMqttTransmitting = false;
    }
}

void LCDDisplay::clearDisplay() {
    u8g2.clearBuffer();
    u8g2.sendBuffer();
}

void LCDDisplay::displayWiFiConnecting(const char* ssid, int attempt) {
    u8g2.clearBuffer();
    u8g2.setFont(u8g2_font_ncenB08_tr);
    u8g2.setCursor(0, 20);
    u8g2.print("Connecting to WiFi");
    u8g2.setCursor(0, 35);
    u8g2.print("SSID: ");
    u8g2.print(ssid);
    u8g2.setCursor(0, 50);
    u8g2.print("Attempt: ");
    u8g2.print(attempt);
    u8g2.sendBuffer();
}

void LCDDisplay::displayWiFiResult(bool connected, const char* ssid, String ipAddress) {
    u8g2.clearBuffer();
    if (connected) {
        u8g2.setCursor(0, 20);
        u8g2.print("WiFi Connected!");
        u8g2.setCursor(0, 35);
        u8g2.print("SSID: ");
        u8g2.print(ssid);
        u8g2.setCursor(0, 50);
        u8g2.print(ipAddress);
        isWiFiConnected = true;
    } else {
        u8g2.setCursor(0, 20);
        u8g2.print("WiFi Connection");
        u8g2.setCursor(0, 35);
        u8g2.print("Failed!");
        u8g2.setCursor(0, 50);
        u8g2.print("Check credentials");
        isWiFiConnected = false;
    }
    u8g2.sendBuffer();
}

void LCDDisplay::displayNoWiFiCredentials() {
    u8g2.clearBuffer();
    u8g2.setFont(u8g2_font_ncenB08_tr);
    u8g2.setCursor(0, 20);
    u8g2.print("No WiFi Credentials");
    u8g2.setCursor(0, 35);
    u8g2.print("Please use BLE app");
    u8g2.setCursor(0, 50);
    u8g2.print("to setup WiFi");
    u8g2.sendBuffer();
}

String LCDDisplay::getFormattedTime() {
    struct tm timeinfo;
    if(!getLocalTime(&timeinfo)){
        return "Failed to get time";
    }
    char timeString[20];
    strftime(timeString, sizeof(timeString), "%H:%M:%S", &timeinfo);
    return String(timeString);
}

String LCDDisplay::getFormattedDate() {
    struct tm timeinfo;
    if(!getLocalTime(&timeinfo)){
        return "Failed to get date";
    }
    char dateString[20];
    strftime(dateString, sizeof(dateString), "%Y-%m-%d", &timeinfo);
    return String(dateString);
}