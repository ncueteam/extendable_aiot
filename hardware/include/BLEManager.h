#ifndef BLE_MANAGER_H
#define BLE_MANAGER_H

#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <functional>

class BLEManager {
public:
    // 连接状态回调函数类型
    typedef std::function<void(bool)> ConnectCallback;
    
    // WiFi凭证回调函数类型
    typedef std::function<void(const char*)> CredentialCallback;

private:
    // BLE服务器和特性
    BLEServer* pServer;
    BLECharacteristic* pWiFiCredentialChar;
    BLECharacteristic* pStatusChar;
    
    // 连接状态
    bool deviceConnected;
    bool oldDeviceConnected;
    
    // 服务和特性UUID
    const char* SERVICE_UUID;
    const char* WIFI_CRED_CHAR_UUID;
    const char* STATUS_CHAR_UUID;
    
    // 自定义回调函数
    ConnectCallback onConnectCallback;
    ConnectCallback onDisconnectCallback;
    CredentialCallback onCredentialCallback;
    
    // BLE服务器回调类
    class ServerCallbacks : public BLEServerCallbacks {
    private:
        BLEManager* manager;
    public:
        ServerCallbacks(BLEManager* mgr) : manager(mgr) {}
        void onConnect(BLEServer* pServer) override;
        void onDisconnect(BLEServer* pServer) override;
    };
    
    // WiFi凭证特性回调类
    class CredentialCallbacks : public BLECharacteristicCallbacks {
    private:
        BLEManager* manager;
    public:
        CredentialCallbacks(BLEManager* mgr) : manager(mgr) {}
        void onWrite(BLECharacteristic* pCharacteristic) override;
    };
    
    // 回调实例
    ServerCallbacks* serverCallbacks;
    CredentialCallbacks* credentialCallbacks;

public:
    // 构造函数
    BLEManager(
        const char* deviceName = "ESP32_AIOT_BLE", 
        const char* serviceUuid = "91bad492-b950-4226-aa2b-4ede9fa42f59",
        const char* wifiCredCharUuid = "0b30ac1c-1c8a-4770-9914-d2abe8351512",
        const char* statusCharUuid = "d2936523-52bf-4b76-a873-727d83e2b357"
    );
    
    // 析构函数
    ~BLEManager();
    
    // 初始化BLE服务
    void begin();
    
    // 设置回调函数
    void setOnConnectCallback(ConnectCallback callback);
    void setOnDisconnectCallback(ConnectCallback callback);
    void setOnCredentialCallback(CredentialCallback callback);
    
    // 发送状态消息
    void sendStatusMessage(const char* message);
    void sendWiFiConnectedStatus(const String& ipAddress);
    void sendWiFiFailedStatus();
    
    // 检查连接状态变化
    void checkConnection();
    
    // 获取连接状态
    bool isConnected() const;
};

#endif // BLE_MANAGER_H