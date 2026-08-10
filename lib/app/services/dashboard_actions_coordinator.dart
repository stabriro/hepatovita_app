import '../../features/dashboard/presentation/viewmodels/dashboard_view_model.dart';
import '../../features/meal_analyzer/presentation/viewmodels/meal_analyzer_view_model.dart';
import 'app_persistence_coordinator.dart';

class DashboardActionsCoordinator {
  final DashboardViewModel _dashboardViewModel;
  final MealAnalyzerViewModel _mealAnalyzerViewModel;
  final AppPersistenceCoordinator _persistenceCoordinator;

  DashboardActionsCoordinator({
    required DashboardViewModel dashboardViewModel,
    required MealAnalyzerViewModel mealAnalyzerViewModel,
    required AppPersistenceCoordinator persistenceCoordinator,
  })  : _dashboardViewModel = dashboardViewModel,
        _mealAnalyzerViewModel = mealAnalyzerViewModel,
        _persistenceCoordinator = persistenceCoordinator;

  Future<void> loadPersistedState() {
    return _persistenceCoordinator.loadUiState(
      dashboardViewModel: _dashboardViewModel,
      mealAnalyzerViewModel: _mealAnalyzerViewModel,
    );
  }

  Future<void> addWater({
    required int delta,
    required List<Map<String, dynamic>> labs,
  }) async {
    _dashboardViewModel.addWater(delta);
    await _persist(labs);
  }

  Future<void> changeTea({
    required int delta,
    required List<Map<String, dynamic>> labs,
  }) async {
    _dashboardViewModel.changeTea(delta);
    await _persist(labs);
  }

  Future<void> setChecklistValue({
    bool? chkVitD,
    bool? walk30,
    bool? sun15,
    bool? lowFatDay,
    required List<Map<String, dynamic>> labs,
  }) async {
    _dashboardViewModel.setChecklistValue(
      chkVitD: chkVitD,
      walk30: walk30,
      sun15: sun15,
      lowFatDay: lowFatDay,
    );
    await _persist(labs);
  }

  Future<void> analyzeMeal({
    required String mealName,
    required bool isAr,
    required List<Map<String, dynamic>> labs,
  }) async {
    _mealAnalyzerViewModel.analyzeMeal(
      mealName: mealName,
      isAr: isAr,
    );
    await _persist(labs);
  }

  Future<void> _persist(List<Map<String, dynamic>> labs) {
    return _persistenceCoordinator.saveUiState(
      dashboardViewModel: _dashboardViewModel,
      mealAnalyzerViewModel: _mealAnalyzerViewModel,
      labs: labs,
    );
  }
}
