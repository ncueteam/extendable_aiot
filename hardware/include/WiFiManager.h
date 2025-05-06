#ifndef WIFI_MANAGER_H
#define WIFI_MANAGER_H

#include <Arduino.h>
#include <WiFi.h>
#include <functional>
#include "ConfigManager.h"

// WiFi狀態變更回調函數類型
typedef std::function<void(bool connected, const String& message)> WiFiStatusCallback;
// WiFi顯示更新回調函數類型
typedef std::function<void(const String& message, int progress)> WiFiDisplayCallback;

class WiFiManager {
public:
    /**
     * 構造函數
     * @param configManager 配置管理器，用於存儲WiFi憑證
     */
    WiFiManager(ConfigManager* configManager);
    ~WiFiManager();
    
    /**
     * 初始化WiFi功能
     */
    void begin();
    
    /**
     * 連接到WiFi網絡
     * @param forceUseStored 是否強制使用存儲的憑證
     * @return 連接成功返回true，否則返回false
     */
    bool connect(bool forceUseStored = false);
    
    /**
     * 斷開WiFi連接
     */
    void disconnect();
    
    /**
     * 設置WiFi憑證
     * @param ssid SSID
     * @param password 密碼
     * @param roomID 房間ID (可選)
     * @return 設置成功返回true
     */
    bool setCredentials(const char* ssid, const char* password, const char* roomID = nullptr);
    
    /**
     * 透過消息字符串設置WiFi憑證（適用於BLE傳輸的格式）
     * @param message 包含SSID、密碼和房間ID的消息字符串
     * @return 解析成功返回true
     */
    bool parseCredentials(const char* message);
    
    /**
     * 獲取當前SSID
     * @return 當前SSID
     */
    const char* getSSID() const;
    
    /**
     * 獲取房間ID
     * @return 房間ID，如果未設置則返回空字符串
     */
    String getRoomID() const;
    
    /**
     * 檢查是否有設置房間ID
     * @return 如果有房間ID則返回true
     */
    bool hasRoomID() const;
    
    /**
     * 獲取當前IP地址
     * @return IP地址字符串
     */
    String getIPAddress() const;
    
    /**
     * 檢查WiFi是否已連接
     * @return 已連接返回true
     */
    bool isConnected() const;
    
    /**
     * 設置狀態回調函數
     * @param callback 回調函數
     */
    void setStatusCallback(WiFiStatusCallback callback);
    
    /**
     * 設置顯示更新回調函數
     * @param callback 回調函數
     */
    void setDisplayCallback(WiFiDisplayCallback callback);

private:
    // WiFi憑證
    char _ssid[33];
    char _password[65];
    char _roomID[33]; // 存儲房間ID的緩衝區
    
    // 狀態變數
    bool _isConnected;
    bool _hasCredentials;
    bool _hasRoomID;
    
    // 配置相關
    ConfigManager* _configManager;
    
    // 回調函數
    WiFiStatusCallback _statusCallback;
    WiFiDisplayCallback _displayCallback;
    
    // 從配置中加載WiFi憑證
    bool loadCredentials();
    
    // 從配置中加載房間ID
    bool loadRoomID();
    
    // 通知狀態變更
    void notifyStatus(bool connected, const String& message);
    
    // 更新顯示
    void updateDisplay(const String& message, int progress = -1);
};

#endif // WIFI_MANAGER_H