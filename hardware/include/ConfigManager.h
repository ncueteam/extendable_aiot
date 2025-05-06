#ifndef CONFIG_MANAGER_H
#define CONFIG_MANAGER_H

#include <Arduino.h>
#include "StorageManager.h"

/**
 * ConfigManager 類負責管理應用程序的配置
 * 它使用StorageManager作為底層存儲機制
 */
class ConfigManager {
public:
    /**
     * 構造函數
     * @param namespace_name 配置命名空間名稱
     */
    ConfigManager(const char* namespace_name = "app_config");
    ~ConfigManager();

    // WiFi憑證相關方法
    bool saveWiFiCredentials(const char* ssid, const char* password);
    bool loadWiFiCredentials(char* ssid, size_t ssidSize, char* password, size_t passwordSize);
    bool hasWiFiCredentials();
    bool deleteWiFiCredentials();

    // 一般設定值管理方法 - 這些方法委託給StorageManager
    bool saveString(const char* key, const char* value);
    String loadString(const char* key, const char* defaultValue = "");
    bool saveInt(const char* key, int value);
    int loadInt(const char* key, int defaultValue = 0);
    bool saveFloat(const char* key, float value);
    float loadFloat(const char* key, float defaultValue = 0.0);
    bool saveBool(const char* key, bool value);
    bool loadBool(const char* key, bool defaultValue = false);
    bool deleteKey(const char* key);
    
    // 清除所有設定
    void clearAll();

private:
    // 使用StorageManager處理底層存儲
    StorageManager _storage;
};

#endif // CONFIG_MANAGER_H