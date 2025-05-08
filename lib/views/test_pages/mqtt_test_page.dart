import 'package:flutter/material.dart';
import 'package:extendable_aiot/components/mqtt_test_component.dart';

class MQTTTestPage extends StatefulWidget {
  const MQTTTestPage({super.key});

  @override
  State<MQTTTestPage> createState() => _MQTTTestPageState();
}

class _MQTTTestPageState extends State<MQTTTestPage> {
  final TextEditingController _brokerController = TextEditingController(
    text: 'broker.emqx.io',
  );
  final TextEditingController _portController = TextEditingController(
    text: '1883',
  );
  final TextEditingController _topicController = TextEditingController(
    text: 'esp32/sensors/#',
  );
  final List<String> _topics = [
    'esp32/sensors',
    'esp32/status',
    'esp32/sensors/#',
  ];

  @override
  void dispose() {
    _brokerController.dispose();
    _portController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  void _addTopic() {
    final String topic = _topicController.text.trim();
    if (topic.isNotEmpty && !_topics.contains(topic)) {
      setState(() {
        _topics.add(topic);
        _topicController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MQTT 測試')),
      body: Column(
        children: [
          // 連接配置區
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'MQTT 連接設置',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _brokerController,
                        decoration: const InputDecoration(
                          labelText: 'Broker',
                          hintText: '例如: broker.emqx.io',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _portController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '端口',
                          hintText: '1883',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _topicController,
                        decoration: const InputDecoration(
                          labelText: '添加訂閱主題',
                          hintText: '例如: esp32/device/+/dht11',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _addTopic(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addTopic,
                      child: const Text('添加'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children:
                      _topics
                          .map(
                            (topic) => Chip(
                              label: Text(topic),
                              deleteIcon: const Icon(Icons.cancel, size: 16),
                              onDeleted: () {
                                setState(() {
                                  _topics.remove(topic);
                                });
                              },
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final broker = _brokerController.text.trim();
                    final port =
                        int.tryParse(_portController.text.trim()) ?? 1883;

                    if (broker.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (context) => MQTTTestComponent(
                                broker: broker,
                                port: port,
                                topics: List.from(_topics),
                              ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('開始測試'),
                ),
              ],
            ),
          ),

          // 使用說明
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '使用說明',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('1. 輸入MQTT broker位址與端口'),
                  Text('2. 添加需要訂閱的主題 (可使用通配符 # 和 +)'),
                  Text('3. 點擊"開始測試"連接到MQTT broker'),
                  Text('4. 查看從硬體設備接收的MQTT消息'),
                  SizedBox(height: 16),
                  Text(
                    '硬體MQTT主題格式',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• esp32/sensors - 基本感測器數據'),
                  Text('• esp32/sensors/{roomId} - 特定房間的感測器數據'),
                  Text('• esp32/sensors/{roomId}/{deviceId} - 特定設備的數據'),
                  Text('• esp32/status - 設備在線狀態 (online/offline)'),
                  SizedBox(height: 16),
                  Text(
                    'MQTT消息格式',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('感測器數據 (JSON):'),
                  Text(
                    '  {\n'
                    '    "temp": 25.5,\n'
                    '    "humidity": 60.2,\n'
                    '    "deviceId": "ABCDEF123456",\n'
                    '    "roomId": "room123"\n'
                    '  }',
                  ),
                  SizedBox(height: 8),
                  Text('狀態消息:'),
                  Text('  "online" 或 "offline"'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
