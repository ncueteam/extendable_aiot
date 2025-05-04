# extendable_aiot

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## 變更日誌 (Changelog)

### 2025年5月4日更新

#### 修復的錯誤
- 修復了設備管理操作後頁面自動跳回「所有房間」頁面的問題
  - 優化了 `TabController` 的重建邏輯，保留用戶當前選擇的標籤頁
  - 在 `home_page.dart` 中增加了狀態保存機制，防止 StreamBuilder 重建時重置頁面狀態
  - 修復了 `room_page.dart` 中刪除房間時的導航邏輯，避免重複彈出頁面

#### 代碼改進
- 增強了頁面狀態的保持能力
  - 實現了 `AutomaticKeepAliveClientMixin` 接口，確保頁面狀態在標籤切換時得到保留
  - 添加了 `_maintainState` 變量來控制頁面狀態的保持邏輯
- 改進了用戶體驗
  - 添加了設備操作後的成功提示
  - 優化了錯誤處理邏輯，提供更清晰的錯誤提示
  - 使用延遲更新確保用戶界面平穩過渡

## 資料庫結構

### 使用者 (Users)

``` markdown
database/
├── users/
    ├── createdAt: 建立時間 (Timestamp)
    ├── email: 使用者電子郵件 (String)
    ├── lastLogin: 最近登入時間 (Timestamp)
    ├── name: 使用者名稱 (String)
    ├── photoURL: 使用者頭像網址 (String)
    ├── friends/: 好友子集合
    │   └── [friendId]: 好友參考 (Reference)
    ├── rooms/: 房間子集合
    │   ├── [roomId]/ 
    │   │   ├── name: 房間名稱 (String)
    │   │   ├── createdAt: 建立時間 (Timestamp)
    │   │   ├── updatedAt: 更新時間 (Timestamp)
    │   │   ├── authorizedUsers: 授權用戶陣列 (Array<String>)
    │   │   └── devices/: 設備子集合
    │   │       └── [deviceId]/: 設備文檔
    │   │           ├── name: 設備名稱 (String)
    │   │           ├── type: 設備類型 (String)
    │   │           ├── status: 設備狀態 (Boolean)
    │   │           ├── lastUpdated: 最近更新時間 (Timestamp)
    │   │           ├── icon: 圖標代碼 (Number)
    │   │           └── data: 特定設備資料 (Map)
    ├── devices/: 設備子集合 (直接關聯到使用者的設備)
    │   └── [deviceId]/: 設備文檔
    │       ├── name: 設備名稱 (String)
    │       ├── type: 設備類型 (String)
    │       ├── status: 設備狀態 (Boolean)
    │       ├── lastUpdated: 最近更新時間 (Timestamp)
    │       ├── icon: 圖標代碼 (Number)
    │       └── data: 特定設備資料 (Map)
    │
    ├── autos/: 
        └──[autoId]/: 設備文檔
            ├── name: 設備名稱 (String)
            ├── room: 房間名稱 (String)
            ├── type: 設備類型 (String)
            ├── status: 設備狀態 (Boolean)
            └── data: 特定設備資料 (Map)

```

## 模型系統介紹

我們的系統採用了一個靈活的物件導向架構，使用繼承和多態來管理不同類型的設備。每個模型都與 Firebase Firestore 資料庫中的對應資料結構關聯。

### 基礎模型 (Base Models)

#### GeneralModel

作為所有模型的基礎類，提供共用屬性和方法：

- **屬性**：id, name, type, lastUpdated, icon
- **方法**：基本的 CRUD 操作 (createData, readData, updateData, deleteData)
- **功能**：為所有設備提供通用介面，實現資料庫交互的基礎功能

### 設備模型 (Device Models)

#### SwitchableModel

可開關控制類設備的抽象基類：

- **繼承自**：GeneralModel
- **新增屬性**：updateValue, previousValue, status
- **用途**：為所有可開關控制的設備提供共有功能，如開關狀態管理
- **子類**：SwitchModel, AirConditionerModel

#### SwitchModel

基本開關設備：

- **繼承自**：SwitchableModel
- **用途**：表示簡單的開/關設備，如燈、插座等

#### AirConditionerModel

空調設備：

- **繼承自**：SwitchableModel
- **新增屬性**：temperature, mode, fanSpeed
- **用途**：管理空調特定功能，如溫度調節和模式切換

#### SensorModel

感測器設備基類：

- **繼承自**：GeneralModel
- **新增屬性**：values
- **用途**：處理各類感測器數據收集
- **子類**：DHT11SensorModel

#### DHT11SensorModel

溫濕度感測器設備：

- **繼承自**：SensorModel
- **新增屬性**：temperature, humidity
- **用途**：處理DHT11感測器的特定數據，包括溫度和濕度值

### 其他模型

#### RoomModel

房間管理：

- **屬性**：id, name, createdAt, updatedAt, authorizedUsers
- **方法**：管理房間相關操作，包括授權用戶管理
- **用途**：對應資料庫中的房間結構，管理設備分組和用戶訪問控制

#### FriendModel

好友關係管理：

- **屬性**：id, name, email, photoURL
- **用途**：管理用戶之間的好友關係，實現權限共享

#### SensorData

感測器數據模型：

- **屬性**：根據不同感測器類型有不同屬性
- **用途**：用於格式化和處理從感測器接收的原始數據

## 資料庫操作機制

我們的應用程序使用 Firebase Firestore 作為主要資料庫，並通過模型類實現以下操作：

### CRUD 操作

- **Create**: 通過 `createData()` 方法將模型實例存儲到 Firestore
- **Read**: 通過 `readData()` 方法從 Firestore 讀取數據
- **Update**: 通過 `updateData()` 方法更新 Firestore 中的現有記錄
- **Delete**: 通過 `deleteData()` 方法從 Firestore 中刪除記錄

### 權限管理

系統實現了基於房間和用戶的多級權限控制：

- 每個用戶擁有自己的設備和房間
- 房間可以通過 `authorizedUsers` 屬性授權給其他用戶
- 好友機制便於用戶之間共享訪問權限

### 實時同步

使用 Firestore 的實時監聽功能：

- 設備狀態變更即時反映在所有授權用戶的客戶端
- 提供 StreamSubscription 以監聽數據變化
- 確保在 dispose 時取消訂閱，防止內存洩漏

## 設備類型和特定數據

### 可控設備 (switchable)

``` md
data:
  └── updateValue: [true, false] - 可設置的值陣列
  └── previousValue: [false, true] - 設定前的值陣列
  └── status: true/false - 設備當前狀態
```

### 感測器設備 (sensor)

``` md
data:
  └── values: [...] - 感測器數據值陣列
  
  # DHT11特定數據
  └── temperature: 25.5 - 溫度讀數
  └── humidity: 60.2 - 濕度讀數
```

### 空調設備 (airconditioner)

``` md
data:
  └── temperature: 26 - 設定溫度
  └── mode: "cool" - 運行模式 (cool, heat, fan, auto)
  └── fanSpeed: 3 - 風扇速度 (1-5)
```

## 系統擴展性

我們的系統設計允許輕鬆擴展新的設備類型：

1. 創建新的設備模型類，繼承自適當的基類
2. 實現特定設備的邏輯和數據結構
3. 更新 UI 以支持新設備類型的控制和顯示

這種面向物件設計確保了系統的可擴展性和維護性，同時保持了資料庫結構的一致性。
