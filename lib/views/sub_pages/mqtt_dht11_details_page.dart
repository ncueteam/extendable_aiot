import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/models/sub_type/mqtt_dht11_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MQTTDht11DetailsPage extends StatefulWidget {
  final MQTTEnabledDHT11Model sensor;

  const MQTTDht11DetailsPage({super.key, required this.sensor});

  @override
  State<MQTTDht11DetailsPage> createState() => _MQTTDht11DetailsPageState();
}

class _MQTTDht11DetailsPageState extends State<MQTTDht11DetailsPage> {
  bool _isOnline = false;
  double _temperature = 0.0;
  double _humidity = 0.0;
  late Timer _refreshTimer;
  final List<Map<String, dynamic>> _dataHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // 初始化顯示數據
    _isOnline = widget.sensor.isOnline;
    _temperature = widget.sensor.temperature;
    _humidity = widget.sensor.humidity;

    // 添加監聽器以接收實時更新
    widget.sensor.addOnlineStatusListener(_handleOnlineStatusChange);
    widget.sensor.addDataUpdateListener(_handleDataUpdate);

    // 定期刷新界面以更新在線狀態 (每10秒)
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          //測試
          // widget.sensor.publishTestData();
          _isOnline = widget.sensor.isOnline;
        });
      }
    });

    // 載入歷史數據
    // _loadDataHistory();
  }

  @override
  void dispose() {
    // 清除監聽器和定時器
    widget.sensor.removeOnlineStatusListener(_handleOnlineStatusChange);
    widget.sensor.removeDataUpdateListener(_handleDataUpdate);
    _refreshTimer.cancel();
    super.dispose();
  }

  // 處理在線狀態變更
  void _handleOnlineStatusChange(bool online) {
    if (mounted) {
      setState(() {
        _isOnline = online;
      });
    }
  }

  // 處理數據更新
  void _handleDataUpdate(double temp, double humid) {
    if (mounted) {
      setState(() {
        _temperature = temp;
        _humidity = humid;

        // 添加新數據到歷史記錄
        _dataHistory.insert(0, {
          'timestamp': DateTime.now(),
          'temperature': temp,
          'humidity': humid,
        });

        // 只保留最近20條記錄
        if (_dataHistory.length > 20) {
          _dataHistory.removeLast();
        }
      });
    }
  }

  // 載入歷史數據 (如果設備ID不為空)
  // Future<void> _loadDataHistory() async {
  //   try {
  //     if (widget.sensor.id.isEmpty) {
  //       setState(() => _isLoading = false);
  //       return;
  //     }
  //     final snapshot =
  //         await FirebaseFirestore.instance
  //             .collection('sensor_history')
  //             .doc(widget.sensor.deviceId)
  //             .collection('readings')
  //             .orderBy('timestamp', descending: true)
  //             .limit(20)
  //             .get();
  //     if (mounted) {
  //       setState(() {
  //         for (var doc in snapshot.docs) {
  //           final data = doc.data();
  //           _dataHistory.add({
  //             'timestamp': (data['timestamp'] as Timestamp).toDate(),
  //             'temperature': data['temperature'] ?? 0.0,
  //             'humidity': data['humidity'] ?? 0.0,
  //           });
  //         }
  //         _isLoading = false;
  //       });
  //     }
  //   } catch (e) {
  //     debugPrint('載入歷史數據失敗: $e');
  //     if (mounted) {
  //       setState(() => _isLoading = false);
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.sensor.name} 詳情'),
        actions: [
          // 如果設備在資料庫中有記錄，顯示保存按鈕
          if (widget.sensor.id.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: '保存當前數據到資料庫',
              onPressed: _saveCurrentReadingToDatabase,
            ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: '發送測試數據',
            onPressed: () => widget.sensor.publishTestData(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 設備狀態卡片
          _buildStatusCard(),

          // 當前讀數卡片
          _buildCurrentReadingsCard(),

          // 歷史數據
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  // 設備狀態卡片
  Widget _buildStatusCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: _isOnline ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 8),
                const Text(
                  '設備資訊',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _isOnline
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isOnline ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isOnline ? '線上' : '離線',
                        style: TextStyle(
                          color:
                              _isOnline ? Colors.green[800] : Colors.red[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('設備名稱', widget.sensor.name),
            _buildInfoRow('設備ID', widget.sensor.deviceId),
            _buildInfoRow('房間ID', widget.sensor.roomId),
            _buildInfoRow(
              '最後更新',
              _formatDateTime(widget.sensor.lastUpdatedTime),
            ),
          ],
        ),
      ),
    );
  }

  // 當前讀數卡片
  Widget _buildCurrentReadingsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.data_usage, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '即時數據',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Icon(
                  Icons.wifi,
                  color: _isOnline ? Colors.green : Colors.red,
                  size: 20,
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildReadingDisplay(
                  icon: Icons.thermostat,
                  label: '溫度',
                  value: '${_temperature.toStringAsFixed(2)}°C',
                  iconColor: Colors.red,
                ),
                const SizedBox(width: 20),
                _buildReadingDisplay(
                  icon: Icons.water_drop,
                  label: '濕度',
                  value: '$_humidity%',
                  iconColor: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 歷史數據列表
  Widget _buildHistoryList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.history, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                '歷史數據',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${_dataHistory.length} 個記錄',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _dataHistory.isEmpty
                  ? const Center(child: Text('沒有歷史數據'))
                  : ListView.builder(
                    itemCount: _dataHistory.length,
                    itemBuilder: (context, index) {
                      final data = _dataHistory[index];
                      return ListTile(
                        leading: const Icon(Icons.access_time),
                        title: Row(
                          children: [
                            Icon(
                              Icons.thermostat,
                              color: Colors.red[400],
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text('${data['temperature'].toStringAsFixed(1)}°C'),
                            const SizedBox(width: 20),
                            Icon(
                              Icons.water_drop,
                              color: Colors.blue[400],
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text('${data['humidity'].toStringAsFixed(1)}%'),
                          ],
                        ),
                        subtitle: Text(
                          _formatDateTime(data['timestamp']),
                          style: const TextStyle(fontSize: 12),
                        ),
                        dense: true,
                      );
                    },
                  ),
        ),
      ],
    );
  }

  // 顯示資訊的行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // 數據顯示元件
  Widget _buildReadingDisplay({
    required IconData icon,
    required String label,
    required String value,
    Color iconColor = Colors.blue,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // 格式化日期時間
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  // 儲存當前讀數到資料庫
  Future<void> _saveCurrentReadingToDatabase() async {
    if (widget.sensor.id.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('此設備為臨時設備，無法保存到資料庫')));
      return;
    }

    try {
      // 1. 更新設備模型
      await widget.sensor.updateData();

      // 2. 保存讀數到歷史記錄集合
      await FirebaseFirestore.instance
          .collection('sensor_history')
          .doc(widget.sensor.deviceId)
          .collection('readings')
          .add({
            'timestamp': Timestamp.now(),
            'temperature': widget.sensor.temperature,
            'humidity': widget.sensor.humidity,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已儲存當前數據'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('儲存失敗: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
