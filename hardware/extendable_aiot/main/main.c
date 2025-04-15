#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/timers.h"
#include "driver/gpio.h"
#include "esp_log.h"
#include "sdkconfig.h"
#include "oled_display.h"
#include "esp_timer.h"
#include "nvs_flash.h"
#include "wifi_manager.h"
#include "time_sync.h"
#include "led_manager.h"

static const char *TAG = "extended_aiot";

// WiFi 相關定義
#define WIFI_SSID      "Yun"
#define WIFI_PASSWORD  "0937565253"

static oled_display_t* oled_display = NULL;

// 時間狀態
static struct {
    uint8_t hours;
    uint8_t minutes;
    uint8_t seconds;
} current_time = {12, 0, 0};  // 從中午12點開始

// 時鐘更新任務句柄
static TaskHandle_t clock_task_handle = NULL;

static void update_oled_display(void)
{
    if (oled_display == NULL) return;
    
    oled_display_clear(oled_display);
    
    // 在位置 (0,0) 顯示 "Hello World"，字體大小為 16
    oled_position_t pos = {0, 0};
    oled_display_text(oled_display, "Hello World", pos, 16);
    
    oled_display_update(oled_display);
}

// 像素測試模式
static void test_pixel_pattern(void)
{
    if (!oled_display) return;

    // 測試模式 1: 逐行掃描
    oled_display_clear(oled_display);
    for (int y = 0; y < 64; y++) {
        for (int x = 0; x < 128; x++) {
            oled_display_pixel(oled_display, x, y, 1);
            if (x % 8 == 7) {  // 每8個像素更新一次顯示
                oled_display_update(oled_display);
                vTaskDelay(1);  // 給一點延遲以便觀察
            }
        }
        oled_display_update(oled_display);
        vTaskDelay(50 / portTICK_PERIOD_MS);  // 每行延遲50ms
    }
    vTaskDelay(1000 / portTICK_PERIOD_MS);

    // 測試模式 2: 棋盤格
    oled_display_clear(oled_display);
    for (int y = 0; y < 64; y++) {
        for (int x = 0; x < 128; x++) {
            oled_display_pixel(oled_display, x, y, (x + y) % 2);
        }
    }
    oled_display_update(oled_display);
    vTaskDelay(1000 / portTICK_PERIOD_MS);

    // 測試模式 3: 對角線
    oled_display_clear(oled_display);
    for (int i = 0; i < 128; i++) {
        int y = (i * 64) / 128;  // 計算對角線上的y座標
        oled_display_pixel(oled_display, i, y, 1);
    }
    oled_display_update(oled_display);
    vTaskDelay(1000 / portTICK_PERIOD_MS);

    // 測試模式 4: 像素讀取驗證
    oled_display_clear(oled_display);
    // 在特定位置設置像素
    for (int x = 0; x < 128; x += 4) {
        for (int y = 0; y < 64; y += 4) {
            oled_display_pixel(oled_display, x, y, 1);
        }
    }
    oled_display_update(oled_display);
    
    // 驗證像素值
    for (int x = 0; x < 128; x++) {
        for (int y = 0; y < 64; y++) {
            uint8_t pixel = oled_display_get_pixel(oled_display, x, y);
            uint8_t expected = ((x % 4 == 0) && (y % 4 == 0)) ? 1 : 0;
            if (pixel != expected) {
                ESP_LOGE(TAG, "Pixel mismatch at (%d,%d): expected %d, got %d", 
                         x, y, expected, pixel);
            }
        }
    }
    vTaskDelay(1000 / portTICK_PERIOD_MS);
}

// WiFi 事件回調函數
static void wifi_event_callback(wifi_manager_event_t event, void* data)
{
    switch (event) {
        case WIFI_EVENT_CONNECTED:
            ESP_LOGI(TAG, "WiFi Connected");
            break;
        case WIFI_EVENT_DISCONNECTED:
            ESP_LOGI(TAG, "WiFi Disconnected");
            break;
        case WIFI_EVENT_GOT_IP:
            ESP_LOGI(TAG, "WiFi Got IP");
            // 初始化時間同步
            ESP_ERROR_CHECK(time_sync_init());
            // 等待時間同步完成（設置30秒超時）
            if (time_sync_wait(30000) == ESP_OK) {
                ESP_LOGI(TAG, "Time synchronized successfully");
                // 更新當前時間
                time_sync_get_time(&current_time.hours, &current_time.minutes, &current_time.seconds);
            } else {
                ESP_LOGE(TAG, "Time synchronization timeout");
            }
            break;
    }
}

static void update_clock_task(void* arg)
{
    while (1) {
        // 更新時間（從網路同步的時間）
        time_sync_get_time(&current_time.hours, &current_time.minutes, &current_time.seconds);

        // 更新顯示
        if (oled_display) {
            oled_display_time(oled_display, 
                            current_time.hours,
                            current_time.minutes,
                            current_time.seconds);
        }

        // 每秒更新一次
        vTaskDelay(1000 / portTICK_PERIOD_MS);
    }
}

void app_main(void)
{
    // Initialize NVS
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);

    // Initialize WiFi
    ESP_LOGI(TAG, "Initializing WiFi");
    ESP_ERROR_CHECK(wifi_manager_init(WIFI_SSID, WIFI_PASSWORD));
    wifi_manager_set_callback(wifi_event_callback);
    ESP_ERROR_CHECK(wifi_manager_start());

    // Initialize LED
    ESP_ERROR_CHECK(led_manager_init());
    
    // Initialize OLED
    oled_display = oled_display_init();
    if (oled_display == NULL) {
        ESP_LOGE(TAG, "Failed to initialize OLED display");
        return;
    }

    // Create clock update task
    xTaskCreate(update_clock_task, "clock_task", 2048, NULL, 5, &clock_task_handle);

    while (1) {
        ESP_LOGI(TAG, "Current time: %02d:%02d:%02d", 
                 current_time.hours, current_time.minutes, current_time.seconds);
        
        // Toggle LED state
        led_manager_toggle();
        vTaskDelay(CONFIG_BLINK_PERIOD / portTICK_PERIOD_MS);
    }
}
