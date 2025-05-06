#include "StorageManager.h"

StorageManager::StorageManager(const char* namespace_name) {
    _namespace = namespace_name;
    _isOpen = false;
}

StorageManager::~StorageManager() {
    if (_isOpen) {
        end();
    }
}

void StorageManager::begin(bool readonly) {
    if (!_isOpen) {
        _preferences.begin(_namespace.c_str(), readonly);
        _isOpen = true;
    }
}

void StorageManager::end() {
    if (_isOpen) {
        _preferences.end();
        _isOpen = false;
    }
}

bool StorageManager::hasKey(const char* key) {
    begin(true); // 以唯讀模式開啟
    bool exists = _preferences.isKey(key);
    end();
    return exists;
}

bool StorageManager::saveString(const char* key, const char* value) {
    if (key == nullptr || value == nullptr) {
        return false;
    }
    
    begin(false); // 以寫入模式開啟
    bool success = _preferences.putString(key, value);
    end();
    return success;
}

String StorageManager::loadString(const char* key, const char* defaultValue) {
    begin(true);
    String result = _preferences.getString(key, defaultValue);
    end();
    return result;
}

bool StorageManager::saveInt(const char* key, int value) {
    begin(false);
    bool success = _preferences.putInt(key, value);
    end();
    return success;
}

int StorageManager::loadInt(const char* key, int defaultValue) {
    begin(true);
    int result = _preferences.getInt(key, defaultValue);
    end();
    return result;
}

bool StorageManager::saveFloat(const char* key, float value) {
    begin(false);
    bool success = _preferences.putFloat(key, value);
    end();
    return success;
}

float StorageManager::loadFloat(const char* key, float defaultValue) {
    begin(true);
    float result = _preferences.getFloat(key, defaultValue);
    end();
    return result;
}

bool StorageManager::saveBool(const char* key, bool value) {
    begin(false);
    bool success = _preferences.putBool(key, value);
    end();
    return success;
}

bool StorageManager::loadBool(const char* key, bool defaultValue) {
    begin(true);
    bool result = _preferences.getBool(key, defaultValue);
    end();
    return result;
}

bool StorageManager::deleteKey(const char* key) {
    if (key == nullptr) {
        return false;
    }
    
    begin(false);
    bool success = _preferences.remove(key);
    end();
    return success;
}

void StorageManager::clearAll() {
    begin(false);
    _preferences.clear();
    end();
}

const char* StorageManager::getNamespace() const {
    return _namespace.c_str();
}