#include "WiFiManager.h"

WiFiManager::WiFiManager(ConfigManager* configManager) {
    _configManager = configManager;
    _isConnected = false;
    _hasCredentials = false;
    
    memset(_ssid, 0, sizeof(_ssid));
    memset(_password, 0, sizeof(_password));
}

WiFiManager::~WiFiManager() {
    disconnect();
}

void WiFiManager::begin() {
    WiFi.mode(WIFI_STA);
    _hasCredentials = loadCredentials();
}

bool WiFiManager::connect(bool forceUseStored) {
    // 檢查是否有憑證可用
    if (!_hasCredentials) {
        updateDisplay("No WiFi Credentials", -1);
        notifyStatus(false, "No WiFi credentials available");
        return false;
    }

    // 如果已經連接，不需要重新連接
    if (WiFi.status() == WL_CONNECTED) {
        notifyStatus(true, "Already connected to WiFi");
        return true;
    }

    // 斷開現有連接
    disconnect();
    
    // 開始連接
    WiFi.begin(_ssid, _password);
    
    // 等待連接建立
    int attempts = 0;
    const int maxAttempts = 20; // 最大嘗試次數
    
    while (WiFi.status() != WL_CONNECTED && attempts < maxAttempts) {
        delay(500);
        attempts++;
        
        // 更新顯示
        String message = String("Connecting to WiFi\nSSID: ") + _ssid;
        int progress = (attempts * 100) / maxAttempts;
        updateDisplay(message, progress);
    }
    
    // 檢查連接結果
    if (WiFi.status() == WL_CONNECTED) {
        _isConnected = true;
        String message = String("WiFi Connected!\nSSID: ") + _ssid + "\n" + getIPAddress();
        updateDisplay(message, 100);
        notifyStatus(true, "Connected to WiFi: " + getIPAddress());
        return true;
    } else {
        _isConnected = false;
        updateDisplay("WiFi Connection Failed!\nCheck credentials", -1);
        notifyStatus(false, "Failed to connect to WiFi");
        return false;
    }
}

void WiFiManager::disconnect() {
    if (_isConnected || WiFi.status() == WL_CONNECTED) {
        WiFi.disconnect();
        _isConnected = false;
        notifyStatus(false, "WiFi disconnected");
    }
}

bool WiFiManager::setCredentials(const char* ssid, const char* password) {
    if (!ssid || !password) {
        return false;
    }
    
    // 復制憑證到本地緩衝區
    strncpy(_ssid, ssid, sizeof(_ssid) - 1);
    _ssid[sizeof(_ssid) - 1] = '\0';
    
    strncpy(_password, password, sizeof(_password) - 1);
    _password[sizeof(_password) - 1] = '\0';
    
    // 保存到配置
    bool saved = _configManager->saveWiFiCredentials(_ssid, _password);
    if (saved) {
        _hasCredentials = true;
    }
    
    return saved;
}

bool WiFiManager::parseCredentials(const char* message) {
    if (!message) {
        return false;
    }
    
    // 檢查前綴
    if (strncmp(message, "WIFI:", 5) != 0) {
        return false;
    }
    
    // 解析SSID
    char* ssidPtr = strstr(message, "SSID=");
    if (!ssidPtr) {
        return false;
    }
    
    ssidPtr += 5; // 跳過"SSID="
    char* ssidEnd = strchr(ssidPtr, ';');
    if (!ssidEnd) {
        return false;
    }
    
    int ssidLen = ssidEnd - ssidPtr;
    if (ssidLen >= sizeof(_ssid)) {
        return false;
    }
    
    // 解析密碼
    char* passPtr = strstr(message, "PASS=");
    if (!passPtr) {
        return false;
    }
    
    passPtr += 5; // 跳過"PASS="
    char* passEnd = strchr(passPtr, ';');
    if (!passEnd) {
        return false;
    }
    
    int passLen = passEnd - passPtr;
    if (passLen >= sizeof(_password)) {
        return false;
    }
    
    // 複製憑證
    memset(_ssid, 0, sizeof(_ssid));
    memset(_password, 0, sizeof(_password));
    
    strncpy(_ssid, ssidPtr, ssidLen);
    strncpy(_password, passPtr, passLen);
    
    // 保存憑證
    bool saved = _configManager->saveWiFiCredentials(_ssid, _password);
    if (saved) {
        _hasCredentials = true;
    }
    
    return saved;
}

const char* WiFiManager::getSSID() const {
    return _ssid;
}

String WiFiManager::getIPAddress() const {
    if (_isConnected || WiFi.status() == WL_CONNECTED) {
        return WiFi.localIP().toString();
    }
    return "Not connected";
}

bool WiFiManager::isConnected() const {
    return WiFi.status() == WL_CONNECTED;
}

void WiFiManager::setStatusCallback(WiFiStatusCallback callback) {
    _statusCallback = callback;
}

void WiFiManager::setDisplayCallback(WiFiDisplayCallback callback) {
    _displayCallback = callback;
}

bool WiFiManager::loadCredentials() {
    if (!_configManager) {
        return false;
    }
    
    // 從ConfigManager獲取憑證
    bool success = _configManager->loadWiFiCredentials(_ssid, sizeof(_ssid), _password, sizeof(_password));
    return success;
}

void WiFiManager::notifyStatus(bool connected, const String& message) {
    if (_statusCallback) {
        _statusCallback(connected, message);
    }
}

void WiFiManager::updateDisplay(const String& message, int progress) {
    if (_displayCallback) {
        _displayCallback(message, progress);
    }
}