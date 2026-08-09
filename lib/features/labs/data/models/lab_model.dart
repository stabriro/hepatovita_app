import '../../domain/entities/lab_entity.dart';

class LabModel {
  final String id;
  final String metric;
  final double value;
  final String unit;
  final String refRange;
  final String status;
  final String date;
  final String target;
  final double progressVal;

  const LabModel({
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

  factory LabModel.fromMap(Map<String, dynamic> map) {
    return LabModel(
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

  LabEntity toEntity() {
    return LabEntity(
      id: id,
      metric: metric,
      value: value,
      unit: unit,
      refRange: refRange,
      status: status,
      date: date,
      target: target,
      progressVal: progressVal,
    );
  }

  factory LabModel.fromEntity(LabEntity entity) {
    return LabModel(
      id: entity.id,
      metric: entity.metric,
      value: entity.value,
      unit: entity.unit,
      refRange: entity.refRange,
      status: entity.status,
      date: entity.date,
      target: entity.target,
      progressVal: entity.progressVal,
    );
  }
}
