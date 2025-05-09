#ifndef IR_MANAGER_H
#define IR_MANAGER_H

#include <Arduino.h>
#include <IRremoteESP8266.h>
#include <IRsend.h>
#include <IRrecv.h>
#include <IRutils.h>
#include <ArduinoJson.h>

// 前向宣告以避免循環引用
class DisplayManager;
class MQTTManager;


class IRManager {
private:
    IRsend* irSender;
    IRrecv* irReceiver;
    decode_results results;  // 儲存解碼結果
    const char* irControlTopic;
    const char* irReceiveTopic;
    bool initialized;
    bool receiverInitialized;    int receiverPin;
    TaskHandle_t irReceiverTaskHandle;
    SemaphoreHandle_t irMutex;
    DisplayManager* displayManager;  // 顯示管理器指標

public:
    // 構造函數
    IRManager(int irSendPin, int irRecvPin = -1, const char* controlTopic = "esp32/ir_control", const char* receiveTopic = "esp32/ir_receive");
    
    // 析構函數
    ~IRManager();
      // 初始化IR發射和接收器
    void begin();
    
    // 初始化IR接收器（如果構造時沒有指定接收引腳，可以後續設置）
    void beginReceiver(int pin);
    
    // 獲取IR控制主題
    const char* getIRControlTopic() const;
    
    // 獲取IR接收主題
    const char* getIRReceiveTopic() const;
    
    // 處理MQTT消息
    bool handleMQTTMessage(const char* topic, const char* payload);
    
    // 發送原始IR數據
    void sendRawData(uint16_t* data, uint16_t len, uint16_t khz);
    
    // 發送NEC格式命令
    void sendNEC(uint32_t data, uint16_t bits = 32);
    
    // 發送Sony格式命令
    void sendSony(uint32_t data, uint16_t bits = 12, uint16_t repeat = 2);
    
    // 發送RC5格式命令
    void sendRC5(uint32_t data, uint16_t bits = 12);
    
    // 發送RC6格式命令
    void sendRC6(uint32_t data, uint16_t bits = 20);
    
    // 設置顯示管理器
    void setDisplayManager(DisplayManager* displayManagerPtr);
    
    // 檢查是否有新的IR信號
    bool available();
    
    // 獲取接收到的IR信號並解碼
    bool read();
      // 解析接收到的IR數據並發送到MQTT
    void publishIRReceived(MQTTManager* mqttManager);
    
    // IR接收任務（靜態方法，用於FreeRTOS任務）
    static void irReceiverTask(void* parameter);
      // 啟動IR接收任務
    void startReceiverTask(MQTTManager* mqttManager);
    
    // 將解碼類型轉換為字符串的靜態方法
    static const char* typeToString(decode_type_t type);
};

#endif // IR_MANAGER_H
