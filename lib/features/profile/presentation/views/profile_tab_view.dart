import 'package:flutter/material.dart';

class ProfileTabView extends StatelessWidget {
  final bool isAr;
  final String currentLanguage;
  final bool notificationsEnabled;
  final bool biometricEnabled;
  final bool canUseBiometric;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<bool> onBiometricChanged;
  final VoidCallback onChangePin;
  final VoidCallback onExportPdfReport;
  final VoidCallback onExportBackup;
  final VoidCallback onRestoreBackup;
  final VoidCallback onLockNow;

  const ProfileTabView({
    super.key,
    required this.isAr,
    required this.currentLanguage,
    required this.notificationsEnabled,
    required this.biometricEnabled,
    required this.canUseBiometric,
    required this.onLanguageChanged,
    required this.onNotificationsChanged,
    required this.onBiometricChanged,
    required this.onChangePin,
    required this.onExportPdfReport,
    required this.onExportBackup,
    required this.onRestoreBackup,
    required this.onLockNow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileHeader(isAr: isAr),
        const SizedBox(height: 12),
        _LanguageSelectorTile(
          isAr: isAr,
          currentLanguage: currentLanguage,
          onLanguageChanged: onLanguageChanged,
        ),
        const SizedBox(height: 10),
        _ProfileTile(
          icon: Icons.lock_rounded,
          title: isAr ? 'تغيير PIN' : 'Change PIN',
          subtitle: isAr
              ? 'قم بتحديث رمز الأمان لحماية بياناتك'
              : 'Update your app lock PIN',
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onChangePin,
        ),
        const SizedBox(height: 10),
        _ProfileSwitchTile(
          icon: Icons.notifications_active_rounded,
          title: isAr ? 'إشعارات التنبيه' : 'Critical Alerts Notifications',
          subtitle: isAr
              ? 'تفعيل/تعطيل إشعارات التحاليل الحرجة'
              : 'Enable or disable critical lab alerts',
          value: notificationsEnabled,
          onChanged: onNotificationsChanged,
        ),
        const SizedBox(height: 10),
        _ProfileSwitchTile(
          icon: Icons.fingerprint_rounded,
          title: isAr ? 'فتح بالبصمة/الوجه' : 'Biometric Unlock',
          subtitle: canUseBiometric
              ? (isAr
                    ? 'استخدم البصمة أو الوجه لفتح التطبيق'
                    : 'Use fingerprint/face to unlock app')
              : (isAr
                    ? 'جهازك لا يدعم البصمة أو غير مفعلة'
                    : 'Biometric authentication is not available on this device'),
          value: biometricEnabled,
          enabled: canUseBiometric,
          onChanged: onBiometricChanged,
        ),
        const SizedBox(height: 14),
        Text(
          isAr ? 'النسخ الاحتياطي والخصوصية' : 'Backup & Privacy',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF102018),
          ),
        ),
        const SizedBox(height: 8),
        _ProfileTile(
          icon: Icons.picture_as_pdf_rounded,
          title: isAr ? 'تصدير تقرير PDF طبي' : 'Export Medical PDF Report',
          subtitle: isAr
              ? 'إنشاء تقرير مختصر لمشاركته مع الطبيب'
              : 'Generate a summary report you can share with your doctor',
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onExportPdfReport,
        ),
        const SizedBox(height: 10),
        _ProfileTile(
          icon: Icons.upload_file_rounded,
          title: isAr ? 'تصدير نسخة احتياطية مشفرة' : 'Export Encrypted Backup',
          subtitle: isAr
              ? 'احفظ نسخة Hvbk مؤمنة من بياناتك'
              : 'Save a secure .hvbk backup of your data',
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onExportBackup,
        ),
        const SizedBox(height: 10),
        _ProfileTile(
          icon: Icons.download_rounded,
          title: isAr ? 'استعادة النسخة الاحتياطية' : 'Restore Backup',
          subtitle: isAr
              ? 'استرجع البيانات من ملف نسخة احتياطية'
              : 'Restore app data from a backup file',
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onRestoreBackup,
        ),
        const SizedBox(height: 10),
        _ProfileTile(
          icon: Icons.lock_clock_rounded,
          title: isAr ? 'قفل التطبيق الآن' : 'Lock App Now',
          subtitle: isAr
              ? 'اقفل التطبيق فورا واطلب إعادة التحقق'
              : 'Immediately lock and require re-authentication',
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onLockNow,
        ),
      ],
    );
  }
}

class _LanguageSelectorTile extends StatelessWidget {
  final bool isAr;
  final String currentLanguage;
  final ValueChanged<String> onLanguageChanged;

  const _LanguageSelectorTile({
    required this.isAr,
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE6E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2E22),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF5F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.language_rounded, color: Color(0xFF1B3B2B), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'لغة التطبيق' : 'App Language',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF102018),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAr ? 'غيّر اللغة في أي وقت' : 'Change language anytime',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _LanguageChoiceButton(
                  title: 'English',
                  active: currentLanguage == 'en',
                  onTap: () => onLanguageChanged('en'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LanguageChoiceButton(
                  title: 'العربية',
                  active: currentLanguage == 'ar',
                  onTap: () => onLanguageChanged('ar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageChoiceButton extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _LanguageChoiceButton({
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1F5A45) : const Color(0xFFF4F7F4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? const Color(0xFF1B3B2B) : const Color(0xFFD9E4DD),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final bool isAr;

  const _ProfileHeader({required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF174535), Color(0xFF2A7658), Color(0xFF3A8D6D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22113A2B),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'الملف الشخصي والإعدادات' : 'Profile & Settings',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr ? 'إدارة الأمان والتنبيهات' : 'Manage security and alerts',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDE6E0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120F2E22),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF5F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF1B3B2B), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF102018),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _ProfileSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ProfileSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE6E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2E22),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF5F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF1B3B2B), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF102018),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}
