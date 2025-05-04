#ifndef DATA_MANAGER_H
#define DATA_MANAGER_H

#include <Arduino.h>
#include <WiFi.h>
#include <freertos/FreeRTOS.h>
#include <freertos/semphr.h>

class DataManager {
private:
    // Mutex for thread safety
    SemaphoreHandle_t mutex;
    
    // Sensor data
    float temperature;
    float humidity;
    
    // Communication status
    bool isMqttConnected;
    bool isMqttTransmitting;
    unsigned long mqttIconBlinkMillis;
    unsigned long mqttIconBlinkInterval;

public:
    // Constructor and destructor
    DataManager(unsigned long blinkInterval = 500);
    ~DataManager();
    
    // Initialize the data manager
    void begin();
    
    // Sensor data methods
    void setTemperature(float temp);
    float getTemperature();
    
    void setHumidity(float hum);
    float getHumidity();
    
    // MQTT status methods
    void setMqttConnected(bool connected);
    bool getMqttConnected();
    
    void setMqttTransmitting(bool transmitting);
    bool getMqttTransmitting();
    
    void updateMqttTransmittingStatus();
    
    // Helper method to get the MQTT blink timestamp
    unsigned long getMqttIconBlinkMillis();
    
    // Access mutex directly for more complex operations
    void lock();
    void unlock();
};

#endif // DATA_MANAGER_H