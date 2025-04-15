#ifndef TIME_SYNC_H
#define TIME_SYNC_H

#include "esp_err.h"

/**
 * @brief 初始化時間同步服務
 * 
 * @return esp_err_t 
 */
esp_err_t time_sync_init(void);

/**
 * @brief 等待時間同步完成
 * 
 * @param timeout_ms 超時時間（毫秒）
 * @return esp_err_t ESP_OK: 同步成功, ESP_ERR_TIMEOUT: 超時
 */
esp_err_t time_sync_wait(uint32_t timeout_ms);

/**
 * @brief 獲取當前時間
 * 
 * @param hours 小時
 * @param minutes 分鐘
 * @param seconds 秒
 */
void time_sync_get_time(uint8_t *hours, uint8_t *minutes, uint8_t *seconds);

#endif // TIME_SYNC_H