import 'package:file_picker/file_picker.dart';

import '../../data/app_database.dart';
import '../../features/dashboard/presentation/viewmodels/dashboard_view_model.dart';
import '../../features/meal_analyzer/presentation/viewmodels/meal_analyzer_view_model.dart';

class AppPersistenceCoordinator {
  final AppDatabase _database;

  AppPersistenceCoordinator({
    required AppDatabase database,
  }) : _database = database;

  Future<void> loadUiState({
    required DashboardViewModel dashboardViewModel,
    required MealAnalyzerViewModel mealAnalyzerViewModel,
  }) async {
    final snapshot = await _database.loadState();
    if (snapshot == null) {
      return;
    }

    dashboardViewModel.hydrateFromSnapshot(
      waterAmount: snapshot.waterAmount,
      greenTeaCount: snapshot.greenTeaCount,
      chkVitD: snapshot.chkVitD,
      walk30: snapshot.walk30,
      sun15: snapshot.sun15,
      lowFatDay: snapshot.lowFatDay,
    );
    mealAnalyzerViewModel.hydrateFromSnapshot(snapshot.analyzedResult);
  }

  Future<void> saveUiState({
    required DashboardViewModel dashboardViewModel,
    required MealAnalyzerViewModel mealAnalyzerViewModel,
    required List<Map<String, dynamic>> labs,
  }) async {
    final snapshot = AppSnapshot(
      waterAmount: dashboardViewModel.waterAmount,
      greenTeaCount: dashboardViewModel.greenTeaCount,
      chkVitD: dashboardViewModel.chkVitD,
      walk30: dashboardViewModel.walk30,
      sun15: dashboardViewModel.sun15,
      lowFatDay: dashboardViewModel.lowFatDay,
      analyzedResult: mealAnalyzerViewModel.analyzedResult,
      labs: labs,
    );
    await _database.saveState(snapshot);
  }

  Future<String> exportDatabase({
    required String defaultFileName,
    required String dialogTitle,
  }) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: ['hvbk'],
    );

    if (path == null) {
      throw _UserCancelledAction();
    }

    return _database.exportDatabaseTo(path);
  }

  Future<bool> importDatabaseFromPicker() async {
    final file = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['hvbk', 'db'],
      allowMultiple: false,
    );

    if (file == null || file.files.isEmpty || file.files.single.path == null) {
      return false;
    }

    await _database.importDatabaseFrom(file.files.single.path!);
    return true;
  }

  bool isUserCancelled(Object error) {
    return error is _UserCancelledAction;
  }
}

class _UserCancelledAction implements Exception {}
