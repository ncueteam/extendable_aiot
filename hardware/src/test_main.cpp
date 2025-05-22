#include <Arduino.h>
#include <U8g2lib.h>
#include <Wire.h>
#include <IRremoteESP8266.h>
#include <IRrecv.h>
#include <IRutils.h>

// 定義IR接收器引腳
#define IR_RECV_PIN 23  // ESP32 GPIO23作為IR接收引腳

// 創建IR接收器實例
IRrecv irReceiver(IR_RECV_PIN);
decode_results irResults;

// 創建U8g2顯示器物件 (使用硬體I2C)
U8G2_SH1106_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, U8X8_PIN_NONE);

// IR接收數據
String irProtocol = "";
uint32_t irValue = 0;
uint16_t irBits = 0;
unsigned long irReceivedTime = 0;
bool hasNewIrData = false;
const unsigned long IR_DISPLAY_TIMEOUT = 10000;  // 10秒顯示超時

// 將協議類型轉換為字串
String getProtocolString(decode_type_t protocol) {
  switch(protocol) {
    case decode_type_t::NEC: return "NEC";
    case decode_type_t::SONY: return "SONY";
    case decode_type_t::RC5: return "RC5";
    case decode_type_t::RC6: return "RC6";
    case decode_type_t::DISH: return "DISH";
    case decode_type_t::SHARP: return "SHARP";
    case decode_type_t::JVC: return "JVC";
    case decode_type_t::SANYO: return "SANYO";
    case decode_type_t::MITSUBISHI: return "MITSU";
    case decode_type_t::SAMSUNG: return "SAMSUNG";
    case decode_type_t::LG: return "LG";
    case decode_type_t::WHYNTER: return "WHYNTER";
    case decode_type_t::PANASONIC: return "PANASONIC";
    case decode_type_t::DENON: return "DENON";
    default: return "UNKNOWN";
  }
}

// 更新紅外線接收資料
void updateIRData(const String& protocol, uint32_t value, uint16_t bits) {
  irProtocol = protocol;
  irValue = value;
  irBits = bits;
  irReceivedTime = millis();
  hasNewIrData = true;
  
  // 立即顯示在Serial監視器
  Serial.println("接收到IR訊號:");
  Serial.print("協議: "); Serial.println(irProtocol);
  Serial.print("數值: 0x"); Serial.println(irValue, HEX);
  Serial.print("位元數: "); Serial.println(irBits);
}

// 顯示紅外線接收資料畫面
void showIRData() {
  u8g2.clearBuffer();
  
  // 顯示標題
  u8g2.setFont(u8g2_font_ncenB10_tr);
  u8g2.drawStr(0, 12, "IR Received");
  
  // 顯示協議
  u8g2.setFont(u8g2_font_ncenB08_tr);
  String protocolText = "Protocol: " + irProtocol;
  u8g2.drawStr(0, 28, protocolText.c_str());
  
  // 顯示值 (十六進制)
  char valueBuffer[24];
  sprintf(valueBuffer, "Value: 0x%08X", irValue);
  u8g2.drawStr(0, 42, valueBuffer);
  
  // 顯示位元數
  String bitsText = "Bits: " + String(irBits);
  u8g2.drawStr(0, 56, bitsText.c_str());
  
  u8g2.sendBuffer();
}

// 顯示等待畫面
void showWaitingScreen() {
  u8g2.clearBuffer();
  u8g2.setFont(u8g2_font_ncenB10_tr);
  u8g2.drawStr(0, 24, "Waiting for");
  u8g2.drawStr(0, 42, "IR signal...");
  u8g2.sendBuffer();
}

void setup() {
  // 初始化序列通訊
  Serial.begin(115200);
  Serial.println("IR接收器測試程式 - 啟動中...");
  
  // 初始化OLED顯示器
  u8g2.begin();
  u8g2.clearBuffer();
  u8g2.setFont(u8g2_font_ncenB10_tr);
  u8g2.drawStr(0, 24, "IR Receiver");
  u8g2.drawStr(0, 42, "Test Starting...");
  u8g2.sendBuffer();
  delay(1000);
  
  // 配置IR接收器
  irReceiver.enableIRIn();  // 啟動IR接收器
  irReceiver.setUnknownThreshold(12);  // 設置未知協議識別閾值
  
  Serial.println("IR接收器已初始化，等待訊號...");
  showWaitingScreen();
}

void loop() {
  // 檢查是否有IR信號
  if (irReceiver.decode(&irResults)) {
    // 獲取協議類型
    String protocol = getProtocolString(irResults.decode_type);
    
    // 更新IR數據
    updateIRData(protocol, irResults.value, irResults.bits);
    
    // 恢復接收下一個值
    irReceiver.resume();
  }
  
  // 處理顯示邏輯
  unsigned long currentMillis = millis();
  if (hasNewIrData) {
    // 如果有新的IR數據，顯示它
    showIRData();
    
    // 檢查是否超時
    if (currentMillis - irReceivedTime > IR_DISPLAY_TIMEOUT) {
      hasNewIrData = false;
      showWaitingScreen();
    }
  }
  
  // 短暫延遲以減少CPU負載
  delay(10);
}
