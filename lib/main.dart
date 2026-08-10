import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
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
import 'features/meal_analyzer/data/meal_image_extraction_service.dart';
import 'features/profile/presentation/views/profile_tab_view.dart';
import 'l10n/app_localizations.dart';
import 'services/local_notification_service.dart';
import 'services/security/app_lock_service.dart';
import 'services/security/app_settings_service.dart';

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

class _HepatoVitaAppState extends State<HepatoVitaApp>
    with WidgetsBindingObserver {
  static const _kHasSeenSplash = 'has_seen_splash';

  final AppLockService _appLockService = AppLockService.instance;
  Locale _locale = const Locale('en');
  bool _isBootstrapping = true;
  bool _showSplash = true;
  bool _needsPinSetup = false;
  bool _isLocked = false;
  bool _biometricAvailable = false;
  bool _biometricAllowed = false;
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
    final hasPin = await _appLockService.hasPin();
    final biometricEnabled = await _appLockService.isBiometricEnabled();
    final canUseBiometrics = await _appLockService.canUseBiometrics();

    if (!mounted) {
      return;
    }

    if (hasSeenSplash) {
      setState(() {
        _isBootstrapping = false;
        _showSplash = false;
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
    return true;
  }

  Future<void> _recoverForgotPin() async {
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
        ScaffoldMessenger.of(context).showSnackBar(
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
        ScaffoldMessenger.of(context).showSnackBar(
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
    final l10n = AppLocalizations.of(context);
    final codeController = TextEditingController();
    String? localError;

    final confirmed = await showDialog<bool>(
      context: context,
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
    final l10n = AppLocalizations.of(context);
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _armLock();
    }
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
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
                  onLanguageChanged: _toggleLanguage,
                  onLockRequested: _lockNow,
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

class LabDraft {
  final String metric;
  final String value;
  final String unit;
  final String refRange;
  final String date;

  const LabDraft({
    required this.metric,
    required this.value,
    required this.unit,
    required this.refRange,
    required this.date,
  });
}

class MainDashboardScreen extends StatefulWidget {
  final String lang;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onLockRequested;

  const MainDashboardScreen({
    super.key,
    required this.lang,
    required this.onLanguageChanged,
    required this.onLockRequested,
  });

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentTabIndex = 0;
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _canUseBiometric = false;

  List<LabEntry> _labs = <LabEntry>[];

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
  final AppLockService _appLockService = AppLockService.instance;
  final AppSettingsService _appSettingsService = AppSettingsService.instance;
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
            'hepatovita_backup_${DateTime.now().toIso8601String().split('T').first}.hvbk',
        dialogTitle: l10n.tr('save_sqlite_backup'),
      );
      if (!mounted) return;

      if (Platform.isAndroid || Platform.isIOS) {
        await Share.shareXFiles(
          [XFile(savedPath)],
          subject: 'HepatoVita Backup',
          text: 'HepatoVita backup (.hvbk)',
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

    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.document_scanner_rounded),
                title: Text(l10n.tr('add_lab_from_image')),
                onTap: () => Navigator.of(sheetContext).pop('image'),
              ),
              ListTile(
                leading: const Icon(Icons.edit_note_rounded),
                title: Text(l10n.tr('add_lab_manual')),
                onTap: () => Navigator.of(sheetContext).pop('manual'),
              ),
            ],
          ),
        );
      },
    );

    if (choice == 'manual') {
      await _upsertLabEntry();
      return;
    }

    if (choice == 'image') {
      await _upsertLabEntryFromImage();
    }
  }

  Future<void> _upsertLabEntryFromImage() async {
    final l10n = AppLocalizations.of(context);
    final source = await _chooseImageSource();
    if (source == null) {
      return;
    }

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

    final draft = _parseLabDraftFromText(extractedText);
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

  LabDraft? _parseLabDraftFromText(String text) {
    final normalized = text.replaceAll(',', '.');
    final lines = normalized
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return null;
    }

    final metricAliases = <String, List<String>>{
      'ALT (SGPT)': ['alt', 'sgpt'],
      'AST (SGOT)': ['ast', 'sgot'],
      'Vitamin D (25-OH)': ['vitamin d', '25-oh', '25 oh'],
      'Hemoglobin (Hgb)': ['hemoglobin', 'hgb'],
      'HbA1C': ['hba1c', 'a1c'],
    };

    String metric = '';
    String value = '';
    String unit = '';
    String refRange = '';

    String candidateLine = lines.first;
    for (final line in lines) {
      final lower = line.toLowerCase();
      for (final entry in metricAliases.entries) {
        final hasAlias = entry.value.any(lower.contains);
        if (hasAlias) {
          metric = entry.key;
          candidateLine = line;
          break;
        }
      }
      if (metric.isNotEmpty) {
        break;
      }
    }

    final numberRegex = RegExp(r'(-?\d+(?:\.\d+)?)');
    final unitRegex = RegExp(r'(U/L|IU/L|mg/dL|mmol/L|ng/mL|g/dL|%)', caseSensitive: false);
    final rangeRegex = RegExp(
      r'((?:<|>)\s*\d+(?:\.\d+)?\s*[%A-Za-z/]+?|\d+(?:\.\d+)?\s*-\s*\d+(?:\.\d+)?\s*[%A-Za-z/]+?)',
      caseSensitive: false,
    );

    final valueMatch = numberRegex.firstMatch(candidateLine);
    if (valueMatch != null) {
      value = valueMatch.group(1) ?? '';
    }

    final unitMatch = unitRegex.firstMatch(candidateLine);
    if (unitMatch != null) {
      unit = unitMatch.group(1)?.toUpperCase() ?? '';
    }

    final rangeMatch = rangeRegex.firstMatch(normalized);
    if (rangeMatch != null) {
      refRange = rangeMatch.group(1) ?? '';
    }

    if (metric.isEmpty) {
      metric = candidateLine.split(RegExp(r'\s{2,}|:')).first.trim();
    }

    final dateMatch = RegExp(r'(\d{4}[-/]\d{1,2}[-/]\d{1,2})').firstMatch(normalized);
    final parsedDate = dateMatch?.group(1)?.replaceAll('/', '-') ??
        DateTime.now().toIso8601String().split('T').first;

    if (metric.isEmpty || value.isEmpty) {
      return null;
    }

    return LabDraft(
      metric: metric,
      value: value,
      unit: unit,
      refRange: refRange,
      date: parsedDate,
    );
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
    try {
      final source = await _chooseImageSource();
      if (source == null) {
        return;
      }

      final barcode = await _mealImageExtractionService.extractBarcode(
        source: source,
      );
      if (barcode == null || barcode.trim().isEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.tr('barcode_not_found_in_image')),
          ),
        );
        return;
      }

      _mealSearchController.text = barcode;
      await _analyzeMeal(barcode);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.tr('barcode_image_analysis_failed', args: {'error': '$e'}),
          ),
        ),
      );
    }
  }

  Future<void> _analyzeMealFromTextImage() async {
    final l10n = AppLocalizations.of(context);
    try {
      final source = await _chooseImageSource();
      if (source == null) {
        return;
      }

      final extractedText = await _mealImageExtractionService.extractText(
        source: source,
      );
      if (extractedText == null || extractedText.trim().isEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.tr('text_not_found_in_image')),
          ),
        );
        return;
      }

      final query = _mealImageExtractionService.pickBestMealQuery(extractedText);
      if (query.trim().isEmpty) {
        return;
      }

      _mealSearchController.text = query;
      await _analyzeMeal(query);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.tr('text_image_analysis_failed', args: {'error': '$e'}),
          ),
        ),
      );
    }
  }

  Future<ImageSource?> _chooseImageSource() {
    final l10n = AppLocalizations.of(context);
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: Text(l10n.tr('image_source_camera')),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: Text(l10n.tr('image_source_gallery')),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateNotifications(bool enabled) async {
    await _appSettingsService.setNotificationsEnabled(enabled);
    if (!mounted) {
      return;
    }
    setState(() {
      _notificationsEnabled = enabled;
    });
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
                        localError = isAr ? 'PIN الحالي غير صحيح' : 'Current PIN is incorrect';
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
                        localError = isAr ? 'PIN غير متطابق' : 'PIN confirmation does not match';
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
          NavigationDestination(
            icon: const Icon(Icons.person_rounded),
            label: isAr ? 'الملف' : 'Profile',
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
      case 4:
        return _buildModernProfileTab(isAr);
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
      onAddLab: _showAddLabEntryOptions,
      onEditLab: (index) => _upsertLabEntry(index: index),
      onDeleteLab: _deleteLabEntry,
      onAddResult: (index) => _addLabResult(_labs[index]),
    );
  }

  Widget _buildModernEducationTab(bool isAr) {
    return EducationTabView(isAr: isAr);
  }

  Widget _buildModernProfileTab(bool isAr) {
    return ProfileTabView(
      isAr: isAr,
      notificationsEnabled: _notificationsEnabled,
      biometricEnabled: _biometricEnabled,
      canUseBiometric: _canUseBiometric,
      onNotificationsChanged: _updateNotifications,
      onBiometricChanged: _updateBiometric,
      onChangePin: _showChangePinDialog,
      onExportBackup: _exportBackupFile,
      onRestoreBackup: _restoreBackupFile,
      onLockNow: widget.onLockRequested,
    );
  }
}

