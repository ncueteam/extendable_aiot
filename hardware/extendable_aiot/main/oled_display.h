/*
 * OLED Display Interface
 */

#pragma once

#include <stdint.h>
#include "esp_err.h"
#include "ssd1306.h"

typedef struct {
    uint8_t x;
    uint8_t y;
} oled_position_t;

typedef struct {
    ssd1306_handle_t device;
    uint8_t width;
    uint8_t height;
} oled_display_t;

/**
 * @brief 初始化 OLED 顯示器
 * 
 * @return oled_display_t* OLED 顯示器實例，如果初始化失敗則返回 NULL
 */
oled_display_t* oled_display_init(void);

/**
 * @brief 清除螢幕
 * 
 * @param display OLED 顯示器實例
 */
void oled_display_clear(oled_display_t* display);

/**
 * @brief 顯示文字
 * 
 * @param display OLED 顯示器實例
 * @param text 要顯示的文字
 * @param position 文字位置
 * @param size 文字大小 (12 或 16)
 */
void oled_display_text(oled_display_t* display, const char* text, oled_position_t position, uint8_t size);

/**
 * @brief 設置單個像素
 * 
 * @param display OLED 顯示器實例
 * @param x X 座標 (0-127)
 * @param y Y 座標 (0-63)
 * @param pixel 像素值 (0: 關閉, 1: 開啟)
 */
void oled_display_pixel(oled_display_t* display, uint8_t x, uint8_t y, uint8_t pixel);

/**
 * @brief 獲取單個像素的狀態
 * 
 * @param display OLED 顯示器實例
 * @param x X 座標 (0-127)
 * @param y Y 座標 (0-63)
 * @return uint8_t 像素值 (0: 關閉, 1: 開啟)
 */
uint8_t oled_display_get_pixel(oled_display_t* display, uint8_t x, uint8_t y);

/**
 * @brief 繪製時間
 * 
 * @param display OLED 顯示器實例
 * @param hours 小時 (0-23)
 * @param minutes 分鐘 (0-59)
 * @param seconds 秒 (0-59)
 */
void oled_display_time(oled_display_t* display, uint8_t hours, uint8_t minutes, uint8_t seconds);

/**
 * @brief 刷新顯示內容
 * 
 * @param display OLED 顯示器實例
 */
void oled_display_update(oled_display_t* display);

/**
 * @brief 釋放 OLED 顯示器資源
 * 
 * @param display OLED 顯示器實例
 */
void oled_display_deinit(oled_display_t* display);