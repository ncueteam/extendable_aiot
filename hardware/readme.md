# ESP32 AIOT 開發板

這是一個基於ESP32的AIOT(AI + IOT)開發板專案,整合了OLED顯示、LED呼吸燈控制、WiFi連接等功能。

## 硬體規格

- 開發板: NodeMCU-32S
- 微控制器: ESP32
- 顯示器: SH1106 128x64 OLED (I2C介面)
- LED: 板載LED (GPIO2)
- WiFi: 2.4GHz IEEE 802.11 b/g/n
- 紅外線: IR發射與接收
- 溫濕度: DHT11感測器

## 接腳定義

| 功能 | GPIO腳位 | 說明 |
|------|----------|------|
| OLED SCL | GPIO22 | I2C時鐘線 (硬體I2C) |
| OLED SDA | GPIO21 | I2C資料線 (硬體I2C) |
| LED | GPIO2 | 內建LED,用於呼吸燈效果 |
| IR Receiver | GPIO23 | 紅外線接收器 |
| IR Transmitter | GPIO32 | 紅外線發射器 |
| DHT11 | GPIO14 | 溫濕度感測器資料腳 |

## 狀態機架構

系統包含以下幾個主要狀態:

1. 初始化狀態
   - 配置LEDC (LED控制)
   - 初始化OLED顯示器
   - 啟用UTF8支援

2. WiFi連接狀態
   - 嘗試連接WiFi
   - 顯示連接進度
   - 最多嘗試20次
   - 連接成功後顯示IP位址

3. 運行狀態
   - LED呼吸燈效果控制
     * 使用LEDC PWM控制
     * 5ms更新間隔
     * 0-255亮度範圍
   - OLED顯示更新
     * 1秒更新間隔
     * 顯示標題
     * 顯示日期時間
     * 顯示WiFi狀態
     * 顯示MQTT連接狀態
     * 顯示數據傳輸指示
   - WiFi狀態監控
     * 持續監控連接狀態
     * 斷線自動重連
   - MQTT通訊
     * 自動重連機制
     * 每5秒發送感測器數據
     * 支援遺囑訊息
     * 在線狀態監控

## 功能特點

1. LED呼吸燈效果
   - 使用LEDC硬體PWM
   - 流暢的漸明漸暗效果
   - 可調整更新頻率

2. OLED顯示
   - 支援中文顯示(UTF8)
   - 即時顯示系統狀態
   - 多字型支援

3. 網路功能
   - WiFi自動連接
   - 自動重連機制
   - NTP時間同步
   - MQTT數據傳輸
   - 顯示網路狀態

4. 時間管理
   - NTP自動校時
   - 即時顯示日期時間
   - 時區設定(GMT+8)

## 配置說明

主要配置參數位於main.cpp:

```cpp
// WiFi設定
const char* ssid = "Your_SSID";
const char* password = "Your_Password";

// NTP服務器設定
const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = 28800;  // GMT+8
const int   daylightOffset_sec = 0;

// MQTT設定
const char* mqtt_server = "broker.emqx.io";
const int mqtt_port = 1883;
const char* mqtt_topic = "esp32/sensors";
const char* client_id = "ESP32_Client_";

// LED設定
const int LEDC_CHANNEL = 0;
const int LEDC_TIMER_BIT = 8;
const int LEDC_BASE_FREQ = 5000;

// 更新間隔設定
const long interval = 5;         // LED更新(ms)
const long displayInterval = 1000; // 顯示更新(ms)
const long mqttPublishInterval = 5000; // MQTT發布間隔(ms)
```

## 相依套件

- U8g2: OLED顯示驅動程式
- Wire: I2C通訊程式庫
- WiFi: ESP32 WiFi功能程式庫
- PubSubClient: MQTT客戶端程式庫
- ArduinoJson: JSON處理程式庫
- DHT sensor library: DHT11溫濕度感測器程式庫

## 編譯與燒錄

使用PlatformIO進行專案管理,主要配置在platformio.ini:

```ini
[env:nodemcu-32s]
platform = espressif32
board = nodemcu-32s
framework = arduino
lib_deps = 
    olikraus/U8g2@^2.35.9
    adafruit/DHT sensor library@^1.4.6
    adafruit/Adafruit Unified Sensor@^1.1.9
    knolleary/PubSubClient@^2.8
    bblanchon/ArduinoJson@^6.21.3
```

## 未來擴充

1. Web控制介面
2. OTA更新功能
3. 更多感測器整合
4. 自定義MQTT主題
5. 數據視覺化介面

## 注意事項

1. 請確保正確連接OLED顯示器
2. WiFi密碼請妥善保管
3. LED亮度可透過LEDC參數調整
4. 時區設定請根據所在地區調整

## MQTT 功能說明

### MQTT 配置
- Broker: broker.emqx.io (公共 MQTT broker)
- 端口: 1883
- 發布主題: esp32/sensors (感測器數據)
- 狀態主題: esp32/status (設備在線狀態)
- 命令主題: esp32/commands (接收控制命令)

### 數據格式
發布的感測器數據使用 JSON 格式：
```json
{
    "temperature": 溫度值,
    "humidity": 濕度值,
    "timestamp": "時間戳"
}
```

### 主要功能
1. 自動重連機制
   - 斷線自動重連
   - 每5秒嘗試重連一次
   - OLED顯示連接狀態

2. 遺囑訊息（Last Will）
   - 異常斷線時自動發送離線狀態
   - 主題：esp32/status
   - 訊息：online/offline

3. 數據發布
   - 每5秒發送一次感測器數據
   - 包含溫度、濕度和時間戳
   - OLED顯示傳輸狀態

### 監控工具使用方法

1. 網頁版 MQTT 客戶端
   - 網址：http://www.hivemq.com/demos/websocket-client/
   - 連接設置：
     * Host: broker.emqx.io
     * Port: 8083 (WebSocket)
     * 訂閱主題：esp32/sensors

2. 手機 App
   - 推薦使用：MQTT Explorer (Android/iOS)
   - 連接設置：
     * Broker: broker.emqx.io
     * Port: 1883
     * 訂閱主題：esp32/sensors

3. 桌面應用程式
   - 推薦使用：MQTT.fx 或 MQTT Explorer
   - 連接設置同上