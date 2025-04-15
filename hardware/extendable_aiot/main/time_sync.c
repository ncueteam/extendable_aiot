#include "time_sync.h"
#include "esp_sntp.h"
#include "esp_log.h"
#include <time.h>
#include <sys/time.h>

static const char *TAG = "time_sync";
static volatile bool sntp_sync_done = false;

static void time_sync_notification_cb(struct timeval *tv)
{
    ESP_LOGI(TAG, "Time synchronization completed!");
    sntp_sync_done = true;
}

esp_err_t time_sync_init(void)
{
    sntp_sync_done = false;

    // 設置時區為 GMT+8 (台灣時區)
    setenv("TZ", "CST-8", 1);
    tzset();

    // 初始化 SNTP
    sntp_setoperatingmode(SNTP_OPMODE_POLL);
    sntp_setservername(0, "pool.ntp.org");
    sntp_set_time_sync_notification_cb(time_sync_notification_cb);
    sntp_init();

    return ESP_OK;
}

esp_err_t time_sync_wait(uint32_t timeout_ms)
{
    uint32_t start = esp_log_timestamp();
    
    while (!sntp_sync_done) {
        if ((esp_log_timestamp() - start) > timeout_ms) {
            return ESP_ERR_TIMEOUT;
        }
        vTaskDelay(pdMS_TO_TICKS(100));
    }
    
    return ESP_OK;
}

void time_sync_get_time(uint8_t *hours, uint8_t *minutes, uint8_t *seconds)
{
    time_t now;
    struct tm timeinfo;
    
    time(&now);
    localtime_r(&now, &timeinfo);
    
    if (hours) *hours = timeinfo.tm_hour;
    if (minutes) *minutes = timeinfo.tm_min;
    if (seconds) *seconds = timeinfo.tm_sec;
}