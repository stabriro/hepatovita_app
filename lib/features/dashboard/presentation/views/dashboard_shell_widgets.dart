import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class DashboardHeader extends StatelessWidget {
  final bool isAr;
  final VoidCallback onMenuPressed;

  const DashboardHeader({
    super.key,
    required this.isAr,
    required this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF174535), Color(0xFF1F5A45), Color(0xFF2F7A5D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF123527).withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      isAr ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        l10n.tr('app_title'),
                        overflow: TextOverflow.ellipsis,
                        textAlign: isAr ? TextAlign.right : TextAlign.left,
                        style: TextStyle(
                          fontFamily: isAr ? 'Cairo' : 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  l10n.tr('dashboard_header_subtitle'),
                  overflow: TextOverflow.ellipsis,
                  textAlign: isAr ? TextAlign.right : TextAlign.left,
                  style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
            ),
            child: IconButton(
              tooltip: l10n.tr('menu'),
              onPressed: onMenuPressed,
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardHeroScoreCard extends StatelessWidget {
  final int score;
  final bool isAr;
  final List<DashboardHeroBiomarkerTag> biomarkerTags;
  final String emptyBiomarkerText;

  const DashboardHeroScoreCard({
    super.key,
    required this.score,
    required this.isAr,
    required this.biomarkerTags,
    required this.emptyBiomarkerText,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF174535), Color(0xFF133A2D), Color(0xFF0E2D23)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102D22).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 320;

              final titleText = Text(
                l10n.tr('dashboard_profile_title'),
                maxLines: isCompact ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              );

              final badge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3D2D).withValues(alpha: 0.46),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFA5E0D7).withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  l10n.tr('dashboard_targeted_badge'),
                  style: const TextStyle(
                      color: Color(0xFFA5E0D7),
                      fontSize: 9,
                      fontWeight: FontWeight.bold),
                ),
              );

              final scoreIndicator = Stack(
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
                        score >= 80
                            ? const Color(0xFFA5E0D7)
                            : (score >= 50
                                ? const Color(0xFF92BFEF)
                                : const Color(0xFFF59E0B)),
                      ),
                    ),
                  ),
                  Text(
                    '$score%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900),
                  ),
                ],
              );

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isCompact)
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                    maxWidth:
                                        math.max(0, constraints.maxWidth - 24)),
                                child: titleText,
                              ),
                              badge,
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(child: titleText),
                              const SizedBox(width: 6),
                              badge,
                            ],
                          ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.tr('dashboard_profile_subtitle'),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  scoreIndicator,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: biomarkerTags.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      emptyBiomarkerText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: biomarkerTags
                        .map(
                          (tag) => _PillarTag(
                            value: tag.value,
                            label: tag.label,
                            color: tag.color,
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class DashboardHeroBiomarkerTag {
  final String value;
  final String label;
  final Color color;

  const DashboardHeroBiomarkerTag({
    required this.value,
    required this.label,
    required this.color,
  });
}

class DashboardSegmentedTabBar extends StatelessWidget {
  final bool isAr;
  final int currentTabIndex;
  final ValueChanged<int> onTabSelected;

  const DashboardSegmentedTabBar({
    super.key,
    required this.isAr,
    required this.currentTabIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _TabSegment(
              title: l10n.tr('dashboard_tab_overview'),
              icon: Icons.dashboard_rounded,
              active: currentTabIndex == 0,
              onTap: () => onTabSelected(0),
            ),
            _TabSegment(
              title: l10n.tr('dashboard_tab_meal_analyzer'),
              icon: Icons.restaurant_rounded,
              active: currentTabIndex == 1,
              onTap: () => onTabSelected(1),
            ),
            _TabSegment(
              title: l10n.tr('dashboard_tab_biomarkers'),
              icon: Icons.science_rounded,
              active: currentTabIndex == 2,
              onTap: () => onTabSelected(2),
            ),
            _TabSegment(
              title: l10n.tr('dashboard_tab_guidance'),
              icon: Icons.menu_book_rounded,
              active: currentTabIndex == 3,
              onTap: () => onTabSelected(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabSegment extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TabSegment({
    required this.title,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2F8F68) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: active ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFF2C4238),
                fontWeight: active ? FontWeight.bold : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillarTag extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _PillarTag({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(value,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
