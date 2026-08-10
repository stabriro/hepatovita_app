import 'package:flutter/material.dart';

class EducationTabView extends StatelessWidget {
  final bool isAr;

  const EducationTabView({
    super.key,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'أبرز الأغذية الفائقة لدعم صحة الكبد' : 'Top Liver Rescue Superfoods',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3B2B)),
              ),
              const SizedBox(height: 16),
              const _SuperfoodCard(
                icon: Icons.coffee_rounded,
                titleAr: 'الشاي الأخضر (EGCG)',
                titleEn: 'Green Tea (EGCG)',
                descAr: 'مضاد أكسدة قوي لحماية خلايا الكبد من الإجهاد',
                descEn: 'Potent hepatocyte antioxidant protection',
              ),
              const _SuperfoodCard(
                icon: Icons.eco_rounded,
                titleAr: 'البروكلي والكرنب',
                titleEn: 'Broccoli & Kale',
                descAr: 'يحفز إنزيمات تنظيف سموم الكبد الطبيعية',
                descEn: 'Boosts hepatic detox enzymes',
              ),
              const _SuperfoodCard(
                icon: Icons.phishing_rounded,
                titleAr: 'السلمون البري (أوميغا-3)',
                titleEn: 'Wild Salmon (Omega-3)',
                descAr: 'دهون صحية ممتازة لامتصاص فيتامين د3',
                descEn: 'Healthy lipids for Vit D3 absorption',
              ),
              const _SuperfoodCard(
                icon: Icons.water_drop_rounded,
                titleAr: 'زيت الزيتون البكر',
                titleEn: 'Extra Virgin Olive Oil',
                descAr: 'دهون غير مشبعة صديقة لإنزيمات ALT/AST',
                descEn: 'Unsaturated fats gentle on ALT/AST',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SuperfoodCard extends StatelessWidget {
  final IconData icon;
  final String titleAr;
  final String titleEn;
  final String descAr;
  final String descEn;

  const _SuperfoodCard({
    required this.icon,
    required this.titleAr,
    required this.titleEn,
    required this.descAr,
    required this.descEn,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final title = isAr ? titleAr : titleEn;
    final desc = isAr ? descAr : descEn;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B3B2B))),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
