import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../data/services/android_trip_foreground_service.dart';
import '../../data/services/fake_location_service.dart';
import '../../data/services/geolocator_location_service.dart';
import '../../domain/entities/trip.dart';
import '../../domain/entities/trip_point.dart';
import '../../domain/repositories/trip_repository.dart';
import '../../domain/services/location_service.dart';
import '../../domain/services/trip_recorder.dart';
import '../widgets/trip_map.dart';

class TripRecordPage extends StatefulWidget {
  const TripRecordPage({
    required this.vehicleId,
    required this.repository,
    this.locationService,
    this.onAddOdometer,
    super.key,
  });

  final String vehicleId;
  final TripRepository repository;
  final LocationService? locationService;
  final Future<bool> Function(int kilometers)? onAddOdometer;

  @override
  State<TripRecordPage> createState() => _TripRecordPageState();
}

class _TripRecordPageState extends State<TripRecordPage> {
  late final LocationService _locationService =
      widget.locationService ??
      (Platform.isWindows
          ? FakeLocationService()
          : GeolocatorLocationService());
  late final TripRecorder _recorder = TripRecorder(_locationService);
  StreamSubscription<TripPoint>? _subscription;
  Trip? _active;
  Trip? _finished;
  TripPoint? _current;
  DateTime? _started;
  Timer? _clock;
  Duration _elapsed = Duration.zero;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subscription = _locationService.positions.listen((point) {
      _recorder.addPoint(point);
      if (mounted) setState(() => _current = point);
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _subscription?.cancel();
    AndroidTripForegroundService.stop();
    super.dispose();
  }

  Future<bool> _explainAndRequest() async {
    final consent = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Izin lokasi untuk perjalanan'),
        content: const Text(
          'Rawatin memakai lokasi hanya setelah kamu menekan “Mulai perjalanan”. Rute disimpan di perangkat ini, tidak dikirim ke server, dan dapat kamu hapus dari Riwayat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
    if (consent != true) return false;
    final allowed = await _locationService.requestWhenInUsePermission();
    if (!allowed && mounted) {
      final openSettings = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Lokasi belum diizinkan'),
          content: const Text(
            'Aktifkan izin lokasi saat aplikasi digunakan melalui Pengaturan perangkat untuk merekam perjalanan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Nanti'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Buka pengaturan'),
            ),
          ],
        ),
      );
      if (openSettings == true && !Platform.isWindows) {
        await Geolocator.openAppSettings();
      }
    }
    return allowed;
  }

  Future<void> _start() async {
    if (!await _explainAndRequest() || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      AndroidTripForegroundService.initialize();
      if (AndroidTripForegroundService.supported) {
        await AndroidTripForegroundService.start();
      }
      final start = DateTime.now();
      _active = await _recorder.start(
        id: start.microsecondsSinceEpoch.toString(),
        vehicleId: widget.vehicleId,
        now: start,
      );
      _started = start;
      _clock?.cancel();
      _clock = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _started != null) {
          setState(() => _elapsed = DateTime.now().difference(_started!));
        }
      });
    } catch (error) {
      await AndroidTripForegroundService.stop();
      _error = error.toString().contains('Izin lokasi')
          ? 'Izin lokasi tidak diberikan. Aktifkan izin saat aplikasi digunakan untuk memulai.'
          : 'Perjalanan belum bisa dimulai. Periksa layanan lokasi lalu coba lagi.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _togglePause() async {
    if (_active == null) return;
    setState(() => _busy = true);
    if (_recorder.isPaused) {
      if (AndroidTripForegroundService.supported) {
        await AndroidTripForegroundService.start();
      }
      await _recorder.resume();
      _started = DateTime.now().subtract(_elapsed);
      _clock?.cancel();
      _clock = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _started != null) {
          setState(() => _elapsed = DateTime.now().difference(_started!));
        }
      });
    } else {
      await _recorder.pause();
      await AndroidTripForegroundService.stop();
      _elapsed = _started == null
          ? _elapsed
          : DateTime.now().difference(_started!);
      _clock?.cancel();
    }
    _active = _recorder.current;
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    try {
      final trip = await _recorder.finish(DateTime.now());
      _clock?.cancel();
      await AndroidTripForegroundService.stop();
      await widget.repository.save(trip);
      if (!mounted) return;
      setState(() {
        _active = null;
        _finished = trip;
        _busy = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Perjalanan gagal disimpan. Data rekaman sementara masih terbuka.';
        });
      }
    }
  }

  String _duration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final trip = _finished;
    if (trip != null) return _summary(trip);
    final active = _active != null;
    final points = active ? _recorder.points : const <TripPoint>[];
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Perjalanan')),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: TripMap(points: points, current: active ? _current : null),
          ),
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    children: [
                      _stat(
                        'JARAK',
                        '${(_recorder.distanceMeters / 1000).toStringAsFixed(2)} km',
                      ),
                      _stat('DURASI', _duration(_elapsed)),
                      _stat(
                        'KECEPATAN',
                        '${_recorder.averageSpeedKmh.toStringAsFixed(0)} km/j',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Jarak GPS dapat sedikit berbeda dari angka speedometer.',
                    textAlign: TextAlign.center,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _error!,
                      style: TextStyle(color: colors.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  if (!active)
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _start,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(_busy ? 'Memulai…' : 'Mulai perjalanan'),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 58,
                            child: OutlinedButton.icon(
                              onPressed: _busy ? null : _togglePause,
                              icon: Icon(
                                _recorder.isPaused
                                    ? Icons.play_arrow_rounded
                                    : Icons.pause_rounded,
                              ),
                              label: Text(
                                _recorder.isPaused ? 'Lanjutkan' : 'Jeda',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: SizedBox(
                            height: 58,
                            child: FilledButton.icon(
                              onPressed: _busy ? null : _finish,
                              icon: const Icon(Icons.stop_rounded),
                              label: const Text('Selesai'),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Expanded(
    child: Column(
      children: [
        Text(label, style: AppType.eyebrow.copyWith(color: AppPalette.muted)),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: AppType.metric.copyWith(color: AppPalette.ink)),
      ],
    ),
  );

  Widget _summary(Trip trip) => Scaffold(
    appBar: AppBar(title: const Text('Ringkasan perjalanan')),
    body: Column(
      children: [
        Expanded(flex: 6, child: TripMap(points: trip.route, fitRoute: true)),
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    _stat(
                      'JARAK',
                      '${(trip.distanceMeters / 1000).toStringAsFixed(2)} km',
                    ),
                    _stat('DURASI', _duration(trip.duration)),
                    _stat(
                      'RATA-RATA',
                      '${trip.averageSpeedKmh.toStringAsFixed(0)} km/j',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Maks ${trip.maximumSpeedKmh.toStringAsFixed(0)} km/j • durasi bergerak ${_duration(Duration(seconds: trip.movingDurationSeconds))}',
                ),
                const Spacer(),
                const Text(
                  'Jarak GPS dapat sedikit berbeda dari angka speedometer.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: widget.onAddOdometer == null
                        ? null
                        : () async {
                            final km = (trip.distanceMeters / 1000).round();
                            // Callback Update KM menampilkan konfirmasi dan validasi yang sama
                            // dengan alur odometer biasa; jangan meminta konfirmasi dua kali.
                            final added = await widget.onAddOdometer!(km);
                            if (added && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Jarak perjalanan ditambahkan ke odometer.',
                                  ),
                                ),
                              );
                            }
                          },
                    child: Text(
                      'Tambahkan ${(trip.distanceMeters / 1000).toStringAsFixed(1)} km ke odometer',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Kembali ke Perjalanan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class TripHistorySection extends StatefulWidget {
  const TripHistorySection({
    required this.vehicleId,
    required this.repository,
    super.key,
  });
  final String vehicleId;
  final TripRepository repository;

  @override
  State<TripHistorySection> createState() => _TripHistorySectionState();
}

class _TripHistorySectionState extends State<TripHistorySection> {
  late Future<List<Trip>> _trips = widget.repository.load(widget.vehicleId);

  Future<void> _delete(Trip trip) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus perjalanan?'),
        content: const Text(
          'Rute dan statistik perjalanan ini akan dihapus dari perangkat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yes == true) {
      await widget.repository.delete(widget.vehicleId, trip.id);
      setState(() => _trips = widget.repository.load(widget.vehicleId));
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Trip>>(
    future: _trips,
    builder: (context, snapshot) {
      final trips = snapshot.data ?? const <Trip>[];
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'PERJALANAN',
              style: AppType.eyebrow.copyWith(color: AppPalette.muted),
            ),
          ),
          if (trips.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Belum ada perjalanan terekam.'),
            )
          else
            for (final trip in trips)
              ListTile(
                leading: const Icon(Icons.route_rounded),
                title: Text(
                  '${(trip.distanceMeters / 1000).toStringAsFixed(2)} km',
                ),
                subtitle: Text(
                  '${trip.startedAt.toLocal()} • ${trip.route.length} titik',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(trip),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _TripDetailPage(trip: trip),
                  ),
                ),
              ),
        ],
      );
    },
  );
}

class _TripDetailPage extends StatelessWidget {
  const _TripDetailPage({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detail perjalanan')),
    body: Column(
      children: [
        Expanded(flex: 6, child: TripMap(points: trip.route, fitRoute: true)),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  '${(trip.distanceMeters / 1000).toStringAsFixed(2)} km',
                  style: AppType.metric,
                ),
                const Spacer(),
                Text(
                  '${trip.averageSpeedKmh.toStringAsFixed(0)} km/j rata-rata',
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
