import 'package:flutter/foundation.dart';

import '../../domain/entities/lab_alert_entity.dart';
import '../../domain/entities/lab_entity.dart';
import '../../domain/entities/lab_history_entity.dart';
import '../../domain/repositories/labs_repository.dart';
import '../../domain/usecases/evaluate_lab_goal_usecase.dart';
import '../../domain/usecases/generate_lab_alerts_usecase.dart';

class LabsViewModel extends ChangeNotifier {
  final LabsRepository _repository;
  final EvaluateLabGoalUseCase _evaluateLabGoal;
  final GenerateLabAlertsUseCase _generateLabAlerts;

  LabsViewModel({
    required LabsRepository repository,
    EvaluateLabGoalUseCase? evaluateLabGoal,
    GenerateLabAlertsUseCase? generateLabAlerts,
  })  : _repository = repository,
        _evaluateLabGoal = evaluateLabGoal ?? EvaluateLabGoalUseCase(),
        _generateLabAlerts = generateLabAlerts ??
            GenerateLabAlertsUseCase(evaluateLabGoal ?? EvaluateLabGoalUseCase());

  List<LabEntity> labs = <LabEntity>[];
  Map<String, List<LabHistoryEntity>> historyByMetric =
      <String, List<LabHistoryEntity>>{};
  List<LabAlertEntity> alerts = <LabAlertEntity>[];
  bool isLoading = false;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    labs = await _repository.loadLabs();
    historyByMetric = await _repository.loadLabHistoryGrouped();
    alerts = _generateLabAlerts(labs: labs, historyByMetric: historyByMetric);

    isLoading = false;
    notifyListeners();
  }

  Future<void> upsertLab(LabEntity lab) async {
    final index = labs.indexWhere((l) => l.id == lab.id);

    final evaluated = _evaluateLabGoal(lab);
    final updated = lab.copyWith(status: evaluated.status);

    if (index == -1) {
      labs = [...labs, updated];
    } else {
      final next = [...labs];
      next[index] = updated;
      labs = next;
    }

    await _repository.saveLabs(labs);
    await _repository.addLabHistory(
      LabHistoryEntity(
        metric: updated.metric,
        value: updated.value,
        unit: updated.unit,
        status: updated.status,
        date: updated.date,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    historyByMetric = await _repository.loadLabHistoryGrouped();
    alerts = _generateLabAlerts(labs: labs, historyByMetric: historyByMetric);
    notifyListeners();
  }

  Future<void> deleteLab(String labId) async {
    final lab = labs.firstWhere((l) => l.id == labId);
    labs = labs.where((l) => l.id != labId).toList();

    await _repository.saveLabs(labs);
    await _repository.deleteLabHistoryByMetric(lab.metric);

    historyByMetric = await _repository.loadLabHistoryGrouped();
    alerts = _generateLabAlerts(labs: labs, historyByMetric: historyByMetric);
    notifyListeners();
  }
}
