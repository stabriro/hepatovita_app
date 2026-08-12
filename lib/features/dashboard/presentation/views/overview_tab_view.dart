import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

const _brandPine = Color(0xFF1A4D3B);
const _brandFern = Color(0xFF2F8F68);
const _brandMint = Color(0xFFA5E0D7);
const _brandSky = Color(0xFF92BFEF);

class OverviewTabView extends StatelessWidget {
  final bool isAr;
  final bool hasLabs;
  final String? coachSummary;
  final bool isGeneratingCoachSummary;
  final VoidCallback onOpenMealAnalyzer;
  final int waterAmount;
  final int waterGoal;
  final int greenTeaCount;
  final int teaGoal;
  final bool chkVitD;
  final bool walk30;
  final bool sun15;
  final bool lowFatDay;
  final ValueChanged<int> onAddWater;
  final ValueChanged<int> onChangeTea;
  final ValueChanged<bool> onChkVitDChanged;
  final ValueChanged<bool> onWalk30Changed;
  final ValueChanged<bool> onSun15Changed;
  final ValueChanged<bool> onLowFatDayChanged;

  const OverviewTabView({
    super.key,
    required this.isAr,
    required this.hasLabs,
    required this.coachSummary,
    required this.isGeneratingCoachSummary,
    required this.onOpenMealAnalyzer,
    required this.waterAmount,
    required this.waterGoal,
    required this.greenTeaCount,
    required this.teaGoal,
    required this.chkVitD,
    required this.walk30,
    required this.sun15,
    required this.lowFatDay,
    required this.onAddWater,
    required this.onChangeTea,
    required this.onChkVitDChanged,
    required this.onWalk30Changed,
    required this.onSun15Changed,
    required this.onLowFatDayChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final waterPct = (waterAmount / waterGoal).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        final cardPadding = compact ? 16.0 : 20.0;
        final sectionGap = compact ? 12.0 : 16.0;
        final innerGap = compact ? 16.0 : 20.0;
        final hasCoachSummary =
            coachSummary != null && coachSummary!.trim().isNotEmpty;

        return Column(
          children: [
            _SectionEntrance(
              duration: const Duration(milliseconds: 380),
              yOffset: compact ? 14 : 20,
              child: Container(
                padding: EdgeInsets.all(cardPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE2EDE6)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x120F2E22),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE7F4FB),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.water_drop_rounded,
                                  color: _brandSky,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.tr('overview_hydration_title'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF1B3B2B)),
                                    ),
                                    Text(
                                      l10n.tr('overview_hydration_subtitle'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7F4FB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(waterPct * 100).round()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _brandSky,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: innerGap),
                    Center(
                      child: Container(
                        width: 140,
                        height: 170,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                              color: _brandSky.withValues(alpha: 0.55),
                              width: 3),
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
                                  colors: [
                                    Color(0xFFA5E0D7),
                                    Color(0xFF92BFEF)
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(24)),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              child: Text(
                                '$waterAmount / $waterGoal mL',
                                style: TextStyle(
                                  color: waterPct > 0.4
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: innerGap),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => onAddWater(250),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('+250 mL',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                        SizedBox(width: compact ? 6 : 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => onAddWater(500),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _brandSky,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('+500 mL',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                        SizedBox(width: compact ? 6 : 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => onAddWater(750),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _brandPine,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('+750 mL',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 10 : 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7F4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _brandMint.withValues(alpha: 0.85)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.coffee_rounded,
                                    color: _brandFern, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.tr('overview_green_tea_counter'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Color(0xFF1B3B2B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => onChangeTea(-1),
                                icon: const Icon(Icons.remove_circle_outline,
                                    size: 20, color: Colors.grey),
                              ),
                              Text(
                                '$greenTeaCount / $teaGoal',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: _brandFern,
                                ),
                              ),
                              IconButton(
                                onPressed: () => onChangeTea(1),
                                icon: const Icon(Icons.add_circle_rounded,
                                    size: 20, color: _brandFern),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: sectionGap),
            _SectionEntrance(
              duration: const Duration(milliseconds: 460),
              yOffset: compact ? 14 : 20,
              child: Container(
                padding: EdgeInsets.all(cardPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE2EDE6)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x120F2E22),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF5F0),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.psychology_alt_rounded,
                            color: _brandFern,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.tr('coach_card_title'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF1B3B2B)),
                              ),
                              Text(
                                l10n.tr('coach_card_subtitle'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 11,
                                    height: 1.2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAF8),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFD7E7DB)),
                      ),
                      child: isGeneratingCoachSummary
                          ? Row(
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.2),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l10n.tr('coach_card_loading'),
                                    style: const TextStyle(
                                        fontSize: 12, color: Color(0xFF1B3B2B)),
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              hasCoachSummary
                                  ? coachSummary!
                                  : l10n.tr('coach_card_empty'),
                              style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.45,
                                  color: Color(0xFF1B3B2B)),
                            ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onOpenMealAnalyzer,
                        icon:
                            const Icon(Icons.restaurant_menu_rounded, size: 18),
                        label: Text(l10n.tr('coach_card_action')),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _brandFern),
                          foregroundColor: _brandFern,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: sectionGap),
            _SectionEntrance(
              duration: const Duration(milliseconds: 520),
              yOffset: compact ? 14 : 20,
              child: Container(
                padding: EdgeInsets.all(cardPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE2EDE6)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x120F2E22),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tr('overview_checklist_title'),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1B3B2B)),
                    ),
                    const SizedBox(height: 12),
                    if (!hasLabs)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F7F4),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFD7E7DB)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEAF5F0),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.science_rounded,
                                color: _brandFern,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.tr('overview_checklist_empty_title'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF1B3B2B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.tr(
                                        'overview_checklist_empty_subtitle'),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      _CheckTile(
                        title: l10n.tr('overview_check_vitd_title'),
                        subtitle: l10n.tr('overview_check_vitd_subtitle'),
                        value: chkVitD,
                        onChanged: onChkVitDChanged,
                        tag: 'Vit D',
                        tagColor: _brandSky,
                      ),
                      _CheckTile(
                        title: l10n.tr('overview_check_walk_title'),
                        subtitle: l10n.tr('overview_check_walk_subtitle'),
                        value: walk30,
                        onChanged: onWalk30Changed,
                        tag: 'ALT Care',
                        tagColor: _brandFern,
                      ),
                      _CheckTile(
                        title: l10n.tr('overview_check_sun_title'),
                        subtitle: l10n.tr('overview_check_sun_subtitle'),
                        value: sun15,
                        onChanged: onSun15Changed,
                        tag: 'Sun D3',
                        tagColor: const Color(0xFFB57A1D),
                      ),
                      _CheckTile(
                        title: l10n.tr('overview_check_low_fat_title'),
                        subtitle: l10n.tr('overview_check_low_fat_subtitle'),
                        value: lowFatDay,
                        onChanged: onLowFatDayChanged,
                        tag: 'ALT/AST',
                        tagColor: _brandPine,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionEntrance extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final double yOffset;

  const _SectionEntrance({
    required this.child,
    required this.duration,
    this.yOffset = 18,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, builtChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * yOffset),
            child: builtChild,
          ),
        );
      },
    );
  }
}

class _CheckTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String tag;
  final Color tagColor;

  const _CheckTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.tag,
    required this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            children: [
              Checkbox(
                value: value,
                activeColor: _brandFern,
                onChanged: (v) => onChanged(v ?? false),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: tagColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(tag,
                              style: TextStyle(
                                  color: tagColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
