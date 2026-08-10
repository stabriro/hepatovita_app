import '../data/app_database.dart';
import 'services/app_persistence_coordinator.dart';
import '../features/labs/data/datasources/labs_local_datasource.dart';
import '../features/labs/data/repositories/labs_repository_impl.dart';
import '../features/labs/domain/repositories/labs_repository.dart';
import '../features/labs/presentation/viewmodels/labs_view_model.dart';

class AppDi {
  AppDi._();

  static LabsRepository provideLabsRepository() {
    final dataSource = LabsLocalDataSource(AppDatabase.instance);
    return LabsRepositoryImpl(dataSource);
  }

  static LabsViewModel provideLabsViewModel() {
    return LabsViewModel(repository: provideLabsRepository());
  }

  static AppPersistenceCoordinator provideAppPersistenceCoordinator() {
    return AppPersistenceCoordinator(database: AppDatabase.instance);
  }
}
