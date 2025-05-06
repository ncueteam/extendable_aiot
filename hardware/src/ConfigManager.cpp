#include "ConfigManager.h"

ConfigManager::ConfigManager(const char* namespace_name)
    : _storage(namespace_name) {
}

ConfigManager::~ConfigManager() {
    // StorageManager會在其析構函數中處理資源清理
}

// WiFi憑證相關方法
bool ConfigManager::saveWiFiCredentials(const char* ssid, const char* password) {
    if (ssid == nullptr || password == nullptr) {
        return false;
    }

    bool success = _storage.saveString("ssid", ssid) && 
                   _storage.saveString("password", password);
    return success;
}

bool ConfigManager::loadWiFiCredentials(char* ssid, size_t ssidSize, char* password, size_t passwordSize) {
    if (ssid == nullptr || password == nullptr || ssidSize == 0 || passwordSize == 0) {
        return false;
    }

    String tempSsid = _storage.loadString("ssid", "");
    String tempPass = _storage.loadString("password", "");

    // 檢查是否有資料和緩衝區大小
    if (tempSsid.length() == 0 || tempPass.length() == 0 || 
        tempSsid.length() >= ssidSize || tempPass.length() >= passwordSize) {
        return false;
    }

    // 複製到提供的緩衝區
    strncpy(ssid, tempSsid.c_str(), ssidSize - 1);
    ssid[ssidSize - 1] = '\0'; // 確保以null結尾
    
    strncpy(password, tempPass.c_str(), passwordSize - 1);
    password[passwordSize - 1] = '\0'; // 確保以null結尾
    
    return true;
}

bool ConfigManager::hasWiFiCredentials() {
    return _storage.hasKey("ssid") && _storage.hasKey("password");
}

bool ConfigManager::deleteWiFiCredentials() {
    return _storage.deleteKey("ssid") && _storage.deleteKey("password");
}

// 一般設定值管理方法 - 簡單委託給StorageManager
bool ConfigManager::saveString(const char* key, const char* value) {
    return _storage.saveString(key, value);
}

String ConfigManager::loadString(const char* key, const char* defaultValue) {
    return _storage.loadString(key, defaultValue);
}

bool ConfigManager::saveInt(const char* key, int value) {
    return _storage.saveInt(key, value);
}

int ConfigManager::loadInt(const char* key, int defaultValue) {
    return _storage.loadInt(key, defaultValue);
}

bool ConfigManager::saveFloat(const char* key, float value) {
    return _storage.saveFloat(key, value);
}

float ConfigManager::loadFloat(const char* key, float defaultValue) {
    return _storage.loadFloat(key, defaultValue);
}

bool ConfigManager::saveBool(const char* key, bool value) {
    return _storage.saveBool(key, value);
}

bool ConfigManager::loadBool(const char* key, bool defaultValue) {
    return _storage.loadBool(key, defaultValue);
}

bool ConfigManager::deleteKey(const char* key) {
    return _storage.deleteKey(key);
}

void ConfigManager::clearAll() {
    _storage.clearAll();
}