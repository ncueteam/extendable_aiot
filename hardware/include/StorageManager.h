#ifndef STORAGE_MANAGER_H
#define STORAGE_MANAGER_H

#include <Arduino.h>
#include <Preferences.h>

/**
 * StorageManager 類處理 ESP32 的數據持久化存儲
 * 這個類是底層存儲實現，提供操作 Preferences 庫的接口
 */
class StorageManager {
public:
    /**
     * 構造函數
     * @param namespace_name 命名空間名稱，最大長度為15個字符
     */
    StorageManager(const char* namespace_name = "default");
    ~StorageManager();

    /**
     * 檢查是否存在指定的鍵
     * @param key 要檢查的鍵名
     * @return 如果鍵存在則返回true
     */
    bool hasKey(const char* key);

    /**
     * 保存字符串值
     * @param key 鍵名
     * @param value 字符串值
     * @return 操作成功返回true
     */
    bool saveString(const char* key, const char* value);

    /**
     * 讀取字符串值
     * @param key 鍵名
     * @param defaultValue 如果鍵不存在則返回的預設值
     * @return 存儲的字符串或預設值
     */
    String loadString(const char* key, const char* defaultValue = "");

    /**
     * 保存整數值
     * @param key 鍵名
     * @param value 整數值
     * @return 操作成功返回true
     */
    bool saveInt(const char* key, int value);

    /**
     * 讀取整數值
     * @param key 鍵名
     * @param defaultValue 如果鍵不存在則返回的預設值
     * @return 存儲的整數或預設值
     */
    int loadInt(const char* key, int defaultValue = 0);

    /**
     * 保存浮點值
     * @param key 鍵名
     * @param value 浮點值
     * @return 操作成功返回true
     */
    bool saveFloat(const char* key, float value);

    /**
     * 讀取浮點值
     * @param key 鍵名
     * @param defaultValue 如果鍵不存在則返回的預設值
     * @return 存儲的浮點數或預設值
     */
    float loadFloat(const char* key, float defaultValue = 0.0);

    /**
     * 保存布爾值
     * @param key 鍵名
     * @param value 布爾值
     * @return 操作成功返回true
     */
    bool saveBool(const char* key, bool value);

    /**
     * 讀取布爾值
     * @param key 鍵名
     * @param defaultValue 如果鍵不存在則返回的預設值
     * @return 存儲的布爾值或預設值
     */
    bool loadBool(const char* key, bool defaultValue = false);

    /**
     * 刪除指定的鍵
     * @param key 要刪除的鍵名
     * @return 操作成功返回true
     */
    bool deleteKey(const char* key);

    /**
     * 清除當前命名空間中的所有鍵
     */
    void clearAll();

    /**
     * 獲取命名空間名稱
     * @return 當前命名空間名稱
     */
    const char* getNamespace() const;

private:
    Preferences _preferences;
    String _namespace;
    bool _isOpen;

    // 私有輔助方法
    void begin(bool readonly = false);
    void end();
};

#endif // STORAGE_MANAGER_H