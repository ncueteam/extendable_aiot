#include "../include/DHT11Sensor.h"

DHT11Sensor::DHT11Sensor(uint8_t pin) : 
    pin(pin), 
    dht(pin, DHT11), 
    temperature(0),
    humidity(0),
    lastReadTime(0),
    lastReadSuccess(false) {
}

void DHT11Sensor::begin() {
    pinMode(pin, INPUT);
    dht.begin();
    delay(2000); // Initial delay for DHT11 to stabilize
}

bool DHT11Sensor::read() {
    int retryCount = 0;
    bool success = false;
    
    while (retryCount < maxRetries && !success) {
        float newTemp = dht.readTemperature();
        float newHum = dht.readHumidity();
        
        if (!isnan(newTemp) && !isnan(newHum)) {
            temperature = newTemp;
            humidity = newHum;
            success = true;
            lastReadSuccess = true;
        } else {
            retryCount++;
            delay(500);
        }
    }
    
    if (!success) {
        lastReadSuccess = false;
    }
    
    return lastReadSuccess;
}

float DHT11Sensor::getTemperature() const {
    return temperature;
}

float DHT11Sensor::getHumidity() const {
    return humidity;
}

bool DHT11Sensor::isReadSuccessful() const {
    return lastReadSuccess;
}

void DHT11Sensor::update() {
    unsigned long currentMillis = millis();
    if (currentMillis - lastReadTime >= readInterval) {
        read();
        lastReadTime = currentMillis;
    }
}