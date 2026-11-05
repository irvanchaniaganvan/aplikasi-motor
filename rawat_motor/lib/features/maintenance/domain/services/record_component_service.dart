import '../entities/maintenance_component.dart';
import '../entities/motor_data.dart';
import '../entities/odometer_entry.dart';
import '../entities/service_record.dart';

class RecordComponentService {
  const RecordComponentService();

  MotorData record({
    required MotorData data,
    required MaintenanceComponent component,
    required int odometer,
    required DateTime date,
    int cost = 0,
    String notes = '',
  }) {
    final state = ComponentMaintenanceState(
      componentName: component.name,
      componentId: component.id,
      lastServicedKm: odometer,
      intervalKmOverride: data.componentStates
          .where(
            (item) =>
                item.componentId == component.id ||
                item.componentName == component.name,
          )
          .firstOrNull
          ?.intervalKmOverride,
      intervalMonthsOverride: data.componentStates
          .where(
            (item) =>
                item.componentId == component.id ||
                item.componentName == component.name,
          )
          .firstOrNull
          ?.intervalMonthsOverride,
      lastServicedAt: date,
    );
    final states = [
      ...data.componentStates.where(
        (item) =>
            item.componentId != component.id &&
            item.componentName != component.name,
      ),
      state,
    ];
    final logs =
        odometer > data.currentOdometer &&
            (data.odometerLogs.isEmpty ||
                odometer > data.odometerLogs.last.kilometers)
        ? [
            ...data.odometerLogs,
            OdometerEntry(kilometers: odometer, date: date, source: 'servis'),
          ]
        : data.odometerLogs;
    final updateOdometer = odometer > data.currentOdometer;
    final serviceHistory = [
      ...data.serviceHistory,
      ServiceRecord(
        date: date,
        odometer: odometer,
        item: component.name,
        cost: cost,
        notes: notes,
      ),
    ];
    if (component.id == 'oli-mesin' || component.name == 'Oli mesin') {
      return data.copyWith(
        currentOdometer: updateOdometer ? odometer : null,
        lastOilOdometer: odometer,
        lastOilChangeDate: date,
        odometerLogs: logs,
        serviceHistory: serviceHistory,
        componentStates: states,
      );
    }
    return data.copyWith(
      currentOdometer: updateOdometer ? odometer : null,
      odometerLogs: logs,
      serviceHistory: serviceHistory,
      componentStates: states,
    );
  }
}
