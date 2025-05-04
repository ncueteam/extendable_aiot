#ifndef LCD_DISPLAY_H
#define LCD_DISPLAY_H

#include <Arduino.h>
#include <U8g2lib.h>
#include <WiFi.h>

// 前向声明
class LCDDisplay {
private:
    // U8G2对象 (使用硬件I2C)
    U8G2_SH1106_128X64_NONAME_F_HW_I2C u8g2;
    
    // 状态变量
    float temperature;
    float humidity;
    bool isMqttConnected;
    bool isMqttTransmitting;
    bool isWiFiConnected;
    bool isBleConnected;
    unsigned long mqttIconBlinkMillis;
    unsigned long mqttIconBlinkInterval;
    
    // 获取格式化时间
    String getFormattedTime();
    
    // 获取格式化日期
    String getFormattedDate();

public:
    // 构造函数
    LCDDisplay();
    
    // 初始化显示
    void begin();
    
    // 更新显示内容
    void updateDisplay();
    
    // 设置各种状态
    void setTemperature(float temp);
    void setHumidity(float humid);
    void setMqttConnected(bool connected);
    void setWiFiConnected(bool connected);
    void setBleConnected(bool connected);
    
    // 设置MQTT传输状态
    void setMqttTransmitting(bool transmitting);
    
    // 清除显示
    void clearDisplay();
    
    // 显示连接WiFi的过程
    void displayWiFiConnecting(const char* ssid, int attempt);
    
    // 显示WiFi连接结果
    void displayWiFiResult(bool connected, const char* ssid, String ipAddress);
    
    // 显示无WiFi凭证信息
    void displayNoWiFiCredentials();
};

#endif // LCD_DISPLAY_H