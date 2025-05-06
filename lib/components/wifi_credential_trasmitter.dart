import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class WifiCredentialTransmitter extends StatefulWidget {
  const WifiCredentialTransmitter({super.key});

  @override
  _WifiCredentialTransmitterState createState() =>
      _WifiCredentialTransmitterState();
}

class _WifiCredentialTransmitterState extends State<WifiCredentialTransmitter> {
  // Bluetooth state
  bool _isBluetoothEnabled = false;
  bool _isScanning = false;
  final List<BluetoothDevice> _devices = [];
  BluetoothDevice? _connectedDevice;
  BluetoothConnection? _connection;

  // 設備特徵值
  BluetoothCharacteristic? _writeCharacteristic;

  // Connection status
  String _status = 'Waiting for Bluetooth';
  String _message = '';
  bool _isConnecting = false;
  bool _isConnected = false;

  // Text controllers for WiFi credentials
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // ESP32 UART service 和特徵值 UUID
  final String ESP32_SERVICE_UUID = "0000180f-0000-1000-8000-00805f9b34fb";
  final String ESP32_CHARACTERISTIC_UUID =
      "00002a19-0000-1000-8000-00805f9b34fb";

  @override
  void initState() {
    super.initState();
    _checkBluetoothPermissions();
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Check and request necessary Bluetooth permissions
  Future<void> _checkBluetoothPermissions() async {
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
      _checkBluetoothStatus();
    } else {
      setState(() {
        _status = 'Bluetooth permissions denied';
      });
    }
  }

  // 檢查藍牙狀態
  Future<void> _checkBluetoothStatus() async {
    try {
      // 檢查藍牙是否開啟
      bool isEnabled = await FlutterBluePlus.isOn;

      setState(() {
        _isBluetoothEnabled = isEnabled;
        _status =
            _isBluetoothEnabled
                ? 'Bluetooth is enabled'
                : 'Bluetooth is disabled';
      });

      if (_isBluetoothEnabled) {
        _startDiscovery();
      } else {
        // 請求用戶打開藍牙
        await FlutterBluePlus.turnOn();
        _checkBluetoothStatus();
      }
    } catch (e) {
      setState(() {
        _status = 'Failed to check Bluetooth status: $e';
      });
    }
  }

  // Start scanning for nearby Bluetooth devices
  void _startDiscovery() async {
    setState(() {
      _isScanning = true;
      _devices.clear();
      _status = 'Scanning for devices...';
    });

    try {
      // 設置掃描超時
      Timer scanTimeout = Timer(const Duration(seconds: 5), () {
        if (_isScanning) {
          FlutterBluePlus.stopScan();
        }
      });

      // 監聽掃描結果
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          // 過濾沒有名稱的設備
          if (result.device.platformName.isNotEmpty) {
            // 避免重複添加
            if (!_devices.any(
              (device) => device.remoteId == result.device.remoteId,
            )) {
              setState(() {
                _devices.add(result.device);
              });
            }
          }
        }
      });

      // 監聽掃描狀態
      FlutterBluePlus.isScanning.listen((isScanning) {
        if (mounted && _isScanning != isScanning) {
          setState(() {
            _isScanning = isScanning;
            if (!isScanning) {
              _status = 'Scan completed, found ${_devices.length} device(s)';
              scanTimeout.cancel();
            }
          });
        }
      });

      // 開始掃描
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 5),
        androidUsesFineLocation: true,
      );
    } catch (e) {
      setState(() {
        _isScanning = false;
        _status = 'Failed to scan: $e';
      });
    }
  }

  // Connect to a Bluetooth device
  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
      _status = 'Connecting to ${device.platformName}...';
      _connectedDevice = device;
    });

    try {
      // 連接設備
      await device.connect(timeout: const Duration(seconds: 10));

      setState(() {
        _isConnecting = false;
        _isConnected = true;
        _status = 'Connected to ${device.platformName}';
      });

      // 發現服務
      List<BluetoothService> services = await device.discoverServices();

      // 尋找適當的服務和特徵
      bool foundCharacteristic = false;

      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          // 檢查特徵是否支持寫入
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse) {
            _writeCharacteristic = characteristic;
            foundCharacteristic = true;
            setState(() {
              _status = 'Found writable characteristic, ready to send data';
            });
            break;
          }
        }
        if (foundCharacteristic) break;
      }

      if (!foundCharacteristic) {
        setState(() {
          _status = 'No writable characteristic found';
        });
      }

      // 設置連接斷開監聽
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          setState(() {
            _isConnected = false;
            _connectedDevice = null;
            _writeCharacteristic = null;
            _status = 'Device disconnected';
          });
        }
      });
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _status = 'Connection failed: $e';
        _connectedDevice = null;
      });
    }
  }

  // Send WiFi credentials to the ESP32
  Future<void> _sendWiFiCredentials() async {
    if (!_isConnected || _writeCharacteristic == null) {
      setState(() {
        _status =
            'Not connected to a device or no writable characteristic found';
      });
      return;
    }

    String ssid = _ssidController.text.trim();
    String password = _passwordController.text.trim();

    if (ssid.isEmpty) {
      setState(() {
        _status = 'SSID cannot be empty';
      });
      return;
    }

    // Format the message according to the ESP32 code
    // "WIFI:SSID=your_ssid;PASS=your_password;"
    String message = "WIFI:SSID=$ssid;PASS=$password;\n";
    List<int> data = utf8.encode(message);

    try {
      // 寫入數據
      await _writeCharacteristic!.write(data, withoutResponse: false);

      setState(() {
        _status = 'Sending WiFi credentials...';
      });

      // 設置監聽來接收回覆
      _writeCharacteristic!.onValueReceived.listen((value) {
        String response = String.fromCharCodes(value);
        setState(() {
          _message = response.trim();

          if (_message.contains('WIFI_CREDS_SAVED')) {
            _status = 'WiFi credentials saved on the device';
          } else if (_message.contains('WIFI_CONNECTED')) {
            _status = 'Device connected to WiFi successfully';
          } else if (_message.contains('WIFI_FAILED')) {
            _status = 'Device failed to connect to WiFi';
          }
        });
      });

      // 啟用通知以接收回覆
      await _writeCharacteristic!.setNotifyValue(true);
    } catch (e) {
      setState(() {
        _status = 'Failed to send credentials: $e';
      });
    }
  }

  // Show WiFi credentials dialog
  Future<void> _showWiFiCredentialsDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter WiFi Credentials'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _ssidController,
                  decoration: const InputDecoration(
                    labelText: 'WiFi SSID',
                    hintText: 'Enter your WiFi network name',
                  ),
                ),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'WiFi Password',
                    hintText: 'Enter your WiFi password',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Send'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi Credential Transmitter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                _isBluetoothEnabled ? _startDiscovery : _checkBluetoothStatus,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade100,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: $_status',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('Message: $_message'),
                  ),
              ],
            ),
          ),

          // Device list or connection controls
          Expanded(
            child:
                _isConnected ? _buildConnectedView() : _buildDeviceListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceListView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Devices (${_devices.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isScanning)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        Expanded(
          child:
              _devices.isEmpty
                  ? const Center(
                    child: Text('No devices found. Tap refresh to scan.'),
                  )
                  : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      BluetoothDevice device = _devices[index];
                      return ListTile(
                        title: Text(device.platformName),
                        subtitle: Text(device.remoteId.toString()),
                        trailing:
                            _isConnecting &&
                                    _connectedDevice?.remoteId ==
                                        device.remoteId
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.bluetooth),
                        onTap:
                            _isConnecting
                                ? null
                                : () => _connectToDevice(device),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildConnectedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bluetooth_connected, size: 80, color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            'Connected to: ${_connectedDevice?.platformName ?? "Unknown Device"}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(_connectedDevice?.remoteId.toString() ?? ''),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _showWiFiCredentialsDialog,
            child: const Text('Send WiFi Credentials'),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            icon: const Icon(Icons.bluetooth_disabled),
            label: const Text('Disconnect'),
            onPressed: () async {
              if (_connectedDevice != null) {
                await _connectedDevice!.disconnect();
                setState(() {
                  _isConnected = false;
                  _connectedDevice = null;
                  _writeCharacteristic = null;
                  _status = 'Disconnected';
                });
              }
            },
          ),
        ],
      ),
    );
  }
}

// 為了防止類型錯誤，定義一個簡單的連接類
class BluetoothConnection {
  final BluetoothDevice device;
  BluetoothConnection(this.device);
}
