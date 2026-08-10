class MedicationSchedule {
  final String id;
  final String name;
  final String dose;
  final int hour;
  final int minute;
  final bool enabled;
  final String? takenDayKey;

  const MedicationSchedule({
    required this.id,
    required this.name,
    required this.dose,
    required this.hour,
    required this.minute,
    required this.enabled,
    required this.takenDayKey,
  });

  String get timeLabel {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  MedicationSchedule copyWith({
    String? id,
    String? name,
    String? dose,
    int? hour,
    int? minute,
    bool? enabled,
    String? takenDayKey,
    bool clearTakenDayKey = false,
  }) {
    return MedicationSchedule(
      id: id ?? this.id,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
      takenDayKey: clearTakenDayKey ? null : (takenDayKey ?? this.takenDayKey),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dose': dose,
      'hour': hour,
      'minute': minute,
      'enabled': enabled,
      'takenDayKey': takenDayKey,
    };
  }

  static MedicationSchedule fromMap(Map<String, dynamic> map) {
    return MedicationSchedule(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      dose: map['dose'] as String? ?? '',
      hour: (map['hour'] as num?)?.toInt() ?? 8,
      minute: (map['minute'] as num?)?.toInt() ?? 0,
      enabled: map['enabled'] as bool? ?? true,
      takenDayKey: map['takenDayKey'] as String?,
    );
  }
}
