import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/app_database.dart';
import 'l10n/app_localizations.dart';
import 'services/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService.instance.init();
  runApp(const HepatoVitaApp());
}

class HepatoVitaApp extends StatefulWidget {
  const HepatoVitaApp({super.key});

  @override
  State<HepatoVitaApp> createState() => _HepatoVitaAppState();
}

class _HepatoVitaAppState extends State<HepatoVitaApp> {
  Locale _locale = const Locale('en');

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
          background: const Color(0xFFF3F7F4),
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F7F4),
      ),
      home: Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: MainDashboardScreen(
          lang: _locale.languageCode,
          onLanguageChanged: _toggleLanguage,
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

  int _waterAmount = 1250;
  final int _waterGoal = 3000;
  int _greenTeaCount = 1;
  final int _teaGoal = 3;

  bool _chkVitD = true;
  bool _walk30 = false;
  bool _sun15 = false;
  bool _lowFatDay = true;

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
  Map<String, dynamic>? _analyzedResult;
  Map<String, List<LabHistoryEntry>> _labHistoryByMetric = {};
  final Set<String> _shownCriticalAlertKeys = <String>{};

  static final RegExp _rangePattern = RegExp(r'(-?\d+(?:\.\d+)?)\s*-\s*(-?\d+(?:\.\d+)?)');
  static final RegExp _ltPattern = RegExp(r'<\s*(-?\d+(?:\.\d+)?)');
  static final RegExp _gtPattern = RegExp(r'>\s*(-?\d+(?:\.\d+)?)');

  @override
  void initState() {
    super.initState();
    _loadPersistedState();
    _loadLabHistory();
  }

  @override
  void dispose() {
    _mealSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadPersistedState() async {
    final snapshot = await AppDatabase.instance.loadState();
    if (!mounted || snapshot == null) {
      return;
    }

    setState(() {
      _waterAmount = snapshot.waterAmount;
      _greenTeaCount = snapshot.greenTeaCount;
      _chkVitD = snapshot.chkVitD;
      _walk30 = snapshot.walk30;
      _sun15 = snapshot.sun15;
      _lowFatDay = snapshot.lowFatDay;
      _analyzedResult = snapshot.analyzedResult;
      _labs = snapshot.labs.map(LabEntry.fromMap).toList();
    });
  }

  Future<void> _loadLabHistory() async {
    final grouped = await AppDatabase.instance.getAllLabHistoryGrouped();
    if (!mounted) {
      return;
    }
    setState(() {
      _labHistoryByMetric = grouped;
    });

    _maybeShowCriticalAlertPopup();
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
        .where((a) => a.severity == _LabAlertSeverity.critical)
        .toList();

    if (criticalAlerts.isEmpty) {
      return;
    }

    _LabAlert? nextAlert;
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
    final defaultFileName = 'hepatovita_backup_${DateTime.now().toIso8601String().split('T').first}.db';
    final path = await FilePicker.platform.saveFile(
      dialogTitle: l10n.tr('save_sqlite_backup'),
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: ['db'],
    );

    if (path == null) {
      return;
    }

    try {
      final savedPath = await AppDatabase.instance.exportDatabaseTo(path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tr('backup_saved_to', args: {'path': savedPath}))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tr('backup_failed', args: {'error': '$e'}))),
      );
    }
  }

  Future<void> _restoreBackupFile() async {
    final l10n = AppLocalizations.of(context);
    final file = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db'],
      allowMultiple: false,
    );

    if (file == null || file.files.isEmpty || file.files.single.path == null) {
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
      await AppDatabase.instance.importDatabaseFrom(file.files.single.path!);
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

  Future<void> _savePersistedState() async {
    final snapshot = AppSnapshot(
      waterAmount: _waterAmount,
      greenTeaCount: _greenTeaCount,
      chkVitD: _chkVitD,
      walk30: _walk30,
      sun15: _sun15,
      lowFatDay: _lowFatDay,
      analyzedResult: _analyzedResult,
      labs: _labs.map((e) => e.toMap()).toList(),
    );
    await AppDatabase.instance.saveState(snapshot);
  }

  _GoalRange? _parseGoalRange(String refRange) {
    final rangeMatch = _rangePattern.firstMatch(refRange);
    if (rangeMatch != null) {
      final min = double.tryParse(rangeMatch.group(1)!);
      final max = double.tryParse(rangeMatch.group(2)!);
      if (min != null && max != null) {
        return _GoalRange.between(min: min, max: max);
      }
    }

    final ltMatch = _ltPattern.firstMatch(refRange);
    if (ltMatch != null) {
      final threshold = double.tryParse(ltMatch.group(1)!);
      if (threshold != null) {
        return _GoalRange.upper(threshold: threshold);
      }
    }

    final gtMatch = _gtPattern.firstMatch(refRange);
    if (gtMatch != null) {
      final threshold = double.tryParse(gtMatch.group(1)!);
      if (threshold != null) {
        return _GoalRange.lower(threshold: threshold);
      }
    }

    return null;
  }

  String _autoStatusFromRange(double value, String refRange) {
    final range = _parseGoalRange(refRange);
    if (range == null) {
      return 'Unknown';
    }
    if (range.isWithin(value)) {
      return 'Normal';
    }

    if (range.type == _GoalRangeType.lower) {
      return 'Low';
    }
    if (range.type == _GoalRangeType.upper) {
      return 'High';
    }

    return value < range.min! ? 'Low' : 'High';
  }

  String _targetLabel(double value, String refRange) {
    final l10n = AppLocalizations.of(context);
    final range = _parseGoalRange(refRange);
    if (range == null) {
      return l10n.tr('target_unknown');
    }
    return range.isWithin(value) ? l10n.tr('on_target') : l10n.tr('off_target');
  }

  double _distanceToTarget(double value, _GoalRange range) {
    if (range.isWithin(value)) {
      return 0;
    }

    switch (range.type) {
      case _GoalRangeType.between:
        return value < range.min! ? (range.min! - value) : (value - range.max!);
      case _GoalRangeType.upper:
        return value <= range.upper! ? 0 : (value - range.upper!);
      case _GoalRangeType.lower:
        return value >= range.lower! ? 0 : (range.lower! - value);
    }
  }

  String _trendLabel(LabEntry lab) {
    final l10n = AppLocalizations.of(context);
    final range = _parseGoalRange(lab.refRange);
    if (range == null) {
      return l10n.tr('no_trend');
    }

    final history = _labHistoryByMetric[lab.metric] ?? <LabHistoryEntry>[];
    if (history.length < 2) {
      return l10n.tr('no_trend');
    }

    final firstDistance = _distanceToTarget(history.first.value, range);
    final lastDistance = _distanceToTarget(history.last.value, range);
    const epsilon = 0.0001;

    if ((firstDistance - lastDistance).abs() <= epsilon) {
      return l10n.tr('stable');
    }
    return lastDistance < firstDistance ? l10n.tr('improving') : l10n.tr('worsening');
  }

  List<_LabAlert> _generateLabAlerts(AppLocalizations l10n) {
    final alerts = <_LabAlert>[];

    for (final lab in _labs) {
      final target = _targetLabel(lab.value, lab.refRange);
      final trend = _trendLabel(lab);

      if (target == l10n.tr('off_target') && trend == l10n.tr('worsening')) {
        alerts.add(
          _LabAlert(
            metric: lab.metric,
            severity: _LabAlertSeverity.critical,
            title: l10n.tr('alert_worsening_title', args: {'metric': lab.metric}),
            message: l10n.tr('alert_worsening_message', args: {'value': '${lab.value}', 'unit': lab.unit}),
          ),
        );
        continue;
      }

      if (target == l10n.tr('off_target') && (trend == l10n.tr('stable') || trend == l10n.tr('no_trend'))) {
        alerts.add(
          _LabAlert(
            metric: lab.metric,
            severity: _LabAlertSeverity.warning,
            title: l10n.tr('alert_off_target_title', args: {'metric': lab.metric}),
            message: l10n.tr('alert_off_target_message'),
          ),
        );
        continue;
      }

      if (target == l10n.tr('target_unknown')) {
        alerts.add(
          _LabAlert(
            metric: lab.metric,
            severity: _LabAlertSeverity.warning,
            title: l10n.tr('alert_unknown_target_title', args: {'metric': lab.metric}),
            message: l10n.tr('alert_unknown_target_message'),
          ),
        );
        continue;
      }

      if (target == l10n.tr('on_target') && trend == l10n.tr('improving')) {
        alerts.add(
          _LabAlert(
            metric: lab.metric,
            severity: _LabAlertSeverity.info,
            title: l10n.tr('alert_good_title', args: {'metric': lab.metric}),
            message: l10n.tr('alert_good_message'),
          ),
        );
      }
    }

    alerts.sort((a, b) => b.severity.priority.compareTo(a.severity.priority));
    return alerts;
  }

  Widget _buildAlertsPanel(bool isAr) {
    final l10n = AppLocalizations.of(context);
    final alerts = _generateLabAlerts(l10n);
    if (alerts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Text(
          l10n.tr('alerts_none'),
          style: TextStyle(fontSize: 11, color: Colors.green.shade900, fontWeight: FontWeight.w600),
        ),
      );
    }

    return Column(
      children: alerts.map((alert) {
        final style = _alertVisuals(alert.severity);
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: style.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: style.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(style.icon, color: style.foreground, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: style.foreground),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alert.message,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  _AlertVisuals _alertVisuals(_LabAlertSeverity severity) {
    switch (severity) {
      case _LabAlertSeverity.critical:
        return _AlertVisuals(
          icon: Icons.warning_amber_rounded,
          background: const Color(0xFFFFF1F2),
          border: const Color(0xFFFDA4AF),
          foreground: const Color(0xFFB91C1C),
        );
      case _LabAlertSeverity.warning:
        return _AlertVisuals(
          icon: Icons.error_outline_rounded,
          background: const Color(0xFFFFF7ED),
          border: const Color(0xFFFDBA74),
          foreground: const Color(0xFF9A3412),
        );
      case _LabAlertSeverity.info:
        return _AlertVisuals(
          icon: Icons.check_circle_outline_rounded,
          background: const Color(0xFFECFEFF),
          border: const Color(0xFF67E8F9),
          foreground: const Color(0xFF155E75),
        );
    }
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

        final shouldStoreHistory = existing == null ||
            existing.metric != updated.metric ||
            existing.value != updated.value ||
            existing.status != updated.status ||
            existing.date != updated.date;

        setState(() {
          if (index == null) {
            _labs.add(updated);
          } else {
            _labs[index] = updated;
          }
        });
        await _savePersistedState();

        if (shouldStoreHistory) {
          await AppDatabase.instance.addLabHistoryEntry(
            LabHistoryEntry(
              metric: updated.metric,
              value: updated.value,
              unit: updated.unit,
              status: updated.status,
              date: parsedDate,
              createdAt: DateTime.now().toIso8601String(),
            ),
          );
          await _loadLabHistory();
        }
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
      final metric = lab.metric;
      setState(() {
        _labs.removeAt(index);
      });
      await _savePersistedState();
      await AppDatabase.instance.deleteLabHistoryByMetric(metric);
      await _loadLabHistory();
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

      await AppDatabase.instance.addLabHistoryEntry(
        LabHistoryEntry(
          metric: lab.metric,
          value: parsedValue,
          unit: lab.unit,
          status: editedStatus,
          date: parsedDate,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      setState(() {
        final index = _labs.indexWhere((e) => e.id == lab.id);
        if (index != -1) {
          _labs[index] = _labs[index].copyWith(
            value: parsedValue,
            status: editedStatus,
            date: parsedDate,
          );
        }
      });

      await _savePersistedState();
      await _loadLabHistory();
    }

    valueController.dispose();
    dateController.dispose();
  }

  int _calculateScore() {
    final waterPct = (_waterAmount / _waterGoal).clamp(0.0, 1.0);
    int chkDone = 0;
    if (_chkVitD) chkDone++;
    if (_walk30) chkDone++;
    if (_sun15) chkDone++;
    if (_lowFatDay) chkDone++;
    final chkPct = chkDone / 4.0;
    final teaPct = (_greenTeaCount / _teaGoal).clamp(0.0, 1.0);

    return ((waterPct * 40) + (chkPct * 40) + (teaPct * 20)).round();
  }

  Future<void> _addWater(int delta) async {
    setState(() {
      _waterAmount = (_waterAmount + delta).clamp(0, 5000);
    });
    await _savePersistedState();
  }

  Future<void> _changeTea(int delta) async {
    setState(() {
      _greenTeaCount = (_greenTeaCount + delta).clamp(0, 10);
    });
    await _savePersistedState();
  }

  Future<void> _setChecklistValue({
    bool? chkVitD,
    bool? walk30,
    bool? sun15,
    bool? lowFatDay,
  }) async {
    setState(() {
      if (chkVitD != null) _chkVitD = chkVitD;
      if (walk30 != null) _walk30 = walk30;
      if (sun15 != null) _sun15 = sun15;
      if (lowFatDay != null) _lowFatDay = lowFatDay;
    });
    await _savePersistedState();
  }

  Future<void> _analyzeMeal(String mealName) async {
    if (mealName.trim().isEmpty) return;
    final isAr = widget.lang == 'ar';
    final textLower = mealName.toLowerCase();

    bool hasRed = false;
    bool hasGreen = false;

    final redKeywords = ['fried', 'shawarma', 'burger', 'mayo', 'fries', 'crispy', 'مقلي', 'شاورما', 'برجر', 'مايونيز', 'ثومية'];
    final greenKeywords = ['grilled', 'salmon', 'salad', 'steamed', 'quinoa', 'olive oil', 'مشوي', 'سلمون', 'سلطة', 'مسلوق', 'كينوا', 'زيت زيتون'];

    for (var k in redKeywords) {
      if (textLower.contains(k)) hasRed = true;
    }
    for (var k in greenKeywords) {
      if (textLower.contains(k)) hasGreen = true;
    }

    String score = 'HIGH';
    if (hasRed) {
      score = 'LOW';
    } else if (!hasGreen) {
      score = 'MEDIUM';
    }

    List<String> tips = [];
    if (textLower.contains('shawarma') || textLower.contains('شاورما')) {
      tips.add(isAr ? 'اطلب الثومية أو المايونيز جانباً واستبدلهما بالليمون والطحينة الخفيفة.' : 'Request garlic paste / mayo on the side; substitute with lemon & tahini.');
      tips.add(isAr ? 'اختر صحن دجاج مشوي بدلاً من الساندويتش المحشو بالبطاطس المقلية.' : 'Opt for grilled chicken platter over fries-stuffed wrap.');
    } else if (textLower.contains('fried') || textLower.contains('مقلي')) {
      tips.add(isAr ? 'اسأل عن إمكانية تحضير خيار مشوي أو مسلوق بدلاً من المقلي.' : 'Ask for a grilled or baked alternative.');
      tips.add(isAr ? 'أزل الجلد المقرمش المقلي لتقليل 60% من الدهون المتحولة الضارة بالإجهاد الكبدي.' : 'Remove crispy fried skin to cut 60%+ trans-fats.');
    } else {
      tips.add(isAr ? 'وجبة ممتازة وصديقة للكبد! لا تتطلب تعديلات رئيسية.' : 'Excellent liver friendly option! Requires zero modifications.');
    }

    setState(() {
      _analyzedResult = {
        'dish': mealName,
        'score': score,
        'protein': (textLower.contains('salmon') || textLower.contains('chicken') || textLower.contains('دجاج') || textLower.contains('سلمون'))
            ? (isAr ? 'بروتين صافي ممتاز' : 'Lean Protein')
            : (isAr ? 'بروتين متوسط' : 'Moderate Protein'),
        'fat': score == 'LOW' ? (isAr ? 'دهون مشبعة مرتفعة' : 'High Saturated Trans-Fat') : (isAr ? 'دهون غير مشبعة منخفضة' : 'Low Saturated Fat'),
        'tips': tips
      };
    });
    await _savePersistedState();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.lang == 'ar';
    final score = _calculateScore();

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
                    _buildSegmentedTabBar(isAr),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1B3B2B),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: const Icon(Icons.eco_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Hepato',
                        style: TextStyle(
                          fontFamily: isAr ? 'Cairo' : 'Outfit',
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Vita',
                        style: TextStyle(
                          fontFamily: isAr ? 'Cairo' : 'Outfit',
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: const Color(0xFF81C784),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    isAr ? 'رفيقك الصحي والسريري الكبدي' : 'Metabolic & Liver Companion',
                    style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => widget.onLanguageChanged('en'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.lang == 'en' ? const Color(0xFF2E7D32) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('EN', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                GestureDetector(
                  onTap: () => widget.onLanguageChanged('ar'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.lang == 'ar' ? const Color(0xFF2E7D32) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('العربية', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildModernHeroScoreCard(int score, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B3B2B), Color(0xFF0F261B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B3B2B).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isAr ? 'الملف الصحي والسريري للمريض' : 'Clinical Patient Profile',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade900.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade400.withOpacity(0.4)),
                          ),
                          child: Text(
                            isAr ? 'مخصص' : 'Targeted',
                            style: const TextStyle(color: Color(0xFF81C784), fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAr ? 'أهداف علاجية مخصصة بناءً على نتائج تحاليلك' : 'Therapeutic protocol built for your biomarkers',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      value: score / 100.0,
                      strokeWidth: 6,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        score >= 80 ? const Color(0xFF81C784) : (score >= 50 ? Colors.amber : Colors.orangeAccent),
                      ),
                    ),
                  ),
                  Text(
                    '$score%',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                  )
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildModernPillarTag('ALT 58', isAr ? 'إنزيم الكبد' : 'ALT / AST', Colors.amber),
                _buildModernPillarTag('16 ng/mL', isAr ? 'فيتامين د' : 'Vitamin D', Colors.purpleAccent),
                _buildModernPillarTag('3.0L Water', isAr ? 'ترطيب Hgb' : 'Hgb Hydration', Colors.lightBlueAccent),
                _buildModernPillarTag('5.0%', isAr ? 'التراكمي' : 'HbA1C', const Color(0xFF81C784)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildModernPillarTag(String val, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Text(val, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSegmentedTabBar(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabSegment(0, isAr ? 'الرئيسية والمتتبعات' : 'Dashboard', Icons.dashboard_rounded),
            _buildTabSegment(1, isAr ? 'مُحلل الوجبات' : 'Meal Analyzer', Icons.restaurant_rounded),
            _buildTabSegment(2, isAr ? 'الفحوصات' : 'Biomarkers', Icons.science_rounded),
            _buildTabSegment(3, isAr ? 'الدليل الطبي' : 'Guidance', Icons.menu_book_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSegment(int index, String title, IconData icon) {
    final active = _currentTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentTabIndex = index);
        if (index == 2) {
          _maybeShowCriticalAlertPopup();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2E7D32) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: active ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFF334155),
                fontWeight: active ? FontWeight.bold : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernOverviewTab(bool isAr) {
    final waterPct = (_waterAmount / _waterGoal).clamp(0.0, 1.0);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.lightBlue.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.water_drop_rounded, color: Colors.lightBlue, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'مُتتبع شُرب الماء (3.0 لتر)' : '3.0L Hydration Station',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3B2B)),
                          ),
                          Text(
                            isAr ? 'بروتوكول ضبط لزوجة الهيموغلوبين' : 'Elevated Hgb / RBC protocol',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(waterPct * 100).round()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.lightBlue, fontSize: 12),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),

              Center(
                child: Container(
                  width: 140,
                  height: 170,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.lightBlue.shade200, width: 3),
                  ),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        width: double.infinity,
                        height: 164 * waterPct,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        child: Text(
                          '$_waterAmount / $_waterGoal mL',
                          style: TextStyle(
                            color: waterPct > 0.4 ? Colors.white : const Color(0xFF1E293B),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _addWater(250),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('+250 mL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _addWater(500),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('+500 mL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _addWater(750),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B3B2B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('+750 mL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7F4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.coffee_rounded, color: Color(0xFF2E7D32), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isAr ? 'أكواب الشاي الأخضر (EGCG)' : 'Green Tea Counter',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1B3B2B)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _changeTea(-1),
                          icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.grey),
                        ),
                        Text(
                          '$_greenTeaCount / $_teaGoal',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E7D32)),
                        ),
                        IconButton(
                          onPressed: () => _changeTea(1),
                          icon: const Icon(Icons.add_circle_rounded, size: 20, color: Color(0xFF2E7D32)),
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'قائمة الفحص السريري اليومية' : 'Daily Clinical Checklist',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3B2B)),
              ),
              const SizedBox(height: 12),
              _buildCheckTile(
                title: isAr ? 'مكمل فيتامين د3 (5,000 وحدة)' : 'Vitamin D3 Supplement (5,000 IU)',
                subtitle: isAr ? 'تناوله مع وجبة تحتوي على دهون صحية' : 'Take with fat-containing meal',
                value: _chkVitD,
                onChanged: (v) => _setChecklistValue(chkVitD: v ?? false),
                tag: 'Vit D 16',
                tagColor: Colors.purple,
              ),
              _buildCheckTile(
                title: isAr ? '30 دقيقة مشي سريع' : '30-Min Aerobic Walk',
                subtitle: isAr ? 'تحفيز حرق دهون الكبد وخصائص الإنزيمات' : 'Stimulates hepatic lipid oxidation',
                value: _walk30,
                onChanged: (v) => _setChecklistValue(walk30: v ?? false),
                tag: 'ALT Care',
                tagColor: const Color(0xFF2E7D32),
              ),
              _buildCheckTile(
                title: isAr ? '15-20 دقيقة شمس الصباح' : '15-20 Mins Morning Sunlight',
                subtitle: isAr ? 'تحفيز فيتامين د الطبيعي' : 'Triggers natural pre-D3 synthesis',
                value: _sun15,
                onChanged: (v) => _setChecklistValue(sun15: v ?? false),
                tag: 'Sun D3',
                tagColor: Colors.amber.shade800,
              ),
              _buildCheckTile(
                title: isAr ? 'يوم خالي تماماً من المقليات' : 'Strict Non-Fried & Low Saturated Fat Day',
                subtitle: isAr ? 'حماية خلايا الكبد من الإجهاد' : 'Zero trans-fats to protect hepatocytes',
                value: _lowFatDay,
                onChanged: (v) => _setChecklistValue(lowFatDay: v ?? false),
                tag: 'ALT/AST',
                tagColor: Colors.red.shade800,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String tag,
    required Color tagColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: CheckboxListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: tagColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
              child: Text(tag, style: TextStyle(color: tagColor, fontSize: 9, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        value: value,
        activeColor: const Color(0xFF2E7D32),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildModernMealAnalyzerTab(bool isAr) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'مُحلل الوجبات والقوائم الذكي' : 'Smart Meal & Menu Analyzer',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3B2B)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _mealSearchController,
                decoration: InputDecoration(
                  hintText: isAr ? 'اكتب اسم أي وجبة (مثل: كبسة، سلمون، شاورما)...' : 'Type ANY meal (e.g. Kabsa, Salmon, Shawarma)...',
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2E7D32)),
                  filled: true,
                  fillColor: const Color(0xFFF9FBF9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _analyzeMeal(_mealSearchController.text),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Text(isAr ? 'تحليل الوجبة' : 'Analyze Dish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B3B2B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_analyzedResult != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _analyzedResult!['dish'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1B3B2B)),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _analyzedResult!['score'] == 'HIGH' ? Colors.green.shade50 : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _analyzedResult!['score'] == 'HIGH' ? Colors.green.shade300 : Colors.amber.shade300),
                  ),
                  child: Text(
                    _analyzedResult!['score'] == 'HIGH'
                        ? (isAr ? '🟢 صديق للكبد (ممتاز)' : '🟢 LIVER FRIENDLY (EXCELLENT)')
                        : (isAr ? '🟡 خطر متوسط (عدّل الطلب)' : '🟡 MODERATE RISK (MODIFY ORDER)'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: _analyzedResult!['score'] == 'HIGH' ? Colors.green.shade900 : Colors.amber.shade900,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _buildMacroMetric(isAr ? 'البروتين:' : 'Protein Profile:', _analyzedResult!['protein'], Colors.blue, 0.8),
                const SizedBox(height: 8),
                _buildMacroMetric(isAr ? 'خطورة الدهون:' : 'Fat Risk Level:', _analyzedResult!['fat'], _analyzedResult!['score'] == 'LOW' ? Colors.red : Colors.green, _analyzedResult!['score'] == 'LOW' ? 0.9 : 0.3),
                const Divider(height: 28),

                Row(
                  children: [
                    const Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isAr ? 'نصائح وتعديلات الطلب السريرية:' : 'Clinical Ordering Modifications:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B3B2B)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...(_analyzedResult!['tips'] as List<String>).map(
                  (t) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(t, style: const TextStyle(fontSize: 12, color: Colors.black87))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ]
      ],
    );
  }

  Widget _buildMacroMetric(String title, String subtitle, Color color, double val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(subtitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: val,
            minHeight: 6,
            backgroundColor: color.withOpacity(0.15),
            color: color,
          ),
        )
      ],
    );
  }

  Widget _buildLabTrendCard(LabEntry lab, bool isAr) {
    final l10n = AppLocalizations.of(context);
    final history = _labHistoryByMetric[lab.metric] ?? <LabHistoryEntry>[];
    final values = history.map((e) => e.value).toList();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _targetLabel(lab.value, lab.refRange) == 'On Target' ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _targetLabel(lab.value, lab.refRange),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _targetLabel(lab.value, lab.refRange) == 'On Target' ? Colors.green.shade800 : Colors.orange.shade800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _trendLabel(lab) == 'Improving'
                      ? Colors.blue.shade50
                      : (_trendLabel(lab) == 'Worsening' ? Colors.red.shade50 : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _trendLabel(lab),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _trendLabel(lab) == 'Improving'
                        ? Colors.blue.shade800
                        : (_trendLabel(lab) == 'Worsening' ? Colors.red.shade800 : Colors.grey.shade700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.tr('trend_history'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF1E293B)),
              ),
              Text(
                l10n.tr('records_count', args: {'count': '${history.length}'}),
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (values.isEmpty)
            Text(
              l10n.tr('no_history'),
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            )
          else
            SizedBox(
              height: 60,
              width: double.infinity,
              child: CustomPaint(
                painter: _MiniTrendPainter(
                  values: values,
                  lineColor: const Color(0xFF0284C7),
                ),
              ),
            ),
          if (history.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l10n.tr(
                  'latest_value',
                  args: {
                    'value': '${history.last.value}',
                    'unit': history.last.unit,
                    'date': history.last.date,
                  },
                ),
                style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernLabsTab(bool isAr) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'مركز الفحوصات والمؤشرات الحيوية' : 'Biomarker & Clinical Lab Hub',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3B2B)),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _exportBackupFile,
                      icon: const Icon(Icons.download_rounded),
                      label: Text(l10n.tr('backup')),
                    ),
                    OutlinedButton.icon(
                      onPressed: _restoreBackupFile,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: Text(l10n.tr('restore')),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _upsertLabEntry(),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.tr('add_lab')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B3B2B),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.tr('sqlite_backup_hint'),
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              _buildAlertsPanel(isAr),
              const SizedBox(height: 6),
              const SizedBox(height: 4),
              if (_labs.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    isAr ? 'لا توجد فحوصات بعد. أضف أول فحص.' : 'No labs yet. Add your first lab record.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _labs.length,
                  separatorBuilder: (_, __) => const Divider(height: 20),
                  itemBuilder: (context, index) {
                    final lab = _labs[index];
                    final isNormal = lab.status == 'Normal';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(lab.metric, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isNormal ? Colors.green.shade50 : Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isNormal ? Colors.green.shade300 : Colors.amber.shade300),
                                  ),
                                  child: Text(
                                    lab.status,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isNormal ? Colors.green.shade900 : Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _upsertLabEntry(index: index),
                                  icon: const Icon(Icons.edit_rounded, size: 18),
                                  tooltip: 'Update lab',
                                ),
                                IconButton(
                                  onPressed: () => _deleteLabEntry(index),
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                  tooltip: 'Delete lab',
                                ),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${lab.value} ${lab.unit}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3B2B))),
                            Text(lab.refRange, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 6),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: lab.progressVal,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            color: isNormal ? Colors.green : Colors.amber.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(lab.target, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                        _buildLabTrendCard(lab, isAr),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: () => _addLabResult(lab),
                            icon: const Icon(Icons.show_chart_rounded, size: 16),
                            label: Text(isAr ? 'إضافة نتيجة' : 'Add Result'),
                          ),
                        )
                      ],
                    );
                  },
                )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildModernEducationTab(bool isAr) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'أبرز الأغذية الفائقة لدعم صحة الكبد' : 'Top Liver Rescue Superfoods',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3B2B)),
              ),
              const SizedBox(height: 16),
              _buildModernSuperfoodCard(Icons.coffee_rounded, isAr ? 'الشاي الأخضر (EGCG)' : 'Green Tea (EGCG)', isAr ? 'مضاد أكسدة قوي لحماية خلايا الكبد من الإجهاد' : 'Potent hepatocyte antioxidant protection'),
              _buildModernSuperfoodCard(Icons.eco_rounded, isAr ? 'البروكلي والكرنب' : 'Broccoli & Kale', isAr ? 'يحفز إنزيمات تنظيف سموم الكبد الطبيعية' : 'Boosts hepatic detox enzymes'),
              _buildModernSuperfoodCard(Icons.phishing_rounded, isAr ? 'السلمون البري (أوميغا-3)' : 'Wild Salmon (Omega-3)', isAr ? 'دهون صحية ممتازة لامتصاص فيتامين د3' : 'Healthy lipids for Vit D3 absorption'),
              _buildModernSuperfoodCard(Icons.water_drop_rounded, isAr ? 'زيت الزيتون البكر' : 'Extra Virgin Olive Oil', isAr ? 'دهون غير مشبعة صديقة لإنزيمات ALT/AST' : 'Unsaturated fats gentle on ALT/AST'),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildModernSuperfoodCard(IconData icon, String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B3B2B))),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _MiniTrendPainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;

  _MiniTrendPainter({
    required this.values,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final span = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = values.length == 1 ? size.width / 2 : (i / (values.length - 1)) * size.width;
      final y = size.height - ((values[i] - minVal) / span) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniTrendPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.lineColor != lineColor;
  }
}

enum _GoalRangeType { between, upper, lower }

class _GoalRange {
  final _GoalRangeType type;
  final double? min;
  final double? max;
  final double? upper;
  final double? lower;

  const _GoalRange._({
    required this.type,
    this.min,
    this.max,
    this.upper,
    this.lower,
  });

  factory _GoalRange.between({required double min, required double max}) {
    return _GoalRange._(type: _GoalRangeType.between, min: min, max: max);
  }

  factory _GoalRange.upper({required double threshold}) {
    return _GoalRange._(type: _GoalRangeType.upper, upper: threshold);
  }

  factory _GoalRange.lower({required double threshold}) {
    return _GoalRange._(type: _GoalRangeType.lower, lower: threshold);
  }

  bool isWithin(double value) {
    switch (type) {
      case _GoalRangeType.between:
        return value >= min! && value <= max!;
      case _GoalRangeType.upper:
        return value <= upper!;
      case _GoalRangeType.lower:
        return value >= lower!;
    }
  }
}

enum _LabAlertSeverity { critical, warning, info }

extension _LabAlertSeverityPriority on _LabAlertSeverity {
  int get priority {
    switch (this) {
      case _LabAlertSeverity.critical:
        return 3;
      case _LabAlertSeverity.warning:
        return 2;
      case _LabAlertSeverity.info:
        return 1;
    }
  }
}

class _LabAlert {
  final String metric;
  final _LabAlertSeverity severity;
  final String title;
  final String message;

  const _LabAlert({
    required this.metric,
    required this.severity,
    required this.title,
    required this.message,
  });
}

class _AlertVisuals {
  final IconData icon;
  final Color background;
  final Color border;
  final Color foreground;

  const _AlertVisuals({
    required this.icon,
    required this.background,
    required this.border,
    required this.foreground,
  });
}
