import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  final bool isAr;
  final String lang;
  final ValueChanged<String> onLanguageChanged;

  const DashboardHeader({
    super.key,
    required this.isAr,
    required this.lang,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B3B2B), Color(0xFF163223)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B3B2B).withOpacity(0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Hepato',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: isAr ? 'Cairo' : 'Outfit',
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        'Vita',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: isAr ? 'Cairo' : 'Outfit',
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: const Color(0xFF81C784),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  isAr ? 'رفيقك الصحي والسريري الكبدي' : 'Metabolic & Liver Companion',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => onLanguageChanged('en'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: lang == 'en' ? const Color(0xFF2E7D32) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('EN', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                GestureDetector(
                  onTap: () => onLanguageChanged('ar'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: lang == 'ar' ? const Color(0xFF2E7D32) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('العربية', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
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
          colors: [Color(0xFF1B3B2B), Color(0xFF0F261B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B3B2B).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isAr ? 'الملف الصحي والسريري للمريض' : 'Clinical Patient Profile',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade900.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade400.withOpacity(0.4)),
                          ),
                          child: Text(
                            isAr ? 'مخصص' : 'Targeted',
                            style: const TextStyle(color: Color(0xFF81C784), fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
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
              Stack(
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
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
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
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
