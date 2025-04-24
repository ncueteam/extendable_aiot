import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  static final MQTTService _instance = MQTTService._internal();
  factory MQTTService() => _instance;
  MQTTService._internal();

  MqttServerClient? _client;
  final String broker = 'broker.hivemq.com';
  final int port = 1883;
  final String clientId = 'flutter_client';

  Future<void> connect() async {
    _client = MqttServerClient(broker, clientId);
    _client!.port = port;
    _client!.keepAlivePeriod = 60;
    _client!.onDisconnected = _onDisconnected;
    _client!.onConnected = _onConnected;

    try {
      await _client!.connect();
    } catch (e) {
      print('MQTT連接失敗: $e');
      _client!.disconnect();
    }
  }

  void subscribe(String topic, Function(String payload) onData) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      _client!.subscribe(topic, MqttQos.atLeastOnce);
      _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(
          message.payload.message,
        );
        onData(payload);
      });
    }
  }

  void publish(String topic, String message) {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      builder.addString(message);
      _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    }
  }

  void disconnect() {
    _client?.disconnect();
  }

  void _onConnected() {
    print('MQTT已連接');
  }

  void _onDisconnected() {
    print('MQTT已斷開');
  }
}
