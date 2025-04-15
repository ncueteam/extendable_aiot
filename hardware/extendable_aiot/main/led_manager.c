#include "led_manager.h"
#include "driver/gpio.h"
#include "led_strip.h"
#include "esp_log.h"
#include "sdkconfig.h"

static const char *TAG = "led_manager";

#define BLINK_GPIO CONFIG_BLINK_GPIO

static uint8_t s_led_state = 0;
static led_strip_handle_t led_strip;

#ifdef CONFIG_BLINK_LED_STRIP

static void configure_led(void)
{
    ESP_LOGI(TAG, "Configuring addressable LED strip");
    led_strip_config_t strip_config = {
        .strip_gpio_num = BLINK_GPIO,
        .max_leds = 1,
    };
    
#if CONFIG_BLINK_LED_STRIP_BACKEND_RMT
    led_strip_rmt_config_t rmt_config = {
        .resolution_hz = 10 * 1000 * 1000,
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
    
    led_strip_clear(led_strip);
}

static void update_led_state(void)
{
    if (s_led_state) {
        led_strip_set_pixel(led_strip, 0, 16, 16, 16);
        led_strip_refresh(led_strip);
    } else {
        led_strip_clear(led_strip);
    }
}

#elif CONFIG_BLINK_LED_GPIO

static void configure_led(void)
{
    ESP_LOGI(TAG, "Configuring GPIO LED");
    gpio_reset_pin(BLINK_GPIO);
    gpio_set_direction(BLINK_GPIO, GPIO_MODE_OUTPUT);
}

static void update_led_state(void)
{
    gpio_set_level(BLINK_GPIO, s_led_state);
}

#else
#error "unsupported LED type"
#endif

esp_err_t led_manager_init(void)
{
    configure_led();
    return ESP_OK;
}

void led_manager_set_state(uint8_t state)
{
    s_led_state = state;
    update_led_state();
}

uint8_t led_manager_toggle(void)
{
    s_led_state = !s_led_state;
    update_led_state();
    return s_led_state;
}