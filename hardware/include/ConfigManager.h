#ifndef CONFIG_MANAGER_H
#define CONFIG_MANAGER_H

#include <Arduino.h>
#include <Preferences.h>

class ConfigManager {
public:
    ConfigManager(const char* namespace_name = "app_config");
    ~ConfigManager();

    // WiFi憑證相關方法
    bool saveWiFiCredentials(const char* ssid, const char* password);
    bool loadWiFiCredentials(char* ssid, size_t ssidSize, char* password, size_t passwordSize);
    bool hasWiFiCredentials();
    bool deleteWiFiCredentials();

    // 一般設定值管理方法
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
    Preferences _preferences;
    const char* _namespace;
    bool _isOpen;

    // 私有輔助方法
    void begin(bool readonly = false);
    void end();
};

#endif // CONFIG_MANAGER_H