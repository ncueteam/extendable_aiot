import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/l10n/app_localizations.dart';
import 'package:extendable_aiot/models/abstract/device_model.dart';
import 'package:extendable_aiot/models/abstract/general_model.dart';
import 'package:extendable_aiot/models/abstract/room_model.dart';
import 'package:extendable_aiot/models/sub_type/airconditioner_model.dart';
import 'package:extendable_aiot/models/sub_type/mqtt_dht11_model.dart';
import 'package:extendable_aiot/models/user_model.dart';
import 'package:extendable_aiot/services/ble_wifi_service.dart';
import 'package:extendable_aiot/views/card/device_card.dart';
import 'package:flutter/material.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:extendable_aiot/utils/edit_room.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

class RoomPage extends StatefulWidget {
  final String roomId;

  const RoomPage({super.key, required this.roomId});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedDeviceType = 'air_conditioner';
  RoomModel? _roomModel;
  bool _maintainState = true;

  int page = 1;
  int limit = 10;
  bool loading = true;
  bool error = false;
  String? errorMsg;
  // BLE WiFi服務
  final BLEWiFiService _bleWiFiService = BLEWiFiService();

  // 修改好友列表狀態的類型
  UserModel? _currentUser;
  List<UserModel> _roomFriends = []; // 更改類型
  bool _loadingFriends = true;
  List<UserModel> _allFriends = []; // 更改類型
  bool _loadingAllFriends = true;

  // 裝置類型列表
  final List<Map<String, dynamic>> _deviceTypes = [
    {'type': AirConditionerModel.TYPE, 'name': '中央空調', 'icon': Icons.ac_unit},
    {'type': 'fan', 'name': '風扇', 'icon': Icons.wind_power},
    {'type': 'light', 'name': '燈光', 'icon': Icons.lightbulb},
    {'type': 'curtain', 'name': '窗簾', 'icon': Icons.curtains},
    {'type': 'door', 'name': '門鎖', 'icon': Icons.lock},
    {'type': 'sensor', 'name': '感測器', 'icon': Icons.sensors},
    {
      'type': MQTTEnabledDHT11Model.TYPE,
      'name': 'DHT11',
      'icon': Icons.cloud_sync,
    },
  ];
  @override
  void initState() {
    super.initState();
    _loadRoomModel();
    _loadRoomFriends();
    _loadAllFriends();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    _bleWiFiService.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    if (UserModel.currentUserId != null) {
      final userModel = await UserModel.getById(UserModel.currentUserId!);
      if (mounted && userModel != null) {
        setState(() {
          _currentUser = userModel;
        });
      }
    }
  }

  Future<void> _loadRoomModel() async {
    try {
      final room = await RoomModel.getRoom(widget.roomId);
      if (mounted) {
        setState(() {
          _roomModel = room;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = true;
          errorMsg = e.toString();
          loading = false;
        });
      }
    }
  }

  // 載入有權限訪問該房間的好友
  Future<void> _loadRoomFriends() async {
    try {
      if (_currentUser == null && UserModel.currentUserId != null) {
        await _loadCurrentUser();
      }

      if (_currentUser != null) {
        final friends = await _currentUser!.getFriendsForRoom(widget.roomId);
        if (mounted) {
          setState(() {
            _roomFriends = friends;
            _loadingFriends = false;
          });
        }
      }
    } catch (e) {
      print('載入房間好友錯誤: $e');
      if (mounted) {
        setState(() {
          _loadingFriends = false;
        });
      }
    }
  }

  // 載入所有好友，用於新增新好友到房間
  void _loadAllFriends() {
    if (UserModel.currentUserId == null) {
      setState(() {
        _loadingAllFriends = false;
      });
      return;
    }

    UserModel(
      id: UserModel.currentUserId!,
      name: '',
      email: '',
    ).getFriendsStream().listen(
      (friendsList) {
        if (mounted) {
          setState(() {
            _allFriends = friendsList;
            _loadingAllFriends = false;
          });
        }
      },
      onError: (error) {
        print("載入所有好友錯誤: $error");
        if (mounted) {
          setState(() {
            _loadingAllFriends = false;
          });
        }
      },
    );
  }

  // 修改 _showAddDeviceDialog 方法
  Future<void> _showAddDeviceDialog() async {
    final localizations = AppLocalizations.of(context);

    return showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(localizations?.addDevice ?? '新增設備'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _deviceNameController,
                        decoration: InputDecoration(
                          labelText: localizations?.deviceName ?? '設備名稱',
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButton<String>(
                        value: _selectedDeviceType,
                        items:
                            _deviceTypes.map((Map<String, dynamic> type) {
                              return DropdownMenuItem<String>(
                                value: type['type'] as String,
                                child: Row(
                                  children: [
                                    Icon(type['icon'] as IconData),
                                    const SizedBox(width: 8),
                                    Text(type['name'] as String),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedDeviceType = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(localizations?.cancel ?? '取消'),
                    ),
                    TextButton(
                      onPressed: () async {
                        if (_deviceNameController.text.isNotEmpty &&
                            _roomModel != null) {
                          Navigator.pop(context); // 先關閉對話框
                          await _addDevice(
                            _deviceNameController.text,
                            _selectedDeviceType,
                          );
                          _deviceNameController.clear();
                        }
                      },
                      child: Text(localizations?.confirm ?? '確認'),
                    ),
                  ],
                ),
          ),
    );
  }

  // 修改 _addDevice 方法
  Future<void> _addDevice(String name, String type) async {
    if (_roomModel == null) return;

    try {
      setState(() => _maintainState = true); // 確保狀態保持

      switch (type) {
        case AirConditionerModel.TYPE:
          final acDevice = AirConditionerModel(
            null,
            name: name,
            roomId: widget.roomId,
            lastUpdated: Timestamp.now(),
          );
          await DeviceModel.addDeviceToRoom(acDevice, widget.roomId);
          break;
        case MQTTEnabledDHT11Model.TYPE:
          final mqttDHT11Device = MQTTEnabledDHT11Model(
            null,
            name: name,
            roomId: widget.roomId,
            deviceId: "",
            roomTopic: widget.roomId,
            lastUpdated: Timestamp.now(),
            temperature: 0.0,
            humidity: 0.0,
          );
          await DeviceModel.addDeviceToRoom(mqttDHT11Device, widget.roomId);

          // 連接到MQTT服務
          await mqttDHT11Device.connectToMQTT();
          break;
        default:
          throw Exception('不支援的設備類型: $type');
      }

      // 強制重新載入房間模型以更新設備列表
      await _loadRoomModel();

      if (mounted) {
        setState(() {}); // 觸發重建
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已成功添加設備：$name')));
      }
    } catch (e) {
      print('新增設備錯誤: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('添加設備失敗：${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Use the BLEWiFiService to check and request Bluetooth permissions
  Future<void> _checkBluetoothPermissions() async {
    bool permissionsGranted = await _bleWiFiService.checkBluetoothPermissions();

    if (!permissionsGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('需要藍牙權限以配置WiFi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Send WiFi credentials and room ID to the ESP32
  Future<void> _sendWiFiCredentials() async {
    String ssid = _ssidController.text.trim();
    String password = _passwordController.text.trim();

    if (ssid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SSID 不可為空'), backgroundColor: Colors.red),
      );
      return;
    }

    bool success = await _bleWiFiService.sendWiFiCredentials(
      ssid,
      password,
      widget.roomId,
    );

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已發送WiFi認證資訊和房間ID')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('發送認證資訊失敗，請確保設備已連接'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show WiFi credentials dialog
  Future<void> _showWiFiCredentialsDialog() async {
    // 重置認證控制器
    _ssidController.text = '';
    _passwordController.text = '';

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('輸入WiFi認證資訊'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('將發送WiFi認證資訊與目前房間ID: ${widget.roomId}'),
                const SizedBox(height: 16),
                TextField(
                  controller: _ssidController,
                  decoration: const InputDecoration(
                    labelText: 'WiFi SSID',
                    hintText: '輸入您的WiFi網絡名稱',
                  ),
                ),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'WiFi 密碼',
                    hintText: '輸入您的WiFi密碼',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('發送'),
              onPressed: () {
                Navigator.of(context).pop();
                _sendWiFiCredentials();
              },
            ),
          ],
        );
      },
    );
  }

  // Shows a dialog to manage BLE WiFi provisioning
  void _showBLEWiFiProvisioningDialog() {
    // Reset the BLE service state before showing the dialog
    _bleWiFiService.reset();

    // Variables to listen to the BLEWiFiService streams
    String statusText = '';
    String messageText = '';
    bool isConnected = false;
    bool isScanning = false;
    List<BluetoothDevice> devices = [];
    BluetoothDevice? connectedDevice;

    // List to keep track of all subscriptions so we can cancel them when the dialog closes
    List<StreamSubscription> subscriptions = [];

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              // Set up stream listeners within the dialog
              void setupStreamListeners() {
                // Status stream
                subscriptions.add(
                  _bleWiFiService.statusStream.listen((status) {
                    try {
                      setDialogState(() {
                        statusText = status;
                      });
                    } catch (e) {
                      // Dialog might be closed, ignore setState errors
                      print('Dialog state update error: $e');
                    }
                  }),
                );

                // Message stream
                subscriptions.add(
                  _bleWiFiService.messageStream.listen((message) {
                    try {
                      setDialogState(() {
                        messageText = message;
                      });
                    } catch (e) {
                      // Dialog might be closed, ignore setState errors
                      print('Dialog state update error: $e');
                    }
                  }),
                );

                // Connection state stream
                subscriptions.add(
                  _bleWiFiService.connectionStateStream.listen((connected) {
                    try {
                      setDialogState(() {
                        isConnected = connected;
                        if (!connected) {
                          connectedDevice = null;
                        } else {
                          connectedDevice = _bleWiFiService.connectedDevice;
                        }
                      });
                    } catch (e) {
                      // Dialog might be closed, ignore setState errors
                      print('Dialog state update error: $e');
                    }
                  }),
                );

                // Scanning state stream
                subscriptions.add(
                  _bleWiFiService.scanningStateStream.listen((scanning) {
                    try {
                      setDialogState(() {
                        isScanning = scanning;
                      });
                    } catch (e) {
                      // Dialog might be closed, ignore setState errors
                      print('Dialog state update error: $e');
                    }
                  }),
                );

                // Devices list stream
                subscriptions.add(
                  _bleWiFiService.devicesStream.listen((deviceList) {
                    try {
                      setDialogState(() {
                        devices = deviceList;
                      });
                    } catch (e) {
                      // Dialog might be closed, ignore setState errors
                      print('Dialog state update error: $e');
                    }
                  }),
                );
              }

              // Call this once to set up all stream listeners
              setupStreamListeners(); // Helper function to connect to a device through the service
              Future<void> connectToDevice(BluetoothDevice device) async {
                bool success = await _bleWiFiService.connectToDevice(device);
                if (success) {
                  // Cancel all subscriptions before closing the dialog
                  for (var subscription in subscriptions) {
                    subscription.cancel();
                  }

                  // First close the dialog, then show WiFi credentials
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context); // 關閉藍牙設備列表對話框
                    // Show the WiFi credentials dialog after a short delay
                    Future.delayed(const Duration(milliseconds: 300), () {
                      _showWiFiCredentialsDialog();
                    });
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('藍牙連接失敗'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }

              return AlertDialog(
                title: const Text('藍牙WiFi設置'),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status display
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.blue.shade50,
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '房間: ${_roomModel?.name ?? ""}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '狀態: ${statusText}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (messageText.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('訊息: $messageText'),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ), // Main content based on connection status
                      Expanded(
                        child:
                            isConnected
                                ? _buildConnectedViewWithService(
                                  context,
                                  connectedDevice,
                                  subscriptions,
                                )
                                : _buildDeviceListViewWithService(
                                  devices,
                                  isScanning,
                                  connectToDevice,
                                ),
                      ),

                      // Bottom buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (isConnected)
                            ElevatedButton(
                              onPressed: () {
                                // Cancel all subscriptions before closing the dialog
                                for (var subscription in subscriptions) {
                                  subscription.cancel();
                                }

                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                  // Brief delay to allow dialog to fully close
                                  Future.delayed(
                                    const Duration(milliseconds: 300),
                                    () {
                                      _showWiFiCredentialsDialog();
                                    },
                                  );
                                }
                              },
                              child: const Text('發送WiFi認證'),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed:
                                  !isScanning
                                      ? () => _checkBluetoothPermissions()
                                      : null,
                              icon: const Icon(Icons.search),
                              label: Text(isScanning ? '掃描中...' : '掃描設備'),
                            ),
                          TextButton(
                            onPressed: () {
                              // Cancel all stream subscriptions before closing the dialog
                              for (var subscription in subscriptions) {
                                subscription.cancel();
                              }

                              if (isConnected) {
                                _bleWiFiService.disconnect();
                              }
                              Navigator.pop(context);
                            },
                            child: const Text('關閉'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildDeviceListViewWithService(
    List<BluetoothDevice> devices,
    bool isScanning,
    Function(BluetoothDevice) onDeviceTap,
  ) {
    return devices.isEmpty
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.bluetooth_searching,
                size: 48,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text('未發現藍牙設備'),
              const SizedBox(height: 8),
              const Text('點擊掃描以搜索ESP32設備'),
              const SizedBox(height: 16),
              if (isScanning) const CircularProgressIndicator(strokeWidth: 2),
            ],
          ),
        )
        : ListView.builder(
          shrinkWrap: true,
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];
            final isConnecting =
                _bleWiFiService.isConnecting &&
                _bleWiFiService.connectedDevice?.remoteId == device.remoteId;

            return ListTile(
              title: Text(device.platformName),
              subtitle: Text(device.remoteId.toString()),
              trailing:
                  isConnecting
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.bluetooth),
              onTap:
                  _bleWiFiService.isConnecting
                      ? null
                      : () => onDeviceTap(device),
            );
          },
        );
  }

  Widget _buildConnectedViewWithService(
    BuildContext context,
    BluetoothDevice? connectedDevice,
    List<StreamSubscription> subscriptions,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bluetooth_connected, size: 48, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            '已連接到: ${connectedDevice?.platformName ?? "Unknown Device"}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(connectedDevice?.remoteId.toString() ?? ''),
          const SizedBox(height: 16),
          Text(
            '已準備好發送WiFi認證資訊',
            style: TextStyle(color: Colors.green.shade700),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.wifi),
            label: const Text('發送WiFi認證'),
            onPressed: () {
              // Cancel all subscriptions before navigating away
              for (var subscription in subscriptions) {
                subscription.cancel();
              }

              if (Navigator.canPop(context)) {
                Navigator.pop(context);
                // Show WiFi dialog after a brief delay
                Future.delayed(const Duration(milliseconds: 300), () {
                  _showWiFiCredentialsDialog();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final localizations = AppLocalizations.of(context);

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error) {
      return Center(child: Text('錯誤: $errorMsg'));
    }

    if (_roomModel == null) {
      return Center(child: Text(localizations?.roomNotFound ?? '找不到房間'));
    }

    return Scaffold(
      body: Column(
        children: [
          _buildRoomHeader(localizations),
          Expanded(
            child: StreamBuilder<List<DocumentSnapshot>>(
              stream: _roomModel!.devicesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('錯誤: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final devices = snapshot.data ?? [];

                if (devices.isEmpty) {
                  return Center(
                    child: Text(localizations?.noDevices ?? '此房間還沒有設備'),
                  );
                }

                // 使用 DeviceModel 處理設備資料
                List<GeneralModel> deviceModels = [];
                for (var device in devices) {
                  try {
                    final data = device.data() as Map<String, dynamic>;
                    final String type = data['type'] as String? ?? '未知';
                    final String name = data['name'] as String? ?? '未命名設備';
                    final Timestamp lastUpdated =
                        data['lastUpdated'] as Timestamp? ?? Timestamp.now();

                    switch (type) {
                      case AirConditionerModel.TYPE:
                        try {
                          final acDevice = AirConditionerModel(
                            device.id,
                            name: name,
                            roomId: widget.roomId,
                            lastUpdated: lastUpdated,
                          );
                          // 安全地使用 fromJson 方法，確保必要的字段存在
                          Map<String, dynamic> safeData = {
                            ...data,
                            'lastUpdated':
                                data['lastUpdated'] ?? Timestamp.now(),
                            'temperature':
                                (data['temperature'] as num?)?.toDouble() ??
                                25.0,
                            'mode': data['mode'] ?? 'Auto',
                            'fanSpeed': data['fanSpeed'] ?? 'Mid',
                          };
                          acDevice.fromJson(safeData);
                          deviceModels.add(acDevice);
                        } catch (e) {
                          throw Exception('解析空調設備錯誤: $e');
                        }
                        break;
                      case MQTTEnabledDHT11Model.TYPE:
                        try {
                          final mqttDHT11Device = MQTTEnabledDHT11Model(
                            device.id,
                            name: name,
                            roomId: widget.roomId,
                            roomTopic: widget.roomId,
                            deviceId: data['deviceId'] as String? ?? '',
                            lastUpdated: lastUpdated,
                            temperature:
                                (data['temperature'] as num?)?.toDouble() ??
                                0.0,
                            humidity:
                                (data['humidity'] as num?)?.toDouble() ?? 0.0,
                          );
                          deviceModels.add(mqttDHT11Device);
                        } catch (e) {
                          throw Exception('解析MQTT DHT11設備錯誤: $e');
                        }
                      default:
                        throw Exception('不支援的設備類型: $type');
                    }
                  } catch (e) {
                    print('設備資料解析錯誤: $e');
                  }
                }

                return EasyRefresh(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.2,
                        ),
                    itemCount: deviceModels.length,
                    padding: const EdgeInsets.all(8.0),
                    itemBuilder: (BuildContext context, int index) {
                      return DeviceCard(device: deviceModels[index]);
                    },
                  ),
                );
              },
            ),
          ),
          //_buildRoomActions(localizations),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'addDeviceTag',
            onPressed: () => _showAddDeviceDialog(),
            tooltip: localizations?.addDevice ?? '新增設備',
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'btuetoothTag',
            onPressed: () => _showBLEWiFiProvisioningDialog(),
            tooltip: '藍牙WiFi設置',
            child: const Icon(Icons.bluetooth),
          ),
        ],
      ),
    );
  }

  // 房間頭部資訊
  Widget _buildRoomHeader(AppLocalizations? localizations) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _roomModel!.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.group_add),
                    onPressed: () => _showManageFriendsDialog(localizations),
                    tooltip: localizations?.manageFriends ?? '管理好友存取權限',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditRoomDialog(localizations),
                    tooltip: localizations?.editRoom ?? '編輯房間',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteRoomConfirmation(localizations),
                    tooltip: localizations?.deleteRoom ?? '刪除房間',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 顯示管理好友存取權限的對話框
  void _showManageFriendsDialog(AppLocalizations? localizations) {
    if (_loadingAllFriends || _loadingFriends) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations?.loadingFriends ?? '正在載入好友列表...')),
      );
      return;
    }

    if (_allFriends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations?.noFriends ?? '您還沒有新增任何好友')),
      );
      return;
    }

    // 使用本地狀態表示好友訪問權限，避免頻繁查詢資料庫
    Map<String, bool> friendAccessState = {};

    // 預先載入所有好友的權限狀態
    Future<void> preloadFriendsAccessStatus() async {
      for (final friend in _allFriends) {
        final hasAccess = await RoomModel.isUserAuthorized(
          widget.roomId,
          friend.id,
        );
        friendAccessState[friend.id] = hasAccess;
      }
      return;
    }

    // 顯示帶有載入指示器的對話框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('載入好友權限狀態...'),
            ],
          ),
        );
      },
    );

    // 預載入所有權限狀態
    preloadFriendsAccessStatus().then((_) {
      // 關閉載入對話框
      Navigator.of(context).pop();

      // 顯示真正的權限管理對話框
      showDialog(
        context: context,
        builder: (context) {
          // 使用StatefulBuilder允許更新對話框內部狀態而不重新載入整個頁面
          return StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(localizations?.manageFriends ?? '管理好友存取權限'),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 300,
                    child: ListView.builder(
                      itemCount: _allFriends.length,
                      itemBuilder: (context, index) {
                        final friend = _allFriends[index];
                        final friendId = friend.id;
                        final hasAccess = friendAccessState[friendId] ?? false;

                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(friend.name),
                          subtitle: Text(friend.email),
                          trailing: Switch(
                            value: hasAccess,
                            onChanged: (value) async {
                              try {
                                // 立即更新UI狀態
                                setDialogState(() {
                                  friendAccessState[friendId] = value;
                                });

                                if (value) {
                                  // 添加訪問權限
                                  await RoomModel.addAuthorizedUser(
                                    widget.roomId,
                                    friendId,
                                  );
                                  // 顯示成功消息
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '已授予 ${friend.name} 訪問此房間的權限',
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  // 移除訪問權限
                                  await RoomModel.removeAuthorizedUser(
                                    widget.roomId,
                                    friendId,
                                  );
                                  // 顯示移除消息
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '已移除 ${friend.name} 訪問此房間的權限',
                                        ),
                                      ),
                                    );
                                  }
                                }

                                // 更新外部狀態但不觸發整個頁面重載
                                if (mounted) {
                                  setState(() {
                                    // 只更新本地房間好友列表，不重新載入或導航
                                    if (value) {
                                      if (!_roomFriends.any(
                                        (f) => f.id == friendId,
                                      )) {
                                        _roomFriends.add(friend);
                                      }
                                    } else {
                                      _roomFriends.removeWhere(
                                        (f) => f.id == friendId,
                                      );
                                    }
                                  });
                                }
                              } catch (e) {
                                print('更新好友權限錯誤: $e');
                                // 發生錯誤時恢復狀態
                                setDialogState(() {
                                  friendAccessState[friendId] = !value;
                                });

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('出現錯誤: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(localizations?.close ?? '關閉'),
                    ),
                  ],
                ),
          );
        },
      );
    });
  }

  // 顯示編輯房間對話框
  Future<void> _showEditRoomDialog(AppLocalizations? localizations) async {
    if (_roomModel == null) return;
    await showEditRoomDialog(context, _roomModel!);
  }

  // 確認刪除房間
  void _showDeleteRoomConfirmation(AppLocalizations? localizations) {
    if (_roomModel == null) return;

    showDeleteRoomDialog(
      context,
      _roomModel!,
      onDeleted: () {
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _maintainState = false;
              });
            }
          });
        }
      },
    );
  }

  @override
  bool get wantKeepAlive => _maintainState;
}
