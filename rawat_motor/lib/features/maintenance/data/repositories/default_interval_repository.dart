import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/maintenance_catalog.dart';
import '../../domain/entities/maintenance_motor_catalog.dart';

class DefaultIntervalRepository {
  const DefaultIntervalRepository([this._bundle]);

  static const assetPath = 'data/motor/data/default_interval.json';
  static const motorAssetPath =
      'data/motor/data/maintenance_motor_catalog.json';
  final AssetBundle? _bundle;

  Future<MaintenanceCatalog> load() async {
    final jsonText = await (_bundle ?? rootBundle).loadString(assetPath);
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Katalog perawatan tidak valid.');
    }
    return MaintenanceCatalog.fromJson(decoded);
  }

  Future<MaintenanceMotorCatalog> loadMotors() async {
    final jsonText = await (_bundle ?? rootBundle).loadString(motorAssetPath);
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Katalog model motor tidak valid.');
    }
    return MaintenanceMotorCatalog.fromJson(decoded);
  }
}
