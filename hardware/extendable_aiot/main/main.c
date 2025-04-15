#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/timers.h"
#include "driver/gpio.h"
#include "esp_log.h"
#include "led_strip.h"
#include "sdkconfig.h"
#include "oled_display.h"
#include "esp_timer.h"

static const char *TAG = "extended_aiot";

#define BLINK_GPIO CONFIG_BLINK_GPIO

static uint8_t s_led_state = 0;
static oled_display_t* oled_display = NULL;

// 時間狀態
static struct {
    uint8_t hours;
    uint8_t minutes;
    uint8_t seconds;
} current_time = {12, 0, 0};  // 從中午12點開始

// 時鐘更新任務句柄
static TaskHandle_t clock_task_handle = NULL;

#ifdef CONFIG_BLINK_LED_STRIP

static led_strip_handle_t led_strip;

static void blink_led(void)
{
    /* If the addressable LED is enabled */
    if (s_led_state) {
        /* Set the LED pixel using RGB from 0 (0%) to 255 (100%) for each color */
        led_strip_set_pixel(led_strip, 0, 16, 16, 16);
        /* Refresh the strip to send data */
        led_strip_refresh(led_strip);
    } else {
        /* Set all LED off to clear all pixels */
        led_strip_clear(led_strip);
    }
}

static void configure_led(void)
{
    ESP_LOGI(TAG, "Example configured to blink addressable LED!");
    /* LED strip initialization with the GPIO and pixels number*/
    led_strip_config_t strip_config = {
        .strip_gpio_num = BLINK_GPIO,
        .max_leds = 1, // at least one LED on board
    };
#if CONFIG_BLINK_LED_STRIP_BACKEND_RMT
    led_strip_rmt_config_t rmt_config = {
        .resolution_hz = 10 * 1000 * 1000, // 10MHz
        .flags.with_dma = false,
    };
    ESP_ERROR_CHECK(led_strip_new_rmt_device(&strip_config, &rmt_config, &led_strip));
#elif CONFIG_BLINK_LED_STRIP_BACKEND_SPI
    led_strip_spi_config_t spi_config = {
        .spi_bus = SPI2_HOST,
        .flags.with_dma = true,
    };
    ESP_ERROR_CHECK(led_strip_new_spi_device(&strip_config, &spi_config, &led_strip));
#else
#error "unsupported LED strip backend"
#endif
    /* Set all LED off to clear all pixels */
    led_strip_clear(led_strip);
}

#elif CONFIG_BLINK_LED_GPIO

static void blink_led(void)
{
    gpio_set_level(BLINK_GPIO, s_led_state);
}

static void configure_led(void)
{
    ESP_LOGI(TAG, "Example configured to blink GPIO LED!");
    gpio_reset_pin(BLINK_GPIO);
    gpio_set_direction(BLINK_GPIO, GPIO_MODE_OUTPUT);
}

#else
#error "unsupported LED type"
#endif

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

static void update_clock_task(void* arg)
{
    while (1) {
        // 更新時間
        current_time.seconds++;
        if (current_time.seconds >= 60) {
            current_time.seconds = 0;
            current_time.minutes++;
            if (current_time.minutes >= 60) {
                current_time.minutes = 0;
                current_time.hours++;
                if (current_time.hours >= 24) {
                    current_time.hours = 0;
                }
            }
        }

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
    // Initialize LED
    configure_led();
    
    // Initialize OLED
    oled_display = oled_display_init();
    if (oled_display == NULL) {
        ESP_LOGE(TAG, "Failed to initialize OLED display");
        return;
    }

    // 創建時鐘更新任務
    xTaskCreate(update_clock_task, "clock_task", 2048, NULL, 5, &clock_task_handle);

    while (1) {
        ESP_LOGI(TAG, "Current time: %02d:%02d:%02d", 
                 current_time.hours, current_time.minutes, current_time.seconds);
        // LED blink
        blink_led();
        s_led_state = !s_led_state;
        vTaskDelay(CONFIG_BLINK_PERIOD / portTICK_PERIOD_MS);
    }
}
