import '../entities/motor_data.dart';
import '../repositories/motor_data_repository.dart';

class SaveMotorData {
  const SaveMotorData(this._repository);
  final MotorDataRepository _repository;

  Future<void> call(MotorData data) => _repository.save(data);
}
