#ifndef WIFI_MANAGER_H
#define WIFI_MANAGER_H

#include "esp_err.h"

// WiFi 連接事件型別
typedef enum {
    WIFI_EVENT_CONNECTED,
    WIFI_EVENT_DISCONNECTED,
    WIFI_EVENT_GOT_IP
} wifi_manager_event_t;

// WiFi 事件回調函數型別
typedef void (*wifi_event_callback_t)(wifi_manager_event_t event, void* data);

/**
 * @brief 初始化 WiFi 管理器並設置為 Station 模式
 * 
 * @param ssid WiFi SSID
 * @param password WiFi 密碼
 * @return esp_err_t 
 */
esp_err_t wifi_manager_init(const char* ssid, const char* password);

/**
 * @brief 開始 WiFi 連接
 * 
 * @return esp_err_t 
 */
esp_err_t wifi_manager_start(void);

/**
 * @brief 停止 WiFi 連接
 * 
 * @return esp_err_t 
 */
esp_err_t wifi_manager_stop(void);

/**
 * @brief 註冊 WiFi 事件回調函數
 * 
 * @param callback 回調函數
 */
void wifi_manager_set_callback(wifi_event_callback_t callback);

#endif // WIFI_MANAGER_H