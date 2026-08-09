enum LabAlertSeverity { critical, warning, info }

class LabAlertEntity {
  final String metric;
  final LabAlertSeverity severity;
  final String code;

  const LabAlertEntity({
    required this.metric,
    required this.severity,
    required this.code,
  });
}
