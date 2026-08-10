import 'dart:math' as math;

import 'package:flutter/material.dart';

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
              crossAxisAlignment: isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: isAr ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        isAr ? 'اطمئن' : 'It',
                        overflow: TextOverflow.ellipsis,
                        textAlign: isAr ? TextAlign.right : TextAlign.left,
                        style: TextStyle(
                          fontFamily: isAr ? 'Cairo' : 'Outfit',
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (!isAr) ...[
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          'main',
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontFamily: isAr ? 'Cairo' : 'Outfit',
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: const Color(0xFF81C784),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  isAr ? 'رفيقك الصحي والسريري الكبدي' : 'Metabolic & Liver Companion',
                  overflow: TextOverflow.ellipsis,
                  textAlign: isAr ? TextAlign.right : TextAlign.left,
                  style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w500),
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
              tooltip: isAr ? 'القائمة' : 'Menu',
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

  const DashboardHeroScoreCard({
    super.key,
    required this.score,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
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
                isAr ? 'الملف الصحي والسريري للمريض' : 'Clinical Patient Profile',
                maxLines: isCompact ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              );

              final badge = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade900.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade400.withValues(alpha: 0.4)),
                ),
                child: Text(
                  isAr ? 'مخصص' : 'Targeted',
                  style: const TextStyle(color: Color(0xFF81C784), fontSize: 9, fontWeight: FontWeight.bold),
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
                        score >= 80 ? const Color(0xFF81C784) : (score >= 50 ? Colors.amber : Colors.orangeAccent),
                      ),
                    ),
                  ),
                  Text(
                    '$score%',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
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
                                constraints: BoxConstraints(maxWidth: math.max(0, constraints.maxWidth - 24)),
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
                          isAr ? 'أهداف علاجية مخصصة بناءً على نتائج تحاليلك' : 'Therapeutic protocol built for your biomarkers',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
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
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                _PillarTag(value: 'ALT 58', label: isAr ? 'إنزيم الكبد' : 'ALT / AST', color: Colors.amber),
                _PillarTag(value: '16 ng/mL', label: isAr ? 'فيتامين د' : 'Vitamin D', color: Colors.purpleAccent),
                _PillarTag(value: '3.0L Water', label: isAr ? 'ترطيب Hgb' : 'Hgb Hydration', color: Colors.lightBlueAccent),
                _PillarTag(value: '5.0%', label: isAr ? 'التراكمي' : 'HbA1C', color: const Color(0xFF81C784)),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
            _TabSegment(
              title: isAr ? 'الرئيسية والمتتبعات' : 'Dashboard',
              icon: Icons.dashboard_rounded,
              active: currentTabIndex == 0,
              onTap: () => onTabSelected(0),
            ),
            _TabSegment(
              title: isAr ? 'مُحلل الوجبات' : 'Meal Analyzer',
              icon: Icons.restaurant_rounded,
              active: currentTabIndex == 1,
              onTap: () => onTabSelected(1),
            ),
            _TabSegment(
              title: isAr ? 'الفحوصات' : 'Biomarkers',
              icon: Icons.science_rounded,
              active: currentTabIndex == 2,
              onTap: () => onTabSelected(2),
            ),
            _TabSegment(
              title: isAr ? 'الدليل الطبي' : 'Guidance',
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
          child: Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
