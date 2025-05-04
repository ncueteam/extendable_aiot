#ifndef LED_MANAGER_H
#define LED_MANAGER_H

#include <Arduino.h>

class LEDManager {
private:
    // LED pin and configuration
    uint8_t pin;
    uint8_t channel;
    uint8_t resolution;
    uint32_t frequency;
    
    // Breathing effect variables
    int breatheValue;
    bool increasing;
    bool breathingEnabled;
    unsigned long lastUpdateTime;
    unsigned long updateInterval;

public:
    // Constructor with default parameters
    LEDManager(
        uint8_t pin = 2,
        uint8_t channel = 0,
        uint8_t resolution = 8,
        uint32_t frequency = 5000,
        unsigned long updateInterval = 5
    );
    
    // Initialize the LED
    void begin();
    
    // Turn LED on with specific brightness (0-255)
    void on(uint8_t brightness = 255);
    
    // Turn LED off
    void off();
    
    // Set LED brightness (0-255)
    void setBrightness(uint8_t brightness);
    
    // Get current brightness
    uint8_t getBrightness() const;
    
    // Enable breathing effect
    void enableBreathing(bool enable = true);
    
    // Disable breathing effect
    void disableBreathing();
    
    // Is breathing effect enabled?
    bool isBreathingEnabled() const;
    
    // Update LED state - call this in loop or timer
    void update();
};

#endif // LED_MANAGER_H