#ifndef DHT11_SENSOR_H
#define DHT11_SENSOR_H

#include <Arduino.h>
#include <DHT.h>

class DHT11Sensor {
private:
    uint8_t pin;
    DHT dht;
    float temperature;
    float humidity;
    unsigned long lastReadTime;
    const unsigned long readInterval = 3000; // Reading interval in ms
    bool lastReadSuccess;
    const int maxRetries = 2;

public:
    DHT11Sensor(uint8_t pin);
    void begin();
    bool read();
    float getTemperature() const;
    float getHumidity() const;
    bool isReadSuccessful() const;
    void update(); // Method to be called from task
};

#endif // DHT11_SENSOR_H