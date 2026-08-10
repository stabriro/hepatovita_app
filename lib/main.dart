import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app/di.dart';
import 'app/services/app_persistence_coordinator.dart';
import 'app/services/dashboard_actions_coordinator.dart';
import 'app/services/pdf_report_service.dart';
import 'app/theme/healthy_theme.dart';
import 'features/dashboard/presentation/views/dashboard_shell_widgets.dart';
import 'features/dashboard/presentation/views/overview_tab_view.dart';
import 'features/dashboard/presentation/viewmodels/dashboard_view_model.dart';
import 'features/education/presentation/views/education_tab_view.dart';
import 'features/labs/domain/entities/lab_entity.dart';
import 'features/labs/domain/entities/lab_history_entity.dart' as domain;
import 'features/labs/domain/usecases/evaluate_lab_goal_usecase.dart';
import 'features/labs/domain/usecases/generate_lab_alerts_usecase.dart';
import 'features/labs/presentation/controllers/lab_entry_flow_controller.dart';
import 'features/labs/presentation/models/lab_entry_models.dart';
import 'features/labs/presentation/presenters/lab_alert_presenter.dart';
import 'features/labs/presentation/views/labs_tab_view.dart';
import 'features/labs/presentation/viewmodels/labs_view_model.dart';
import 'features/medication/data/medication_scheduler_service.dart';
import 'features/medication/presentation/models/medication_schedule_model.dart';
import 'features/medication/presentation/views/medication_tab_view.dart';
import 'features/meal_analyzer/presentation/views/meal_analyzer_tab_view.dart';
import 'features/meal_analyzer/presentation/controllers/meal_image_analysis_controller.dart';
import 'features/meal_analyzer/presentation/viewmodels/meal_analyzer_view_model.dart';
import 'features/meal_analyzer/data/meal_image_extraction_service.dart';
import 'features/nutrition_plan/data/weekly_nutrition_plan_storage.dart';
import 'features/nutrition_plan/data/free_mealdb_service.dart';
import 'features/nutrition_plan/domain/weekly_nutrition_rule_engine.dart';
import 'features/nutrition_plan/presentation/views/weekly_nutrition_plan_tab_view.dart';
import 'features/profile/presentation/views/profile_tab_view.dart';
import 'l10n/app_localizations.dart';
import 'services/local_notification_service.dart';
import 'services/home_widget_sync_service.dart';
import 'services/security/app_lock_service.dart';
import 'services/security/app_settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await LocalNotificationService.instance.init();
  runApp(const ItmainApp());
}

class ItmainApp extends StatefulWidget {
  const ItmainApp({super.key});

  @override
  State<ItmainApp> createState() => _ItmainAppState();
}

class _ItmainAppState extends State<ItmainApp>
    with WidgetsBindingObserver {
  static const _kHasSeenSplash = 'has_seen_splash';
  static const _kSelectedLanguageCode = 'selected_language_code';
  static const _kHasSelectedLanguage = 'has_selected_language';
  final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

  final AppLockService _appLockService = AppLockService.instance;
  Locale _locale = const Locale('en');
  bool _isBootstrapping = true;
  bool _showSplash = true;
  bool _needsLanguageSetup = false;
  bool _needsPinSetup = false;
  bool _isLocked = false;
  bool _biometricAvailable = false;
  bool _biometricAllowed = false;
  DateTime? _skipNextResumeLockUntil;
  DateTime? _lastSuccessfulUnlockAt;
  AppLifecycleState? _lastLifecycleState;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeLaunchFlow();
  }

  Future<void> _initializeLaunchFlow() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenSplash = prefs.getBool(_kHasSeenSplash) ?? false;
    final savedLangCode = prefs.getString(_kSelectedLanguageCode);
    final hasSelectedLanguage =
        (prefs.getBool(_kHasSelectedLanguage) ?? false) || savedLangCode != null;
    final hasPin = await _appLockService.hasPin();
    final biometricEnabled = await _appLockService.isBiometricEnabled();
    final canUseBiometrics = await _appLockService.canUseBiometrics();

    if (!mounted) {
      return;
    }

    if (savedLangCode != null && savedLangCode.isNotEmpty) {
      _locale = Locale(savedLangCode);
    }

    if (!hasSelectedLanguage) {
      setState(() {
        _isBootstrapping = false;
        _showSplash = false;
        _needsLanguageSetup = true;
        _needsPinSetup = !hasPin;
        _isLocked = hasPin;
        _biometricAvailable = canUseBiometrics;
        _biometricAllowed = biometricEnabled && canUseBiometrics;
      });
      return;
    }

    if (hasSeenSplash) {
      setState(() {
        _isBootstrapping = false;
        _showSplash = false;
        _needsLanguageSetup = false;
        _needsPinSetup = !hasPin;
        _isLocked = hasPin;
        _biometricAvailable = canUseBiometrics;
        _biometricAllowed = biometricEnabled && canUseBiometrics;
      });
      return;
    }

    setState(() {
      _isBootstrapping = false;
      _showSplash = true;
      _needsLanguageSetup = false;
      _needsPinSetup = !hasPin;
      _isLocked = hasPin;
      _biometricAvailable = canUseBiometrics;
      _biometricAllowed = biometricEnabled && canUseBiometrics;
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

  Future<void> _completeLanguageSelection(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSelectedLanguageCode, languageCode);
    await prefs.setBool(_kHasSelectedLanguage, true);

    if (!mounted) {
      return;
    }

    setState(() {
      _locale = Locale(languageCode);
      _needsLanguageSetup = false;
      _showSplash = true;
    });

    _splashTimer?.cancel();
    _splashTimer = Timer(const Duration(seconds: 2), _handleSplashContinue);
  }

  Future<void> _completePinSetup({
    required String pin,
    required bool enableBiometric,
  }) async {
    await _appLockService.setPin(pin);
    final recoveryCode = await _appLockService.rotateRecoveryCode();
    await _appLockService.setBiometricEnabled(enableBiometric);

    if (!mounted) {
      return;
    }

    setState(() {
      _needsPinSetup = false;
      _isLocked = false;
      _biometricAllowed = enableBiometric;
    });

    await _showRecoveryCodeDialog(recoveryCode);
  }

  Future<bool> _unlockWithPin(String pin) async {
    final isValid = await _appLockService.verifyPin(pin);
    if (!mounted) {
      return false;
    }
    if (!isValid) {
      return false;
    }

    setState(() {
      _isLocked = false;
    });
    _lastSuccessfulUnlockAt = DateTime.now();
    _skipNextResumeLock(duration: const Duration(seconds: 12));
    return true;
  }

  Future<bool> _unlockWithBiometric() async {
    final authenticated = await _appLockService.authenticateWithBiometrics();
    if (!mounted || !authenticated) {
      return false;
    }

    setState(() {
      _isLocked = false;
    });
    _lastSuccessfulUnlockAt = DateTime.now();
    _skipNextResumeLock(duration: const Duration(seconds: 12));
    return true;
  }

  Future<void> _recoverForgotPin() async {
    final appContext = _rootNavigatorKey.currentContext;
    if (appContext == null) {
      return;
    }

    final isAr = _locale.languageCode == 'ar';
    final canUseBiometrics = await _appLockService.canUseBiometrics();
    final hasRecoveryCode = await _appLockService.hasRecoveryCode();
    if (!mounted) {
      return;
    }

    if (!canUseBiometrics) {
      if (hasRecoveryCode) {
        await _recoverWithRecoveryCode();
      } else {
        final messengerContext = _rootNavigatorKey.currentContext;
        if (messengerContext == null || !messengerContext.mounted) {
          return;
        }

        ScaffoldMessenger.of(messengerContext).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'لا يمكن استعادة PIN بدون بصمة أو رمز استعادة.'
                  : 'PIN recovery requires biometrics or a recovery code.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final verified = await _appLockService.authenticateWithBiometrics();
    if (!mounted) {
      return;
    }

    if (!verified) {
      if (hasRecoveryCode) {
        await _recoverWithRecoveryCode();
      } else {
        final messengerContext = _rootNavigatorKey.currentContext;
        if (messengerContext == null || !messengerContext.mounted) {
          return;
        }

        ScaffoldMessenger.of(messengerContext).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'فشل التحقق بالبصمة ولا يوجد رمز استعادة متاح.'
                  : 'Biometric verification failed and no recovery code is available.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLocked = false;
      _needsPinSetup = true;
    });
  }

  Future<void> _recoverWithRecoveryCode() async {
    final appContext = _rootNavigatorKey.currentContext;
    if (appContext == null) {
      return;
    }

    final l10n = AppLocalizations.of(appContext);
    final codeController = TextEditingController();
    String? localError;

    final confirmed = await showDialog<bool>(
      context: appContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return AlertDialog(
              title: Text(l10n.tr('recover_with_code_title')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.tr('recover_with_code_hint'),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: codeController,
                    decoration: InputDecoration(
                      labelText: l10n.tr('recovery_code_label'),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  if (localError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      localError!,
                      style: const TextStyle(color: Color(0xFFB91C1C)),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.tr('cancel')),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final candidate = codeController.text.trim().toUpperCase();
                    final ok = await _appLockService.verifyRecoveryCode(candidate);
                    if (!ok) {
                      setInnerState(() {
                        localError = l10n.tr('recovery_code_invalid');
                      });
                      return;
                    }
                    if (!dialogContext.mounted) {
                      return;
                    }
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: Text(l10n.tr('verify')),
                ),
              ],
            );
          },
        );
      },
    );

    codeController.dispose();

    if (confirmed == true && mounted) {
      setState(() {
        _isLocked = false;
        _needsPinSetup = true;
      });
    }
  }

  Future<void> _showRecoveryCodeDialog(String code) async {
    final appContext = _rootNavigatorKey.currentContext;
    if (appContext == null) {
      return;
    }

    final l10n = AppLocalizations.of(appContext);
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: appContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.tr('save_recovery_code_title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.tr('save_recovery_code_hint'),
              ),
              const SizedBox(height: 10),
              SelectableText(
                code,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.tr('save_recovery_code_footer'),
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.tr('done')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _armLock() async {
    final hasPin = await _appLockService.hasPin();
    final biometricEnabled = await _appLockService.isBiometricEnabled();
    final canUseBiometric = await _appLockService.canUseBiometrics();
    if (!mounted || !hasPin) {
      return;
    }

    setState(() {
      _isLocked = true;
      _biometricAllowed = biometricEnabled && canUseBiometric;
    });
  }

  Future<void> _lockNow() async {
    await _armLock();
  }

  void _skipNextResumeLock({Duration duration = const Duration(seconds: 45)}) {
    _skipNextResumeLockUntil = DateTime.now().add(duration);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final previous = _lastLifecycleState;
    _lastLifecycleState = state;

    if (state == AppLifecycleState.resumed) {
      if (previous == null || previous == AppLifecycleState.resumed) {
        return;
      }

      final unlockedAt = _lastSuccessfulUnlockAt;
      if (unlockedAt != null && DateTime.now().difference(unlockedAt) < const Duration(seconds: 12)) {
        return;
      }

      final skipUntil = _skipNextResumeLockUntil;
      if (skipUntil != null && DateTime.now().isBefore(skipUntil)) {
        _skipNextResumeLockUntil = null;
        return;
      }
      _armLock();
    }
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _toggleLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSelectedLanguageCode, lang);
    await prefs.setBool(_kHasSelectedLanguage, true);
    if (!mounted) {
      return;
    }
    setState(() {
      _locale = Locale(lang);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _locale.languageCode == 'ar';
    return MaterialApp(
      navigatorKey: _rootNavigatorKey,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'اطمئن',
      debugShowCheckedModeBanner: false,
      theme: HealthyTheme.theme(isAr: isAr),
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
              : _needsLanguageSetup
              ? LanguageSetupScreen(
                  key: const ValueKey('language_setup'),
                  onLanguageSelected: _completeLanguageSelection,
                )
              : _needsPinSetup
              ? SecurityPinSetupScreen(
                  key: const ValueKey('pin_setup'),
                  isAr: isAr,
                  canUseBiometric: _biometricAvailable,
                  onPinCreated: _completePinSetup,
                )
              : _isLocked
              ? SecurityUnlockScreen(
                  key: const ValueKey('pin_unlock'),
                  isAr: isAr,
                  enableBiometric: _biometricAllowed,
                  onUnlockWithPin: _unlockWithPin,
                  onUnlockWithBiometric: _unlockWithBiometric,
                  onForgotPin: _recoverForgotPin,
                )
              : MainDashboardScreen(
                  key: const ValueKey('main_dashboard'),
                  lang: _locale.languageCode,
                  onLanguageChanged: (lang) => _toggleLanguage(lang),
                  onLockRequested: _lockNow,
                  onExternalIntentStarted: _skipNextResumeLock,
                ),
        ),
      ),
    );
  }
}

class SecurityPinSetupScreen extends StatefulWidget {
  final bool isAr;
  final bool canUseBiometric;
  final Future<void> Function({required String pin, required bool enableBiometric})
      onPinCreated;

  const SecurityPinSetupScreen({
    super.key,
    required this.isAr,
    required this.canUseBiometric,
    required this.onPinCreated,
  });

  @override
  State<SecurityPinSetupScreen> createState() => _SecurityPinSetupScreenState();
}

class _SecurityPinSetupScreenState extends State<SecurityPinSetupScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _enableBiometric = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (pin.length < 4 || int.tryParse(pin) == null) {
      setState(() {
        _error = widget.isAr
            ? 'أدخل رقم PIN مكونا من 4 أرقام على الأقل'
            : 'Enter a PIN with at least 4 digits';
      });
      return;
    }
    if (pin != confirmPin) {
      setState(() {
        _error = widget.isAr ? 'PIN غير متطابق' : 'PIN confirmation does not match';
      });
      return;
    }

    setState(() {
      _error = null;
    });

    await widget.onPinCreated(
      pin: pin,
      enableBiometric: widget.canUseBiometric && _enableBiometric,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.isAr ? 'تفعيل حماية التطبيق' : 'Enable App Security',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isAr
                            ? 'أنشئ PIN لحماية بياناتك الطبية محليا.'
                            : 'Create a PIN to protect your health data locally.',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _pinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: widget.isAr ? 'PIN جديد' : 'New PIN',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: widget.isAr ? 'تأكيد PIN' : 'Confirm PIN',
                        ),
                      ),
                      if (widget.canUseBiometric) ...[
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(widget.isAr
                              ? 'تفعيل البصمة/الوجه'
                              : 'Enable biometric unlock'),
                          value: _enableBiometric,
                          onChanged: (value) {
                            setState(() {
                              _enableBiometric = value;
                            });
                          },
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFB91C1C)),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _submit,
                        child: Text(widget.isAr ? 'حفظ ومتابعة' : 'Save & Continue'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SecurityUnlockScreen extends StatefulWidget {
  final bool isAr;
  final bool enableBiometric;
  final Future<bool> Function(String pin) onUnlockWithPin;
  final Future<bool> Function() onUnlockWithBiometric;
  final Future<void> Function() onForgotPin;

  const SecurityUnlockScreen({
    super.key,
    required this.isAr,
    required this.enableBiometric,
    required this.onUnlockWithPin,
    required this.onUnlockWithBiometric,
    required this.onForgotPin,
  });

  @override
  State<SecurityUnlockScreen> createState() => _SecurityUnlockScreenState();
}

class _SecurityUnlockScreenState extends State<SecurityUnlockScreen> {
  final TextEditingController _pinController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.enableBiometric) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _unlockWithBiometric();
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _unlockWithPin() async {
    final pin = _pinController.text.trim();
    final ok = await widget.onUnlockWithPin(pin);
    if (!ok && mounted) {
      setState(() {
        _error = widget.isAr ? 'PIN غير صحيح' : 'Invalid PIN';
      });
    }
  }

  Future<void> _unlockWithBiometric() async {
    final ok = await widget.onUnlockWithBiometric();
    if (!ok && mounted) {
      setState(() {
        _error = widget.isAr
            ? 'فشل التحقق بالبصمة، استخدم PIN'
            : 'Biometric auth failed, please use PIN.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.isAr ? 'افتح التطبيق' : 'Unlock App',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isAr
                            ? 'أدخل PIN للوصول إلى بياناتك الصحية.'
                            : 'Enter your PIN to access your health data.',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: widget.isAr ? 'PIN' : 'PIN',
                        ),
                        onSubmitted: (_) => _unlockWithPin(),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFB91C1C)),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _unlockWithPin,
                        child: Text(widget.isAr ? 'دخول' : 'Unlock'),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: widget.onForgotPin,
                        child: Text(
                          AppLocalizations.of(context).tr('forgot_pin'),
                        ),
                      ),
                      if (widget.enableBiometric) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _unlockWithBiometric,
                          icon: const Icon(Icons.fingerprint_rounded),
                          label: Text(widget.isAr
                              ? 'استخدام البصمة/الوجه'
                              : 'Use biometrics'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LanguageSetupScreen extends StatelessWidget {
  final ValueChanged<String> onLanguageSelected;

  const LanguageSetupScreen({
    super.key,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF1F7F3), Color(0xFFE8F2EC), Color(0xFFF7FBF9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFFDDE6E0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A1A4D3B),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.language_rounded,
                        size: 42,
                        color: Color(0xFF1F5A45),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Choose your language',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF102018),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'اختر لغة التطبيق',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F5A45),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'You can change language later from Profile settings.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: () => onLanguageSelected('en'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B3B2B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('English', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () => onLanguageSelected('ar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1B3B2B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFF1F5A45)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('العربية', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.92, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 118,
                    height: 118,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0x66FFFFFF), Color(0x22FFFFFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 58,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'اطمئن',
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
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SplashTag(label: isAr ? 'تحاليل ديناميكية' : 'Dynamic labs'),
                    _SplashTag(label: isAr ? 'تتبع يومي' : 'Daily tracking'),
                    _SplashTag(label: isAr ? 'نسخ احتياطي مشفر' : 'Encrypted backup'),
                  ],
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

class _SplashTag extends StatelessWidget {
  final String label;

  const _SplashTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class MainDashboardScreen extends StatefulWidget {
  final String lang;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onLockRequested;
  final VoidCallback onExternalIntentStarted;

  const MainDashboardScreen({
    super.key,
    required this.lang,
    required this.onLanguageChanged,
    required this.onLockRequested,
    required this.onExternalIntentStarted,
  });

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  static const _kReminderHydration = 'hydration';
  static const _kReminderChecklist = 'checklist';
  static const _kReminderLowScore = 'low_score';
  static const _kReminderLabsFollowUp = 'labs_follow_up';

  int _currentTabIndex = 0;
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _canUseBiometric = false;
  bool _isEvaluatingSmartReminders = false;

  List<LabEntry> _labs = <LabEntry>[];
  List<MedicationSchedule> _medications = <MedicationSchedule>[];
  WeeklyNutritionPlan? _weeklyNutritionPlan;

  final TextEditingController _mealSearchController = TextEditingController();
  final DashboardViewModel _dashboardViewModel = DashboardViewModel();
  final MealAnalyzerViewModel _mealAnalyzerViewModel = MealAnalyzerViewModel();
  final MealImageExtractionService _mealImageExtractionService =
      MealImageExtractionService();
  Map<String, List<domain.LabHistoryEntity>> _labHistoryByMetric = {};
  final Set<String> _shownCriticalAlertKeys = <String>{};
  final LabsViewModel _labsViewModel = AppDi.provideLabsViewModel();
  final AppPersistenceCoordinator _persistenceCoordinator =
      AppDi.provideAppPersistenceCoordinator();
  final PdfReportService _pdfReportService = PdfReportService();
  final AppLockService _appLockService = AppLockService.instance;
  final AppSettingsService _appSettingsService = AppSettingsService.instance;
  final MedicationSchedulerService _medicationSchedulerService =
      MedicationSchedulerService();
    final WeeklyNutritionRuleEngine _weeklyNutritionRuleEngine =
      WeeklyNutritionRuleEngine();
    final WeeklyNutritionPlanStorage _weeklyNutritionPlanStorage =
      WeeklyNutritionPlanStorage();
      final FreeMealDbService _freeMealDbService = FreeMealDbService();
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
    _loadMedicationSchedules();
    _loadWeeklyNutritionPlan();
    _loadProfileSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _labsViewModel.load();
    });
  }

  Future<void> _loadProfileSettings() async {
    final notificationsEnabled =
        await _appSettingsService.isNotificationsEnabled();
    final biometricEnabled = await _appLockService.isBiometricEnabled();
    final canUseBiometric = await _appLockService.canUseBiometrics();

    if (!mounted) {
      return;
    }

    setState(() {
      _notificationsEnabled = notificationsEnabled;
      _biometricEnabled = biometricEnabled;
      _canUseBiometric = canUseBiometric;
    });

    _requestSmartReminderEvaluation();
    _requestHomeWidgetSync();
  }

  @override
  void didUpdateWidget(covariant MainDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lang != widget.lang) {
      _requestHomeWidgetSync();
    }
  }

  @override
  void dispose() {
    _dashboardViewModel.removeListener(_onScreenStateChanged);
    _mealAnalyzerViewModel.removeListener(_onScreenStateChanged);
    _labsViewModel.removeListener(_onLabsViewModelChanged);
    _mealImageExtractionService.dispose();
    _mealSearchController.dispose();
    super.dispose();
  }

  void _onScreenStateChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
    _requestSmartReminderEvaluation();
    _requestHomeWidgetSync();
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
      _requestSmartReminderEvaluation();
      _requestHomeWidgetSync();
    });
  }

  void _requestHomeWidgetSync() {
    unawaited(_syncHomeWidget());
  }

  Future<void> _syncHomeWidget() async {
    if (!Platform.isAndroid) {
      return;
    }

    await HomeWidgetSyncService.syncDashboardSnapshot(
      isAr: widget.lang == 'ar',
      waterAmount: _dashboardViewModel.waterAmount,
      waterGoal: _dashboardViewModel.waterGoal,
      greenTeaCount: _dashboardViewModel.greenTeaCount,
      teaGoal: _dashboardViewModel.teaGoal,
      chkVitD: _dashboardViewModel.chkVitD,
      walk30: _dashboardViewModel.walk30,
      sun15: _dashboardViewModel.sun15,
      lowFatDay: _dashboardViewModel.lowFatDay,
      score: _dashboardViewModel.score,
    );
  }

  Future<void> _applyPendingHomeWidgetActions() async {
    if (!Platform.isAndroid) {
      return;
    }

    final pending = await HomeWidgetSyncService.consumePendingActions();
    if (!pending.hasActions) {
      return;
    }

    if (pending.waterDeltaMl > 0) {
      await _dashboardActionsCoordinator.addWater(
        delta: pending.waterDeltaMl,
        labs: _labsAsMapList(),
      );
    }

    for (int i = 0; i < pending.taskCompletions; i++) {
      final applied = await _completeNextChecklistTaskFromWidget();
      if (!applied) {
        break;
      }
    }

    _requestHomeWidgetSync();
  }

  Future<bool> _completeNextChecklistTaskFromWidget() async {
    if (!_dashboardViewModel.chkVitD) {
      await _dashboardActionsCoordinator.setChecklistValue(
        chkVitD: true,
        labs: _labsAsMapList(),
      );
      return true;
    }
    if (!_dashboardViewModel.walk30) {
      await _dashboardActionsCoordinator.setChecklistValue(
        walk30: true,
        labs: _labsAsMapList(),
      );
      return true;
    }
    if (!_dashboardViewModel.sun15) {
      await _dashboardActionsCoordinator.setChecklistValue(
        sun15: true,
        labs: _labsAsMapList(),
      );
      return true;
    }
    if (!_dashboardViewModel.lowFatDay) {
      await _dashboardActionsCoordinator.setChecklistValue(
        lowFatDay: true,
        labs: _labsAsMapList(),
      );
      return true;
    }
    return false;
  }

  void _requestSmartReminderEvaluation() {
    unawaited(_evaluateSmartReminders());
  }

  Future<void> _evaluateSmartReminders() async {
    if (_isEvaluatingSmartReminders || !_notificationsEnabled || !mounted) {
      return;
    }

    _isEvaluatingSmartReminders = true;
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final dayStamp = _dayStamp(now);

    try {
      if (now.hour >= 11 &&
          _dashboardViewModel.waterAmount <
              (_dashboardViewModel.waterGoal * 0.45).round()) {
        await _maybeSendSmartReminder(
          key: _kReminderHydration,
          stamp: dayStamp,
          id: 401,
          title: l10n.tr('smart_reminder_title'),
          body: l10n.tr('smart_reminder_hydration'),
        );
      }

      if (now.hour >= 18 && _checklistDoneCount() <= 2) {
        await _maybeSendSmartReminder(
          key: _kReminderChecklist,
          stamp: dayStamp,
          id: 402,
          title: l10n.tr('smart_reminder_title'),
          body: l10n.tr('smart_reminder_checklist'),
        );
      }

      if (now.hour >= 20 && _dashboardViewModel.score < 60) {
        await _maybeSendSmartReminder(
          key: _kReminderLowScore,
          stamp: dayStamp,
          id: 403,
          title: l10n.tr('smart_reminder_title'),
          body: l10n.tr('smart_reminder_low_score'),
        );
      }

      final latestLabDate = _latestLabRecordDate();
      if (latestLabDate != null && now.difference(latestLabDate).inDays >= 14) {
        await _maybeSendSmartReminder(
          key: _kReminderLabsFollowUp,
          stamp: _weekStamp(now),
          id: 404,
          title: l10n.tr('smart_reminder_title'),
          body: l10n.tr('smart_reminder_labs_follow_up'),
        );
      }
    } finally {
      _isEvaluatingSmartReminders = false;
    }
  }

  Future<void> _maybeSendSmartReminder({
    required String key,
    required String stamp,
    required int id,
    required String title,
    required String body,
  }) async {
    final lastStamp = await _appSettingsService.getSmartReminderStamp(key);
    if (lastStamp == stamp) {
      return;
    }

    await LocalNotificationService.instance.showSmartReminder(
      id: id,
      title: title,
      body: body,
    );
    await _appSettingsService.setSmartReminderStamp(key, stamp);
  }

  int _checklistDoneCount() {
    int done = 0;
    if (_dashboardViewModel.chkVitD) done++;
    if (_dashboardViewModel.walk30) done++;
    if (_dashboardViewModel.sun15) done++;
    if (_dashboardViewModel.lowFatDay) done++;
    return done;
  }

  DateTime? _latestLabRecordDate() {
    DateTime? latest;
    for (final entries in _labHistoryByMetric.values) {
      for (final entry in entries) {
        final candidate = _parseLabDate(entry.date, fallbackIso: entry.createdAt);
        if (candidate == null) {
          continue;
        }
        if (latest == null || candidate.isAfter(latest)) {
          latest = candidate;
        }
      }
    }
    return latest;
  }

  String _dayStamp(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _weekStamp(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final week = ((date.difference(firstDayOfYear).inDays) / 7).floor() + 1;
    return '${date.year}-W${week.toString().padLeft(2, '0')}';
  }

  DateTime? _parseLabDate(String raw, {String? fallbackIso}) {
    final normalized = raw.trim();
    if (normalized.isNotEmpty) {
      final direct = DateTime.tryParse(normalized);
      if (direct != null) {
        return direct;
      }

      final slashParts = normalized.split('/');
      if (slashParts.length == 3) {
        final a = int.tryParse(slashParts[0]);
        final b = int.tryParse(slashParts[1]);
        final c = int.tryParse(slashParts[2]);
        if (a != null && b != null && c != null) {
          if (a > 31) {
            return DateTime(a, b, c);
          }
          return DateTime(c, b, a);
        }
      }
    }

    if (fallbackIso != null && fallbackIso.trim().isNotEmpty) {
      return DateTime.tryParse(fallbackIso);
    }
    return null;
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
    await _applyPendingHomeWidgetActions();
  }

  Future<void> _loadMedicationSchedules() async {
    final loaded = await _medicationSchedulerService.loadSchedules();
    if (!mounted) {
      return;
    }
    setState(() {
      _medications = loaded;
    });
    if (_notificationsEnabled) {
      await _scheduleMedicationReminders(loaded);
    }
  }

  Future<void> _loadWeeklyNutritionPlan() async {
    final loaded = await _weeklyNutritionPlanStorage.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _weeklyNutritionPlan = loaded;
    });
  }

  Future<void> _saveWeeklyNutritionPlan(WeeklyNutritionPlan plan) async {
    await _weeklyNutritionPlanStorage.save(plan);
    if (!mounted) {
      return;
    }
    setState(() {
      _weeklyNutritionPlan = plan;
    });
  }

  Future<void> _generateWeeklyNutritionPlan() async {
    final signals = _labs
        .map(
          (lab) => NutritionLabSignal(
            metric: lab.metric,
            value: lab.value,
            status: lab.status,
          ),
        )
        .toList();

    final generated = _weeklyNutritionRuleEngine.generate(
      isAr: widget.lang == 'ar',
      labs: signals,
    );

    final enriched = await _enrichPlanWithFreeApi(generated);

    await _saveWeeklyNutritionPlan(enriched);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.lang == 'ar'
              ? 'تم إنشاء الخطة الغذائية الأسبوعية.'
              : 'Weekly nutrition plan generated.',
        ),
      ),
    );
  }

  Future<void> _regenerateWeeklyNutritionPlan() async {
    await _generateWeeklyNutritionPlan();
  }

  Future<WeeklyNutritionPlan> _enrichPlanWithFreeApi(
    WeeklyNutritionPlan plan,
  ) async {
    try {
      final prefersSeafood = plan.ruleFlags.contains('liver_protect') ||
          plan.ruleFlags.contains('vit_d_support');
      final category = prefersSeafood ? 'Seafood' : 'Chicken';
      final meals = await _freeMealDbService.fetchMealsByCategory(category);
      if (meals.isEmpty) {
        return plan;
      }

      final seededOffset = DateTime.now().weekday % meals.length;
      final updatedDays = <DailyNutritionPlan>[];
      for (int i = 0; i < plan.days.length; i++) {
        final meal = meals[(seededOffset + i) % meals.length];
        final day = plan.days[i];
        updatedDays.add(
          day.copyWith(
            composition: day.composition.copyWith(
              dishName: meal.name,
              dishImageUrl: meal.imageUrl,
            ),
          ),
        );
      }

      return plan.copyWith(days: updatedDays);
    } catch (_) {
      return plan;
    }
  }

  Future<void> _saveMedicationSchedules(List<MedicationSchedule> items) async {
    await _medicationSchedulerService.saveSchedules(items);
    if (!mounted) {
      return;
    }
    setState(() {
      _medications = items;
    });

    if (_notificationsEnabled) {
      await _scheduleMedicationReminders(items);
    } else {
      await _cancelMedicationReminders(items);
    }
  }

  Future<void> _scheduleMedicationReminders(
    List<MedicationSchedule> items,
  ) async {
    if (!(Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux)) {
      return;
    }

    for (final med in items) {
      final id = _medicationNotificationId(med.id);
      await LocalNotificationService.instance.cancelScheduledNotification(id);
      if (!med.enabled) {
        continue;
      }
      await LocalNotificationService.instance.scheduleDailyMedicationReminder(
        id: id,
        title: widget.lang == 'ar'
            ? 'تذكير الدواء: ${med.name}'
            : 'Medication Reminder: ${med.name}',
        body: widget.lang == 'ar'
            ? 'حان وقت جرعة ${med.dose} (${med.timeLabel})'
            : 'Time for ${med.dose} at ${med.timeLabel}',
        hour: med.hour,
        minute: med.minute,
      );
    }
  }

  Future<void> _cancelMedicationReminders(
    List<MedicationSchedule> items,
  ) async {
    if (!(Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux)) {
      return;
    }

    for (final med in items) {
      await LocalNotificationService.instance.cancelScheduledNotification(
        _medicationNotificationId(med.id),
      );
    }
  }

  int _medicationNotificationId(String medicationId) {
    return 600000 + (medicationId.hashCode.abs() % 100000);
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  Future<void> _toggleMedicationTaken(String id) async {
    final today = _todayKey();
    final updated = _medications.map((m) {
      if (m.id != id) {
        return m;
      }
      final isTakenToday = m.takenDayKey == today;
      return m.copyWith(
        takenDayKey: isTakenToday ? null : today,
        clearTakenDayKey: isTakenToday,
      );
    }).toList();

    await _saveMedicationSchedules(updated);
  }

  Future<void> _toggleMedicationEnabled(String id) async {
    final updated = _medications.map((m) {
      if (m.id != id) {
        return m;
      }
      return m.copyWith(enabled: !m.enabled);
    }).toList();

    await _saveMedicationSchedules(updated);
  }

  Future<void> _deleteMedication(String id) async {
    final isAr = widget.lang == 'ar';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isAr ? 'حذف الدواء؟' : 'Delete medication?'),
        content: Text(
          isAr
              ? 'سيتم حذف الدواء وجدوله اليومي.'
              : 'This removes the medication and its daily schedule.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text(isAr ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    final removed = _medications.firstWhere((m) => m.id == id);
    await LocalNotificationService.instance.cancelScheduledNotification(
      _medicationNotificationId(removed.id),
    );

    final updated = _medications.where((m) => m.id != id).toList();
    await _saveMedicationSchedules(updated);
  }

  Future<void> _openMedicationEditor({String? medicationId}) async {
    final isAr = widget.lang == 'ar';
    final existing = medicationId == null
        ? null
        : _medications.firstWhere((m) => m.id == medicationId);

    final nameController =
        TextEditingController(text: existing?.name ?? '');
    final doseController =
        TextEditingController(text: existing?.dose ?? '');
    TimeOfDay selectedTime = TimeOfDay(
      hour: existing?.hour ?? 8,
      minute: existing?.minute ?? 0,
    );

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return AlertDialog(
              title: Text(
                existing == null
                    ? (isAr ? 'إضافة دواء' : 'Add Medication')
                    : (isAr ? 'تعديل الدواء' : 'Edit Medication'),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText:
                            isAr ? 'اسم الدواء' : 'Medication Name',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: doseController,
                      decoration: InputDecoration(
                        labelText:
                            isAr ? 'الجرعة (مثال: 500mg)' : 'Dose (e.g. 500mg)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: dialogContext,
                          initialTime: selectedTime,
                        );
                        if (picked == null) {
                          return;
                        }
                        setInnerState(() {
                          selectedTime = picked;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Text(
                          '${isAr ? 'وقت التذكير' : 'Reminder Time'}: ${selectedTime.format(dialogContext)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(isAr ? 'إلغاء' : 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(isAr ? 'حفظ' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (save == true) {
      final name = nameController.text.trim();
      final dose = doseController.text.trim();
      if (name.isEmpty || dose.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isAr
                    ? 'الاسم والجرعة مطلوبان.'
                    : 'Name and dose are required.',
              ),
            ),
          );
        }
      } else {
        final model = MedicationSchedule(
          id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
          name: name,
          dose: dose,
          hour: selectedTime.hour,
          minute: selectedTime.minute,
          enabled: existing?.enabled ?? true,
          takenDayKey: existing?.takenDayKey,
        );

        final updated = [..._medications];
        final index = updated.indexWhere((m) => m.id == model.id);
        if (index == -1) {
          updated.add(model);
        } else {
          updated[index] = model;
        }

        await _saveMedicationSchedules(updated);
      }
    }

    nameController.dispose();
    doseController.dispose();
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

    if (_notificationsEnabled) {
      final notificationId = alertKey.hashCode.abs() % 2147483647;
      LocalNotificationService.instance.showCriticalAlert(
        id: notificationId,
        title: l10n.tr('high_alert_title'),
        body: popupText,
      );
    }

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
            'itmain_backup_${DateTime.now().toIso8601String().split('T').first}.hvbk',
        dialogTitle: l10n.tr('save_sqlite_backup'),
      );
      if (!mounted) return;

      if (Platform.isAndroid || Platform.isIOS) {
        await Share.shareXFiles(
          [XFile(savedPath)],
          subject: 'اطمئن Backup',
          text: 'اطمئن backup (.hvbk)',
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.tr('backup_ready_to_share'))),
        );
        return;
      }

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

  Future<void> _exportMedicalPdfReport() async {
    final l10n = AppLocalizations.of(context);
    try {
      final reportPath = await _pdfReportService.generateMedicalReport(
        isAr: widget.lang == 'ar',
        score: _dashboardViewModel.score,
        waterAmount: _dashboardViewModel.waterAmount,
        waterGoal: _dashboardViewModel.waterGoal,
        greenTeaCount: _dashboardViewModel.greenTeaCount,
        teaGoal: _dashboardViewModel.teaGoal,
        chkVitD: _dashboardViewModel.chkVitD,
        walk30: _dashboardViewModel.walk30,
        sun15: _dashboardViewModel.sun15,
        lowFatDay: _dashboardViewModel.lowFatDay,
        labs: List<LabEntry>.from(_labs),
      );

      if (!mounted || reportPath == null) {
        return;
      }

      if (Platform.isAndroid || Platform.isIOS) {
        await Share.shareXFiles(
          [XFile(reportPath)],
          subject: l10n.tr('pdf_report_subject'),
          text: l10n.tr('pdf_report_share_text'),
        );

        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.tr('pdf_report_ready_to_share'))),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tr('pdf_report_saved_to', args: {'path': reportPath}))),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tr('pdf_report_failed', args: {'error': '$e'}))),
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

  Future<void> _showAddLabEntryOptions() async {
    final l10n = AppLocalizations.of(context);

    final choice = await LabEntryFlowController.chooseLabEntryMethod(
      context,
      l10n,
    );

    if (choice == LabEntryMethod.manual) {
      await _upsertLabEntry();
      return;
    }

    if (choice == LabEntryMethod.image) {
      await _upsertLabEntryFromImage();
    }
  }

  Future<void> _upsertLabEntryFromImage() async {
    final l10n = AppLocalizations.of(context);
    final source = await LabEntryFlowController.chooseImageSource(context, l10n);
    if (source == null) {
      return;
    }

    widget.onExternalIntentStarted();

    final extractedText = await _mealImageExtractionService.extractText(
      source: source,
    );

    if (extractedText == null || extractedText.trim().isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tr('lab_image_no_text'))),
      );
      return;
    }

    final draft = LabEntryFlowController.parseLabDraftFromText(extractedText);
    if (draft == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tr('lab_image_parse_failed'))),
      );
      await _upsertLabEntry();
      return;
    }

    await _upsertLabEntry(prefill: draft);
  }

  Future<void> _upsertLabEntry({int? index, LabDraft? prefill}) async {
    final l10n = AppLocalizations.of(context);
    final existing = index == null ? null : _labs[index];

    final metricController = TextEditingController(text: prefill?.metric ?? existing?.metric ?? '');
    final valueController = TextEditingController(text: prefill?.value ?? existing?.value.toString() ?? '');
    final unitController = TextEditingController(text: prefill?.unit ?? existing?.unit ?? '');
    final refRangeController = TextEditingController(text: prefill?.refRange ?? existing?.refRange ?? '');
    final dateController = TextEditingController(text: prefill?.date ?? existing?.date ?? DateTime.now().toIso8601String().split('T').first);
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

  Future<void> _analyzeMealFromBarcodeImage() async {
    final l10n = AppLocalizations.of(context);
    final result = await MealImageAnalysisController.analyzeFromBarcodeImage(
      chooseImageSource: () =>
          LabEntryFlowController.chooseImageSource(context, l10n),
      extractionService: _mealImageExtractionService,
      onImageSourceSelected: widget.onExternalIntentStarted,
    );

    await _handleMealImageAnalysisResult(result, l10n);
  }

  Future<void> _analyzeMealFromTextImage() async {
    final l10n = AppLocalizations.of(context);
    final result = await MealImageAnalysisController.analyzeFromTextImage(
      chooseImageSource: () =>
          LabEntryFlowController.chooseImageSource(context, l10n),
      extractionService: _mealImageExtractionService,
      onImageSourceSelected: widget.onExternalIntentStarted,
    );

    await _handleMealImageAnalysisResult(result, l10n);
  }

  Future<void> _handleMealImageAnalysisResult(
    MealImageAnalysisResult result,
    AppLocalizations l10n,
  ) async {
    if (result.cancelled) {
      return;
    }

    if (result.hasQuery) {
      final query = result.query!;
      _mealSearchController.text = query;
      await _analyzeMeal(query);
      return;
    }

    if (!mounted) {
      return;
    }

    String? message;
    switch (result.failure) {
      case MealImageAnalysisFailure.barcodeNotFound:
        message = l10n.tr('barcode_not_found_in_image');
        break;
      case MealImageAnalysisFailure.textNotFound:
        message = l10n.tr('text_not_found_in_image');
        break;
      case MealImageAnalysisFailure.barcodeAnalysisFailed:
        message = l10n.tr(
          'barcode_image_analysis_failed',
          args: {'error': '${result.error}'},
        );
        break;
      case MealImageAnalysisFailure.textAnalysisFailed:
        message = l10n.tr(
          'text_image_analysis_failed',
          args: {'error': '${result.error}'},
        );
        break;
      case null:
        break;
    }

    if (message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _updateNotifications(bool enabled) async {
    await _appSettingsService.setNotificationsEnabled(enabled);
    if (!mounted) {
      return;
    }
    setState(() {
      _notificationsEnabled = enabled;
    });
    if (enabled) {
      _requestSmartReminderEvaluation();
      await _scheduleMedicationReminders(_medications);
    } else {
      await _cancelMedicationReminders(_medications);
    }
  }

  Future<void> _updateBiometric(bool enabled) async {
    await _appLockService.setBiometricEnabled(enabled);
    if (!mounted) {
      return;
    }
    setState(() {
      _biometricEnabled = enabled;
    });
  }

  Future<void> _showChangePinDialog() async {
    final isAr = widget.lang == 'ar';
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    String? localError;

    final nextRecoveryCode = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return AlertDialog(
              title: Text(isAr ? 'تغيير PIN' : 'Change PIN'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: oldPinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isAr ? 'PIN الحالي' : 'Current PIN',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newPinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isAr ? 'PIN جديد' : 'New PIN',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmPinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: isAr ? 'تأكيد PIN' : 'Confirm PIN',
                      ),
                    ),
                    if (localError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        localError!,
                        style: const TextStyle(color: Color(0xFFB91C1C)),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(isAr ? 'إلغاء' : 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final oldPin = oldPinController.text.trim();
                    final newPin = newPinController.text.trim();
                    final confirmPin = confirmPinController.text.trim();

                    final validOldPin = await _appLockService.verifyPin(oldPin);
                    if (!validOldPin) {
                      setInnerState(() {
                        localError = isAr
                            ? 'PIN الحالي غير صحيح'
                            : 'Current PIN is incorrect';
                      });
                      return;
                    }

                    if (newPin.length < 4 || int.tryParse(newPin) == null) {
                      setInnerState(() {
                        localError = isAr
                            ? 'PIN الجديد يجب أن يكون 4 أرقام على الأقل'
                            : 'New PIN must be at least 4 digits';
                      });
                      return;
                    }

                    if (newPin != confirmPin) {
                      setInnerState(() {
                        localError = isAr
                            ? 'PIN غير متطابق'
                            : 'PIN confirmation does not match';
                      });
                      return;
                    }

                    await _appLockService.setPin(newPin);
                    final rotatedRecoveryCode =
                        await _appLockService.rotateRecoveryCode();
                    if (!dialogContext.mounted) {
                      return;
                    }
                    Navigator.of(dialogContext).pop(rotatedRecoveryCode);
                  },
                  child: Text(isAr ? 'حفظ' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    oldPinController.dispose();
    newPinController.dispose();
    confirmPinController.dispose();

    if (nextRecoveryCode != null) {
      if (!mounted) {
        return;
      }
      await _showRecoveryCodeDialogFromProfile(nextRecoveryCode);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم تحديث PIN بنجاح' : 'PIN updated successfully'),
        ),
      );
    }
  }

  Future<void> _showRecoveryCodeDialogFromProfile(String code) async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.tr('new_recovery_code_title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.tr('new_recovery_code_hint'),
              ),
              const SizedBox(height: 10),
              SelectableText(
                code,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.tr('done')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.lang == 'ar';
    final score = _dashboardViewModel.score;

    return Scaffold(
      body: Stack(
        children: [
          const _HealthyBackdrop(),
          SafeArea(
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
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F1A4D3B),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: NavigationBar(
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
              NavigationDestination(
                icon: const Icon(Icons.medication_rounded),
                label: isAr ? 'الأدوية' : 'Meds',
              ),
              NavigationDestination(
                icon: const Icon(Icons.calendar_month_rounded),
                label: isAr ? 'الخطة الأسبوعية' : 'Weekly Plan',
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_rounded),
                label: isAr ? 'الملف' : 'Profile',
              ),
            ],
          ),
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
      case 4:
        return _buildModernMedicationTab(isAr);
      case 5:
        return _buildWeeklyNutritionPlanTab(isAr);
      case 6:
        return _buildModernProfileTab(isAr);
      default:
        return _buildModernOverviewTab(isAr);
    }
  }

  Widget _buildModernHeader(bool isAr) {
    return DashboardHeader(
      isAr: isAr,
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
      mealSearchController: _mealSearchController,
      onAnalyzeMeal: _analyzeMeal,
      onAnalyzeFromBarcode: _analyzeMealFromBarcodeImage,
      onAnalyzeFromTextImage: _analyzeMealFromTextImage,
      supportsImageActions: Platform.isAndroid || Platform.isIOS,
      analysis: _toMealAnalysisUiModel(),
      isAnalyzing: _mealAnalyzerViewModel.isAnalyzing,
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
      reason: (raw['reason'] ?? '').toString(),
      confidence: (raw['confidence'] ?? '').toString(),
      matchedName: (raw['matched_name'] ?? '').toString(),
      kcalPer100g: (raw['kcal_per_100g'] as num?)?.toDouble(),
      proteinPer100g: (raw['protein_per_100g'] as num?)?.toDouble(),
      fatPer100g: (raw['fat_per_100g'] as num?)?.toDouble(),
      satFatPer100g: (raw['sat_fat_per_100g'] as num?)?.toDouble(),
      sugarPer100g: (raw['sugar_per_100g'] as num?)?.toDouble(),
      sodiumMgPer100g: (raw['sodium_mg_per_100g'] as num?)?.toDouble(),
      caveat: (raw['caveat'] ?? '').toString(),
      protein: (raw['protein'] ?? '').toString(),
      fat: (raw['fat'] ?? '').toString(),
      tips: ((raw['tips'] as List<dynamic>? ?? const <dynamic>[]).map((e) => e.toString()).toList()),
      source: (raw['source'] ?? 'local_fallback').toString(),
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
              status: e.status,
              createdAt: e.createdAt,
            ),
          )
          .toList();
    });
    return uiHistoryByMetric;
  }

  List<LabsTimelineEvent> _toLabsTimelineEvents() {
    final events = <LabsTimelineEvent>[];
    _labHistoryByMetric.forEach((metric, entries) {
      for (final entry in entries) {
        events.add(
          LabsTimelineEvent(
            metric: metric,
            value: entry.value,
            unit: entry.unit,
            status: entry.status,
            date: entry.date,
          ),
        );
      }
    });

    events.sort((a, b) {
      final aDate = _parseLabDate(a.date);
      final bDate = _parseLabDate(b.date);

      if (aDate == null && bDate == null) {
        return 0;
      }
      if (aDate == null) {
        return 1;
      }
      if (bDate == null) {
        return -1;
      }
      return bDate.compareTo(aDate);
    });

    return events;
  }

  Widget _buildModernLabsTab(bool isAr) {
    final l10n = AppLocalizations.of(context);
    return LabsTabView(
      isAr: isAr,
      labs: _toLabsTabLabItems(),
      historyByMetric: _toLabsTabHistoryByMetric(),
      timelineEvents: _toLabsTimelineEvents(),
      alerts: _generateLabAlerts(l10n),
      onExportBackup: _exportBackupFile,
      onRestoreBackup: _restoreBackupFile,
      onAddLab: _showAddLabEntryOptions,
      onEditLab: (index) => _upsertLabEntry(index: index),
      onDeleteLab: _deleteLabEntry,
      onAddResult: (index) => _addLabResult(_labs[index]),
    );
  }

  Widget _buildModernEducationTab(bool isAr) {
    return EducationTabView(isAr: isAr);
  }

  Widget _buildModernMedicationTab(bool isAr) {
    return MedicationTabView(
      isAr: isAr,
      medications: _medications,
      onToggleTaken: (id) {
        unawaited(_toggleMedicationTaken(id));
      },
      onToggleEnabled: (id) {
        unawaited(_toggleMedicationEnabled(id));
      },
      onDeleteMedication: (id) {
        unawaited(_deleteMedication(id));
      },
      onEditMedication: (id) {
        unawaited(_openMedicationEditor(medicationId: id));
      },
      onAddMedication: () {
        unawaited(_openMedicationEditor());
      },
      todayKey: _todayKey(),
    );
  }

  Widget _buildWeeklyNutritionPlanTab(bool isAr) {
    return WeeklyNutritionPlanTabView(
      isAr: isAr,
      plan: _weeklyNutritionPlan,
      onGenerate: () {
        unawaited(_generateWeeklyNutritionPlan());
      },
      onRegenerate: () {
        unawaited(_regenerateWeeklyNutritionPlan());
      },
      onSave: () {
        final plan = _weeklyNutritionPlan;
        if (plan == null) {
          return;
        }
        unawaited(_saveWeeklyNutritionPlan(plan));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr ? 'تم حفظ الخطة الأسبوعية.' : 'Weekly plan saved.',
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernProfileTab(bool isAr) {
    return ProfileTabView(
      isAr: isAr,
      currentLanguage: widget.lang,
      onLanguageChanged: widget.onLanguageChanged,
      notificationsEnabled: _notificationsEnabled,
      biometricEnabled: _biometricEnabled,
      canUseBiometric: _canUseBiometric,
      onNotificationsChanged: _updateNotifications,
      onBiometricChanged: _updateBiometric,
      onChangePin: _showChangePinDialog,
      onExportPdfReport: _exportMedicalPdfReport,
      onExportBackup: _exportBackupFile,
      onRestoreBackup: _restoreBackupFile,
      onLockNow: widget.onLockRequested,
    );
  }
}

class _HealthyBackdrop extends StatelessWidget {
  const _HealthyBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF4F8F5), Color(0xFFEAF3EE), Color(0xFFF8FBF9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF9ED5BF).withValues(alpha: 0.24),
              ),
            ),
          ),
          Positioned(
            top: 240,
            left: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFB9E1F3).withValues(alpha: 0.22),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            right: -26,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFDDEFD6).withValues(alpha: 0.32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

