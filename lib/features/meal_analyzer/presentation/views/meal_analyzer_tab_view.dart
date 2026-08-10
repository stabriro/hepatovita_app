import 'package:flutter/material.dart';

class MealAnalysisUiModel {
  final String dish;
  final String score;
  final String reason;
  final String confidence;
  final String matchedName;
  final double? kcalPer100g;
  final double? proteinPer100g;
  final double? fatPer100g;
  final double? satFatPer100g;
  final double? sugarPer100g;
  final double? sodiumMgPer100g;
  final String caveat;
  final String protein;
  final String fat;
  final List<String> tips;
  final String source;

  const MealAnalysisUiModel({
    required this.dish,
    required this.score,
    required this.reason,
    required this.confidence,
    required this.matchedName,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.fatPer100g,
    required this.satFatPer100g,
    required this.sugarPer100g,
    required this.sodiumMgPer100g,
    required this.caveat,
    required this.protein,
    required this.fat,
    required this.tips,
    required this.source,
  });
}

class MealAnalyzerTabView extends StatelessWidget {
  final bool isAr;
  final TextEditingController mealSearchController;
  final Future<void> Function(String) onAnalyzeMeal;
  final MealAnalysisUiModel? analysis;
  final bool isAnalyzing;

  const MealAnalyzerTabView({
    super.key,
    required this.isAr,
    required this.mealSearchController,
    required this.onAnalyzeMeal,
    required this.analysis,
    required this.isAnalyzing,
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
                isAr ? 'مُحلل الوجبات والقوائم الذكي' : 'Smart Meal & Menu Analyzer',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3B2B)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mealSearchController,
                decoration: InputDecoration(
                  hintText: isAr ? 'اكتب اسم أي وجبة (مثل: كبسة، سلمون، شاورما)...' : 'Type ANY meal (e.g. Kabsa, Salmon, Shawarma)...',
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2E7D32)),
                  filled: true,
                  fillColor: const Color(0xFFF9FBF9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isAnalyzing
                      ? null
                      : () async {
                          await onAnalyzeMeal(mealSearchController.text);
                        },
                  icon: isAnalyzing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(isAr ? 'تحليل الوجبة' : 'Analyze Dish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B3B2B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (analysis != null) ...[
          const SizedBox(height: 16),
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
                  analysis!.dish,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1B3B2B)),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: analysis!.score == 'HIGH'
                        ? Colors.green.shade50
                        : (analysis!.score == 'LOW' ? Colors.red.shade50 : Colors.amber.shade50),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: analysis!.score == 'HIGH'
                          ? Colors.green.shade300
                          : (analysis!.score == 'LOW' ? Colors.red.shade300 : Colors.amber.shade300),
                    ),
                  ),
                  child: Text(
                    analysis!.score == 'HIGH'
                        ? (isAr ? '🟢 صديق للكبد (ممتاز)' : '🟢 LIVER FRIENDLY (EXCELLENT)')
                        : (analysis!.score == 'LOW'
                            ? (isAr ? '🔴 خطورة أعلى (غيّر الطلب)' : '🔴 HIGHER RISK (CHANGE ORDER)')
                            : (isAr ? '🟡 خطر متوسط (عدّل الطلب)' : '🟡 MODERATE RISK (MODIFY ORDER)')),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: analysis!.score == 'HIGH'
                          ? Colors.green.shade900
                          : (analysis!.score == 'LOW' ? Colors.red.shade900 : Colors.amber.shade900),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  analysis!.reason,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Text(
                  '${isAr ? 'المنتج المطابق' : 'Matched item'}: ${analysis!.matchedName}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  '${isAr ? 'مستوى الثقة' : 'Confidence'}: ${analysis!.confidence}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                _MacroMetric(
                  title: isAr ? 'البروتين:' : 'Protein Profile:',
                  subtitle: analysis!.protein,
                  color: Colors.blue,
                  value: 0.8,
                ),
                const SizedBox(height: 8),
                _MacroMetric(
                  title: isAr ? 'خطورة الدهون:' : 'Fat Risk Level:',
                  subtitle: analysis!.fat,
                  color: analysis!.score == 'LOW' ? Colors.red : Colors.green,
                  value: analysis!.score == 'LOW' ? 0.9 : 0.3,
                ),
                if (analysis!.source == 'open_food_facts') ...[
                  const SizedBox(height: 14),
                  Text(
                    isAr ? 'القيم الغذائية (لكل 100غ):' : 'Nutrition facts (per 100g):',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1B3B2B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _NutrientChip(label: isAr ? 'طاقة' : 'Energy', value: _fmt(analysis!.kcalPer100g, 'kcal')),
                      _NutrientChip(label: isAr ? 'بروتين' : 'Protein', value: _fmt(analysis!.proteinPer100g, 'g')),
                      _NutrientChip(label: isAr ? 'دهون' : 'Fat', value: _fmt(analysis!.fatPer100g, 'g')),
                      _NutrientChip(label: isAr ? 'دهون مشبعة' : 'Sat Fat', value: _fmt(analysis!.satFatPer100g, 'g')),
                      _NutrientChip(label: isAr ? 'سكر' : 'Sugar', value: _fmt(analysis!.sugarPer100g, 'g')),
                      _NutrientChip(label: isAr ? 'صوديوم' : 'Sodium', value: _fmt(analysis!.sodiumMgPer100g, 'mg')),
                    ],
                  ),
                ],
                const Divider(height: 28),
                Text(
                  analysis!.source == 'open_food_facts'
                      ? (isAr ? 'تحليل ديناميكي (API مجاني)' : 'Dynamic Analysis (Free API)')
                      : (isAr ? 'تحليل محلي احتياطي' : 'Local Fallback Analysis'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  analysis!.caveat,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isAr ? 'نصائح وتعديلات الطلب السريرية:' : 'Clinical Ordering Modifications:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B3B2B)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...analysis!.tips.map(
                  (tip) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(tip, style: const TextStyle(fontSize: 12, color: Colors.black87))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MacroMetric extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final double value;

  const _MacroMetric({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(subtitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: color.withOpacity(0.15),
            color: color,
          ),
        ),
      ],
    );
  }
}

class _NutrientChip extends StatelessWidget {
  final String label;
  final String value;

  const _NutrientChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 11, color: Colors.black87),
      ),
    );
  }
}

String _fmt(double? value, String unit) {
  if (value == null) {
    return '--';
  }
  return '${value.toStringAsFixed(unit == 'mg' ? 0 : 1)} $unit';
}
