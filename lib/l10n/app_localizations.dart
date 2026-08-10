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
      'app_title': 'Itmain',
      'backup': 'Backup',
      'restore': 'Restore',
      'add_lab': 'Add Lab',
      'sqlite_backup_hint': 'SQLite: Export and restore your local data.',
      'save_sqlite_backup': 'Save SQLite Backup',
      'backup_saved_to': 'Backup saved to {path}',
      'backup_ready_to_share': 'Backup is ready. Choose where to save/share the file.',
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
      'verify': 'Verify',
      'done': 'Done',
      'forgot_pin': 'Forgot PIN?',
      'recover_with_code_title': 'Recover With Code',
      'recover_with_code_hint': 'Enter your 3-part recovery code (example: 1234-5678-9012).',
      'recovery_code_label': 'Recovery Code',
      'recovery_code_invalid': 'Invalid recovery code',
      'save_recovery_code_title': 'Save Recovery Code',
      'save_recovery_code_hint': 'Use this code to reset PIN if you forget it.',
      'save_recovery_code_footer': 'Store it safely. It will rotate when PIN changes.',
      'new_recovery_code_title': 'New Recovery Code',
      'new_recovery_code_hint': 'Save this code to recover your PIN if forgotten:',
      'image_source_camera': 'Camera',
      'image_source_gallery': 'Gallery',
      'barcode_not_found_in_image': 'No clear barcode was found in the image.',
      'barcode_image_analysis_failed': 'Barcode image analysis failed: {error}',
      'text_not_found_in_image': 'No clear text was detected in the image.',
      'text_image_analysis_failed': 'Text image analysis failed: {error}',
      'meal_analyzer_title': 'Smart Meal & Menu Analyzer',
      'meal_analyzer_hint': 'Type ANY meal (e.g. Kabsa, Salmon, Shawarma)...',
      'analyze_dish': 'Analyze Dish',
      'analyze_barcode': 'Analyze Barcode',
      'analyze_label_text': 'Analyze Label Text',
      'liver_friendly_excellent': 'LIVER FRIENDLY (EXCELLENT)',
      'higher_risk_change_order': 'HIGHER RISK (CHANGE ORDER)',
      'moderate_risk_modify_order': 'MODERATE RISK (MODIFY ORDER)',
      'matched_item': 'Matched item',
      'confidence': 'Confidence',
      'protein_profile': 'Protein Profile',
      'fat_risk_level': 'Fat Risk Level',
      'nutrition_facts_per_100g': 'Nutrition facts (per 100g)',
      'nutrient_energy': 'Energy',
      'nutrient_protein': 'Protein',
      'nutrient_fat': 'Fat',
      'nutrient_sat_fat': 'Sat Fat',
      'nutrient_sugar': 'Sugar',
      'nutrient_sodium': 'Sodium',
      'dynamic_analysis_free_api': 'Dynamic Analysis (Free API)',
      'local_fallback_analysis': 'Local Fallback Analysis',
      'clinical_ordering_modifications': 'Clinical Ordering Modifications',
      'add_lab_choose_method': 'Choose Lab Entry Method',
      'add_lab_from_image': 'Scan Lab Report Image',
      'add_lab_manual': 'Manual Entry',
      'lab_image_no_text': 'No clear text was detected in the selected image.',
      'lab_image_parse_failed': 'Could not extract lab data automatically. You can still enter it manually.',
    },
    'ar': {
      'app_title': 'اطمئن',
      'backup': 'نسخ احتياطي',
      'restore': 'استعادة',
      'add_lab': 'إضافة فحص',
      'sqlite_backup_hint': 'SQLite: نسخ واستعادة البيانات المحلية.',
      'save_sqlite_backup': 'حفظ النسخة الاحتياطية',
      'backup_saved_to': 'تم حفظ النسخة الاحتياطية في {path}',
      'backup_ready_to_share': 'النسخة الاحتياطية جاهزة. اختر المكان المناسب لحفظها أو مشاركتها.',
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
      'verify': 'تحقق',
      'done': 'تم',
      'forgot_pin': 'نسيت PIN؟',
      'recover_with_code_title': 'استعادة باستخدام الرمز',
      'recover_with_code_hint': 'أدخل رمز الاستعادة المكون من 3 مجموعات (مثال: 1234-5678-9012).',
      'recovery_code_label': 'رمز الاستعادة',
      'recovery_code_invalid': 'رمز الاستعادة غير صحيح',
      'save_recovery_code_title': 'احفظ رمز الاستعادة',
      'save_recovery_code_hint': 'استخدم هذا الرمز لإعادة تعيين PIN إذا نسيته.',
      'save_recovery_code_footer': 'احتفظ به في مكان آمن. سيتم تغييره عند تغيير PIN.',
      'new_recovery_code_title': 'رمز الاستعادة الجديد',
      'new_recovery_code_hint': 'احفظ الرمز التالي لاستعادة PIN عند نسيانه:',
      'image_source_camera': 'الكاميرا',
      'image_source_gallery': 'المعرض',
      'barcode_not_found_in_image': 'لم يتم العثور على باركود واضح في الصورة.',
      'barcode_image_analysis_failed': 'فشل تحليل الباركود من الصورة: {error}',
      'text_not_found_in_image': 'لم يتم اكتشاف نص واضح في الصورة.',
      'text_image_analysis_failed': 'فشل تحليل النص من الصورة: {error}',
      'meal_analyzer_title': 'مُحلل الوجبات والقوائم الذكي',
      'meal_analyzer_hint': 'اكتب اسم أي وجبة (مثل: كبسة، سلمون، شاورما)...',
      'analyze_dish': 'تحليل الوجبة',
      'analyze_barcode': 'تحليل عبر الباركود',
      'analyze_label_text': 'تحليل نص الصورة',
      'liver_friendly_excellent': 'صديق للكبد (ممتاز)',
      'higher_risk_change_order': 'خطورة أعلى (غيّر الطلب)',
      'moderate_risk_modify_order': 'خطر متوسط (عدّل الطلب)',
      'matched_item': 'المنتج المطابق',
      'confidence': 'مستوى الثقة',
      'protein_profile': 'البروتين',
      'fat_risk_level': 'خطورة الدهون',
      'nutrition_facts_per_100g': 'القيم الغذائية (لكل 100غ)',
      'nutrient_energy': 'طاقة',
      'nutrient_protein': 'بروتين',
      'nutrient_fat': 'دهون',
      'nutrient_sat_fat': 'دهون مشبعة',
      'nutrient_sugar': 'سكر',
      'nutrient_sodium': 'صوديوم',
      'dynamic_analysis_free_api': 'تحليل ديناميكي (API مجاني)',
      'local_fallback_analysis': 'تحليل محلي احتياطي',
      'clinical_ordering_modifications': 'نصائح وتعديلات الطلب السريرية',
      'add_lab_choose_method': 'اختر طريقة إدخال الفحص',
      'add_lab_from_image': 'مسح صورة تقرير الفحص',
      'add_lab_manual': 'إدخال يدوي',
      'lab_image_no_text': 'لم يتم اكتشاف نص واضح في الصورة المختارة.',
      'lab_image_parse_failed': 'تعذر استخراج بيانات الفحص تلقائيا. يمكنك المتابعة بالإدخال اليدوي.',
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