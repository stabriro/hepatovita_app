import '../../../../data/app_database.dart';
import '../../domain/entities/lab_entity.dart';
import '../../domain/entities/lab_history_entity.dart';
import '../../domain/repositories/labs_repository.dart';
import '../datasources/labs_local_datasource.dart';
import '../models/lab_model.dart';

class LabsRepositoryImpl implements LabsRepository {
  final LabsLocalDataSource local;

  const LabsRepositoryImpl(this.local);

  @override
  Future<List<LabEntity>> loadLabs() async {
    final models = await local.loadLabs();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> saveLabs(List<LabEntity> labs) async {
    final models = labs.map(LabModel.fromEntity).toList();
    await local.saveLabs(models);
  }

  @override
  Future<Map<String, List<LabHistoryEntity>>> loadLabHistoryGrouped() async {
    final grouped = await local.loadLabHistoryGrouped();
    final output = <String, List<LabHistoryEntity>>{};

    grouped.forEach((metric, entries) {
      output[metric] = entries
          .map((e) => LabHistoryEntity(
                id: e.id,
                metric: e.metric,
                value: e.value,
                unit: e.unit,
                status: e.status,
                date: e.date,
                createdAt: e.createdAt,
              ))
          .toList();
    });

    return output;
  }

  @override
  Future<void> addLabHistory(LabHistoryEntity entry) {
    return local.addLabHistory(
      LabHistoryEntry(
        id: entry.id,
        metric: entry.metric,
        value: entry.value,
        unit: entry.unit,
        status: entry.status,
        date: entry.date,
        createdAt: entry.createdAt,
      ),
    );
  }

  @override
  Future<void> deleteLabHistoryByMetric(String metric) {
    return local.deleteLabHistoryByMetric(metric);
  }
}
