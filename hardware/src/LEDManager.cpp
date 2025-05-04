#include "../include/LEDManager.h"

LEDManager::LEDManager(
    uint8_t pin,
    uint8_t channel,
    uint8_t resolution,
    uint32_t frequency,
    unsigned long updateInterval
) : 
    pin(pin),
    channel(channel),
    resolution(resolution),
    frequency(frequency),
    breatheValue(0),
    increasing(true),
    breathingEnabled(true),
    lastUpdateTime(0),
    updateInterval(updateInterval) {
}

void LEDManager::begin() {
    // Configure the LEDC channel and attach the pin
    ledcSetup(channel, frequency, resolution);
    ledcAttachPin(pin, channel);
    
    // Initialize to off state
    off();
}

void LEDManager::on(uint8_t brightness) {
    breathingEnabled = false;
    setBrightness(brightness);
}

void LEDManager::off() {
    breathingEnabled = false;
    setBrightness(0);
}

void LEDManager::setBrightness(uint8_t brightness) {
    breatheValue = constrain(brightness, 0, (1 << resolution) - 1);
    ledcWrite(channel, breatheValue);
}

uint8_t LEDManager::getBrightness() const {
    return breatheValue;
}

void LEDManager::enableBreathing(bool enable) {
    breathingEnabled = enable;
}

void LEDManager::disableBreathing() {
    breathingEnabled = false;
}

bool LEDManager::isBreathingEnabled() const {
    return breathingEnabled;
}

void LEDManager::update() {
    // Only update when breathing is enabled
    if (!breathingEnabled) {
        return;
    }
    
    // Only update at the specified interval
    unsigned long currentMillis = millis();
    if (currentMillis - lastUpdateTime < updateInterval) {
        return;
    }
    lastUpdateTime = currentMillis;
    
    // Update breathe value based on direction
    if (increasing) {
        breatheValue++;
        if (breatheValue >= (1 << resolution) - 1) {
            breatheValue = (1 << resolution) - 1;
            increasing = false;
        }
    } else {
        breatheValue--;
        if (breatheValue <= 0) {
            breatheValue = 0;
            increasing = true;
        }
    }
    
    // Write the value to the LED
    ledcWrite(channel, breatheValue);
}