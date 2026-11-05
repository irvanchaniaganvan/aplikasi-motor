import '../entities/maintenance_component.dart';
import '../entities/maintenance_motor_catalog.dart';

List<MaintenanceComponent> filterPartsForMotor({
  required List<MaintenanceComponent> parts,
  required MaintenanceMotor motor,
}) {
  return parts
      .where((part) {
        if (!motor.parts.contains(part.id)) {
          return false;
        }
        if ((part.id == 'v-belt' || part.id == 'roller') &&
            motor.transmission != 'cvt_matic') {
          return false;
        }
        if (part.id == 'rantai-gear-set' && motor.transmission != 'manual') {
          return false;
        }
        if (part.id == 'coolant' && motor.cooling != 'cair') {
          return false;
        }
        return true;
      })
      .toList(growable: false);
}

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
  return components
      .where((component) {
        final matchesType =
            motorType == null ||
            component.appliesTo.isEmpty ||
            component.appliesTo.contains('semua') ||
            component.appliesTo.contains(motorType);
        if (!matchesType) return false;

        return switch (component.requirement) {
          null => true,
          'pendingin_cair' => cooling == 'cair',
          'rem_cakram' => frontBrake == null || frontBrake == 'cakram',
          _ => false,
        };
      })
      .toList(growable: false);
}
