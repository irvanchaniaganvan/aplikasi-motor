import '../entities/motor_data.dart';

abstract interface class MotorDataRepository {
  Future<MotorData?> load();
  Future<void> save(MotorData data);
  Future<void> clear();
}
