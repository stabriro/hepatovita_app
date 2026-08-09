import '../../../../data/app_database.dart';
import '../models/lab_model.dart';

class LabsLocalDataSource {
  final AppDatabase db;

  const LabsLocalDataSource(this.db);

  Future<List<LabModel>> loadLabs() async {
    final snapshot = await db.loadState();
    if (snapshot == null) {
      return <LabModel>[];
    }
    return snapshot.labs.map(LabModel.fromMap).toList();
  }

  Future<void> saveLabs(List<LabModel> labs) async {
    final existing = await db.loadState();

    final snapshot = AppSnapshot(
      waterAmount: existing?.waterAmount ?? 1250,
      greenTeaCount: existing?.greenTeaCount ?? 1,
      chkVitD: existing?.chkVitD ?? true,
      walk30: existing?.walk30 ?? false,
      sun15: existing?.sun15 ?? false,
      lowFatDay: existing?.lowFatDay ?? true,
      analyzedResult: existing?.analyzedResult,
      labs: labs.map((e) => e.toMap()).toList(),
    );

    await db.saveState(snapshot);
  }

  Future<Map<String, List<LabHistoryEntry>>> loadLabHistoryGrouped() {
    return db.getAllLabHistoryGrouped();
  }

  Future<void> addLabHistory(LabHistoryEntry entry) {
    return db.addLabHistoryEntry(entry);
  }

  Future<void> deleteLabHistoryByMetric(String metric) {
    return db.deleteLabHistoryByMetric(metric);
  }
}
