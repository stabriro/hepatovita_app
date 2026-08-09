class LabHistoryEntity {
  final int? id;
  final String metric;
  final double value;
  final String unit;
  final String status;
  final String date;
  final String createdAt;

  const LabHistoryEntity({
    this.id,
    required this.metric,
    required this.value,
    required this.unit,
    required this.status,
    required this.date,
    required this.createdAt,
  });
}
