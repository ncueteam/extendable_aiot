import 'package:extendable_aiot/models/abstract/general_model.dart';

abstract class SensorModel extends GeneralModel {
  List<dynamic> value;
  SensorModel(
    super.id, {
    required this.value,
    required super.name,
    required super.type,
    required super.lastUpdated,
    required super.icon,
  });

  // 把資料存到firebase user 的 device裡面
}
