import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../../l10n/app_localizations.dart';
import '../../domain/weekly_nutrition_rule_engine.dart';

class WeeklyNutritionPlanTabView extends StatelessWidget {
  final bool isAr;
  final WeeklyNutritionPlan? plan;
  final VoidCallback onGenerate;
  final VoidCallback onRegenerate;
  final VoidCallback onSave;

  const WeeklyNutritionPlanTabView({
    super.key,
    required this.isAr,
    required this.plan,
    required this.onGenerate,
    required this.onRegenerate,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
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
              Expanded(
                child: Text(
                  l10n.tr('weekly_plan_title'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B3B2B),
                  ),
                ),
              ),
              if (plan != null) ...[
                IconButton(
                  onPressed: onSave,
                  tooltip: l10n.tr('save'),
                  icon: const Icon(Icons.save_rounded),
                ),
                IconButton(
                  onPressed: onRegenerate,
                  tooltip: l10n.tr('weekly_plan_regenerate'),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.tr('weekly_plan_subtitle'),
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          if (plan == null)
            _EmptyPlanState(
              isAr: isAr,
              onGenerate: onGenerate,
            )
          else
            _PlanBody(isAr: isAr, plan: plan!),
        ],
      ),
    );
  }
}

class _EmptyPlanState extends StatelessWidget {
  final bool isAr;
  final VoidCallback onGenerate;

  const _EmptyPlanState({
    required this.isAr,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E3EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tr('weekly_plan_empty_text'),
            style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onGenerate,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(l10n.tr('weekly_plan_generate')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B3B2B),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanBody extends StatelessWidget {
  final bool isAr;
  final WeeklyNutritionPlan plan;

  const _PlanBody({
    required this.isAr,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final generatedAt = DateTime.tryParse(plan.generatedAtIso);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Text(
            l10n.tr('weekly_plan_last_generated', args: {
              'date': generatedAt?.toLocal().toString().split('.').first ?? '-',
            }),
            style: const TextStyle(fontSize: 11, color: Color(0xFF166534)),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.tr('weekly_plan_used_flags'),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: plan.ruleFlags
              .map(
                (flag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    flag,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: plan.days.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final day = plan.days[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF8FFF6), Color(0xFFF7FBFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD9E9DF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          day.dayLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          day.focus,
                          style: const TextStyle(fontSize: 10, color: Color(0xFF075985)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PlateCard(isAr: isAr, day: day),
                  const SizedBox(height: 10),
                  ...day.meals.map(
                    (meal) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 5),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0284C7),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${meal.type}: ${meal.name}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  meal.reason,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PlateCard extends StatelessWidget {
  final bool isAr;
  final DailyNutritionPlan day;

  const _PlateCard({
    required this.isAr,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    final composition = day.composition;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EEE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _DishImage(imageUrl: composition.dishImageUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      composition.dishName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${composition.totalWeightGrams} g',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: _PlateCompositionChart(
                segments: composition.segments,
                centerImageUrl: composition.dishImageUrl,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: composition.segments
                .map(
                  (s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(s.colorValue).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${s.percent}% ${s.label} (${s.grams}g)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(s.colorValue),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          _NutritionValuesRow(isAr: isAr, values: composition.values),
        ],
      ),
    );
  }
}

class _DishImage extends StatelessWidget {
  final String? imageUrl;

  const _DishImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD8E5DD)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _DishFallbackIcon(),
              )
            : const _DishFallbackIcon(),
      ),
    );
  }
}

class _DishFallbackIcon extends StatelessWidget {
  const _DishFallbackIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEAF7EE),
      child: const Icon(Icons.restaurant_menu_rounded, color: Color(0xFF3B7D53)),
    );
  }
}

class _NutritionValuesRow extends StatelessWidget {
  final bool isAr;
  final PlateNutritionValues values;

  const _NutritionValuesRow({
    required this.isAr,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <({IconData icon, String label, String value, Color color})>[
      (
        icon: Icons.local_fire_department_rounded,
        label: l10n.tr('weekly_plan_nutrition_kcal'),
        value: '${values.calories}',
        color: const Color(0xFFF97316),
      ),
      (
        icon: Icons.grass_rounded,
        label: l10n.tr('weekly_plan_nutrition_carbs'),
        value: '${values.carbs.toStringAsFixed(1)} g',
        color: const Color(0xFF16A34A),
      ),
      (
        icon: Icons.fitness_center_rounded,
        label: l10n.tr('weekly_plan_nutrition_protein'),
        value: '${values.protein.toStringAsFixed(1)} g',
        color: const Color(0xFF0EA5E9),
      ),
      (
        icon: Icons.opacity_rounded,
        label: l10n.tr('weekly_plan_nutrition_fats'),
        value: '${values.fats.toStringAsFixed(1)} g',
        color: const Color(0xFFF59E0B),
      ),
      (
        icon: Icons.spa_rounded,
        label: l10n.tr('weekly_plan_nutrition_fiber'),
        value: '${values.fiber.toStringAsFixed(1)} g',
        color: const Color(0xFF8B5CF6),
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, size: 14, color: item.color),
                  const SizedBox(width: 5),
                  Text(
                    '${item.label}: ${item.value}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: item.color,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PlateCompositionChart extends StatelessWidget {
  final List<PlateSegment> segments;
  final String? centerImageUrl;

  const _PlateCompositionChart({
    required this.segments,
    required this.centerImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = centerImageUrl != null && centerImageUrl!.trim().isNotEmpty;
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size.square(180),
          painter: _PlatePainter(segments: segments),
        ),
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFFD8E5DD), width: 2),
          ),
          child: ClipOval(
            child: hasImage
                ? Image.network(
                    centerImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _DishFallbackIcon(),
                  )
                : const _DishFallbackIcon(),
          ),
        ),
      ],
    );
  }
}

class _PlatePainter extends CustomPainter {
  final List<PlateSegment> segments;

  const _PlatePainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 34
      ..strokeCap = StrokeCap.round;

    double startAngle = -math.pi / 2;
    for (final s in segments) {
      final sweep = (s.percent / 100) * 2 * math.pi;
      ringPaint.color = Color(s.colorValue);
      canvas.drawArc(rect.deflate(18), startAngle, sweep, false, ringPaint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PlatePainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}
