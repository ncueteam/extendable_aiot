#include "../include/BLEManager.h"

// ServerCallbacks实现
void BLEManager::ServerCallbacks::onConnect(BLEServer* pServer) {
    manager->deviceConnected = true;
    
    // 更新状态消息
    if(manager->pStatusChar != nullptr) {
        String status = "Connected to ESP32 BLE";
        manager->pStatusChar->setValue(status.c_str());
        manager->pStatusChar->notify();
    }
    
    // 调用自定义连接回调
    if(manager->onConnectCallback) {
        manager->onConnectCallback(true);
    }
}

void BLEManager::ServerCallbacks::onDisconnect(BLEServer* pServer) {
    manager->deviceConnected = false;
    
    // 重新广播
    pServer->getAdvertising()->start();
    
    // 调用自定义断开连接回调
    if(manager->onDisconnectCallback) {
        manager->onDisconnectCallback(false);
    }
}

// CredentialCallbacks实现
void BLEManager::CredentialCallbacks::onWrite(BLECharacteristic* pCharacteristic) {
    std::string value = pCharacteristic->getValue();
    
    if (value.length() > 0 && manager->onCredentialCallback) {
        // 将收到的BLE数据转换为C风格字符串处理
        manager->onCredentialCallback(value.c_str());
    }
}

// BLEManager构造函数
BLEManager::BLEManager(
    const char* deviceName,
    const char* serviceUuid,
    const char* wifiCredCharUuid,
    const char* statusCharUuid
) : 
    pServer(nullptr),
    pWiFiCredentialChar(nullptr),
    pStatusChar(nullptr),
    deviceConnected(false),
    oldDeviceConnected(false),
    SERVICE_UUID(serviceUuid),
    WIFI_CRED_CHAR_UUID(wifiCredCharUuid),
    STATUS_CHAR_UUID(statusCharUuid),
    onConnectCallback(nullptr),
    onDisconnectCallback(nullptr),
    onCredentialCallback(nullptr),
    serverCallbacks(nullptr),
    credentialCallbacks(nullptr) {
        
    // 初始化BLE设备
    BLEDevice::init(deviceName);
}

// BLEManager析构函数
BLEManager::~BLEManager() {
    // 清理资源
    if (serverCallbacks != nullptr) {
        delete serverCallbacks;
    }
    if (credentialCallbacks != nullptr) {
        delete credentialCallbacks;
    }
}

// 初始化BLE服务
void BLEManager::begin() {
    // 创建BLE服务器
    pServer = BLEDevice::createServer();
    
    // 创建回调实例
    serverCallbacks = new ServerCallbacks(this);
    credentialCallbacks = new CredentialCallbacks(this);
    
    // 设置服务器回调
    pServer->setCallbacks(serverCallbacks);
    
    // 创建BLE服务
    BLEService *pService = pServer->createService(SERVICE_UUID);
    
    // 创建BLE特性 - WiFi凭证接收
    pWiFiCredentialChar = pService->createCharacteristic(
                            WIFI_CRED_CHAR_UUID,
                            BLECharacteristic::PROPERTY_WRITE
                        );
    pWiFiCredentialChar->setCallbacks(credentialCallbacks);
    
    // 创建BLE特性 - 状态通知
    pStatusChar = pService->createCharacteristic(
                    STATUS_CHAR_UUID,
                    BLECharacteristic::PROPERTY_READ |
                    BLECharacteristic::PROPERTY_NOTIFY
                );
    pStatusChar->addDescriptor(new BLE2902());
    
    // 启动服务
    pService->start();
    
    // 启动广播
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06);  // 修正：只设置一次参数
    pAdvertising->setMinInterval(0x20);   // 添加间隔以改善发现性
    pAdvertising->setMaxInterval(0x40);
    BLEDevice::startAdvertising();
    
    Serial.println("BLE服务已启动，等待连接...");
}

// 设置连接回调
void BLEManager::setOnConnectCallback(ConnectCallback callback) {
    onConnectCallback = callback;
}

// 设置断开连接回调
void BLEManager::setOnDisconnectCallback(ConnectCallback callback) {
    onDisconnectCallback = callback;
}

// 设置凭证接收回调
void BLEManager::setOnCredentialCallback(CredentialCallback callback) {
    onCredentialCallback = callback;
}

// 发送状态消息
void BLEManager::sendStatusMessage(const char* message) {
    if (pStatusChar != nullptr && deviceConnected) {
        pStatusChar->setValue(message);
        pStatusChar->notify();
    }
}

// 发送WiFi连接成功状态
void BLEManager::sendWiFiConnectedStatus(const String& ipAddress) {
    String statusMsg = "WIFI_CONNECTED:" + ipAddress;
    sendStatusMessage(statusMsg.c_str());
}

// 发送WiFi连接失败状态
void BLEManager::sendWiFiFailedStatus() {
    sendStatusMessage("WIFI_FAILED");
}

// 检查连接状态变化
void BLEManager::checkConnection() {
    // 处理BLE连接状态变化
    if (deviceConnected != oldDeviceConnected) {
        if (deviceConnected) {
            // 新建立的连接
            Serial.println("BLE设备已连接");
        } else {
            // 连接中断
            Serial.println("BLE设备已断开");
            delay(500); // 给客户端时间接收断开通知
        }
        oldDeviceConnected = deviceConnected;
    }
}

// 获取连接状态
bool BLEManager::isConnected() const {
    return deviceConnected;
}