import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class AppSplashScreen extends StatelessWidget {
  final bool isAr;
  final VoidCallback onContinue;
  final bool isLoadingPhase;

  const AppSplashScreen({
    super.key,
    required this.isAr,
    required this.onContinue,
    this.isLoadingPhase = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final titleSize = screenWidth < 360 ? 42.0 : 48.0;
    final subtitleSize = screenWidth < 360 ? 16.0 : 17.0;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF123B31), Color(0xFF1A624A), Color(0xFF2FA06F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                const Spacer(flex: 2),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.95, end: 1),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    width: 84,
                    height: 84,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/branding/splash_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.tr('app_title'),
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: isAr ? 'Cairo' : 'Plus Jakarta Sans',
                    fontSize: titleSize,
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.tr('splash_subtitle'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xC6FFFFFF),
                    fontSize: subtitleSize,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _SplashTag(label: l10n.tr('splash_tag_dynamic_labs')),
                    _SplashTag(label: l10n.tr('splash_tag_daily_tracking')),
                    _SplashTag(label: l10n.tr('splash_tag_encrypted_backup')),
                  ],
                ),
                const Spacer(flex: 2),
                _SplashStatusPanel(
                  label: isLoadingPhase
                      ? l10n.tr('splash_loading_boot')
                      : l10n.tr('splash_loading_security_check'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: isLoadingPhase ? null : onContinue,
                  child: Text(
                    l10n.tr('splash_skip'),
                    style: const TextStyle(
                      color: Color(0xE6FFFFFF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr
                      ? 'بياناتك مشفرة ومحفوظة على جهازك فقط'
                      : 'Your data is encrypted and stored only on your device',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xA8FFFFFF),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
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

class _SplashStatusPanel extends StatelessWidget {
  final String label;

  const _SplashStatusPanel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
