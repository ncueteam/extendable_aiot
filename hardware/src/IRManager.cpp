#include "IRManager.h"
#include "DisplayManager.h"  // 添加 DisplayManager 引用
#include "MQTTManager.h"     // 添加 MQTTManager 引用

// 構造函數
IRManager::IRManager(int irSendPin, int irRecvPin, const char* controlTopic, const char* receiveTopic) {
    // 初始化發射器
    irSender = new IRsend(irSendPin);
    irControlTopic = controlTopic;
    initialized = false;
    
    // 初始化接收器
    irReceiver = NULL;
    receiverPin = irRecvPin;
    irReceiveTopic = receiveTopic;
    receiverInitialized = false;
    irReceiverTaskHandle = NULL;
    
    // 創建互斥鎖
    irMutex = xSemaphoreCreateMutex();

    // 初始化 DisplayManager 為空指針
    displayManager = nullptr;
}

// 析構函數
IRManager::~IRManager() {
    if (irSender) {
        delete irSender;
    }
    
    if (irReceiver) {
        delete irReceiver;
    }
    
    if (irMutex != NULL) {
        vSemaphoreDelete(irMutex);
    }
    
    // 如果任務在運行，刪除它
    if (irReceiverTaskHandle != NULL) {
        vTaskDelete(irReceiverTaskHandle);
    }
}

// 初始化IR發射器和接收器
void IRManager::begin() {
    // 初始化發射器
    irSender->begin();
    initialized = true;
    Serial.println("IR發射器已初始化");
    
    // 如果接收引腳已設置，初始化接收器
    if (receiverPin > 0) {
        beginReceiver(receiverPin);
    }
}

// 初始化IR接收器
void IRManager::beginReceiver(int pin) {
    receiverPin = pin;
    
    // 避免重複初始化
    if (irReceiver != NULL) {
        delete irReceiver;
    }
    
    // 創建接收器（增加緩衝區大小至2048，並設置較長的接收超時，以提高捕獲能力）
    irReceiver = new IRrecv(pin, 2048, 60, true);
    irReceiver->enableIRIn();  // 啟動接收器
    
    // 設置接收器允許處理未知協議
    irReceiver->setUnknownThreshold(12);  // 允許偵測更短的協議
    irReceiver->setTolerance(25);  // 增加容錯率(%)，預設是25%
    
    receiverInitialized = true;
    Serial.printf("IR接收器已增強模式初始化於引腳 %d\n", pin);
}

// 獲取IR控制主題
const char* IRManager::getIRControlTopic() const {
    return irControlTopic;
}

// 獲取IR接收主題
const char* IRManager::getIRReceiveTopic() const {
    return irReceiveTopic;
}

// 處理MQTT消息
bool IRManager::handleMQTTMessage(const char* topic, const char* payload) {
    // 檢查是否是IR控制主題
    if (strcmp(topic, irControlTopic) != 0) {
        return false;
    }
    
    // 解析 JSON 數據
    StaticJsonDocument<200> doc;
    DeserializationError error = deserializeJson(doc, payload);
    
    if (error) {
        Serial.println("JSON解析錯誤");
        return false;
    }
    
    // 獲取命令類型
    const char* command = doc["command"];
    
    if (!command) {
        return false;
    }
    
    Serial.printf("收到IR命令: %s\n", command);
    
    if (strcmp(command, "raw") == 0 && doc.containsKey("data")) {
        // 處理原始IR數據發送
        JsonArray rawData = doc["data"].as<JsonArray>();
        if (!rawData.isNull()) {
            uint16_t rawCodes[100]; // 假設最多100個代碼
            int i = 0;
            for (JsonVariant value : rawData) {
                if (i < 100) {
                    rawCodes[i++] = value.as<uint16_t>();
                }
            }
            // 發送原始IR代碼
            uint16_t khz = doc["khz"] | 38; // 默認38kHz
            irSender->sendRaw(rawCodes, i, khz);
            Serial.println("發送原始IR代碼");
        }
    } 
    else if (strcmp(command, "nec") == 0 && doc.containsKey("value")) {
        // 發送NEC格式命令
        uint32_t code = doc["value"];
        uint16_t bits = doc["bits"] | 32; // 默認32位
        irSender->sendNEC(code, bits);
        Serial.printf("發送NEC命令: 0x%08X, %d位\n", code, bits);
    }
    else if (strcmp(command, "sony") == 0 && doc.containsKey("value")) {
        // 發送Sony格式命令
        uint32_t code = doc["value"];
        uint16_t bits = doc["bits"] | 12; // 默認12位
        uint8_t repeat = doc["repeat"] | 2; // 默認2次重複
        irSender->sendSony(code, bits, repeat);
        Serial.printf("發送Sony命令: 0x%08X, %d位\n", code, bits);
    }
    else if (strcmp(command, "rc5") == 0 && doc.containsKey("value")) {
        // 發送RC5格式命令
        uint32_t code = doc["value"];
        uint16_t bits = doc["bits"] | 12; // 默認12位
        irSender->sendRC5(code, bits);
        Serial.printf("發送RC5命令: 0x%08X, %d位\n", code, bits);
    }
    else if (strcmp(command, "rc6") == 0 && doc.containsKey("value")) {
        // 發送RC6格式命令
        uint32_t code = doc["value"];
        uint16_t bits = doc["bits"] | 20; // 默認20位
        irSender->sendRC6(code, bits);
        Serial.printf("發送RC6命令: 0x%08X, %d位\n", code, bits);
    }
    else {
        return false;
    }
    
    return true;
}

// 發送原始IR數據
void IRManager::sendRawData(uint16_t* data, uint16_t len, uint16_t khz) {
    if (!initialized) {
        begin();
    }
    irSender->sendRaw(data, len, khz);
}

// 發送NEC格式命令
void IRManager::sendNEC(uint32_t data, uint16_t bits) {
    if (!initialized) {
        begin();
    }
    irSender->sendNEC(data, bits);
}

// 發送Sony格式命令
void IRManager::sendSony(uint32_t data, uint16_t bits, uint16_t repeat) {
    if (!initialized) {
        begin();
    }
    irSender->sendSony(data, bits, repeat);
}

// 發送RC5格式命令
void IRManager::sendRC5(uint32_t data, uint16_t bits) {
    if (!initialized) {
        begin();
    }
    irSender->sendRC5(data, bits);
}

// 發送RC6格式命令
void IRManager::sendRC6(uint32_t data, uint16_t bits) {
    if (!initialized) {
        begin();
    }
    irSender->sendRC6(data, bits);
}

// 檢查是否有新的IR信號
bool IRManager::available() {
    if (!receiverInitialized || irReceiver == NULL) {
        return false;
    }
    
    xSemaphoreTake(irMutex, portMAX_DELAY);
    bool hasData = irReceiver->decode(&results);
    xSemaphoreGive(irMutex);
    
    return hasData;
}

// 獲取接收到的IR信號並解碼
bool IRManager::read() {
    if (!receiverInitialized || irReceiver == NULL) {
        return false;
    }
    
    xSemaphoreTake(irMutex, portMAX_DELAY);
    bool hasData = irReceiver->decode(&results);
    
    if (hasData) {
        // 準備接收下一個信號
        irReceiver->resume();
    }
    
    xSemaphoreGive(irMutex);
    
    return hasData;
}

// 解析接收到的IR數據並發送到MQTT
void IRManager::publishIRReceived(MQTTManager* mqttManager) {
    if (!receiverInitialized) {
        return;
    }    if (read()) {
        // 在Serial Monitor上顯示詳細的解碼結果
        Serial.println("\n================ IR 信號接收 ================");
        Serial.printf("協議類型: %s\n", IRManager::typeToString(results.decode_type));
        Serial.printf("位元數: %d\n", results.bits);
        
        // 創建JSON對象來存儲IR數據
        StaticJsonDocument<512> doc;
        
        // 將解碼類型轉換為字符串
        String typeStr = IRManager::typeToString(results.decode_type);
        doc["type"] = typeStr;
        doc["bits"] = results.bits;
        
        // 若有Display Manager可用，通知顯示紅外線數據
        if (displayManager != nullptr) {
            displayManager->updateIRData(typeStr, results.value, results.bits);
        }
        
        // 處理不同類型的編碼
        switch (results.decode_type) {
            case decode_type_t::NEC:
            case decode_type_t::RC5:
            case decode_type_t::RC6:
            case decode_type_t::SONY:
            case decode_type_t::PANASONIC:
            case decode_type_t::JVC:
            case decode_type_t::SAMSUNG:
            case decode_type_t::LG:
                doc["value"] = results.value;
                doc["address"] = results.address;
                doc["command"] = results.command;
                
                // 在Serial上顯示詳細值
                Serial.printf("十六進制值: 0x%08X\n", results.value);
                Serial.printf("十進制值: %u\n", results.value);
                Serial.printf("位址: 0x%04X\n", results.address);
                Serial.printf("指令: 0x%04X\n", results.command);
                break;
            
            case decode_type_t::UNKNOWN:
            default:
                // 對於未知編碼或原始數據，保存並顯示原始時序
                Serial.println("未知協議，顯示原始時序數據:");
                Serial.printf("原始數據長度: %d\n", results.rawlen - 1);
                Serial.println("原始值: ");
                
                JsonArray rawData = doc.createNestedArray("raw");
                // 限制原始數據大小以避免緩衝區溢出
                int max_count = min((int)results.rawlen, 100);
                for (int i = 1; i < max_count; i++) {
                    unsigned int value = results.rawbuf[i] * RAWTICK;
                    rawData.add(value);
                    Serial.printf("%d ", value);
                    if (i % 10 == 0) Serial.println(); // 每10個數值換行
                }
                Serial.println();
                doc["rawlen"] = results.rawlen - 1;
                break;
        }
        
        // 顯示用於重放的代碼示例
        Serial.println("\n用於重放的MQTT JSON指令:");
        if (results.decode_type == decode_type_t::NEC) {
            Serial.printf("{\n  \"command\": \"nec\",\n  \"value\": %u,\n  \"bits\": %d\n}\n", 
                         results.value, results.bits);
        } else if (results.decode_type == decode_type_t::SONY) {
            Serial.printf("{\n  \"command\": \"sony\",\n  \"value\": %u,\n  \"bits\": %d\n}\n", 
                         results.value, results.bits);
        } else if (results.decode_type == decode_type_t::RC5) {
            Serial.printf("{\n  \"command\": \"rc5\",\n  \"value\": %u,\n  \"bits\": %d\n}\n", 
                         results.value, results.bits);
        } else if (results.decode_type == decode_type_t::RC6) {
            Serial.printf("{\n  \"command\": \"rc6\",\n  \"value\": %u,\n  \"bits\": %d\n}\n", 
                         results.value, results.bits);
        }
        Serial.println("===============================================");
          // 只有在MQTT連接時才發布
        if (mqttManager && mqttManager->isConnected()) {
            // 使用JSON發布
            mqttManager->publishJson(irReceiveTopic, doc);
            
            Serial.printf("已發佈IR接收數據到主題: %s\n", irReceiveTopic);
        }
    }
}

// IR接收任務（靜態方法，用於FreeRTOS任務）
void IRManager::irReceiverTask(void* parameter) {
    // 獲取傳入參數
    struct ReceiverTaskParams {
        IRManager* irManager;
        MQTTManager* mqttManager;
    };
    
    ReceiverTaskParams* params = (ReceiverTaskParams*)parameter;
    
    IRManager* irManager = params->irManager;
    MQTTManager* mqttManager = params->mqttManager;
    
    // 釋放參數結構體內存
    delete params;
    
    Serial.println("IR接收任務已啟動");    // 任務主循環
    while (true) {
        // 檢查並發佈接收到的IR數據
        irManager->publishIRReceived(mqttManager);
        
        // 使用更短的延遲，提高IR信號捕獲的靈敏度
        vTaskDelay(10 / portTICK_PERIOD_MS);
    }
}

// 啟動IR接收任務
void IRManager::startReceiverTask(MQTTManager* mqttManager) {
    // 確保接收器已初始化
    if (!receiverInitialized) {
        Serial.println("IR接收器未初始化，無法啟動接收任務");
        return;
    }
    
    // 為任務參數分配內存
    struct ReceiverTaskParams {
        IRManager* irManager;
        MQTTManager* mqttManager;
    };
    
    ReceiverTaskParams* params = new ReceiverTaskParams;
    
    params->irManager = this;
    params->mqttManager = mqttManager;
    
    // 創建任務
    xTaskCreatePinnedToCore(
        irReceiverTask,         // 任務函數
        "IRRecvTask",           // 任務名稱
        4096,                   // 堆棧大小
        params,                 // 任務參數
        1,                      // 任務優先級
        &irReceiverTaskHandle,  // 任務句柄指針
        0                       // 在核心0上執行
    );
    
    Serial.println("IR接收任務已啟動");
}

// 將解碼類型轉換為字符串的靜態方法
const char* IRManager::typeToString(decode_type_t type) {
    switch (type) {
        case decode_type_t::NEC:
            return "NEC";
        case decode_type_t::SONY:
            return "SONY";
        case decode_type_t::RC5:
            return "RC5";
        case decode_type_t::RC6:
            return "RC6";
        case decode_type_t::DISH:
            return "DISH";
        case decode_type_t::SHARP:
            return "SHARP";
        case decode_type_t::JVC:
            return "JVC";
        case decode_type_t::SANYO:
            return "SANYO";
        case decode_type_t::MITSUBISHI:
            return "MITSUBISHI";
        case decode_type_t::SAMSUNG:
            return "SAMSUNG";
        case decode_type_t::LG:
            return "LG";
        case decode_type_t::WHYNTER:
            return "WHYNTER";
        case decode_type_t::AIWA_RC_T501:
            return "AIWA_RC_T501";
        case decode_type_t::PANASONIC:
            return "PANASONIC";
        case decode_type_t::DENON:
            return "DENON";
        case decode_type_t::COOLIX:
            return "COOLIX";
        default:
            return "UNKNOWN";
    }
}

// 設置顯示管理器
void IRManager::setDisplayManager(DisplayManager* displayManagerPtr) {
    this->displayManager = displayManagerPtr;
}