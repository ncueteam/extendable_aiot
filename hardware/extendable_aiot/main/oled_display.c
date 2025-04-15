#include "oled_display.h"
#include "driver/i2c.h"
#include "esp_log.h"

static const char *TAG = "oled_display";

#define I2C_MASTER_SCL_IO           22
#define I2C_MASTER_SDA_IO           21
#define I2C_MASTER_NUM              0
#define I2C_MASTER_FREQ_HZ          400000
#define SH1106_SET_PAGE_ADDR        0xB0

// Display buffer structure from ssd1306.c
typedef struct {
    i2c_port_t bus;
    uint16_t dev_addr;
    uint8_t s_chDisplayBuffer[128][8];
} ssd1306_dev_t;

static void i2c_master_init(void)
{
    i2c_config_t conf = {
        .mode = I2C_MODE_MASTER,
        .sda_io_num = I2C_MASTER_SDA_IO,
        .scl_io_num = I2C_MASTER_SCL_IO,
        .sda_pullup_en = GPIO_PULLUP_ENABLE,
        .scl_pullup_en = GPIO_PULLUP_ENABLE,
        .master.clk_speed = I2C_MASTER_FREQ_HZ,
    };
    ESP_ERROR_CHECK(i2c_param_config(I2C_MASTER_NUM, &conf));
    ESP_ERROR_CHECK(i2c_driver_install(I2C_MASTER_NUM, conf.mode, 0, 0, 0));
}

static esp_err_t sh1106_init(ssd1306_handle_t dev)
{
    i2c_cmd_handle_t cmd = i2c_cmd_link_create();
    if (cmd == NULL) {
        ESP_LOGE(TAG, "I2C command link create failed");
        return ESP_FAIL;
    }

    i2c_master_start(cmd);
    i2c_master_write_byte(cmd, (SSD1306_I2C_ADDRESS << 1) | I2C_MASTER_WRITE, true);

    // SH1106 initialization sequence
    i2c_master_write_byte(cmd, 0x00, true);  // Command stream
    i2c_master_write_byte(cmd, 0xAE, true);  // Display off
    i2c_master_write_byte(cmd, 0xA8, true);  // Set multiplex ratio
    i2c_master_write_byte(cmd, 0x3F, true);  // 64 lines
    i2c_master_write_byte(cmd, 0xD3, true);  // Set display offset
    i2c_master_write_byte(cmd, 0x00, true);  // No offset
    i2c_master_write_byte(cmd, 0x40, true);  // Set display start line to 0
    i2c_master_write_byte(cmd, 0xA1, true);  // Set segment re-map (A0=normal, A1=reverse)
    i2c_master_write_byte(cmd, 0xC0, true);  // Set COM output scan direction (C0=normal, C8=reverse) - Changed from C8 to C0
    i2c_master_write_byte(cmd, 0xDA, true);  // Set COM pins hardware configuration
    i2c_master_write_byte(cmd, 0x12, true);  // Alternative COM pin configuration
    i2c_master_write_byte(cmd, 0x81, true);  // Set contrast control
    i2c_master_write_byte(cmd, 0xFF, true);  // Contrast value
    i2c_master_write_byte(cmd, 0xA4, true);  // Disable entire display on
    i2c_master_write_byte(cmd, 0xA6, true);  // Set normal display mode
    i2c_master_write_byte(cmd, 0xD5, true);  // Set oscillator frequency
    i2c_master_write_byte(cmd, 0x80, true);  // Default frequency
    i2c_master_write_byte(cmd, 0x8D, true);  // Enable charge pump regulator
    i2c_master_write_byte(cmd, 0x14, true);  // Enable charge pump
    i2c_master_write_byte(cmd, 0xAF, true);  // Display on

    i2c_master_stop(cmd);
    esp_err_t ret = i2c_master_cmd_begin(I2C_MASTER_NUM, cmd, 1000 / portTICK_PERIOD_MS);
    i2c_cmd_link_delete(cmd);

    return ret;
}

static esp_err_t sh1106_set_pos(uint8_t page, uint8_t column)
{
    i2c_cmd_handle_t cmd = i2c_cmd_link_create();
    i2c_master_start(cmd);
    i2c_master_write_byte(cmd, (SSD1306_I2C_ADDRESS << 1) | I2C_MASTER_WRITE, true);
    i2c_master_write_byte(cmd, 0x00, true);  // Command stream
    
    // Set page address (0-7)
    i2c_master_write_byte(cmd, SH1106_SET_PAGE_ADDR | (page & 0x07), true);
    
    // Set column address (需要加 2 的偏移，SH1106 特性)
    column += 2;  // Add offset for SH1106
    i2c_master_write_byte(cmd, 0x10 | ((column >> 4) & 0x0F), true);  // Higher column address
    i2c_master_write_byte(cmd, 0x00 | (column & 0x0F), true);         // Lower column address
    
    i2c_master_stop(cmd);
    esp_err_t ret = i2c_master_cmd_begin(I2C_MASTER_NUM, cmd, 1000 / portTICK_PERIOD_MS);
    i2c_cmd_link_delete(cmd);
    
    return ret;
}

oled_display_t* oled_display_init(void)
{
    oled_display_t* display = (oled_display_t*)malloc(sizeof(oled_display_t));
    if (!display) {
        ESP_LOGE(TAG, "Failed to allocate memory for display");
        return NULL;
    }

    // 初始化 I2C
    i2c_master_init();

    // 建立 SSD1306 裝置
    display->device = ssd1306_create(I2C_MASTER_NUM, SSD1306_I2C_ADDRESS);
    if (display->device == NULL) {
        ESP_LOGE(TAG, "OLED create failed");
        free(display);
        return NULL;
    }

    // 初始化 SH1106
    if (sh1106_init(display->device) != ESP_OK) {
        ESP_LOGE(TAG, "OLED initialization failed");
        ssd1306_delete(display->device);
        free(display);
        return NULL;
    }

    display->width = SSD1306_WIDTH;
    display->height = SSD1306_HEIGHT;

    // 清除螢幕
    oled_display_clear(display);
    oled_display_update(display);
    
    ESP_LOGI(TAG, "OLED display initialized successfully");
    return display;
}

void oled_display_clear(oled_display_t* display)
{
    if (!display || !display->device) return;
    ssd1306_clear_screen(display->device, 0x00);
}

void oled_display_text(oled_display_t* display, const char* text, oled_position_t position, uint8_t size)
{
    if (!display || !display->device || !text) return;

    // 確認字體大小只能是 12 或 16
    if (size != 12 && size != 16) {
        size = 12; // 預設使用 12 點字
    }

    // 設置 SH1106 的列位址偏移
    i2c_cmd_handle_t cmd = i2c_cmd_link_create();
    i2c_master_start(cmd);
    i2c_master_write_byte(cmd, (SSD1306_I2C_ADDRESS << 1) | I2C_MASTER_WRITE, true);
    i2c_master_write_byte(cmd, 0x00, true); // Command stream
    i2c_master_write_byte(cmd, 0x02, true); // Set lower column address (offset)
    i2c_master_write_byte(cmd, 0x10, true); // Set higher column address
    i2c_master_stop(cmd);
    i2c_master_cmd_begin(I2C_MASTER_NUM, cmd, 1000 / portTICK_PERIOD_MS);
    i2c_cmd_link_delete(cmd);

    // 繪製文字並自動更新
    ssd1306_draw_string(display->device, position.x, position.y, (const uint8_t*)text, size, 1);
    oled_display_update(display);
}

void oled_display_pixel(oled_display_t* display, uint8_t x, uint8_t y, uint8_t pixel)
{
    if (!display || !display->device) return;
    if (x >= display->width || y >= display->height) return;

    ssd1306_dev_t* dev = (ssd1306_dev_t*)display->device;
    
    // 計算頁面和位元位置
    uint8_t page = y / 8;         // 每8個像素為一頁
    uint8_t bit = y % 8;          // 在頁內的位置
    uint8_t mask = 1 << bit;      // 直接使用 bit，不需要反轉位元位置

    if (pixel) {
        dev->s_chDisplayBuffer[x][page] |= mask;
    } else {
        dev->s_chDisplayBuffer[x][page] &= ~mask;
    }
}

uint8_t oled_display_get_pixel(oled_display_t* display, uint8_t x, uint8_t y)
{
    if (!display || !display->device) return 0;
    if (x >= display->width || y >= display->height) return 0;

    ssd1306_dev_t* dev = (ssd1306_dev_t*)display->device;
    
    // 保持與 set_pixel 相同的邏輯
    uint8_t page = y / 8;
    uint8_t bit = y % 8;
    uint8_t mask = 1 << bit;

    return (dev->s_chDisplayBuffer[x][page] & mask) ? 1 : 0;
}

void oled_display_update(oled_display_t* display)
{
    if (!display || !display->device) return;
    ssd1306_dev_t* dev = (ssd1306_dev_t*)display->device;

    // 逐頁更新顯示內容
    for (int page = 0; page < 8; page++) {
        // 設置頁面和列地址
        sh1106_set_pos(page, 0);

        // 寫入顯示數據
        i2c_cmd_handle_t cmd = i2c_cmd_link_create();
        i2c_master_start(cmd);
        i2c_master_write_byte(cmd, (SSD1306_I2C_ADDRESS << 1) | I2C_MASTER_WRITE, true);
        i2c_master_write_byte(cmd, 0x40, true);  // Data stream
        for (int col = 0; col < 128; col++) {
            i2c_master_write_byte(cmd, dev->s_chDisplayBuffer[col][page], true);
        }
        i2c_master_stop(cmd);
        i2c_master_cmd_begin(I2C_MASTER_NUM, cmd, 1000 / portTICK_PERIOD_MS);
        i2c_cmd_link_delete(cmd);
    }
}

void oled_display_deinit(oled_display_t* display)
{
    if (!display) return;
    
    if (display->device) {
        ssd1306_delete(display->device);
    }
    
    free(display);
}

void oled_display_time(oled_display_t* display, uint8_t hours, uint8_t minutes, uint8_t seconds)
{
    if (!display || !display->device) return;

    char time_str[16] = {0};  // Initialize to 0 and ensure enough space
    
    // Ensure values are in valid range before formatting
    const unsigned int h = hours % 24;    // Range: 0-23
    const unsigned int m = minutes % 60;  // Range: 0-59
    const unsigned int s = seconds % 60;  // Range: 0-59
    
    // Format time string - now the compiler can see the bounded ranges
    snprintf(time_str, sizeof(time_str), "%02u:%02u:%02u", h, m, s);

    // Clear display area
    oled_display_clear(display);

    // Display time in center position
    oled_position_t pos = {
        .x = (display->width - (16 * 8)) / 2,  // 16pt font, ~8px per char
        .y = (display->height - 16) / 2        // 16pt font height
    };
    
    // Display time using 16pt font
    oled_display_text(display, time_str, pos, 16);
}