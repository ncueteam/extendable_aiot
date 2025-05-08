import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// A service class that handles Bluetooth Low Energy (BLE) operations for WiFi provisioning
/// This service manages Bluetooth permissions, device scanning, connections, and WiFi credential sending
class BLEWiFiService {
  // BLE related variables
  bool isBluetoothEnabled = false;
  bool isScanning = false;
  final List<BluetoothDevice> devices = [];
  BluetoothDevice? connectedDevice;
  bool isConnecting = false;
  bool isConnected = false;
  BluetoothCharacteristic? writeCharacteristic;
  String bleStatus = '';
  String bleMessage = '';

  // Stream controllers to broadcast status changes
  final _statusController = StreamController<String>.broadcast();
  final _messageController = StreamController<String>.broadcast();
  final _devicesController =
      StreamController<List<BluetoothDevice>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();
  final _scanningStateController = StreamController<bool>.broadcast();

  // Public streams that UI can listen to
  Stream<String> get statusStream => _statusController.stream;
  Stream<String> get messageStream => _messageController.stream;
  Stream<List<BluetoothDevice>> get devicesStream => _devicesController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  Stream<bool> get scanningStateStream => _scanningStateController.stream;

  // Constructor
  BLEWiFiService() {
    // Initialize any needed setup
  }

  // Update status text and notify listeners
  void _updateStatus(String status) {
    bleStatus = status;
    _statusController.add(status);
  }

  // Update message text and notify listeners
  void _updateMessage(String message) {
    bleMessage = message;
    _messageController.add(message);
  }

  // Check and request necessary Bluetooth permissions
  Future<bool> checkBluetoothPermissions() async {
    // Request Bluetooth permissions
    Map<Permission, PermissionStatus> statuses =
        await [
          Permission.bluetooth,
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
          Permission.location,
        ].request();

    bool allGranted = true;
    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        allGranted = false;
      }
    });

    if (allGranted) {
      await checkBluetoothStatus();
      return true;
    } else {
      _updateStatus('藍牙權限被拒絕');
      return false;
    }
  }

  // Check Bluetooth status
  Future<bool> checkBluetoothStatus() async {
    try {
      bool isEnabled = await FlutterBluePlus.isOn;

      isBluetoothEnabled = isEnabled;
      _updateStatus(isBluetoothEnabled ? '藍牙已啟用' : '藍牙未啟用');

      if (isBluetoothEnabled) {
        startDiscovery();
        return true;
      } else {
        // Request user to turn on Bluetooth
        await FlutterBluePlus.turnOn();
        return await checkBluetoothStatus();
      }
    } catch (e) {
      _updateStatus('檢查藍牙狀態失敗: $e');
      return false;
    }
  }

  // Start scanning for nearby Bluetooth devices
  Future<void> startDiscovery() async {
    if (isScanning) {
      return;
    }

    isScanning = true;
    _scanningStateController.add(true);
    devices.clear();
    _devicesController.add(devices);
    _updateStatus('正在掃描設備...');

    try {
      // Set scan timeout
      Timer scanTimeout = Timer(const Duration(seconds: 5), () {
        if (isScanning) {
          FlutterBluePlus.stopScan();
        }
      });

      // Listen for scan results
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          // Filter devices without names
          if (result.device.platformName.isNotEmpty) {
            // Avoid duplicates
            if (!devices.any(
              (device) => device.remoteId == result.device.remoteId,
            )) {
              devices.add(result.device);
              _devicesController.add(List.from(devices));
            }
          }
        }
      });

      // Listen for scan status
      FlutterBluePlus.isScanning.listen((scanning) {
        if (isScanning != scanning) {
          isScanning = scanning;
          _scanningStateController.add(scanning);

          if (!scanning) {
            _updateStatus('掃描完成，找到 ${devices.length} 個設備');
            scanTimeout.cancel();
          }
        }
      });

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 5),
        androidUsesFineLocation: true,
      );
    } catch (e) {
      isScanning = false;
      _scanningStateController.add(false);
      _updateStatus('掃描失敗: $e');
    }
  }

  // Connect to a Bluetooth device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    if (isConnecting) return false;

    isConnecting = true;
    _updateStatus('正在連接到 ${device.platformName}...');
    connectedDevice = device;

    try {
      // Connect to device with explicit timeout handling
      print('開始連接到藍牙設備: ${device.platformName}');
      await device.connect(timeout: const Duration(seconds: 15)).catchError((
        error,
      ) {
        print('藍牙連接錯誤: $error');
        throw error; // 重新拋出錯誤，讓下面的 catch 區塊捕獲
      });

      print('已成功連接到藍牙設備，正在搜尋服務...');
      isConnecting = false;
      isConnected = true;
      _connectionStateController.add(true);
      _updateStatus('已連接到 ${device.platformName}，正在搜尋服務...');

      // Discover services with explicit error handling
      List<BluetoothService> services = await device
          .discoverServices()
          .catchError((error) {
            print('搜尋服務錯誤: $error');
            throw error; // 重新拋出錯誤
          });

      print('找到 ${services.length} 個服務');

      // 詳細記錄找到的所有服務和特徵，幫助調試
      for (var service in services) {
        print('服務 UUID: ${service.uuid}');
        for (var characteristic in service.characteristics) {
          print('  特徵 UUID: ${characteristic.uuid}');
          print(
            '  特徵屬性: 讀:${characteristic.properties.read} 寫:${characteristic.properties.write} 通知:${characteristic.properties.notify}',
          );
        }
      }

      // Find appropriate service and characteristic
      bool foundCharacteristic = false;

      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          // Check if characteristic supports write
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            writeCharacteristic = characteristic;
            foundCharacteristic = true;
            print('找到可寫入的特徵: ${characteristic.uuid}');
            _updateStatus('找到可寫入的特徵，準備發送數據');
            break;
          }
        }
        if (foundCharacteristic) break;
      }

      if (!foundCharacteristic) {
        print('沒有找到可寫入的特徵');
        _updateStatus('沒有找到可寫入的特徵');
        // We still continue even if no characteristic is found
      }

      // Setup disconnection listener
      device.connectionState.listen((state) {
        print('藍牙連接狀態變更: $state');
        if (state == BluetoothConnectionState.disconnected) {
          isConnected = false;
          connectedDevice = null;
          writeCharacteristic = null;
          _connectionStateController.add(false);
          _updateStatus('設備已斷開連接');
        }
      });

      return true;
    } catch (e) {
      print('藍牙連接完整錯誤: $e');
      isConnecting = false;
      isConnected = false;
      _connectionStateController.add(false);
      _updateStatus('連接失敗: $e');
      connectedDevice = null;
      return false;
    }
  }

  // Disconnect from current device
  Future<void> disconnect() async {
    if (connectedDevice != null && isConnected) {
      try {
        await connectedDevice!.disconnect();
      } catch (e) {
        print('藍牙斷開連接錯誤: $e');
      }
    }

    isConnected = false;
    connectedDevice = null;
    writeCharacteristic = null;
    _connectionStateController.add(false);
    _updateStatus('已斷開連接');
  }

  // Send WiFi credentials and room ID to the ESP32
  Future<bool> sendWiFiCredentials(
    String ssid,
    String password,
    String roomId,
  ) async {
    if (!isConnected || writeCharacteristic == null) {
      _updateStatus('未連接到設備或未找到可寫入特徵');
      return false;
    }

    if (ssid.isEmpty) {
      _updateStatus('SSID 不可為空');
      return false;
    }

    // Format the message according to the ESP32 code format:
    // "WIFI:SSID=your_ssid;PASS=your_password;ROOM=room_id;"
    String message = "WIFI:SSID=$ssid;PASS=$password;ROOM=$roomId;\n";
    List<int> data = utf8.encode(message);

    try {
      // Write data
      await writeCharacteristic!.write(data, withoutResponse: false);
      _updateStatus('正在發送WiFi認證資訊和房間ID...');

      // Set up listener to receive reply
      writeCharacteristic!.onValueReceived.listen((value) {
        String response = String.fromCharCodes(value);
        _updateMessage(response.trim());

        if (response.contains('WIFI_CREDS_SAVED')) {
          _updateStatus('設備已保存WiFi認證資訊');
        } else if (response.contains('WIFI_CONNECTED')) {
          _updateStatus('設備已成功連接到WiFi');
        } else if (response.contains('WIFI_FAILED')) {
          _updateStatus('設備連接WiFi失敗');
        }
      });

      // Enable notifications to receive replies
      await writeCharacteristic!.setNotifyValue(true);
      return true;
    } catch (e) {
      _updateStatus('發送認證資訊失敗: $e');
      return false;
    }
  }

  // Clean up resources when service is no longer needed
  void dispose() {
    _statusController.close();
    _messageController.close();
    _devicesController.close();
    _connectionStateController.close();
    _scanningStateController.close();

    if (isConnected && connectedDevice != null) {
      connectedDevice!.disconnect();
    }
  }

  // Reset the service state for fresh use
  void reset() {
    bleStatus = '';
    bleMessage = '';
    isConnected = false;
    connectedDevice = null;
    writeCharacteristic = null;
    devices.clear();
    isScanning = false;

    _statusController.add(bleStatus);
    _messageController.add(bleMessage);
    _devicesController.add(devices);
    _connectionStateController.add(false);
    _scanningStateController.add(false);
  }
}
