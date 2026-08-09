import '../entities/lab_alert_entity.dart';
import '../entities/lab_entity.dart';
import '../entities/lab_history_entity.dart';
import 'evaluate_lab_goal_usecase.dart';

class GenerateLabAlertsUseCase {
  final EvaluateLabGoalUseCase _evaluateLabGoal;

  const GenerateLabAlertsUseCase(this._evaluateLabGoal);

  double _distanceToTarget(double value, GoalRange range) {
    if (range.isWithin(value)) {
      return 0;
    }

    switch (range.type) {
      case GoalRangeType.between:
        return value < range.min! ? (range.min! - value) : (value - range.max!);
      case GoalRangeType.upper:
        return value <= range.upper! ? 0 : (value - range.upper!);
      case GoalRangeType.lower:
        return value >= range.lower! ? 0 : (range.lower! - value);
    }
  }

  String evaluateTrend(LabEntity lab, List<LabHistoryEntity> history) {
    final range = _evaluateLabGoal.parseRange(lab.refRange);
    if (range == null || history.length < 2) {
      return 'No Trend';
    }

    final firstDistance = _distanceToTarget(history.first.value, range);
    final lastDistance = _distanceToTarget(history.last.value, range);
    const epsilon = 0.0001;

    if ((firstDistance - lastDistance).abs() <= epsilon) {
      return 'Stable';
    }
    return lastDistance < firstDistance ? 'Improving' : 'Worsening';
  }

  List<LabAlertEntity> call({
    required List<LabEntity> labs,
    required Map<String, List<LabHistoryEntity>> historyByMetric,
  }) {
    final alerts = <LabAlertEntity>[];

    for (final lab in labs) {
      final goal = _evaluateLabGoal(lab);
      final trend = evaluateTrend(lab, historyByMetric[lab.metric] ?? const []);

      if (goal.targetLabel == 'Off Target' && trend == 'Worsening') {
        alerts.add(const LabAlertEntity(
          metric: '',
          severity: LabAlertSeverity.critical,
          code: 'OFF_TARGET_WORSENING',
        ).copy(metric: lab.metric));
      } else if (goal.targetLabel == 'Off Target' &&
          (trend == 'Stable' || trend == 'No Trend')) {
        alerts.add(const LabAlertEntity(
          metric: '',
          severity: LabAlertSeverity.warning,
          code: 'OFF_TARGET',
        ).copy(metric: lab.metric));
      } else if (goal.targetLabel == 'Target Unknown') {
        alerts.add(const LabAlertEntity(
          metric: '',
          severity: LabAlertSeverity.warning,
          code: 'TARGET_UNKNOWN',
        ).copy(metric: lab.metric));
      } else if (goal.targetLabel == 'On Target' && trend == 'Improving') {
        alerts.add(const LabAlertEntity(
          metric: '',
          severity: LabAlertSeverity.info,
          code: 'ON_TARGET_IMPROVING',
        ).copy(metric: lab.metric));
      }
    }

    alerts.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    return alerts;
  }
}

extension on LabAlertEntity {
  LabAlertEntity copy({
    String? metric,
    LabAlertSeverity? severity,
    String? code,
  }) {
    return LabAlertEntity(
      metric: metric ?? this.metric,
      severity: severity ?? this.severity,
      code: code ?? this.code,
    );
  }
}
