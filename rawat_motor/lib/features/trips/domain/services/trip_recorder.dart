import '../entities/trip.dart';
import '../entities/trip_point.dart';
import 'location_service.dart';
import 'route_math.dart';

class TripRecorder {
  TripRecorder(this.locationService);

  final LocationService locationService;
  Trip? _trip;
  final List<TripPoint> _points = [];
  TripPoint? _previousSegmentPoint;
  double _distanceMeters = 0;
  double _maximumSpeedKmh = 0;
  double _speedTotal = 0;
  int _acceptedSegments = 0;
  int _movingSeconds = 0;
  bool _paused = false;

  Trip? get current => _trip;
  List<TripPoint> get points => List.unmodifiable(_points);
  bool get isPaused => _paused;
  double get distanceMeters => _distanceMeters;
  double get averageSpeedKmh =>
      _acceptedSegments == 0 ? 0 : _speedTotal / _acceptedSegments;
  double get maximumSpeedKmh => _maximumSpeedKmh;
  int get movingDurationSeconds => _movingSeconds;

  Future<Trip> start({
    required String id,
    required String vehicleId,
    required DateTime now,
  }) async {
    if (!await locationService.requestWhenInUsePermission()) {
      throw StateError('Izin lokasi belum diberikan.');
    }
    await locationService.start();
    _points.clear();
    _previousSegmentPoint = null;
    _distanceMeters = 0;
    _maximumSpeedKmh = 0;
    _speedTotal = 0;
    _acceptedSegments = 0;
    _movingSeconds = 0;
    _paused = false;
    return _trip = Trip(id: id, vehicleId: vehicleId, startedAt: now);
  }

  void addPoint(TripPoint point) {
    if (_trip == null || _paused || _points.length >= TripThresholds.maxPoints)
      return;
    final previous = _previousSegmentPoint;
    if (!isAcceptablePoint(point, previous)) return;
    if (previous != null) {
      final distance = haversineMeters(previous, point);
      final seconds =
          point.timestamp.difference(previous.timestamp).inMilliseconds ~/ 1000;
      final speed = seconds > 0 ? distance / seconds * 3.6 : 0.0;
      _distanceMeters += distance;
      _maximumSpeedKmh = speed > _maximumSpeedKmh ? speed : _maximumSpeedKmh;
      _speedTotal += speed;
      _acceptedSegments++;
      if (speed >= TripThresholds.movingSpeedKmh) _movingSeconds += seconds;
    }
    _points.add(point);
    _previousSegmentPoint = point;
    _trip = _snapshot(status: TripStatus.recording);
  }

  Future<void> pause() async {
    if (_trip == null || _paused) return;
    _paused = true;
    _previousSegmentPoint = null;
    await locationService.stop();
    _trip = _snapshot(status: TripStatus.paused);
  }

  Future<void> resume() async {
    if (_trip == null || !_paused) return;
    _paused = false;
    _previousSegmentPoint = null;
    await locationService.start();
    _trip = _snapshot(status: TripStatus.recording);
  }

  Future<Trip> finish(DateTime now) async {
    final trip = _trip;
    if (trip == null) throw StateError('Tidak ada perjalanan aktif.');
    await locationService.stop();
    _paused = false;
    final average = _acceptedSegments == 0
        ? 0.0
        : _speedTotal / _acceptedSegments;
    final done = Trip(
      id: trip.id,
      vehicleId: trip.vehicleId,
      startedAt: trip.startedAt,
      finishedAt: now,
      distanceMeters: _distanceMeters,
      movingDurationSeconds: _movingSeconds,
      averageSpeedKmh: average,
      maximumSpeedKmh: _maximumSpeedKmh,
      status: TripStatus.completed,
      route: simplifyRoute(_points),
    );
    _trip = null;
    return done;
  }

  Trip _snapshot({required TripStatus status}) => Trip(
    id: _trip!.id,
    vehicleId: _trip!.vehicleId,
    startedAt: _trip!.startedAt,
    distanceMeters: _distanceMeters,
    movingDurationSeconds: _movingSeconds,
    averageSpeedKmh: _acceptedSegments == 0
        ? 0
        : _speedTotal / _acceptedSegments,
    maximumSpeedKmh: _maximumSpeedKmh,
    status: status,
    route: List.unmodifiable(_points),
  );
}
