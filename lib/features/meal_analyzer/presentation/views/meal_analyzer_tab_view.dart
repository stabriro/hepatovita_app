import 'package:flutter/material.dart';

class MealAnalysisUiModel {
  final String dish;
  final String score;
  final String protein;
  final String fat;
  final List<String> tips;

  const MealAnalysisUiModel({
    required this.dish,
    required this.score,
    required this.protein,
    required this.fat,
    required this.tips,
  });
}

class MealAnalyzerTabView extends StatelessWidget {
  final bool isAr;
  final TextEditingController mealSearchController;
  final ValueChanged<String> onAnalyzeMeal;
  final MealAnalysisUiModel? analysis;

  const MealAnalyzerTabView({
    super.key,
    required this.isAr,
    required this.mealSearchController,
    required this.onAnalyzeMeal,
    required this.analysis,
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
                  onPressed: () => onAnalyzeMeal(mealSearchController.text),
                  icon: const Icon(Icons.auto_awesome_rounded),
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
                    color: analysis!.score == 'HIGH' ? Colors.green.shade50 : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: analysis!.score == 'HIGH' ? Colors.green.shade300 : Colors.amber.shade300),
                  ),
                  child: Text(
                    analysis!.score == 'HIGH'
                        ? (isAr ? '🟢 صديق للكبد (ممتاز)' : '🟢 LIVER FRIENDLY (EXCELLENT)')
                        : (isAr ? '🟡 خطر متوسط (عدّل الطلب)' : '🟡 MODERATE RISK (MODIFY ORDER)'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: analysis!.score == 'HIGH' ? Colors.green.shade900 : Colors.amber.shade900,
                    ),
                  ),
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
                const Divider(height: 28),
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
