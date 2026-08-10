import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class EducationTabView extends StatelessWidget {
  final bool isAr;

  const EducationTabView({
    super.key,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
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
                l10n.tr('education_superfoods_title'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3B2B)),
              ),
              const SizedBox(height: 16),
              _SuperfoodCard(
                icon: Icons.coffee_rounded,
                title: l10n.tr('education_superfood_green_tea_title'),
                description: l10n.tr('education_superfood_green_tea_desc'),
              ),
              _SuperfoodCard(
                icon: Icons.eco_rounded,
                title: l10n.tr('education_superfood_broccoli_title'),
                description: l10n.tr('education_superfood_broccoli_desc'),
              ),
              _SuperfoodCard(
                icon: Icons.phishing_rounded,
                title: l10n.tr('education_superfood_salmon_title'),
                description: l10n.tr('education_superfood_salmon_desc'),
              ),
              _SuperfoodCard(
                icon: Icons.water_drop_rounded,
                title: l10n.tr('education_superfood_olive_oil_title'),
                description: l10n.tr('education_superfood_olive_oil_desc'),
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
  final String title;
  final String description;

  const _SuperfoodCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6E8DE)),
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
                Text(description, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
