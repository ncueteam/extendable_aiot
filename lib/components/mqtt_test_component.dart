import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTTestComponent extends StatefulWidget {
  final String broker;
  final int port;
  final List<String> topics;

  const MQTTTestComponent({
    super.key,
    this.broker = 'broker.emqx.io',
    this.port = 1883,
    this.topics = const ['esp32/sensors', 'esp32/status', 'esp32/sensors/#'],
  });

  @override
  State<MQTTTestComponent> createState() => _MQTTTestComponentState();
}

class _MQTTTestComponentState extends State<MQTTTestComponent> {
  MqttServerClient? _client;
  final Map<String, List<MQTTMessage>> _messages = {};
  bool _isConnected = false;
  String _connectionStatus = '尚未連接';
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _topicController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _connectMQTT();
  }

  @override
  void dispose() {
    _disconnectMQTT();
    _topicController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _connectMQTT() async {
    final String clientId =
        'flutter_test_${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      _connectionStatus = '正在連接到 ${widget.broker}...';
    });

    _client = MqttServerClient(widget.broker, clientId);
    _client!.port = widget.port;
    _client!.keepAlivePeriod = 60;
    _client!.onDisconnected = _onDisconnected;
    _client!.onConnected = _onConnected;
    _client!.onSubscribed = _onSubscribed;

    try {
      await _client!.connect();

      // 訂閱主題
      for (var topic in widget.topics) {
        _client!.subscribe(topic, MqttQos.atLeastOnce);
      }

      // 監聽消息
      _client!.updates?.listen(_onMessage);
    } catch (e) {
      setState(() {
        _connectionStatus = '連接失敗: $e';
      });
      _client!.disconnect();
    }
  }

  void _disconnectMQTT() {
    _client?.disconnect();
  }

  void _onConnected() {
    setState(() {
      _isConnected = true;
      _connectionStatus = '已連接到 ${widget.broker}';
    });
  }

  void _onDisconnected() {
    setState(() {
      _isConnected = false;
      _connectionStatus = '已斷開連接';
    });
  }

  void _onSubscribed(String topic) {
    setState(() {
      _connectionStatus = '已訂閱主題: $topic';
    });
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (var message in messages) {
      final MqttPublishMessage publishMessage =
          message.payload as MqttPublishMessage;
      final String payload = MqttPublishPayload.bytesToStringAsString(
        publishMessage.payload.message,
      );

      final MQTTMessage mqttMessage = MQTTMessage(
        topic: message.topic,
        message: payload,
        timestamp: DateTime.now(),
      );

      setState(() {
        if (!_messages.containsKey(message.topic)) {
          _messages[message.topic] = [];
        }
        _messages[message.topic]!.add(mqttMessage);

        // 限制每個主題存儲的消息數量，避免內存過度使用
        if (_messages[message.topic]!.length > 100) {
          _messages[message.topic]!.removeAt(0);
        }
      });

      // 自動滾動到底部
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _subscribeToTopic() {
    final topic = _topicController.text.trim();
    if (topic.isNotEmpty && _isConnected && _client != null) {
      _client!.subscribe(topic, MqttQos.atLeastOnce);
      _topicController.clear();
    }
  }

  Widget _buildMessageCard(MQTTMessage message) {
    dynamic messageContent;
    bool isJson = false;

    try {
      // 嘗試解析JSON
      messageContent = json.decode(message.message);
      isJson = true;
    } catch (e) {
      // 不是JSON，直接顯示
      messageContent = message.message;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '主題: ${message.topic}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${message.timestamp.hour}:${message.timestamp.minute}:${message.timestamp.second}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const Divider(),
            if (isJson)
              ..._buildJsonContent(messageContent)
            else
              Text(message.message),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildJsonContent(dynamic content) {
    if (content is Map) {
      return content.entries.map<Widget>((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entry.key}: ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(child: Text('${entry.value}')),
            ],
          ),
        );
      }).toList();
    } else {
      return [Text('$content')];
    }
  }

  @override
  Widget build(BuildContext context) {
    // 計算所有消息的總數
    int totalMessages = 0;
    _messages.forEach((_, messages) => totalMessages += messages.length);

    // 將所有主題的消息合併並按時間排序
    final List<MQTTMessage> allMessages = [];
    _messages.forEach((_, messages) => allMessages.addAll(messages));
    allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Scaffold(
      appBar: AppBar(
        title: const Text('MQTT 測試工具'),
        actions: [
          IconButton(
            icon: Icon(_isConnected ? Icons.link : Icons.link_off),
            onPressed: _isConnected ? _disconnectMQTT : _connectMQTT,
            tooltip: _isConnected ? '斷開連接' : '連接',
          ),
        ],
      ),
      body: Column(
        children: [
          // 連接狀態指示器
          Container(
            padding: const EdgeInsets.all(8),
            color: _isConnected ? Colors.green.shade100 : Colors.red.shade100,
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.check_circle : Icons.error,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _connectionStatus,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text('接收: $totalMessages'),
              ],
            ),
          ),

          // 主題訂閱區
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _topicController,
                    decoration: const InputDecoration(
                      labelText: '輸入主題',
                      hintText: '例如: esp32/sensors/#',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _subscribeToTopic(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _subscribeToTopic,
                  child: const Text('訂閱'),
                ),
              ],
            ),
          ),

          // 已訂閱主題列表
          if (widget.topics.isNotEmpty || _messages.isNotEmpty)
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._messages.keys.map(
                    (topic) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Chip(
                        label: Text(topic),
                        deleteIcon: const Icon(Icons.cancel, size: 16),
                        onDeleted: () {
                          setState(() {
                            _messages.remove(topic);
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 消息列表
          Expanded(
            child:
                allMessages.isEmpty
                    ? const Center(child: Text('尚未接收到任何消息'))
                    : ListView.builder(
                      controller: _scrollController,
                      itemCount: allMessages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageCard(allMessages[index]);
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _messages.clear();
          });
        },
        tooltip: '清除消息',
        child: const Icon(Icons.delete),
      ),
    );
  }
}

class MQTTMessage {
  final String topic;
  final String message;
  final DateTime timestamp;

  MQTTMessage({
    required this.topic,
    required this.message,
    required this.timestamp,
  });
}
