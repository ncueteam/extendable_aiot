import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  static final MQTTService _instance = MQTTService._internal();
  factory MQTTService() => _instance;
  MQTTService._internal();

  MqttServerClient? _client;
  final String broker = 'broker.emqx.io';
  final int port = 1883;
  final String clientId =
      'flutter_client_${DateTime.now().millisecondsSinceEpoch}';

  Stream<List<MqttReceivedMessage<MqttMessage>>>? get updates =>
      _client?.updates;
  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<void> connect() async {
    _client = MqttServerClient(broker, clientId);
    _client!.port = port;
    _client!.keepAlivePeriod = 60;
    _client!.onDisconnected = () => print('MQTT已斷開連接');
    _client!.onConnected = () => print('MQTT已連接到 $broker');
    _client!.onSubscribed = (topic) => print('已訂閱主題: $topic');

    try {
      await _client!.connect();
    } catch (e) {
      print('MQTT連接失敗: $e');
      _client!.disconnect();
    }
  }

  void subscribe(String topic) {
    if (isConnected) {
      _client!.subscribe(topic, MqttQos.atLeastOnce);
    }
  }

  void publish(String topic, String message) {
    if (isConnected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    }
  }

  void disconnect() {
    _client?.disconnect();
  }
}
