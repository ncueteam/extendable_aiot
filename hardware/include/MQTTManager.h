#ifndef MQTT_MANAGER_H
#define MQTT_MANAGER_H

#include <Arduino.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include "WiFiManager.h"

// 定義 MQTT 回調函數的格式
typedef std::function<void(const char*, byte*, unsigned int)> MqttCallbackFunction;

// MQTT管理器類別 - 用於處理MQTT相關功能
class MQTTManager {
private:
    WiFiClient* wifiClient;                  // WiFi客戶端指標
    PubSubClient* mqttClient;                // MQTT客戶端指標
    WiFiManager* wifiManager;                // WiFi管理器指標
    String deviceId;                         // 設備ID
    unsigned long lastMqttReconnectAttempt;  // 上次嘗試重連的時間
    const long mqttReconnectInterval;        // 重連間隔
    unsigned long lastMqttPublish;           // 上次發布的時間
    const long mqttPublishInterval;          // 發布間隔
    SemaphoreHandle_t* mutex;                // 互斥鎖指標
    bool isMqttConnected;                    // MQTT連接狀態
    bool isMqttTransmitting;                 // MQTT傳輸狀態
    unsigned long mqttIconBlinkMillis;       // MQTT圖標閃爍時間
    const long mqttIconBlinkInterval;        // MQTT圖標閃爍間隔
    
    // MQTT設定
    const char* mqttServer;                  // MQTT伺服器地址
    const int mqttPort;                      // MQTT伺服器埠
    const char* mqttTopic;                   // 基本主題
    const char* clientIdPrefix;              // 客戶端ID前綴
    
    // 用戶回調函數
    MqttCallbackFunction userCallback;
    
    // 內部回調處理
    static void handleCallback(char* topic, byte* payload, unsigned int length, void* instance);

public:
    // 建構函數
    MQTTManager(
        WiFiClient* wifiClientPtr, 
        WiFiManager* wifiManagerPtr,
        SemaphoreHandle_t* mutexPtr,
        const char* server = "broker.emqx.io",
        int port = 1883,
        const char* baseTopic = "esp32/sensors",
        const char* clientPrefix = "ESP32_Client_",
        long reconnectInterval = 5000,
        long publishInterval = 5000,
        long blinkInterval = 500
    );
    
    // 析構函數
    ~MQTTManager();
    
    // 初始化MQTT服務
    void begin(const String& deviceIdentifier);
    
    // 設置使用者回調函數
    void setCallback(MqttCallbackFunction callback);
    
    // 訂閱主題
    bool subscribe(const char* topic);
    
    // 取消訂閱主題
    bool unsubscribe(const char* topic);
    
    // 發布消息
    bool publish(const char* topic, const char* payload, bool retain = false);
    
    // 發布JSON格式的數據
    bool publishJson(const char* topic, JsonDocument& doc, bool retain = false);
    
    // 發布標準傳感器數據
    bool publishSensorData(float temperature, float humidity);
    
    // 檢查並維護MQTT連接
    bool loop();
    
    // 嘗試連接MQTT伺服器
    bool connect();
    
    // 獲取連接狀態
    bool isConnected() const;
    
    // 獲取傳輸狀態
    bool isTransmitting() const;
    
    // 獲取傳輸圖標閃爍時間
    unsigned long getIconBlinkMillis() const;
    
    // 設置傳輸狀態
    void setTransmitting(bool state);
    
    // 獲取客戶端實例
    PubSubClient* getClient();
    
    // 獲取基礎主題
    String getBaseTopic() const;

    // 生成完整的設備主題路徑
    String getDeviceTopic(const String& suffix = "") const;
};

#endif // MQTT_MANAGER_H
