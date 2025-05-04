#ifndef LED_H
#define LED_H

#include <Arduino.h>

class LEDController {
public:
    LEDController(int pin, int channel = 0, int timerBit = 8, int frequency = 5000);
    void begin();
    void setBreathing(bool enabled);
    void setBrightness(int brightness); // 0-255
    void updateBreathing();

private:
    int _pin;
    int _channel;
    int _timerBit;
    int _frequency;
    int _breatheValue;
    bool _increasing;
    bool _breathingEnabled;
};

#endif // LED_H