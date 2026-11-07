import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class AndroidTripForegroundService {
  static bool get supported => Platform.isAndroid;

  static void initialize() {
    if (!supported) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'rawatin_trip_recording',
        channelName: 'Perekaman perjalanan',
        channelDescription: 'Notifikasi aktif saat Rawatin merekam perjalanan.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        stopWithTask: true,
      ),
    );
  }

  static Future<void> start() async {
    if (!supported) return;
    await FlutterForegroundTask.requestNotificationPermission();
    await FlutterForegroundTask.startService(
      serviceId: 7301,
      serviceTypes: const [ForegroundServiceTypes.location],
      notificationTitle: 'Merekam perjalanan',
      notificationText: 'Lokasi diproses dan disimpan di perangkat ini.',
      callback: _startTripTask,
    );
  }

  static Future<void> stop() async {
    if (!supported || !await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.stopService();
  }
}

@pragma('vm:entry-point')
void _startTripTask() {
  FlutterForegroundTask.setTaskHandler(_TripTaskHandler());
}

class _TripTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
