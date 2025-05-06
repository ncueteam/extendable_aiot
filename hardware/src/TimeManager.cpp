#include "TimeManager.h"

TimeManager::TimeManager(const char* ntpServer, long gmtOffsetSec, int daylightOffsetSec, WiFiManager* wifiManager)
    : _ntpServer(ntpServer),
      _gmtOffsetSec(gmtOffsetSec),
      _daylightOffsetSec(daylightOffsetSec),
      _wifiManager(wifiManager),
      _isTimeConfigured(false) {
}

bool TimeManager::begin() {
    // 如果WiFi未連接，則無法同步時間
    if (_wifiManager != nullptr && !_wifiManager->isConnected()) {
        Serial.println("WiFi未連接，無法同步時間");
        return false;
    }
    
    // 配置NTP時間同步服務
    configTime(_gmtOffsetSec, _daylightOffsetSec, _ntpServer);
    Serial.println("正在嘗試取得NTP時間...");
    
    // 嘗試取得時間以確認是否配置成功
    struct tm timeinfo;
    if (getLocalTime(&timeinfo)) {
        Serial.println("NTP時間同步成功");
        _isTimeConfigured = true;
        return true;
    } else {
        Serial.println("NTP時間同步失敗");
        return false;
    }
}

bool TimeManager::updateTime() {
    // 如果WiFi未連接，則無法同步時間
    if (_wifiManager != nullptr && !_wifiManager->isConnected()) {
        return false;
    }
    
    // 重新配置NTP時間同步服務
    configTime(_gmtOffsetSec, _daylightOffsetSec, _ntpServer);
    
    // 檢查是否成功取得時間
    struct tm timeinfo;
    if (getLocalTime(&timeinfo)) {
        _isTimeConfigured = true;
        return true;
    }
    
    return false;
}

String TimeManager::getFormattedTime() {
    struct tm timeinfo;
    if (!getLocalTime(&timeinfo)) {
        return "未同步時間";
    }
    
    char timeString[20];
    strftime(timeString, sizeof(timeString), "%H:%M:%S", &timeinfo);
    return String(timeString);
}

String TimeManager::getFormattedDate() {
    struct tm timeinfo;
    if (!getLocalTime(&timeinfo)) {
        return "未同步日期";
    }
    
    char dateString[20];
    strftime(dateString, sizeof(dateString), "%Y-%m-%d", &timeinfo);
    return String(dateString);
}

String TimeManager::getCustomFormattedTime(const char* format) {
    struct tm timeinfo;
    if (!getLocalTime(&timeinfo)) {
        return "未同步時間";
    }
    
    char timeString[64]; // 較大的緩衝區以適應各種格式
    strftime(timeString, sizeof(timeString), format, &timeinfo);
    return String(timeString);
}

bool TimeManager::isTimeConfigured() const {
    return _isTimeConfigured;
}