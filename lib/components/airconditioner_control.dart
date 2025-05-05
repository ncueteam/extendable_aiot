import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:extendable_aiot/l10n/app_localizations.dart';
import 'package:extendable_aiot/models/sub_type/airconditioner_model.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    // 初始化狀態
    temperature = widget.airConditioner.temperature;
    mode = widget.airConditioner.mode;
    fanSpeed = widget.airConditioner.fanSpeed;
    powerOn = widget.airConditioner.status;
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
          onPressed: () => Navigator.of(context).pop(),
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
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      // 最後更新時間
                      const SizedBox(height: 20),
                      Text(
                        '最後更新: ${widget.airConditioner.lastUpdated.toDate().toString().substring(0, 19)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _updateAirConditioner,
        child: const Icon(Icons.save),
      ),
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
}
