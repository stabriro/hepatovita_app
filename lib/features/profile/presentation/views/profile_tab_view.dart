import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
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
          title: l10n.tr('profile_change_pin_title'),
          subtitle: l10n.tr('profile_change_pin_subtitle'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onChangePin,
        ),
        const SizedBox(height: 10),
        _ProfileSwitchTile(
          icon: Icons.notifications_active_rounded,
          title: l10n.tr('profile_alerts_title'),
          subtitle: l10n.tr('profile_alerts_subtitle'),
          value: notificationsEnabled,
          onChanged: onNotificationsChanged,
        ),
        const SizedBox(height: 10),
        _ProfileSwitchTile(
          icon: Icons.fingerprint_rounded,
          title: l10n.tr('profile_biometric_title'),
          subtitle: canUseBiometric
              ? l10n.tr('profile_biometric_subtitle_enabled')
              : l10n.tr('profile_biometric_subtitle_unavailable'),
          value: biometricEnabled,
          enabled: canUseBiometric,
          onChanged: onBiometricChanged,
        ),
        const SizedBox(height: 14),
        Text(
          l10n.tr('profile_backup_section_title'),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF102018),
          ),
        ),
        const SizedBox(height: 8),
        _ProfileTile(
          icon: Icons.picture_as_pdf_rounded,
          title: l10n.tr('profile_export_pdf_title'),
          subtitle: l10n.tr('profile_export_pdf_subtitle'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onExportPdfReport,
        ),
        const SizedBox(height: 10),
        _ProfileTile(
          icon: Icons.upload_file_rounded,
          title: l10n.tr('profile_export_backup_title'),
          subtitle: l10n.tr('profile_export_backup_subtitle'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onExportBackup,
        ),
        const SizedBox(height: 10),
        _ProfileTile(
          icon: Icons.download_rounded,
          title: l10n.tr('profile_restore_backup_title'),
          subtitle: l10n.tr('profile_restore_backup_subtitle'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onRestoreBackup,
        ),
        const SizedBox(height: 10),
        _ProfileTile(
          icon: Icons.lock_clock_rounded,
          title: l10n.tr('profile_lock_now_title'),
          subtitle: l10n.tr('profile_lock_now_subtitle'),
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
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE6E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4EF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.language_rounded,
                    color: Color(0xFF1B3B2B), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tr('profile_language_title'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF102018),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.tr('profile_language_subtitle'),
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
                  title: l10n.tr('language_option_english'),
                  active: currentLanguage == 'en',
                  onTap: () => onLanguageChanged('en'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LanguageChoiceButton(
                  title: l10n.tr('language_option_arabic'),
                  active: currentLanguage == 'ar',
                  onTap: () => onLanguageChanged('ar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LanguageChoiceButton(
                  title: l10n.tr('language_option_tunisian'),
                  active: currentLanguage == 'ar_TN',
                  onTap: () => onLanguageChanged('ar_TN'),
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
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF133D30), Color(0xFF1A5B45), Color(0xFF2B8B66)],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tr('profile_header_title'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.tr('profile_header_subtitle'),
            style: const TextStyle(
              color: Color(0xC9FFFFFF),
              fontSize: 13,
              fontWeight: FontWeight.w500,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDE6E0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1B3B2B), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
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
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1B3B2B), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
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
