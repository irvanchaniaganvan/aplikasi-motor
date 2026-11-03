import '../entities/motor_data.dart';
import '../repositories/motor_data_repository.dart';

class LoadMotorData {
  const LoadMotorData(this._repository);
  final MotorDataRepository _repository;

  Future<MotorData?> call() => _repository.load();
}
