#include "MQTTManager.h"

// 建構函數
MQTTManager::MQTTManager(
    WiFiClient* wifiClientPtr, 
    WiFiManager* wifiManagerPtr,
    SemaphoreHandle_t* mutexPtr,
    const char* server,
    int port,
    const char* baseTopic,
    const char* clientPrefix,
    long reconnectInterval,
    long publishInterval,
    long blinkInterval
) : wifiClient(wifiClientPtr),
    wifiManager(wifiManagerPtr),
    mqttServer(server),
    mqttPort(port),
    mqttTopic(baseTopic),
    clientIdPrefix(clientPrefix),
    mutex(mutexPtr),
    lastMqttReconnectAttempt(0),
    lastMqttPublish(0),
    mqttReconnectInterval(reconnectInterval),
    mqttPublishInterval(publishInterval),
    mqttIconBlinkInterval(blinkInterval),
    isMqttConnected(false),
    isMqttTransmitting(false),
    mqttIconBlinkMillis(0) {
    
    mqttClient = new PubSubClient(*wifiClientPtr);
}

// 析構函數
MQTTManager::~MQTTManager() {
    if (mqttClient) {
        if (mqttClient->connected()) {
            mqttClient->disconnect();
        }
        delete mqttClient;
    }
}

// 初始化MQTT服務
void MQTTManager::begin(const String& deviceIdentifier) {
    deviceId = deviceIdentifier;
    
    mqttClient->setServer(mqttServer, mqttPort);
    mqttClient->setCallback([this](char* topic, byte* payload, unsigned int length) {
        handleCallback(topic, payload, length, this);
    });
    
    connect();
    
    Serial.println("MQTT管理器已初始化");
}

// 靜態回調處理函數
void MQTTManager::handleCallback(char* topic, byte* payload, unsigned int length, void* instance) {
    // 確保實例有效
    MQTTManager* mqttManager = static_cast<MQTTManager*>(instance);
    if (mqttManager && mqttManager->userCallback) {
        mqttManager->userCallback(topic, payload, length);
    }
}

// 設置使用者回調函數
void MQTTManager::setCallback(MqttCallbackFunction callback) {
    userCallback = callback;
}

// 訂閱主題
bool MQTTManager::subscribe(const char* topic) {
    if (mqttClient->connected()) {
        return mqttClient->subscribe(topic);
    }
    return false;
}

// 取消訂閱主題
bool MQTTManager::unsubscribe(const char* topic) {
    if (mqttClient->connected()) {
        return mqttClient->unsubscribe(topic);
    }
    return false;
}

// 發布消息
bool MQTTManager::publish(const char* topic, const char* payload, bool retain) {
    if (mqttClient->connected()) {
        bool result = mqttClient->publish(topic, payload, retain);
        
        if (result) {
            if (mutex != NULL) {
                xSemaphoreTake(*mutex, portMAX_DELAY);
            }
            
            isMqttTransmitting = true;
            mqttIconBlinkMillis = millis();
            
            if (mutex != NULL) {
                xSemaphoreGive(*mutex);
            }
            
            Serial.printf("成功發布到主題: %s\n", topic);
        } else {
            Serial.printf("發布失敗，主題: %s\n", topic);
        }
        
        return result;
    }
    
    Serial.println("MQTT未連接，無法發布消息");
    return false;
}

// 發布JSON格式的數據
bool MQTTManager::publishJson(const char* topic, JsonDocument& doc, bool retain) {
    char jsonBuffer[512];
    serializeJson(doc, jsonBuffer);
    return publish(topic, jsonBuffer, retain);
}

// 發布標準傳感器數據
bool MQTTManager::publishSensorData(float temperature, float humidity) {
    if (millis() - lastMqttPublish < mqttPublishInterval) {
        return true; // 尚未到發布時間
    }
    
    lastMqttPublish = millis();
    
    // 創建JSON文檔
    StaticJsonDocument<200> doc;
    
    doc["temp"] = temperature;
    doc["humidity"] = humidity;
    doc["deviceId"] = deviceId;
    doc["features"] = "ir_control";  // 添加表明支持IR控制的特性標記
    
    // 添加房間ID (如果有)
    if (wifiManager->hasRoomID()) {
        doc["roomId"] = wifiManager->getRoomID();
    } else {
        doc["roomId"] = "unknown";
    }
    
    // 發布到主題，使用房間ID作為分類
    String topic = mqttTopic;
    
    if (wifiManager->hasRoomID()) {
        // 使用房間ID作為MQTT的主要分類方式
        topic = String(mqttTopic) + "/" + wifiManager->getRoomID();
        
        // 也發布到包含裝置ID的主題，讓App可以追蹤個別裝置
        String deviceTopic = topic + "/" + deviceId;
        bool result1 = publishJson(deviceTopic.c_str(), doc);
        Serial.println("發送數據到房間和裝置主題: " + deviceTopic);
        
        // 發布到主題
        bool result2 = publishJson(topic.c_str(), doc);
        Serial.println("發送數據到主題: " + topic);
        
        return result1 && result2;
    } else {
        // 如果沒有房間ID，則使用裝置ID作為分類
        topic = String(mqttTopic) + "/unknown/" + deviceId;
        
        // 發布到主題
        bool result = publishJson(topic.c_str(), doc);
        Serial.println("發送數據到主題: " + topic);
        
        return result;
    }
}

// 檢查並維護MQTT連接
bool MQTTManager::loop() {
    unsigned long currentMillis = millis();
    
    // 檢查傳輸圖示是否需要關閉
    if (isMqttTransmitting && currentMillis - mqttIconBlinkMillis >= mqttIconBlinkInterval) {
        if (mutex != NULL) {
            xSemaphoreTake(*mutex, portMAX_DELAY);
        }
        
        isMqttTransmitting = false;
        
        if (mutex != NULL) {
            xSemaphoreGive(*mutex);
        }
    }
    
    // MQTT連接檢查
    if (!mqttClient->connected()) {
        isMqttConnected = false;
        
        if (currentMillis - lastMqttReconnectAttempt >= mqttReconnectInterval) {
            lastMqttReconnectAttempt = currentMillis;
            
            if (connect()) {
                lastMqttReconnectAttempt = 0;
                isMqttConnected = true;
                return true;
            }
            return false;
        }
    } else {
        isMqttConnected = true;
        mqttClient->loop();
        return true;
    }
    
    return false;
}

// 嘗試連接MQTT伺服器
bool MQTTManager::connect() {
    if (!wifiManager->isConnected()) {
        Serial.println("WiFi未連接，無法連接MQTT");
        return false;
    }
    
    if (mqttClient->connected()) {
        return true;
    }
    
    // 生成唯一的客戶端ID
    char uniqueClientId[25];
    sprintf(uniqueClientId, "%s%08X", clientIdPrefix, random(0xFFFFFFFF));
    
    // 設置遺囑消息
    const char* willTopic = "esp32/status";
    const char* willMessage = "offline";
    bool willRetain = true;
    
    Serial.printf("嘗試連接MQTT伺服器 %s:%d 使用ID: %s\n", mqttServer, mqttPort, uniqueClientId);
    
    if (mqttClient->connect(uniqueClientId, NULL, NULL, willTopic, 0, willRetain, willMessage)) {
        Serial.println("MQTT伺服器連接成功");
        
        // 訂閱基本命令主題
        mqttClient->subscribe("esp32/commands");
        
        // 發布在線狀態
        mqttClient->publish("esp32/status", "online", true);
        
        return true;
    } else {
        int state = mqttClient->state();
        Serial.printf("MQTT連接失敗，錯誤碼: %d\n", state);
        
        switch (state) {
            case -4: Serial.println("連接超時"); break;
            case -3: Serial.println("伺服器不可用"); break;
            case -2: Serial.println("錯誤的網絡連接"); break;
            case -1: Serial.println("客戶端不可用"); break;
            case 1: Serial.println("協議版本錯誤"); break;
            case 2: Serial.println("客戶端ID被拒絕"); break;
            case 3: Serial.println("伺服器不可用"); break;
            case 4: Serial.println("用戶名/密碼錯誤"); break;
            case 5: Serial.println("未授權"); break;
            default: Serial.println("未知錯誤"); break;
        }
        
        return false;
    }
}

// 獲取連接狀態
bool MQTTManager::isConnected() const {
    return isMqttConnected;
}

// 獲取傳輸狀態
bool MQTTManager::isTransmitting() const {
    return isMqttTransmitting;
}

// 獲取傳輸圖標閃爍時間
unsigned long MQTTManager::getIconBlinkMillis() const {
    return mqttIconBlinkMillis;
}

// 設置傳輸狀態
void MQTTManager::setTransmitting(bool state) {
    if (mutex != NULL) {
        xSemaphoreTake(*mutex, portMAX_DELAY);
    }
    
    isMqttTransmitting = state;
    
    if (state) {
        mqttIconBlinkMillis = millis();
    }
    
    if (mutex != NULL) {
        xSemaphoreGive(*mutex);
    }
}

// 獲取客戶端實例
PubSubClient* MQTTManager::getClient() {
    return mqttClient;
}

// 獲取基礎主題
String MQTTManager::getBaseTopic() const {
    return String(mqttTopic);
}

// 生成完整的設備主題路徑
String MQTTManager::getDeviceTopic(const String& suffix) const {
    String baseTopic = getBaseTopic();
    
    if (wifiManager->hasRoomID()) {
        baseTopic += "/" + wifiManager->getRoomID();
    } else {
        baseTopic += "/unknown";
    }
    
    baseTopic += "/" + deviceId;
    
    if (suffix.length() > 0) {
        baseTopic += "/" + suffix;
    }
    
    return baseTopic;
}
