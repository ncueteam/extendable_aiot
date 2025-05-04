#include "ConfigManager.h"

ConfigManager::ConfigManager(const char* namespace_name) {
    _namespace = namespace_name;
    _isOpen = false;
}

ConfigManager::~ConfigManager() {
    if (_isOpen) {
        end();
    }
}

void ConfigManager::begin(bool readonly) {
    if (!_isOpen) {
        _preferences.begin(_namespace, readonly);
        _isOpen = true;
    }
}

void ConfigManager::end() {
    if (_isOpen) {
        _preferences.end();
        _isOpen = false;
    }
}

// WiFi憑證相關方法
bool ConfigManager::saveWiFiCredentials(const char* ssid, const char* password) {
    if (ssid == nullptr || password == nullptr) {
        return false;
    }

    begin(false); // 寫入模式
    bool success = _preferences.putString("ssid", ssid) && 
                   _preferences.putString("password", password);
    end();
    return success;
}

bool ConfigManager::loadWiFiCredentials(char* ssid, size_t ssidSize, char* password, size_t passwordSize) {
    if (ssid == nullptr || password == nullptr || ssidSize == 0 || passwordSize == 0) {
        return false;
    }

    begin(true); // 唯讀模式
    String tempSsid = _preferences.getString("ssid", "");
    String tempPass = _preferences.getString("password", "");
    end();

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
    begin(true); // 唯讀模式
    bool hasCredentials = _preferences.isKey("ssid") && _preferences.isKey("password");
    end();
    return hasCredentials;
}

bool ConfigManager::deleteWiFiCredentials() {
    begin(false); // 寫入模式
    bool success = _preferences.remove("ssid") && _preferences.remove("password");
    end();
    return success;
}

// 一般設定值管理方法
bool ConfigManager::saveString(const char* key, const char* value) {
    if (key == nullptr || value == nullptr) {
        return false;
    }
    
    begin(false);
    bool success = _preferences.putString(key, value);
    end();
    return success;
}

String ConfigManager::loadString(const char* key, const char* defaultValue) {
    begin(true);
    String result = _preferences.getString(key, defaultValue);
    end();
    return result;
}

bool ConfigManager::saveInt(const char* key, int value) {
    begin(false);
    bool success = _preferences.putInt(key, value);
    end();
    return success;
}

int ConfigManager::loadInt(const char* key, int defaultValue) {
    begin(true);
    int result = _preferences.getInt(key, defaultValue);
    end();
    return result;
}

bool ConfigManager::saveFloat(const char* key, float value) {
    begin(false);
    bool success = _preferences.putFloat(key, value);
    end();
    return success;
}

float ConfigManager::loadFloat(const char* key, float defaultValue) {
    begin(true);
    float result = _preferences.getFloat(key, defaultValue);
    end();
    return result;
}

bool ConfigManager::saveBool(const char* key, bool value) {
    begin(false);
    bool success = _preferences.putBool(key, value);
    end();
    return success;
}

bool ConfigManager::loadBool(const char* key, bool defaultValue) {
    begin(true);
    bool result = _preferences.getBool(key, defaultValue);
    end();
    return result;
}

bool ConfigManager::deleteKey(const char* key) {
    if (key == nullptr) {
        return false;
    }
    
    begin(false);
    bool success = _preferences.remove(key);
    end();
    return success;
}

void ConfigManager::clearAll() {
    begin(false);
    _preferences.clear();
    end();
}