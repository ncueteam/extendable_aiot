import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/l10n/app_localizations.dart';
import 'package:extendable_aiot/models/sub_type/airconditioner_model.dart';
import 'package:extendable_aiot/models/abstract/device_model.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class AirConditionerControl extends StatefulWidget {
  final AirConditionerModel airConditioner;
  final VoidCallback? onUpdate;

  const AirConditionerControl({
    super.key,
    required this.airConditioner,
    this.onUpdate,
  });

  @override
  State<AirConditionerControl> createState() => _AirConditionerControlState();
}

class _AirConditionerControlState extends State<AirConditionerControl> {
  late double temperature;
  late String mode;
  late String fanSpeed;
  late bool powerOn;
  bool _isUpdating = false;
  bool _localChanges = false; // 追踪是否有未保存的本地更改
  StreamSubscription? _deviceSubscription;

  @override
  void initState() {
    super.initState();
    // 初始化狀態
    _initializeState();
    // 開始監聽設備數據變化
    _startDeviceListener();
  }

  @override
  void dispose() {
    // 取消數據庫監聽，避免內存洩漏
    _deviceSubscription?.cancel();
    super.dispose();
  }

  // 初始化状态变量
  void _initializeState() {
    temperature = widget.airConditioner.temperature;
    mode = widget.airConditioner.mode;
    fanSpeed = widget.airConditioner.fanSpeed;
    powerOn = widget.airConditioner.status;
  }

  // 监听设备数据变化
  void _startDeviceListener() {
    try {
      // 设置实时数据监听
      _deviceSubscription = DeviceModel.getDeviceStream(
        widget.airConditioner.id,
      ).listen(
        (snapshot) {
          if (snapshot.exists && !_localChanges) {
            // 只有在没有本地更改时才更新
            final updatedData = snapshot.data() as Map<String, dynamic>?;
            if (updatedData != null) {
              setState(() {
                // 更新本地模型
                widget.airConditioner.fromJson(updatedData);
                // 更新控制器状态变量
                _initializeState();
              });
            }
          }
        },
        onError: (error) {
          debugPrint('设备数据监听错误: $error');
        },
      );
    } catch (e) {
      debugPrint('启动设备数据监听失败: $e');
    }
  }

  // 标记本地有未保存的更改
  void _markLocalChanges() {
    _localChanges = true;
  }

  // 更新空調設置到Firebase
  Future<void> _updateAirConditioner() async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      // 更新本地模型數據
      widget.airConditioner.temperature = temperature;
      widget.airConditioner.mode = mode;
      widget.airConditioner.fanSpeed = fanSpeed;
      widget.airConditioner.status = powerOn;
      widget.airConditioner.lastUpdated = Timestamp.now();

      // 保存到Firebase
      await widget.airConditioner.updateData();

      // 重置本地更改标记
      _localChanges = false;

      // 回調通知父元件已更新
      if (widget.onUpdate != null) {
        widget.onUpdate!();
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('空調設置已更新')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('更新失敗: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 如果有未保存的更改，显示确认对话框
            if (_localChanges) {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('未保存的更改'),
                      content: const Text('您有未保存的設置更改，是否保存後再離開？'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // 关闭对话框
                            Navigator.of(context).pop(); // 离开页面
                          },
                          child: const Text('不保存'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop(); // 关闭对话框
                            await _updateAirConditioner();
                            if (context.mounted) {
                              Navigator.of(context).pop(); // 更新后离开页面
                            }
                          },
                          child: const Text('保存'),
                        ),
                      ],
                    ),
              );
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(localizations?.airCondition ?? '空調'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateAirConditioner,
            tooltip: '保存設置',
          ),
        ],
      ),
      body:
          _isUpdating
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // 設備名稱
                      Text(
                        widget.airConditioner.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 房間信息
                      Text(
                        '位置: ${widget.airConditioner.roomId}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 溫度顯示
                      Text(
                        '${temperature.toInt()}°',
                        style: const TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        localizations?.celsius ?? '攝氏度',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 溫度調節滑塊
                      Slider(
                        value: temperature,
                        min: 16,
                        max: 30,
                        divisions: 14,
                        onChanged:
                            powerOn
                                ? (value) {
                                  setState(() {
                                    temperature = value;
                                    _markLocalChanges();
                                  });
                                }
                                : null,
                      ),
                      const SizedBox(height: 30),

                      // 模式選擇
                      _buildSectionTitle(localizations?.mode ?? '模式'),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children:
                            AirConditionerModel.modes.map((modeOption) {
                              final modeText = _getModeText(
                                modeOption,
                                localizations,
                              );
                              return _buildOptionButton(
                                label: modeText,
                                selected: mode == modeOption,
                                onTap:
                                    powerOn
                                        ? () {
                                          setState(() {
                                            mode = modeOption;
                                            _markLocalChanges();
                                          });
                                        }
                                        : null,
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 30),

                      // 風速選擇
                      _buildSectionTitle(localizations?.fanSpeed ?? '風速'),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children:
                            AirConditionerModel.fanSpeeds.map((speedOption) {
                              final speedText = _getFanSpeedText(
                                speedOption,
                                localizations,
                              );
                              return _buildOptionButton(
                                label: speedText,
                                selected: fanSpeed == speedOption,
                                onTap:
                                    powerOn
                                        ? () {
                                          setState(() {
                                            fanSpeed = speedOption;
                                            _markLocalChanges();
                                          });
                                        }
                                        : null,
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 60),

                      // 電源開關
                      Container(
                        decoration: BoxDecoration(
                          color: powerOn ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              localizations?.power ?? '電源',
                              style: TextStyle(
                                fontSize: 18,
                                color: powerOn ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Switch(
                              value: powerOn,
                              onChanged: (value) {
                                setState(() {
                                  powerOn = value;
                                  _markLocalChanges();
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      // 最後更新時間
                      const SizedBox(height: 20),
                      Text(
                        '最後更新: ${_formatLastUpdated(widget.airConditioner.lastUpdated)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),

                      // 如果有未保存的本地更改，显示提示
                      if (_localChanges)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.warning_amber, color: Colors.orange),
                              SizedBox(width: 8),
                              Text(
                                '有未保存的更改',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      floatingActionButton:
          _localChanges
              ? FloatingActionButton(
                onPressed: _updateAirConditioner,
                backgroundColor: Colors.blue,
                child: const Icon(Icons.save),
              )
              : null, // 只在有未保存更改时显示保存按钮
    );
  }

  // 構建標題元件
  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 構建選項按鈕
  Widget _buildOptionButton({
    required String label,
    required bool selected,
    VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 50,
        decoration: BoxDecoration(
          color:
              selected
                  ? (isEnabled ? Colors.pink[100] : Colors.grey[300])
                  : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                selected
                    ? (isEnabled ? Colors.pink : Colors.grey)
                    : Colors.transparent,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color:
                selected
                    ? (isEnabled ? Colors.pink[800] : Colors.grey[600])
                    : Colors.black87,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // 獲取本地化的模式文本
  String _getModeText(String mode, AppLocalizations? localizations) {
    switch (mode) {
      case 'Auto':
        return localizations?.auto ?? '自動';
      case 'Cool':
        return localizations?.cool ?? '製冷';
      case 'Dry':
        return localizations?.dry ?? '除濕';
      default:
        return mode;
    }
  }

  // 獲取本地化的風速文本
  String _getFanSpeedText(String speed, AppLocalizations? localizations) {
    switch (speed) {
      case 'Low':
        return localizations?.low ?? '低速';
      case 'Mid':
        return localizations?.mid ?? '中速';
      case 'High':
        return localizations?.high ?? '高速';
      default:
        return speed;
    }
  }

  // 格式化最後更新時間
  String _formatLastUpdated(Timestamp? timestamp) {
    if (timestamp == null) return '未知';
    return timestamp.toDate().toString().substring(0, 19);
  }
}
