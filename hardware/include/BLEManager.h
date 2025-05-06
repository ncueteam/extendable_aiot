#ifndef BLE_MANAGER_H
#define BLE_MANAGER_H

#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// WiFi憑證處理回調函數類型
typedef void (*WiFiCredentialCallback)(const char* message);
// 連接狀態變更通知回調函數類型
typedef void (*StatusNotifyCallback)(bool connected, const String& message);

class BLEManager {
public:
    BLEManager(const char* deviceName = "ESP32_AIOT_BLE");
    ~BLEManager();

    // 初始化BLE服務
    void begin();
    
    // 處理連線狀態，應在loop中呼叫
    void handleConnection();
    
    // 設置WiFi憑證回調
    void setCredentialCallback(WiFiCredentialCallback callback);
    
    // 設置狀態通知回調
    void setStatusCallback(StatusNotifyCallback callback);
    
    // 發送狀態訊息
    void sendStatusNotification(const String& message);
    
    // 檢查是否有設備連接
    bool isDeviceConnected() const;
    
    // 檢查BLE服務是否已啟動
    bool isServiceActive() const;
    
    // 檢查連接狀態是否變更
    bool isConnectionChanged() const;
    
    // 重設連接狀態變更標志
    void resetConnectionChanged();

private:
    // BLE相關物件
    BLEServer* _pServer;
    BLECharacteristic* _pWiFiCredentialChar;
    BLECharacteristic* _pStatusChar;
    bool _deviceConnected;
    bool _oldDeviceConnected;
    String _deviceName;
    bool _serviceActive;  // 新增: 標記BLE服務是否啟動
    
    // 回調函數
    WiFiCredentialCallback _credentialCallback;
    StatusNotifyCallback _statusCallback;
    
    // UUID常量
    const char* SERVICE_UUID = "91bad492-b950-4226-aa2b-4ede9fa42f59";
    const char* WIFI_CRED_CHAR_UUID = "0b30ac1c-1c8a-4770-9914-d2abe8351512";
    const char* STATUS_CHAR_UUID = "d2936523-52bf-4b76-a873-727d83e2b357";
    
    // 內部回調類前向宣告
    class MyServerCallbacks;
    class WiFiCredentialsCallbacks;
    
    // 友元類聲明
    friend class MyServerCallbacks;
    friend class WiFiCredentialsCallbacks;
};

#endif // BLE_MANAGER_H