import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localization = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localization != null, 'AppLocalizations not found in context');
    return localization!;
  }

  bool get isAr => locale.languageCode == 'ar';

  static const Map<String, Map<String, String>> _values = {
    'en': {
      'app_title': 'HepatoVita Companion',
      'backup': 'Backup',
      'restore': 'Restore',
      'add_lab': 'Add Lab',
      'sqlite_backup_hint': 'SQLite: Export and restore your local data.',
      'save_sqlite_backup': 'Save SQLite Backup',
      'backup_saved_to': 'Backup saved to {path}',
      'backup_failed': 'Backup failed: {error}',
      'restore_backup_title': 'Restore Backup?',
      'restore_backup_message': 'This will replace current app data with the selected backup file.',
      'cancel': 'Cancel',
      'restore_action': 'Restore',
      'restore_success': 'Backup restored successfully.',
      'restore_failed': 'Restore failed: {error}',
      'status_auto': 'Status is auto-calculated from reference range.',
      'target_unknown': 'Target Unknown',
      'on_target': 'On Target',
      'off_target': 'Off Target',
      'no_trend': 'No Trend',
      'stable': 'Stable',
      'improving': 'Improving',
      'worsening': 'Worsening',
      'alerts_none': 'No active alerts. Biomarkers look stable.',
      'alert_worsening_title': 'Worsening Risk: {metric}',
      'alert_worsening_message': 'Value {value} {unit} is off target and trending worse. Review care plan.',
      'alert_off_target_title': 'Off Target: {metric}',
      'alert_off_target_message': 'Result is outside reference range. Add new results to monitor improvement.',
      'alert_unknown_target_title': 'Unknown Target: {metric}',
      'alert_unknown_target_message': 'Reference range cannot be parsed. Use formats like 7-56, < 5.7, or > 30.',
      'alert_good_title': 'Good Progress: {metric}',
      'alert_good_message': 'Result is on target and improving over time.',
      'high_alert_popup': 'High Alert: {metric} is worsening off target.',
      'high_alert_title': 'High Clinical Alert',
      'view': 'View',
      'trend_history': 'Trend History',
      'records_count': '{count} records',
      'no_history': 'No history yet. Add a new result.',
      'latest_value': 'Latest: {value} {unit} on {date}',
      'critical': 'Critical',
      'warning': 'Warning',
      'info': 'Info',
    },
    'ar': {
      'app_title': 'مرافق هيباتوفيتا',
      'backup': 'نسخ احتياطي',
      'restore': 'استعادة',
      'add_lab': 'إضافة فحص',
      'sqlite_backup_hint': 'SQLite: نسخ واستعادة البيانات المحلية.',
      'save_sqlite_backup': 'حفظ النسخة الاحتياطية',
      'backup_saved_to': 'تم حفظ النسخة الاحتياطية في {path}',
      'backup_failed': 'فشل النسخ الاحتياطي: {error}',
      'restore_backup_title': 'استعادة النسخة الاحتياطية؟',
      'restore_backup_message': 'سيتم استبدال البيانات الحالية بالملف المحدد.',
      'cancel': 'إلغاء',
      'restore_action': 'استعادة',
      'restore_success': 'تمت الاستعادة بنجاح.',
      'restore_failed': 'فشلت الاستعادة: {error}',
      'status_auto': 'يتم حساب الحالة تلقائيا من المجال المرجعي.',
      'target_unknown': 'الهدف غير معروف',
      'on_target': 'ضمن الهدف',
      'off_target': 'خارج الهدف',
      'no_trend': 'لا يوجد اتجاه',
      'stable': 'مستقر',
      'improving': 'يتحسن',
      'worsening': 'يتدهور',
      'alerts_none': 'لا توجد تنبيهات حالية. المؤشرات مستقرة.',
      'alert_worsening_title': 'تدهور واضح: {metric}',
      'alert_worsening_message': 'القيمة {value} {unit} خارج الهدف وتتجه للأسوأ. يُنصح بمراجعة الخطة العلاجية.',
      'alert_off_target_title': 'خارج الهدف: {metric}',
      'alert_off_target_message': 'النتيجة خارج المجال المرجعي. أضف نتائج جديدة لمتابعة التحسن.',
      'alert_unknown_target_title': 'مرجع غير واضح: {metric}',
      'alert_unknown_target_message': 'المرجع الحالي غير قابل للقراءة. أدخل مرجعا مثل 7-56 أو < 5.7 أو > 30.',
      'alert_good_title': 'تحسن جيد: {metric}',
      'alert_good_message': 'النتيجة ضمن الهدف ومع اتجاه تحسن.',
      'high_alert_popup': 'تنبيه عالي: {metric} يتدهور خارج الهدف.',
      'high_alert_title': 'تنبيه سريري عالي',
      'view': 'عرض',
      'trend_history': 'اتجاه الفحوصات',
      'records_count': '{count} قياس',
      'no_history': 'لا يوجد تاريخ بعد. أضف نتيجة جديدة.',
      'latest_value': 'آخر نتيجة: {value} {unit} في {date}',
      'critical': 'حرج',
      'warning': 'تحذير',
      'info': 'معلومة',
    },
  };

  String tr(String key, {Map<String, String>? args}) {
    final langValues = _values[locale.languageCode] ?? _values['en']!;
    var value = langValues[key] ?? _values['en']![key] ?? key;
    if (args != null) {
      args.forEach((k, v) {
        value = value.replaceAll('{$k}', v);
      });
    }
    return value;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((l) => l.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}