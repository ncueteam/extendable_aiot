// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get themeVicky => 'Vicky主题';

  @override
  String get themeAurora => '极光主题';

  @override
  String get hello => '您好';

  @override
  String get manageSmartHome => '让我们管理您的智能家居。';

  @override
  String get addRoom => '添加房间';

  @override
  String get addDevice => '添加设备';

  @override
  String get roomName => '房间名称';

  @override
  String get deviceName => '设备名称';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get allRooms => '所有房间';

  @override
  String get noDevices => '还没有创建设备';

  @override
  String get noRooms => '还没有创建房间';

  @override
  String get profile => '个人资料';

  @override
  String get settings => '设置';

  @override
  String get logout => '登出';

  @override
  String get familyList => '家人列表';

  @override
  String get functions => '功能';

  @override
  String get changeName => '更改名字';

  @override
  String get save => '保存';

  @override
  String get enterNewName => '输入新的名字';

  @override
  String get createdAt => '创建于';

  @override
  String get id => 'ID';

  @override
  String get email => '电子邮件';

  @override
  String get lastLogin => '最后登录';

  @override
  String get airCondition => '空调';

  @override
  String get livingRoom => '客厅';

  @override
  String get celsius => '摄氏';

  @override
  String get mode => '模式';

  @override
  String get auto => '自动';

  @override
  String get cool => '制冷';

  @override
  String get dry => '除湿';

  @override
  String get fanSpeed => '风速';

  @override
  String get low => '低速';

  @override
  String get mid => '中速';

  @override
  String get high => '高速';

  @override
  String get power => '电源';

  @override
  String get editRoom => '编辑房间';

  @override
  String get deleteRoom => '删除房间';

  @override
  String get confirmDelete => '确认删除';

  @override
  String get delete => '删除';

  @override
  String get temperature => '温度';

  @override
  String get humidity => '湿度';

  @override
  String get on => '开';

  @override
  String get off => '关';

  @override
  String get lastUpdated => '最后更新';

  @override
  String get rooms => '房间';

  @override
  String get devices => '设备';

  @override
  String get recentlyUsed => '最近使用';

  @override
  String get error => '错误';

  @override
  String get roomNotFound => '找不到房间';

  @override
  String confirmDeleteRoom(String name) {
    return '确定要删除房间 \"$name\" 吗？此操作无法撤销，且会同时删除所有关联设备。';
  }

  @override
  String get bedroom => '卧室';

  @override
  String get kitchen => '厨房';

  @override
  String get bathroom => '浴室';

  @override
  String get studyRoom => '书房';

  @override
  String get diningRoom => '餐厅';

  @override
  String get nameUpdated => '名字已更新';

  @override
  String get updateError => '更新失败';

  @override
  String get addFriend => '添加好友';

  @override
  String get enterEmail => '请输入好友邮箱';

  @override
  String get add => '添加';

  @override
  String get addingFriend => '正在添加好友...';

  @override
  String get friendAdded => '好友添加成功';

  @override
  String get friendAddFailed => '添加好友失败，该用户可能不存在或已是您的好友';

  @override
  String get selectRoom => '选择房间';

  @override
  String get loadingRooms => '正在加载房间列表...';

  @override
  String get removeAccess => '移除访问权限';

  @override
  String get confirmRemoveAccess => '确定要移除该好友对此房间的访问权限吗？';

  @override
  String get accessRemoved => '访问权限已移除';

  @override
  String get accessGranted => '访问权限已授予';

  @override
  String get deleteFriend => '删除好友';

  @override
  String confirmDeleteFriend(String name) {
    return '确定要删除好友 $name 吗？所有相关的房间访问权限也会被删除。';
  }

  @override
  String get friendRemoved => '好友已删除';

  @override
  String get manageFriends => '管理好友';

  @override
  String get loadingFriends => '正在加载好友列表...';

  @override
  String get noFriends => '还没有添加好友';

  @override
  String get close => '关闭';

  @override
  String get roomUpdated => '房间已更新';

  @override
  String get friendList => '好友列表';

  @override
  String get addToRoom => '添加到房间';
}

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn(): super('zh_CN');

  @override
  String get themeVicky => 'Vicky主题';

  @override
  String get themeAurora => '极光主题';

  @override
  String get hello => '您好';

  @override
  String get manageSmartHome => '让我们管理您的智能家居。';

  @override
  String get addRoom => '新增房间';

  @override
  String get addDevice => '新增设备';

  @override
  String get roomName => '房间名称';

  @override
  String get deviceName => '设备名称';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get allRooms => '所有房间';

  @override
  String get noDevices => '还没有创建设备';

  @override
  String get noRooms => '还没有创建房间';

  @override
  String get profile => '个人资料';

  @override
  String get settings => '设置';

  @override
  String get logout => '退出登录';

  @override
  String get familyList => '家人列表';

  @override
  String get functions => '功能';

  @override
  String get changeName => '更改名字';

  @override
  String get save => '保存';

  @override
  String get enterNewName => '输入新的名字';

  @override
  String get createdAt => '创建于';

  @override
  String get id => 'ID';

  @override
  String get email => '电子邮件';

  @override
  String get lastLogin => '最后登录';

  @override
  String get airCondition => '空调';

  @override
  String get livingRoom => '客厅';

  @override
  String get celsius => '摄氏';

  @override
  String get mode => '模式';

  @override
  String get auto => '自动';

  @override
  String get cool => '制冷';

  @override
  String get dry => '除湿';

  @override
  String get fanSpeed => '风速';

  @override
  String get low => '低速';

  @override
  String get mid => '中速';

  @override
  String get high => '高速';

  @override
  String get power => '电源';

  @override
  String get editRoom => '编辑房间';

  @override
  String get deleteRoom => '删除房间';

  @override
  String get confirmDelete => '确认删除';

  @override
  String get delete => '删除';

  @override
  String get temperature => '温度';

  @override
  String get humidity => '湿度';

  @override
  String get on => '开';

  @override
  String get off => '关';

  @override
  String get lastUpdated => '最后更新';

  @override
  String get rooms => '房间';

  @override
  String get devices => '设备';

  @override
  String get recentlyUsed => '最近使用';

  @override
  String get error => '错误';

  @override
  String get roomNotFound => '找不到房间';

  @override
  String confirmDeleteRoom(String name) {
    return '确定要删除房间 \"$name\" 吗？此操作无法撤销，且会同时删除所有关联设备。';
  }

  @override
  String get bedroom => '卧室';

  @override
  String get kitchen => '厨房';

  @override
  String get bathroom => '浴室';

  @override
  String get studyRoom => '书房';

  @override
  String get diningRoom => '餐厅';

  @override
  String get nameUpdated => '名字已更新';

  @override
  String get updateError => '更新失败';

  @override
  String get addFriend => '添加好友';

  @override
  String get enterEmail => '请输入好友邮箱';

  @override
  String get add => '添加';

  @override
  String get addingFriend => '正在添加好友...';

  @override
  String get friendAdded => '好友添加成功';

  @override
  String get friendAddFailed => '添加好友失败，该用户可能不存在或已是您的好友';

  @override
  String get selectRoom => '选择房间';

  @override
  String get loadingRooms => '正在加载房间列表...';

  @override
  String get removeAccess => '移除访问权限';

  @override
  String get confirmRemoveAccess => '确定要移除该好友对此房间的访问权限吗？';

  @override
  String get accessRemoved => '访问权限已移除';

  @override
  String get accessGranted => '访问权限已授予';

  @override
  String get deleteFriend => '删除好友';

  @override
  String confirmDeleteFriend(String name) {
    return '确定要删除好友 $name 吗？所有相关的房间访问权限也会被删除。';
  }

  @override
  String get friendRemoved => '好友已删除';

  @override
  String get manageFriends => '管理好友';

  @override
  String get loadingFriends => '正在加载好友列表...';

  @override
  String get noFriends => '还没有添加好友';

  @override
  String get close => '关闭';

  @override
  String get roomUpdated => '房间已更新';

  @override
  String get friendList => '好友列表';

  @override
  String get addToRoom => '添加到房间';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw(): super('zh_TW');

  @override
  String get themeVicky => 'Vicky主題';

  @override
  String get themeAurora => '極光主題';

  @override
  String get hello => '您好';

  @override
  String get manageSmartHome => '讓我們管理您的智能家居。';

  @override
  String get addRoom => '新增房間';

  @override
  String get addDevice => '新增設備';

  @override
  String get roomName => '房間名稱';

  @override
  String get deviceName => '設備名稱';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '確認';

  @override
  String get allRooms => '所有房間';

  @override
  String get noDevices => '還沒有創建設備';

  @override
  String get noRooms => '還沒有創建房間';

  @override
  String get profile => '個人資料';

  @override
  String get settings => '設定';

  @override
  String get logout => '登出';

  @override
  String get familyList => '家人列表';

  @override
  String get functions => '功能';

  @override
  String get changeName => '更改名字';

  @override
  String get save => '儲存';

  @override
  String get enterNewName => '輸入新的名字';

  @override
  String get createdAt => '創建於';

  @override
  String get id => 'ID';

  @override
  String get email => '電子郵件';

  @override
  String get lastLogin => '最後登入';

  @override
  String get airCondition => '空調';

  @override
  String get livingRoom => '客廳';

  @override
  String get celsius => '攝氏';

  @override
  String get mode => '模式';

  @override
  String get auto => '自動';

  @override
  String get cool => '製冷';

  @override
  String get dry => '除濕';

  @override
  String get fanSpeed => '風速';

  @override
  String get low => '低速';

  @override
  String get mid => '中速';

  @override
  String get high => '高速';

  @override
  String get power => '電源';

  @override
  String get editRoom => '編輯房間';

  @override
  String get deleteRoom => '刪除房間';

  @override
  String get confirmDelete => '確認刪除';

  @override
  String get delete => '刪除';

  @override
  String get temperature => '溫度';

  @override
  String get humidity => '濕度';

  @override
  String get on => '開';

  @override
  String get off => '關';

  @override
  String get lastUpdated => '最後更新';

  @override
  String get rooms => '房間';

  @override
  String get devices => '設備';

  @override
  String get recentlyUsed => '最近使用';

  @override
  String get error => '錯誤';

  @override
  String get roomNotFound => '找不到房間';

  @override
  String confirmDeleteRoom(String name) {
    return '確定要刪除房間 \"$name\" 嗎？此操作無法撤銷，且會同時刪除所有關聯設備。';
  }

  @override
  String get bedroom => '臥室';

  @override
  String get kitchen => '廚房';

  @override
  String get bathroom => '浴室';

  @override
  String get studyRoom => '書房';

  @override
  String get diningRoom => '餐廳';

  @override
  String get nameUpdated => '名字已更新';

  @override
  String get updateError => '更新失敗';

  @override
  String get addFriend => '新增好友';

  @override
  String get enterEmail => '請輸入好友郵箱';

  @override
  String get add => '新增';

  @override
  String get addingFriend => '正在新增好友...';

  @override
  String get friendAdded => '好友新增成功';

  @override
  String get friendAddFailed => '新增好友失敗，該用戶可能不存在或已是您的好友';

  @override
  String get selectRoom => '選擇房間';

  @override
  String get loadingRooms => '正在載入房間列表...';

  @override
  String get removeAccess => '移除訪問權限';

  @override
  String get confirmRemoveAccess => '確定要移除該好友對此房間的訪問權限嗎？';

  @override
  String get accessRemoved => '訪問權限已移除';

  @override
  String get accessGranted => '訪問權限已授予';

  @override
  String get deleteFriend => '刪除好友';

  @override
  String confirmDeleteFriend(String name) {
    return '確定要刪除好友 $name 嗎？所有相關的房間訪問權限也會被刪除。';
  }

  @override
  String get friendRemoved => '好友已刪除';

  @override
  String get manageFriends => '管理好友';

  @override
  String get loadingFriends => '正在載入好友列表...';

  @override
  String get noFriends => '還沒有新增好友';

  @override
  String get close => '關閉';

  @override
  String get roomUpdated => '房間已更新';

  @override
  String get friendList => '好友列表';

  @override
  String get addToRoom => '添加到房間';
}
