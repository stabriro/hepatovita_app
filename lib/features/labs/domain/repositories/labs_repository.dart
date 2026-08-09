import '../entities/lab_entity.dart';
import '../entities/lab_history_entity.dart';

abstract class LabsRepository {
  Future<List<LabEntity>> loadLabs();
  Future<void> saveLabs(List<LabEntity> labs);

  Future<Map<String, List<LabHistoryEntity>>> loadLabHistoryGrouped();
  Future<void> addLabHistory(LabHistoryEntity entry);
  Future<void> deleteLabHistoryByMetric(String metric);
}
