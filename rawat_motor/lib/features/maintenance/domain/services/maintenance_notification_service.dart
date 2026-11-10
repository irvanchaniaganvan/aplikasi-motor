import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../entities/maintenance_component.dart';
import '../entities/motor_data.dart';

/// Menjembatani jadwal perawatan dengan notifikasi lokal perangkat.
///
/// Jadwal berbasis waktu dapat dipasang saat aplikasi memuat data. Jadwal
/// berbasis kilometer tetap diperiksa saat aplikasi dibuka atau KM diperbarui,
/// karena odometer tidak bisa berubah sendiri ketika aplikasi tertutup.
class MaintenanceNotificationService {
  MaintenanceNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'maintenance_reminders';
  static const _channelName = 'Pengingat perawatan';
  static const _channelDescription =
      'Pengingat jadwal servis dan pemeriksaan motor.';
  static const _dueNotificationId = 700001;
  static const _timeNotificationBaseId = 710000;

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _permissionRequested = false;
  bool _disabled = false;

  Future<void> initialize() async {
    if (_initialized || _disabled || kIsWeb || !_supportsLocalNotifications) {
      return;
    }
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    final settings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: const DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    try {
      await _plugin.initialize(settings: settings);
      _initialized = true;
    } catch (_) {
      // Flutter test/desktop engine bisa belum mendaftarkan platform plugin.
      // Snackbar tetap menjadi fallback tanpa membuat halaman gagal dibuka.
      _disabled = true;
    }
  }

  Future<void> requestPermission() async {
    await initialize();
    if (!_initialized || _permissionRequested) return;
    _permissionRequested = true;
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (_) {
      _disabled = true;
    }
  }

  bool get _supportsLocalNotifications =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> syncTimeReminders({
    required MotorData data,
    required List<MaintenanceComponent> components,
  }) async {
    await initialize();
    if (!_initialized) return;

    for (var index = 0; index < 100; index++) {
      await _plugin.cancel(id: _timeNotificationBaseId + index);
    }
    for (var index = 0; index < components.length; index++) {
      final component = components[index];
      final state = data.componentStates
          .where(
            (item) =>
                item.componentId == component.id ||
                item.componentName == component.name,
          )
          .firstOrNull;
      final months = state?.intervalMonthsOverride ?? component.intervalMonths;
      final lastDate =
          state?.lastServicedAt ??
          (component.id == 'oli-mesin' ? data.lastOilChangeDate : null);
      if (months == null || lastDate == null) continue;
      final scheduled = _addMonths(lastDate, months);
      if (!scheduled.isAfter(DateTime.now())) continue;
      try {
        await _plugin.zonedSchedule(
          id: _timeNotificationBaseId + index,
          scheduledDate: tz.TZDateTime.from(scheduled, tz.local),
          title: 'Pengingat Rawatin',
          body: '${component.name} sudah waktunya diperiksa atau diganti.',
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (_) {
        _disabled = true;
        return;
      }
    }
  }

  Future<void> showDueReminder(List<MaintenanceComponent> due) async {
    if (due.isEmpty) return;
    await initialize();
    if (!_initialized) return;
    final names = due.take(2).map((item) => item.name).join(' dan ');
    try {
      await _plugin.show(
        id: _dueNotificationId,
        title: 'Pengingat Rawatin',
        body: '$names sudah waktunya diperiksa atau diganti.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {
      _disabled = true;
    }
  }

  DateTime _addMonths(DateTime date, int months) {
    final targetMonth = date.month - 1 + months;
    final year = date.year + targetMonth ~/ 12;
    final month = targetMonth % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(
      year,
      month,
      date.day > lastDay ? lastDay : date.day,
      date.hour,
      date.minute,
    );
  }
}
