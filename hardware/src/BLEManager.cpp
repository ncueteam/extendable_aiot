#include "BLEManager.h"

// 伺服器連接回調類別定義
class BLEManager::MyServerCallbacks: public BLEServerCallbacks {
private:
    BLEManager* _bleManager;

public:
    MyServerCallbacks(BLEManager* manager) : _bleManager(manager) {}

    void onConnect(BLEServer* pServer) {
        _bleManager->_deviceConnected = true;

        // 更新狀態消息
        String status = "Connected to ESP32 BLE";
        if (_bleManager->_pStatusChar != nullptr) {
            _bleManager->_pStatusChar->setValue(status.c_str());
            _bleManager->_pStatusChar->notify();
        }

        // 呼叫外部狀態回調
        if (_bleManager->_statusCallback) {
            _bleManager->_statusCallback(true, status);
        }
    }

    void onDisconnect(BLEServer* pServer) {
        _bleManager->_deviceConnected = false;
        
        // 重新廣播
        pServer->getAdvertising()->start();

        // 呼叫外部狀態回調
        if (_bleManager->_statusCallback) {
            _bleManager->_statusCallback(false, "Device disconnected");
        }
    }
};

// WiFi憑證處理回調類別定義
class BLEManager::WiFiCredentialsCallbacks: public BLECharacteristicCallbacks {
private:
    BLEManager* _bleManager;

public:
    WiFiCredentialsCallbacks(BLEManager* manager) : _bleManager(manager) {}

    void onWrite(BLECharacteristic *pCharacteristic) {
        std::string value = pCharacteristic->getValue();
        
        if (value.length() > 0 && _bleManager->_credentialCallback) {
            // 呼叫外部處理函數
            _bleManager->_credentialCallback(value.c_str());
        }
    }
};

// BLEManager實現
BLEManager::BLEManager(const char* deviceName) {
    _deviceName = deviceName;
    _pServer = NULL;
    _pWiFiCredentialChar = NULL;
    _pStatusChar = NULL;
    _deviceConnected = false;
    _oldDeviceConnected = false;
    _serviceActive = false;  // 初始化為未啟動狀態
    _credentialCallback = NULL;
    _statusCallback = NULL;
}

BLEManager::~BLEManager() {
    // 由於ESP32 BLE庫會自動處理資源釋放，這裡不需要特殊清理
}

void BLEManager::begin() {
    // 初始化BLE裝置
    BLEDevice::init(_deviceName.c_str());
    
    // 創建BLE伺服器
    _pServer = BLEDevice::createServer();
    _pServer->setCallbacks(new MyServerCallbacks(this));
    
    // 創建BLE服務
    BLEService *pService = _pServer->createService(SERVICE_UUID);
    
    // 創建BLE特性 - WiFi憑證接收
    _pWiFiCredentialChar = pService->createCharacteristic(
                            WIFI_CRED_CHAR_UUID,
                            BLECharacteristic::PROPERTY_WRITE
                        );
    _pWiFiCredentialChar->setCallbacks(new WiFiCredentialsCallbacks(this));
    
    // 創建BLE特性 - 狀態通知
    _pStatusChar = pService->createCharacteristic(
                    STATUS_CHAR_UUID,
                    BLECharacteristic::PROPERTY_READ |
                    BLECharacteristic::PROPERTY_NOTIFY
                );
    _pStatusChar->addDescriptor(new BLE2902());
    
    // 啟動服務
    pService->start();
    
    // 啟動廣播
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06);
    pAdvertising->setMinInterval(0x20);
    pAdvertising->setMaxInterval(0x40);
    BLEDevice::startAdvertising();
    
    // 設置BLE服務為啟動狀態
    _serviceActive = true;
    
    Serial.println("BLE服務已啟動，等待連接...");
}

void BLEManager::handleConnection() {
    // 處理BLE連接狀態變化
    if (_deviceConnected != _oldDeviceConnected) {
        if (_deviceConnected) {
            Serial.println("BLE裝置已連接");
        } else {
            Serial.println("BLE裝置已斷開");
            delay(500); // 給客戶端時間接收斷開通知
        }
        _oldDeviceConnected = _deviceConnected;
    }
}

void BLEManager::setCredentialCallback(WiFiCredentialCallback callback) {
    _credentialCallback = callback;
}

void BLEManager::setStatusCallback(StatusNotifyCallback callback) {
    _statusCallback = callback;
}

void BLEManager::sendStatusNotification(const String& message) {
    if (_pStatusChar != NULL && _deviceConnected) {
        _pStatusChar->setValue(message.c_str());
        _pStatusChar->notify();
    }
}

bool BLEManager::isDeviceConnected() const {
    return _deviceConnected;
}

bool BLEManager::isServiceActive() const {
    return _serviceActive;
}

bool BLEManager::isConnectionChanged() const {
    return _deviceConnected != _oldDeviceConnected;
}

void BLEManager::resetConnectionChanged() {
    _oldDeviceConnected = _deviceConnected;
}