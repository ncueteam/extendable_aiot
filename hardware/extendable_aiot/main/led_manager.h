#ifndef LED_MANAGER_H
#define LED_MANAGER_H

#include "esp_err.h"

/**
 * @brief 初始化 LED 管理器
 * 
 * @return esp_err_t 
 */
esp_err_t led_manager_init(void);

/**
 * @brief 設置 LED 狀態
 * 
 * @param state LED 的狀態：1 為開啟，0 為關閉
 */
void led_manager_set_state(uint8_t state);

/**
 * @brief 切換 LED 狀態
 * 
 * @return uint8_t 切換後的狀態
 */
uint8_t led_manager_toggle(void);

#endif // LED_MANAGER_H