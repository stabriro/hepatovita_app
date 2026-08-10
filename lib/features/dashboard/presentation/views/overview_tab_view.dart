import 'package:flutter/material.dart';

class OverviewTabView extends StatelessWidget {
  final bool isAr;
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
    final waterPct = (waterAmount / waterGoal).clamp(0.0, 1.0);

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.lightBlue.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.water_drop_rounded, color: Colors.lightBlue, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'مُتتبع شُرب الماء (3.0 لتر)' : '3.0L Hydration Station',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3B2B)),
                          ),
                          Text(
                            isAr ? 'بروتوكول ضبط لزوجة الهيموغلوبين' : 'Elevated Hgb / RBC protocol',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(waterPct * 100).round()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.lightBlue, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 140,
                  height: 170,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.lightBlue.shade200, width: 3),
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
                            colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        child: Text(
                          '$waterAmount / $waterGoal mL',
                          style: TextStyle(
                            color: waterPct > 0.4 ? Colors.white : const Color(0xFF1E293B),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onAddWater(250),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('+250 mL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onAddWater(500),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('+500 mL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onAddWater(750),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B3B2B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('+750 mL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7F4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.coffee_rounded, color: Color(0xFF2E7D32), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isAr ? 'أكواب الشاي الأخضر (EGCG)' : 'Green Tea Counter',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1B3B2B)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => onChangeTea(-1),
                          icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.grey),
                        ),
                        Text(
                          '$greenTeaCount / $teaGoal',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E7D32)),
                        ),
                        IconButton(
                          onPressed: () => onChangeTea(1),
                          icon: const Icon(Icons.add_circle_rounded, size: 20, color: Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
                isAr ? 'قائمة الفحص السريري اليومية' : 'Daily Clinical Checklist',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3B2B)),
              ),
              const SizedBox(height: 12),
              _CheckTile(
                title: isAr ? 'مكمل فيتامين د3 (5,000 وحدة)' : 'Vitamin D3 Supplement (5,000 IU)',
                subtitle: isAr ? 'تناوله مع وجبة تحتوي على دهون صحية' : 'Take with fat-containing meal',
                value: chkVitD,
                onChanged: onChkVitDChanged,
                tag: 'Vit D 16',
                tagColor: Colors.purple,
              ),
              _CheckTile(
                title: isAr ? '30 دقيقة مشي سريع' : '30-Min Aerobic Walk',
                subtitle: isAr ? 'تحفيز حرق دهون الكبد وخصائص الإنزيمات' : 'Stimulates hepatic lipid oxidation',
                value: walk30,
                onChanged: onWalk30Changed,
                tag: 'ALT Care',
                tagColor: const Color(0xFF2E7D32),
              ),
              _CheckTile(
                title: isAr ? '15-20 دقيقة شمس الصباح' : '15-20 Mins Morning Sunlight',
                subtitle: isAr ? 'تحفيز فيتامين د الطبيعي' : 'Triggers natural pre-D3 synthesis',
                value: sun15,
                onChanged: onSun15Changed,
                tag: 'Sun D3',
                tagColor: Colors.amber.shade800,
              ),
              _CheckTile(
                title: isAr ? 'يوم خالي تماماً من المقليات' : 'Strict Non-Fried & Low Saturated Fat Day',
                subtitle: isAr ? 'حماية خلايا الكبد من الإجهاد' : 'Zero trans-fats to protect hepatocytes',
                value: lowFatDay,
                onChanged: onLowFatDayChanged,
                tag: 'ALT/AST',
                tagColor: Colors.red.shade800,
              ),
            ],
          ),
        ),
      ],
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
      child: CheckboxListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: tagColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
              child: Text(tag, style: TextStyle(color: tagColor, fontSize: 9, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        value: value,
        activeColor: const Color(0xFF2E7D32),
        onChanged: (v) => onChanged(v ?? false),
      ),
    );
  }
}
