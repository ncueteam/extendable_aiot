#include "LED.h"

LEDController::LEDController(int pin, int channel, int timerBit, int frequency) {
    _pin = pin;
    _channel = channel;
    _timerBit = timerBit;
    _frequency = frequency;
    _breatheValue = 0;
    _increasing = true;
    _breathingEnabled = false;
}

void LEDController::begin() {
    // 配置LED的PWM控制
    ledcSetup(_channel, _frequency, _timerBit);
    ledcAttachPin(_pin, _channel);
    setBrightness(0); // 初始亮度為0
}

void LEDController::setBreathing(bool enabled) {
    _breathingEnabled = enabled;
}

void LEDController::setBrightness(int brightness) {
    // 確保亮度值在0-255範圍內
    int value = constrain(brightness, 0, 255);
    ledcWrite(_channel, value);
}

void LEDController::updateBreathing() {
    if (!_breathingEnabled) return;
    
    if (_increasing) {
        _breatheValue++;
        if (_breatheValue >= 255) {
            _increasing = false;
        }
    } else {
        _breatheValue--;
        if (_breatheValue <= 0) {
            _increasing = true;
        }
    }
    setBrightness(_breatheValue);
}