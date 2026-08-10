import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

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
  final TextEditingController mealSearchController;
  final Future<void> Function(String) onAnalyzeMeal;
  final Future<void> Function()? onAnalyzeFromBarcode;
  final Future<void> Function()? onAnalyzeFromTextImage;
  final bool supportsImageActions;
  final MealAnalysisUiModel? analysis;
  final bool isAnalyzing;

  const MealAnalyzerTabView({
    super.key,
    required this.mealSearchController,
    required this.onAnalyzeMeal,
    this.onAnalyzeFromBarcode,
    this.onAnalyzeFromTextImage,
    this.supportsImageActions = false,
    required this.analysis,
    required this.isAnalyzing,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        final cardPadding = compact ? 16.0 : 20.0;

        return Column(
          children: [
            _SectionEntrance(
              duration: const Duration(milliseconds: 360),
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
                l10n.tr('meal_analyzer_title'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3B2B)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mealSearchController,
                decoration: InputDecoration(
                  hintText: l10n.tr('meal_analyzer_hint'),
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
                  label: Text(l10n.tr('analyze_dish')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B3B2B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              if (supportsImageActions) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: compact ? 6 : 8,
                  runSpacing: compact ? 6 : 8,
                  children: [
                    SizedBox(
                      width: compact ? constraints.maxWidth - (cardPadding * 2) : ((constraints.maxWidth - (cardPadding * 2) - 8) / 2),
                      child: OutlinedButton.icon(
                        onPressed: isAnalyzing
                            ? null
                            : () async {
                                await onAnalyzeFromBarcode?.call();
                              },
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: Text(l10n.tr('analyze_barcode')),
                      ),
                    ),
                    SizedBox(
                      width: compact ? constraints.maxWidth - (cardPadding * 2) : ((constraints.maxWidth - (cardPadding * 2) - 8) / 2),
                      child: OutlinedButton.icon(
                        onPressed: isAnalyzing
                            ? null
                            : () async {
                                await onAnalyzeFromTextImage?.call();
                              },
                        icon: const Icon(Icons.document_scanner_rounded),
                        label: Text(l10n.tr('analyze_label_text')),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
              ),
            ),
            SizedBox(height: compact ? 12 : 16),
            if (analysis != null)
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
                      ? '🟢 ${l10n.tr('liver_friendly_excellent')}'
                        : (analysis!.score == 'LOW'
                        ? '🔴 ${l10n.tr('higher_risk_change_order')}'
                        : '🟡 ${l10n.tr('moderate_risk_modify_order')}'),
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
                  '${l10n.tr('matched_item')}: ${analysis!.matchedName}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  '${l10n.tr('confidence')}: ${analysis!.confidence}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                _MacroMetric(
                  title: '${l10n.tr('protein_profile')}:',
                  subtitle: analysis!.protein,
                  color: Colors.blue,
                  value: 0.8,
                ),
                const SizedBox(height: 8),
                _MacroMetric(
                  title: '${l10n.tr('fat_risk_level')}:',
                  subtitle: analysis!.fat,
                  color: analysis!.score == 'LOW' ? Colors.red : Colors.green,
                  value: analysis!.score == 'LOW' ? 0.9 : 0.3,
                ),
                if (analysis!.source == 'open_food_facts') ...[
                  const SizedBox(height: 14),
                  Text(
                    '${l10n.tr('nutrition_facts_per_100g')}:',
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
                      _NutrientChip(label: l10n.tr('nutrient_energy'), value: _fmt(analysis!.kcalPer100g, 'kcal')),
                      _NutrientChip(label: l10n.tr('nutrient_protein'), value: _fmt(analysis!.proteinPer100g, 'g')),
                      _NutrientChip(label: l10n.tr('nutrient_fat'), value: _fmt(analysis!.fatPer100g, 'g')),
                      _NutrientChip(label: l10n.tr('nutrient_sat_fat'), value: _fmt(analysis!.satFatPer100g, 'g')),
                      _NutrientChip(label: l10n.tr('nutrient_sugar'), value: _fmt(analysis!.sugarPer100g, 'g')),
                      _NutrientChip(label: l10n.tr('nutrient_sodium'), value: _fmt(analysis!.sodiumMgPer100g, 'mg')),
                    ],
                  ),
                ],
                const Divider(height: 28),
                Text(
                  analysis!.source == 'open_food_facts'
                      ? l10n.tr('dynamic_analysis_free_api')
                      : l10n.tr('local_fallback_analysis'),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7F4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD7E7DB)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.tr('meal_analyzer_educational_note'),
                          style: const TextStyle(fontSize: 11, height: 1.35, color: Color(0xFF1B3B2B)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${l10n.tr('meal_analyzer_suggestions_title')}:',
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
              )
            else
              _SectionEntrance(
                duration: const Duration(milliseconds: 520),
                yOffset: compact ? 14 : 20,
                child: _MealAnalyzerEmptyState(
                  isAr: Directionality.of(context) == TextDirection.rtl,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MealAnalyzerEmptyState extends StatelessWidget {
  final bool isAr;

  const _MealAnalyzerEmptyState({
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6E3EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F3EA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.restaurant_menu_rounded, color: Color(0xFF1B3B2B), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAr ? 'نتيجة التحليل ستظهر هنا' : 'Meal analysis appears here',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isAr
                ? 'جرّب كتابة اسم طبق أو تحليل باركود المنتج للحصول على تقييم مناسب للكبد.'
                : 'Search a dish name or scan a barcode to get a liver-friendly score.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HintChip(label: isAr ? 'سمك مشوي' : 'Grilled salmon'),
              _HintChip(label: isAr ? 'دجاج مشوي' : 'Chicken shawarma'),
              _HintChip(label: isAr ? 'زبادي يوناني' : 'Greek yogurt'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HintChip extends StatelessWidget {
  final String label;

  const _HintChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF6F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1F5A45)),
      ),
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
            backgroundColor: color.withValues(alpha: 0.15),
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
