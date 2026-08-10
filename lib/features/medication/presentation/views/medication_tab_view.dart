import 'package:flutter/material.dart';

import '../models/medication_schedule_model.dart';

class MedicationTabView extends StatelessWidget {
  final bool isAr;
  final List<MedicationSchedule> medications;
  final ValueChanged<String> onToggleTaken;
  final ValueChanged<String> onToggleEnabled;
  final ValueChanged<String> onDeleteMedication;
  final ValueChanged<String> onEditMedication;
  final VoidCallback onAddMedication;
  final String todayKey;

  const MedicationTabView({
    super.key,
    required this.isAr,
    required this.medications,
    required this.onToggleTaken,
    required this.onToggleEnabled,
    required this.onDeleteMedication,
    required this.onEditMedication,
    required this.onAddMedication,
    required this.todayKey,
  });

  @override
  Widget build(BuildContext context) {
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
                  isAr ? 'جدول الأدوية الذكي' : 'Medication Scheduler',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B3B2B),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: onAddMedication,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(isAr ? 'إضافة' : 'Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B3B2B),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isAr
                ? 'نظّم تذكيرات يومية لكل دواء وتتبع جرعاتك بسهولة.'
                : 'Set daily reminders per medication and track today\'s dose.',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          if (medications.isEmpty)
            _EmptyMedicationState(
              isAr: isAr,
              onAddMedication: onAddMedication,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: medications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final med = medications[index];
                final isTakenToday = med.takenDayKey == todayKey;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDCE7F3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: med.enabled ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.medication_liquid_rounded,
                              color: med.enabled ? const Color(0xFF0369A1) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${med.dose}  •  ${med.timeLabel}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: med.enabled,
                            onChanged: (_) => onToggleEnabled(med.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => onToggleTaken(med.id),
                              icon: Icon(
                                isTakenToday ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                size: 18,
                              ),
                              label: Text(
                                isTakenToday
                                    ? (isAr ? 'تم أخذ الجرعة اليوم' : 'Taken Today')
                                    : (isAr ? 'تأكيد أخذ الجرعة' : 'Mark As Taken'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => onEditMedication(med.id),
                            icon: const Icon(Icons.edit_rounded),
                            tooltip: isAr ? 'تعديل' : 'Edit',
                          ),
                          IconButton(
                            onPressed: () => onDeleteMedication(med.id),
                            icon: const Icon(Icons.delete_outline_rounded),
                            tooltip: isAr ? 'حذف' : 'Delete',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _EmptyMedicationState extends StatelessWidget {
  final bool isAr;
  final VoidCallback onAddMedication;

  const _EmptyMedicationState({
    required this.isAr,
    required this.onAddMedication,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.schedule_rounded, color: Color(0xFF1B5E20), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAr ? 'أضف أول دواء الآن' : 'Add your first medication',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isAr
                ? 'حدد اسم الدواء والجرعة ووقت التذكير اليومي.'
                : 'Set medication name, dose, and a daily reminder time.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onAddMedication,
            icon: const Icon(Icons.add_rounded),
            label: Text(isAr ? 'إضافة دواء' : 'Add Medication'),
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
