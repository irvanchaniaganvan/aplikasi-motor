import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../profile/domain/entities/motor_model_catalog.dart';
import '../../domain/entities/oil_specification.dart';

/// Mencari spesifikasi oli lokal dari katalog model motor.
///
/// Katalog model (`data/model_motor.json`) lebih luas daripada katalog
/// maintenance. Resolver ini menjembatani profil pengguna dengan spesifikasi
/// oli yang sudah terverifikasi tanpa harus menambah entri maintenance.
class MotorOilSpecResolver {
  MotorOilSpecResolver({MotorModelCatalog? catalog}) {
    _catalog = catalog;
  }

  MotorModelCatalog? _catalog;

  Future<OilSpecification?> resolve({
    required String brand,
    required String model,
  }) async {
    final catalog = _catalog ??= await _loadCatalog();
    return resolveFromCatalog(catalog, brand: brand, model: model);
  }

  static OilSpecification? resolveFromCatalog(
    MotorModelCatalog catalog, {
    required String brand,
    required String model,
  }) {
    final normalizedBrand = brand.trim().toLowerCase();
    final normalizedModel = model.trim().toLowerCase();
    if (normalizedModel.isEmpty) return null;

    final brands = normalizedBrand.isEmpty
        ? catalog.brands
        : catalog.brands
              .where((item) => item.name.toLowerCase() == normalizedBrand)
              .toList(growable: false);

    // 1. Cocokkan nama model atau alias secara persis.
    for (final brandEntry in brands) {
      for (final candidate in brandEntry.models) {
        final names = <String>[
          candidate.name,
          ...candidate.aliases,
        ].map((item) => item.trim().toLowerCase());
        if (names.any((name) => name == normalizedModel)) {
          return candidate.oilSpec;
        }
      }
    }

    // 2. Cocokkan jika nama katalog terkandung di nama profil, misalnya
    // "Mio Gear 2024" dengan alias "Mio Gear".
    for (final brandEntry in brands) {
      for (final candidate in brandEntry.models) {
        final names = <String>[
          candidate.name,
          ...candidate.aliases,
        ].map((item) => item.trim().toLowerCase());
        if (names.any(
          (name) => name.length >= 4 && normalizedModel.contains(name),
        )) {
          return candidate.oilSpec;
        }
      }
    }

    return null;
  }

  Future<MotorModelCatalog> _loadCatalog() async {
    try {
      final raw = await rootBundle.loadString('data/model_motor.json');
      return MotorModelCatalog.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const MotorModelCatalog(brands: []);
    }
  }
}
