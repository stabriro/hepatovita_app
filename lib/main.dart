import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app/di.dart';
import 'app/services/app_persistence_coordinator.dart';
import 'app/services/dashboard_actions_coordinator.dart';
import 'features/dashboard/presentation/views/dashboard_shell_widgets.dart';
import 'features/dashboard/presentation/views/overview_tab_view.dart';
import 'features/dashboard/presentation/viewmodels/dashboard_view_model.dart';
import 'features/education/presentation/views/education_tab_view.dart';
import 'features/labs/domain/entities/lab_entity.dart';
import 'features/labs/domain/entities/lab_history_entity.dart' as domain;
import 'features/labs/domain/usecases/evaluate_lab_goal_usecase.dart';
import 'features/labs/domain/usecases/generate_lab_alerts_usecase.dart';
import 'features/labs/presentation/presenters/lab_alert_presenter.dart';
import 'features/labs/presentation/views/labs_tab_view.dart';
import 'features/labs/presentation/viewmodels/labs_view_model.dart';
import 'features/meal_analyzer/presentation/views/meal_analyzer_tab_view.dart';
import 'features/meal_analyzer/presentation/viewmodels/meal_analyzer_view_model.dart';
import 'l10n/app_localizations.dart';
import 'services/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await LocalNotificationService.instance.init();
  runApp(const HepatoVitaApp());
}

class HepatoVitaApp extends StatefulWidget {
  const HepatoVitaApp({super.key});

  @override
  State<HepatoVitaApp> createState() => _HepatoVitaAppState();
}

class _HepatoVitaAppState extends State<HepatoVitaApp> {
  static const _kHasSeenSplash = 'has_seen_splash';

  Locale _locale = const Locale('en');
  bool _isBootstrapping = true;
  bool _showSplash = true;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    _initializeLaunchFlow();
  }

  Future<void> _initializeLaunchFlow() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenSplash = prefs.getBool(_kHasSeenSplash) ?? false;

    if (!mounted) {
      return;
    }

    if (hasSeenSplash) {
      setState(() {
        _isBootstrapping = false;
        _showSplash = false;
      });
      return;
    }

    setState(() {
      _isBootstrapping = false;
      _showSplash = true;
    });

    _splashTimer?.cancel();
    _splashTimer = Timer(const Duration(seconds: 2), _handleSplashContinue);
  }

  Future<void> _handleSplashContinue() async {
    if (!mounted || !_showSplash) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasSeenSplash, true);

    if (!mounted) {
      return;
    }

    setState(() {
      _showSplash = false;
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  void _toggleLanguage(String lang) {
    setState(() {
      _locale = Locale(lang);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _locale.languageCode == 'ar';
    return MaterialApp(
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'HepatoVita Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: isAr ? 'Cairo' : 'Plus Jakarta Sans',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF1B3B2B),
          secondary: const Color(0xFF2E7D32),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F7F4),
      ),
      home: Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          child: _isBootstrapping
              ? const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                )
              : _showSplash
              ? AppSplashScreen(
                  key: const ValueKey('splash'),
                  isAr: isAr,
                  onContinue: _handleSplashContinue,
                )
              : MainDashboardScreen(
                  key: const ValueKey('main_dashboard'),
                  lang: _locale.languageCode,
                  onLanguageChanged: _toggleLanguage,
                ),
        ),
      ),
    );
  }
}

class AppSplashScreen extends StatelessWidget {
  final bool isAr;
  final VoidCallback onContinue;

  const AppSplashScreen({
    super.key,
    required this.isAr,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2A20), Color(0xFF1B3B2B), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'HepatoVita',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: isAr ? 'Cairo' : 'Outfit',
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAr
                      ? 'مساعد ذكي لصحتك الكبدية والنمط اليومي'
                      : 'Smart companion for liver health and daily routine',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: onContinue,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(isAr ? 'ابدأ الآن' : 'Get Started'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1B3B2B),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LabEntry {
  final String id;
  final String metric;
  final double value;
  final String unit;
  final String refRange;
  final String status;
  final String date;
  final String target;
  final double progressVal;

  LabEntry({
    required this.id,
    required this.metric,
    required this.value,
    required this.unit,
    required this.refRange,
    required this.status,
    required this.date,
    required this.target,
    required this.progressVal,
  });

  LabEntry copyWith({
    String? metric,
    double? value,
    String? unit,
    String? refRange,
    String? status,
    String? date,
    String? target,
    double? progressVal,
  }) {
    return LabEntry(
      id: id,
      metric: metric ?? this.metric,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      refRange: refRange ?? this.refRange,
      status: status ?? this.status,
      date: date ?? this.date,
      target: target ?? this.target,
      progressVal: progressVal ?? this.progressVal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'metric': metric,
      'value': value,
      'unit': unit,
      'refRange': refRange,
      'status': status,
      'date': date,
      'target': target,
      'progressVal': progressVal,
    };
  }

  static LabEntry fromMap(Map<String, dynamic> map) {
    return LabEntry(
      id: map['id'] as String,
      metric: map['metric'] as String,
      value: (map['value'] as num).toDouble(),
      unit: map['unit'] as String,
      refRange: map['refRange'] as String,
      status: map['status'] as String,
      date: map['date'] as String,
      target: map['target'] as String,
      progressVal: (map['progressVal'] as num).toDouble(),
    );
  }
}

class MainDashboardScreen extends StatefulWidget {
  final String lang;
  final ValueChanged<String> onLanguageChanged;

  const MainDashboardScreen({
    super.key,
    required this.lang,
    required this.onLanguageChanged,
  });

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentTabIndex = 0;

  List<LabEntry> _labs = [
    LabEntry(
      id: 'l1',
      metric: 'ALT (SGPT)',
      value: 58,
      unit: 'U/L',
      refRange: '7-56 U/L',
      status: 'High',
      date: '2026-08-01',
      target: 'Target < 40 U/L via low-fat protocol',
      progressVal: 0.82,
    ),
    LabEntry(
      id: 'l2',
      metric: 'AST (SGOT)',
      value: 48,
      unit: 'U/L',
      refRange: '10-40 U/L',
      status: 'High',
      date: '2026-08-01',
      target: 'Target < 35 U/L via green tea EGCG',
      progressVal: 0.75,
    ),
    LabEntry(
      id: 'l3',
      metric: 'Vitamin D (25-OH)',
      value: 16,
      unit: 'ng/mL',
      refRange: '30-100 ng/mL',
      status: 'Low',
      date: '2026-08-01',
      target: 'Target > 30 ng/mL via D3 + healthy fats',
      progressVal: 0.28,
    ),
    LabEntry(
      id: 'l4',
      metric: 'Hemoglobin (Hgb)',
      value: 17.2,
      unit: 'g/dL',
      refRange: '13.8-17.2 g/dL',
      status: 'High',
      date: '2026-08-01',
      target: 'Target 15.0 g/dL via 3.0L daily water',
      progressVal: 0.88,
    ),
    LabEntry(
      id: 'l5',
      metric: 'HbA1C',
      value: 5.0,
      unit: '%',
      refRange: '< 5.7 %',
      status: 'Normal',
      date: '2026-08-01',
      target: 'Optimal baseline; sustain with low GI carbs',
      progressVal: 0.45,
    ),
  ];

  final TextEditingController _mealSearchController = TextEditingController();
  final DashboardViewModel _dashboardViewModel = DashboardViewModel();
  final MealAnalyzerViewModel _mealAnalyzerViewModel = MealAnalyzerViewModel();
  Map<String, List<domain.LabHistoryEntity>> _labHistoryByMetric = {};
  final Set<String> _shownCriticalAlertKeys = <String>{};
  final LabsViewModel _labsViewModel = AppDi.provideLabsViewModel();
  final AppPersistenceCoordinator _persistenceCoordinator =
      AppDi.provideAppPersistenceCoordinator();
  late final DashboardActionsCoordinator _dashboardActionsCoordinator =
      AppDi.provideDashboardActionsCoordinator(
        dashboardViewModel: _dashboardViewModel,
        mealAnalyzerViewModel: _mealAnalyzerViewModel,
        persistenceCoordinator: _persistenceCoordinator,
      );
  final EvaluateLabGoalUseCase _evaluateLabGoal = EvaluateLabGoalUseCase();
  final LabAlertPresenter _labAlertPresenter = const LabAlertPresenter();
  late final GenerateLabAlertsUseCase _generateLabAlertsUseCase =
      GenerateLabAlertsUseCase(_evaluateLabGoal);

  @override
  void initState() {
    super.initState();
    _dashboardViewModel.addListener(_onScreenStateChanged);
    _mealAnalyzerViewModel.addListener(_onScreenStateChanged);
    _labsViewModel.addListener(_onLabsViewModelChanged);
    _loadPersistedState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _labsViewModel.load();
    });
  }

  @override
  void dispose() {
    _dashboardViewModel.removeListener(_onScreenStateChanged);
    _mealAnalyzerViewModel.removeListener(_onScreenStateChanged);
    _labsViewModel.removeListener(_onLabsViewModelChanged);
    _mealSearchController.dispose();
    super.dispose();
  }

  void _onScreenStateChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _onLabsViewModelChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      _labs = _labsViewModel.labs.map(_fromLabEntity).toList();

      final grouped = <String, List<domain.LabHistoryEntity>>{};
      _labsViewModel.historyByMetric.forEach((metric, entries) {
        grouped[metric] = List<domain.LabHistoryEntity>.from(entries);
      });
      _labHistoryByMetric = grouped;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _maybeShowCriticalAlertPopup();
    });
  }

  LabEntity _toLabEntity(LabEntry entry) {
    return LabEntity(
      id: entry.id,
      metric: entry.metric,
      value: entry.value,
      unit: entry.unit,
      refRange: entry.refRange,
      status: entry.status,
      date: entry.date,
      target: entry.target,
      progressVal: entry.progressVal,
    );
  }

  LabEntry _fromLabEntity(LabEntity entity) {
    return LabEntry(
      id: entity.id,
      metric: entity.metric,
      value: entity.value,
      unit: entity.unit,
      refRange: entity.refRange,
      status: entity.status,
      date: entity.date,
      target: entity.target,
      progressVal: entity.progressVal,
    );
  }

  Future<void> _loadPersistedState() async {
    await _dashboardActionsCoordinator.loadPersistedState();
  }

  Future<void> _loadLabHistory() async {
    await _labsViewModel.load();
  }

  Future<void> _reloadAllData() async {
    await _loadPersistedState();
    await _loadLabHistory();
  }

  void _maybeShowCriticalAlertPopup() {
    if (!mounted) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    final criticalAlerts = _generateLabAlerts(l10n)
      .where((a) => a.severity == LabAlertUiSeverity.critical)
        .toList();

    if (criticalAlerts.isEmpty) {
      return;
    }

    LabAlertUiModel? nextAlert;
    String? alertKey;
    for (final alert in criticalAlerts) {
      final key = '${alert.metric}|${alert.message}';
      if (!_shownCriticalAlertKeys.contains(key)) {
        _shownCriticalAlertKeys.add(key);
        nextAlert = alert;
        alertKey = key;
        break;
      }
    }

    if (nextAlert == null) {
      return;
    }

    final popupText = l10n.tr('high_alert_popup', args: {'metric': nextAlert.metric});

    final notificationId = alertKey.hashCode.abs() % 2147483647;
    LocalNotificationService.instance.showCriticalAlert(
      id: notificationId,
      title: l10n.tr('high_alert_title'),
      body: popupText,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(popupText),
          backgroundColor: const Color(0xFFB91C1C),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: l10n.tr('view'),
            textColor: Colors.white,
            onPressed: () {
              if (!mounted) {
                return;
              }
              setState(() {
                _currentTabIndex = 2;
              });
            },
          ),
        ),
      );
    });
  }

  Future<void> _exportBackupFile() async {
    final l10n = AppLocalizations.of(context);
    try {
      final savedPath = await _persistenceCoordinator.exportDatabase(
        defaultFileName:
            'hepatovita_backup_${DateTime.now().toIso8601String().split('T').first}.db',
        dialogTitle: l10n.tr('save_sqlite_backup'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tr('backup_saved_to', args: {'path': savedPath}))),
      );
    } catch (e) {
      if (_persistenceCoordinator.isUserCancelled(e)) {
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tr('backup_failed', args: {'error': '$e'}))),
      );
    }
  }

  Future<void> _restoreBackupFile() async {
    final l10n = AppLocalizations.of(context);
    final selected = await _persistenceCoordinator.importDatabaseFromPicker();
    if (!selected) {
      return;
    }

    if (!mounted) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.tr('restore_backup_title')),
          content: Text(l10n.tr('restore_backup_message')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.tr('restore_action')),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await _reloadAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tr('restore_success'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tr('restore_failed', args: {'error': '$e'}))),
      );
    }
  }

  List<Map<String, dynamic>> _labsAsMapList() {
    return _labs.map((e) => e.toMap()).toList();
  }

  String _autoStatusFromRange(double value, String refRange) {
    final probe = LabEntity(
      id: 'tmp',
      metric: 'tmp',
      value: value,
      unit: '',
      refRange: refRange,
      status: 'Unknown',
      date: '',
      target: '',
      progressVal: 0,
    );
    return _evaluateLabGoal(probe).status;
  }

  String _targetLabel(double value, String refRange) {
    final l10n = AppLocalizations.of(context);
    final probe = LabEntity(
      id: 'tmp',
      metric: 'tmp',
      value: value,
      unit: '',
      refRange: refRange,
      status: 'Unknown',
      date: '',
      target: '',
      progressVal: 0,
    );
    final result = _evaluateLabGoal(probe).targetLabel;

    switch (result) {
      case 'On Target':
        return l10n.tr('on_target');
      case 'Off Target':
        return l10n.tr('off_target');
      default:
        return l10n.tr('target_unknown');
    }
  }

  String _trendLabel(LabEntry lab) {
    final l10n = AppLocalizations.of(context);
    final domainHistory =
        _labHistoryByMetric[lab.metric] ?? <domain.LabHistoryEntity>[];

    final trend =
        _generateLabAlertsUseCase.evaluateTrend(_toLabEntity(lab), domainHistory);

    switch (trend) {
      case 'Improving':
        return l10n.tr('improving');
      case 'Worsening':
        return l10n.tr('worsening');
      case 'Stable':
        return l10n.tr('stable');
      default:
        return l10n.tr('no_trend');
    }
  }

  Map<String, List<domain.LabHistoryEntity>> _toDomainHistoryByMetric() {
    return _labHistoryByMetric;
  }

  List<LabAlertUiModel> _generateLabAlerts(AppLocalizations l10n) {
    final domainLabs = _labs.map(_toLabEntity).toList();
    final domainHistoryByMetric = _toDomainHistoryByMetric();

    final domainAlerts = _generateLabAlertsUseCase(
      labs: domainLabs,
      historyByMetric: domainHistoryByMetric,
    );

    return _labAlertPresenter.mapToUi(
      l10n: l10n,
      domainAlerts: domainAlerts,
      labs: domainLabs,
    );
  }

  Future<void> _upsertLabEntry({int? index}) async {
    final l10n = AppLocalizations.of(context);
    final existing = index == null ? null : _labs[index];

    final metricController = TextEditingController(text: existing?.metric ?? '');
    final valueController = TextEditingController(text: existing?.value.toString() ?? '');
    final unitController = TextEditingController(text: existing?.unit ?? '');
    final refRangeController = TextEditingController(text: existing?.refRange ?? '');
    final dateController = TextEditingController(text: existing?.date ?? DateTime.now().toIso8601String().split('T').first);
    final targetController = TextEditingController(text: existing?.target ?? '');
    final progressController = TextEditingController(text: ((existing?.progressVal ?? 0.5) * 100).round().toString());
    String editedStatus = existing?.status ?? 'Normal';

    final didSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(existing == null ? 'Add New Lab' : 'Update ${existing.metric}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: metricController,
                  decoration: const InputDecoration(labelText: 'Metric Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: valueController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Value'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: unitController,
                  decoration: const InputDecoration(labelText: 'Unit (e.g. U/L)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: refRangeController,
                  decoration: const InputDecoration(labelText: 'Reference Range'),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.tr('status_auto'),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: targetController,
                  decoration: const InputDecoration(labelText: 'Target / Notes'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: progressController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Progress % (0-100)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (didSave == true) {
      final metric = metricController.text.trim();
      if (metric.isNotEmpty) {
        final parsedValue = double.tryParse(valueController.text.trim()) ?? (existing?.value ?? 0);
        final progressPct = double.tryParse(progressController.text.trim()) ?? ((existing?.progressVal ?? 0.5) * 100);
        final clampedProgress = (progressPct / 100).clamp(0.0, 1.0);
        final parsedDate = dateController.text.trim().isEmpty
            ? (existing?.date ?? DateTime.now().toIso8601String().split('T').first)
            : dateController.text.trim();

        final resolvedRefRange = refRangeController.text.trim().isEmpty ? (existing?.refRange ?? '') : refRangeController.text.trim();
        editedStatus = _autoStatusFromRange(parsedValue, resolvedRefRange);

        final updated = LabEntry(
          id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
          metric: metric,
          value: parsedValue,
          unit: unitController.text.trim().isEmpty ? (existing?.unit ?? '') : unitController.text.trim(),
          refRange: resolvedRefRange,
          status: editedStatus,
          date: parsedDate,
          target: targetController.text.trim().isEmpty ? (existing?.target ?? '') : targetController.text.trim(),
          progressVal: clampedProgress,
        );

        await _labsViewModel.upsertLab(_toLabEntity(updated));
      }
    }

    metricController.dispose();
    valueController.dispose();
    unitController.dispose();
    refRangeController.dispose();
    dateController.dispose();
    targetController.dispose();
    progressController.dispose();
  }

  Future<void> _deleteLabEntry(int index) async {
    final lab = _labs[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Lab?'),
          content: Text('Remove ${lab.metric} from your records?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _labsViewModel.deleteLab(lab.id);
    }
  }

  Future<void> _addLabResult(LabEntry lab) async {
    final l10n = AppLocalizations.of(context);
    final valueController = TextEditingController(text: lab.value.toString());
    final dateController = TextEditingController(text: DateTime.now().toIso8601String().split('T').first);
    String editedStatus = lab.status;

    final didSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Add Result: ${lab.metric}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: valueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Value (${lab.unit})'),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.tr('status_auto'),
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save Result'),
            ),
          ],
        );
      },
    );

    if (didSave == true) {
      final parsedValue = double.tryParse(valueController.text.trim()) ?? lab.value;
      final parsedDate = dateController.text.trim().isEmpty ? DateTime.now().toIso8601String().split('T').first : dateController.text.trim();
      editedStatus = _autoStatusFromRange(parsedValue, lab.refRange);

      final updated = lab.copyWith(
        value: parsedValue,
        status: editedStatus,
        date: parsedDate,
      );
      await _labsViewModel.upsertLab(_toLabEntity(updated));
    }

    valueController.dispose();
    dateController.dispose();
  }

  Future<void> _addWater(int delta) async {
    await _dashboardActionsCoordinator.addWater(
      delta: delta,
      labs: _labsAsMapList(),
    );
  }

  Future<void> _changeTea(int delta) async {
    await _dashboardActionsCoordinator.changeTea(
      delta: delta,
      labs: _labsAsMapList(),
    );
  }

  Future<void> _setChecklistValue({
    bool? chkVitD,
    bool? walk30,
    bool? sun15,
    bool? lowFatDay,
  }) async {
    await _dashboardActionsCoordinator.setChecklistValue(
      chkVitD: chkVitD,
      walk30: walk30,
      sun15: sun15,
      lowFatDay: lowFatDay,
      labs: _labsAsMapList(),
    );
  }

  Future<void> _analyzeMeal(String mealName) async {
    await _dashboardActionsCoordinator.analyzeMeal(
      mealName: mealName,
      isAr: widget.lang == 'ar',
      labs: _labsAsMapList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.lang == 'ar';
    final score = _dashboardViewModel.score;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(isAr),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  children: [
                    _buildModernHeroScoreCard(score, isAr),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildActiveTabContent(isAr),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        onDestinationSelected: _goToTab,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_rounded),
            label: isAr ? 'الرئيسية' : 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.restaurant_menu_rounded),
            label: isAr ? 'الوجبات' : 'Meals',
          ),
          NavigationDestination(
            icon: const Icon(Icons.science_rounded),
            label: isAr ? 'التحاليل' : 'Labs',
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_rounded),
            label: isAr ? 'التثقيف' : 'Education',
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent(bool isAr) {
    switch (_currentTabIndex) {
      case 0:
        return _buildModernOverviewTab(isAr);
      case 1:
        return _buildModernMealAnalyzerTab(isAr);
      case 2:
        return _buildModernLabsTab(isAr);
      case 3:
        return _buildModernEducationTab(isAr);
      default:
        return _buildModernOverviewTab(isAr);
    }
  }

  Widget _buildModernHeader(bool isAr) {
    return DashboardHeader(
      isAr: isAr,
      lang: widget.lang,
      onLanguageChanged: widget.onLanguageChanged,
    );
  }

  Widget _buildModernHeroScoreCard(int score, bool isAr) {
    return DashboardHeroScoreCard(
      score: score,
      isAr: isAr,
    );
  }

  void _goToTab(int index) {
    setState(() {
      _currentTabIndex = index;
    });
    if (index == 2) {
      _maybeShowCriticalAlertPopup();
    }
  }

  Widget _buildModernOverviewTab(bool isAr) {
    return OverviewTabView(
      isAr: isAr,
      waterAmount: _dashboardViewModel.waterAmount,
      waterGoal: _dashboardViewModel.waterGoal,
      greenTeaCount: _dashboardViewModel.greenTeaCount,
      teaGoal: _dashboardViewModel.teaGoal,
      chkVitD: _dashboardViewModel.chkVitD,
      walk30: _dashboardViewModel.walk30,
      sun15: _dashboardViewModel.sun15,
      lowFatDay: _dashboardViewModel.lowFatDay,
      onAddWater: _addWater,
      onChangeTea: _changeTea,
      onChkVitDChanged: (value) => _setChecklistValue(chkVitD: value),
      onWalk30Changed: (value) => _setChecklistValue(walk30: value),
      onSun15Changed: (value) => _setChecklistValue(sun15: value),
      onLowFatDayChanged: (value) => _setChecklistValue(lowFatDay: value),
    );
  }

  Widget _buildModernMealAnalyzerTab(bool isAr) {
    return MealAnalyzerTabView(
      isAr: isAr,
      mealSearchController: _mealSearchController,
      onAnalyzeMeal: _analyzeMeal,
      analysis: _toMealAnalysisUiModel(),
    );
  }

  MealAnalysisUiModel? _toMealAnalysisUiModel() {
    final raw = _mealAnalyzerViewModel.analyzedResult;
    if (raw == null) {
      return null;
    }

    return MealAnalysisUiModel(
      dish: (raw['dish'] ?? '').toString(),
      score: (raw['score'] ?? '').toString(),
      protein: (raw['protein'] ?? '').toString(),
      fat: (raw['fat'] ?? '').toString(),
      tips: ((raw['tips'] as List<dynamic>? ?? const <dynamic>[]).map((e) => e.toString()).toList()),
    );
  }

  List<LabsTabLabItem> _toLabsTabLabItems() {
    return _labs
        .map(
          (lab) => LabsTabLabItem(
            metric: lab.metric,
            value: lab.value,
            unit: lab.unit,
            refRange: lab.refRange,
            status: lab.status,
            target: lab.target,
            progressVal: lab.progressVal,
            targetLabel: _targetLabel(lab.value, lab.refRange),
            trendLabel: _trendLabel(lab),
          ),
        )
        .toList();
  }

  Map<String, List<LabsTabHistoryItem>> _toLabsTabHistoryByMetric() {
    final uiHistoryByMetric = <String, List<LabsTabHistoryItem>>{};
    _labHistoryByMetric.forEach((metric, entries) {
      uiHistoryByMetric[metric] = entries
          .map(
            (e) => LabsTabHistoryItem(
              value: e.value,
              unit: e.unit,
              date: e.date,
            ),
          )
          .toList();
    });
    return uiHistoryByMetric;
  }

  Widget _buildModernLabsTab(bool isAr) {
    final l10n = AppLocalizations.of(context);
    return LabsTabView(
      isAr: isAr,
      labs: _toLabsTabLabItems(),
      historyByMetric: _toLabsTabHistoryByMetric(),
      alerts: _generateLabAlerts(l10n),
      onExportBackup: _exportBackupFile,
      onRestoreBackup: _restoreBackupFile,
      onAddLab: () => _upsertLabEntry(),
      onEditLab: (index) => _upsertLabEntry(index: index),
      onDeleteLab: _deleteLabEntry,
      onAddResult: (index) => _addLabResult(_labs[index]),
    );
  }

  Widget _buildModernEducationTab(bool isAr) {
    return EducationTabView(isAr: isAr);
  }
}

