#ifndef TIME_MANAGER_H
#define TIME_MANAGER_H

#include <Arduino.h>
#include "time.h"
#include "WiFiManager.h"

class TimeManager {
private:
    const char* _ntpServer;
    long _gmtOffsetSec;
    int _daylightOffsetSec;
    WiFiManager* _wifiManager;
    bool _isTimeConfigured;
    
public:
    // 建構函數
    TimeManager(
        const char* ntpServer = "pool.ntp.org",
        long gmtOffsetSec = 28800, // GMT+8 (台灣時區)
        int daylightOffsetSec = 0,
        WiFiManager* wifiManager = nullptr
    );
    
    // 初始化時間服務
    bool begin();
    
    // 手動更新NTP時間
    bool updateTime();
    
    // 取得格式化時間字串 (時:分:秒)
    String getFormattedTime();
    
    // 取得格式化日期字串 (年-月-日)
    String getFormattedDate();
    
    // 取得自定格式的時間字串
    String getCustomFormattedTime(const char* format);
    
    // 檢查時間是否已配置完成
    bool isTimeConfigured() const;
};

#endif // TIME_MANAGER_H