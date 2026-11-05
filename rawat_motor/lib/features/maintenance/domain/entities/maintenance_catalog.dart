import 'maintenance_component.dart';

class MaintenanceCatalog {
  const MaintenanceCatalog({required this.source, required this.components});

  final String source;
  final List<MaintenanceComponent> components;

  factory MaintenanceCatalog.fromJson(Map<String, dynamic> json) {
    final source = json['sumber'];
    final rawComponents = json['komponen'];
    if (source is! String || rawComponents is! List) {
      throw const FormatException('Katalog perawatan tidak valid.');
    }
    return MaintenanceCatalog(
      source: source,
      components: rawComponents
          .map(
            (entry) => MaintenanceComponent.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}
