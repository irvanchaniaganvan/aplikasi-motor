import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/maintenance_catalog.dart';

class DefaultIntervalRepository {
  const DefaultIntervalRepository([this._bundle]);

  static const assetPath = 'data/motor/data/default_interval.json';
  final AssetBundle? _bundle;

  Future<MaintenanceCatalog> load() async {
    final jsonText = await (_bundle ?? rootBundle).loadString(assetPath);
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Katalog perawatan tidak valid.');
    }
    return MaintenanceCatalog.fromJson(decoded);
  }
}
