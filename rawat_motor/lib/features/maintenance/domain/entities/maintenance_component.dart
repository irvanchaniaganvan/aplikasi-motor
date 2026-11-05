class MaintenanceComponent {
  const MaintenanceComponent({
    this.id,
    required this.name,
    required this.action,
    required this.intervalKm,
    this.intervalMonths,
    this.appliesTo = const ['semua'],
    this.requirement,
    this.note,
    this.todoVerify = false,
  });

  final String? id;
  final String name;

  /// Aksi yang disarankan: [ganti] atau [cek].
  final String action;
  final int intervalKm;
  final int? intervalMonths;
  final List<String> appliesTo;

  /// Syarat tambahan, misalnya [pendingin_cair] atau [rem_cakram].
  final String? requirement;
  final String? note;
  final bool todoVerify;

  bool get isInspection => action == 'cek';

  factory MaintenanceComponent.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['nama'];
    final action = json['aksi'];
    final intervalKm = json['intervalKm'];
    final intervalMonths = json['intervalBulan'];
    final rawAppliesTo = json['untuk'];
    final requirement = json['syarat'];
    final note = json['catatan'];

    final appliesTo = rawAppliesTo == null
        ? const ['semua']
        : rawAppliesTo is List && rawAppliesTo.every((value) => value is String)
        ? rawAppliesTo.cast<String>()
        : null;

    final todoVerify = json['verifikasi'] == 'TODO_VERIFY';
    if ((id != null && id is! String) ||
        name is! String ||
        name.trim().isEmpty ||
        (action != 'ganti' && action != 'cek') ||
        intervalKm is! int ||
        intervalKm <= 0 ||
        (intervalMonths != null &&
            (intervalMonths is! int || intervalMonths <= 0)) ||
        appliesTo == null ||
        (requirement != null && requirement is! String) ||
        (note != null && note is! String)) {
      throw const FormatException('Data komponen perawatan tidak valid.');
    }

    return MaintenanceComponent(
      id: id as String?,
      name: name,
      action: action,
      intervalKm: intervalKm,
      intervalMonths: intervalMonths == null ? null : intervalMonths as int,
      appliesTo: appliesTo,
      requirement: requirement as String?,
      note: note as String?,
      todoVerify: todoVerify,
    );
  }
}

class ComponentMaintenanceState {
  const ComponentMaintenanceState({
    required this.componentName,
    this.componentId,
    this.lastServicedKm,
    this.intervalKmOverride,
    this.intervalMonthsOverride,
    this.lastServicedAt,
  });

  final String componentName;
  final String? componentId;

  /// Kosong berarti komponen belum pernah dicatat.
  final int? lastServicedKm;
  final int? intervalKmOverride;
  final int? intervalMonthsOverride;
  final DateTime? lastServicedAt;

  Map<String, Object?> toJson() => {
    'componentName': componentName,
    'componentId': componentId,
    'lastServicedKm': lastServicedKm,
    'intervalKmOverride': intervalKmOverride,
    'intervalMonthsOverride': intervalMonthsOverride,
    'lastServicedAt': lastServicedAt?.toIso8601String(),
  };

  factory ComponentMaintenanceState.fromJson(Map<String, dynamic> json) {
    final name = json['componentName'];
    final componentId = json['componentId'];
    final lastKm = json['lastServicedKm'];
    final kmOverride = json['intervalKmOverride'];
    final monthOverride = json['intervalMonthsOverride'];
    final date = json['lastServicedAt'];
    if (name is! String ||
        (componentId != null && componentId is! String) ||
        (lastKm != null && (lastKm is! int || lastKm < 0)) ||
        (kmOverride != null && (kmOverride is! int || kmOverride <= 0)) ||
        (monthOverride != null &&
            (monthOverride is! int || monthOverride <= 0)) ||
        (date != null && date is! String)) {
      throw const FormatException('Status perawatan komponen tidak valid.');
    }
    final parsedDate = date is String ? DateTime.tryParse(date) : null;
    if (date != null && parsedDate == null) {
      throw const FormatException('Tanggal servis komponen tidak valid.');
    }
    return ComponentMaintenanceState(
      componentName: name,
      componentId: componentId as String?,
      lastServicedKm: lastKm == null ? null : lastKm as int,
      intervalKmOverride: kmOverride == null ? null : kmOverride as int,
      intervalMonthsOverride: monthOverride == null
          ? null
          : monthOverride as int,
      lastServicedAt: parsedDate,
    );
  }
}
