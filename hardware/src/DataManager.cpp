#include "../include/DataManager.h"

DataManager::DataManager(unsigned long blinkInterval) :
    mutex(nullptr),
    temperature(0.0f),
    humidity(0.0f),
    isMqttConnected(false),
    isMqttTransmitting(false),
    mqttIconBlinkMillis(0),
    mqttIconBlinkInterval(blinkInterval) {
}

DataManager::~DataManager() {
    if (mutex != nullptr) {
        vSemaphoreDelete(mutex);
        mutex = nullptr;
    }
}

void DataManager::begin() {
    // Create mutex for thread safety
    mutex = xSemaphoreCreateMutex();
    
    // Initialize values
    temperature = 0.0f;
    humidity = 0.0f;
    isMqttConnected = false;
    isMqttTransmitting = false;
    mqttIconBlinkMillis = 0;
}

void DataManager::setTemperature(float temp) {
    lock();
    temperature = temp;
    unlock();
}

float DataManager::getTemperature() {
    lock();
    float temp = temperature;
    unlock();
    return temp;
}

void DataManager::setHumidity(float hum) {
    lock();
    humidity = hum;
    unlock();
}

float DataManager::getHumidity() {
    lock();
    float hum = humidity;
    unlock();
    return hum;
}

void DataManager::setMqttConnected(bool connected) {
    lock();
    isMqttConnected = connected;
    unlock();
}

bool DataManager::getMqttConnected() {
    lock();
    bool connected = isMqttConnected;
    unlock();
    return connected;
}

void DataManager::setMqttTransmitting(bool transmitting) {
    lock();
    isMqttTransmitting = transmitting;
    if (transmitting) {
        mqttIconBlinkMillis = millis();
    }
    unlock();
}

bool DataManager::getMqttTransmitting() {
    lock();
    bool transmitting = isMqttTransmitting;
    unlock();
    return transmitting;
}

void DataManager::updateMqttTransmittingStatus() {
    lock();
    if (isMqttTransmitting && millis() - mqttIconBlinkMillis >= mqttIconBlinkInterval) {
        isMqttTransmitting = false;
    }
    unlock();
}

unsigned long DataManager::getMqttIconBlinkMillis() {
    lock();
    unsigned long timestamp = mqttIconBlinkMillis;
    unlock();
    return timestamp;
}

void DataManager::lock() {
    if (mutex != nullptr) {
        xSemaphoreTake(mutex, portMAX_DELAY);
    }
}

void DataManager::unlock() {
    if (mutex != nullptr) {
        xSemaphoreGive(mutex);
    }
}