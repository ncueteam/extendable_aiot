import 'package:extendable_aiot/models/abstract/switchable_model.dart';

class SwitchModel extends SwitchableModel {
  SwitchModel(
    super.id, {
    required super.name,
    required super.type,
    required super.lastUpdated,
    required super.icon,
    required super.updateValue,
    required super.previousValue,
    required super.status,
  });
}
