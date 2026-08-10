class LabEntry {
  final String id;
  final String metric;
  final double value;
  final String unit;
  final String refRange;
  final String status;
  final String date;
  final String target;
  final double progressVal;

  LabEntry({
    required this.id,
    required this.metric,
    required this.value,
    required this.unit,
    required this.refRange,
    required this.status,
    required this.date,
    required this.target,
    required this.progressVal,
  });

  LabEntry copyWith({
    String? metric,
    double? value,
    String? unit,
    String? refRange,
    String? status,
    String? date,
    String? target,
    double? progressVal,
  }) {
    return LabEntry(
      id: id,
      metric: metric ?? this.metric,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      refRange: refRange ?? this.refRange,
      status: status ?? this.status,
      date: date ?? this.date,
      target: target ?? this.target,
      progressVal: progressVal ?? this.progressVal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'metric': metric,
      'value': value,
      'unit': unit,
      'refRange': refRange,
      'status': status,
      'date': date,
      'target': target,
      'progressVal': progressVal,
    };
  }

  static LabEntry fromMap(Map<String, dynamic> map) {
    return LabEntry(
      id: map['id'] as String,
      metric: map['metric'] as String,
      value: (map['value'] as num).toDouble(),
      unit: map['unit'] as String,
      refRange: map['refRange'] as String,
      status: map['status'] as String,
      date: map['date'] as String,
      target: map['target'] as String,
      progressVal: (map['progressVal'] as num).toDouble(),
    );
  }
}

class LabDraft {
  final String metric;
  final String value;
  final String unit;
  final String refRange;
  final String date;

  const LabDraft({
    required this.metric,
    required this.value,
    required this.unit,
    required this.refRange,
    required this.date,
  });
}
