import '../entities/maintenance_component.dart';

/// Menyaring komponen sesuai jenis motor, pendingin, dan rem depan.
///
/// Nilai yang belum diisi pada profil tidak memfilter komponen, supaya
/// pengguna lama tetap bisa melihat jadwal sampai profilnya dilengkapi.
List<MaintenanceComponent> filterMaintenanceComponents({
  required List<MaintenanceComponent> components,
  String? motorType,
  String? cooling,
  String? frontBrake,
}) {
  return components.where((component) {
    final matchesType = motorType == null ||
        component.appliesTo.isEmpty ||
        component.appliesTo.contains('semua') ||
        component.appliesTo.contains(motorType);
    if (!matchesType) return false;

    return switch (component.requirement) {
      null => true,
      'pendingin_cair' => cooling == null || cooling == 'cair',
      'rem_cakram' => frontBrake == null || frontBrake == 'cakram',
      _ => false,
    };
  }).toList(growable: false);
}
