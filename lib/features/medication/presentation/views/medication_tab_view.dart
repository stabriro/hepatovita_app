import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2EDE6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2E22),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tr('med_scheduler_title'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF173C2F),
              height: 0.95,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.tr('med_scheduler_subtitle'),
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7A73)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onAddMedication,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.tr('med_add_medication')),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E5F49),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
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
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FCFA),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFDCE9E2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: Color(0xFF153629),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${med.timeLabel} - ${med.dose}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6A7B74),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => onToggleEnabled(med.id),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: med.enabled
                                    ? const Color(0xFF1E5F49)
                                    : const Color(0xFFE7EFEA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.circle,
                                size: 18,
                                color: med.enabled
                                    ? Colors.white
                                    : const Color(0xFFC0CDC6),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => onToggleTaken(med.id),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF214F3D),
                                side:
                                    const BorderSide(color: Color(0xFFD8E7DF)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 11),
                              ),
                              child: Text(
                                isTakenToday
                                    ? l10n.tr('med_taken_today')
                                    : l10n.tr('med_mark_taken'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => onEditMedication(med.id),
                            icon: const Icon(
                              Icons.edit_rounded,
                              color: Color(0xFF376E58),
                            ),
                            tooltip: l10n.tr('edit'),
                          ),
                          IconButton(
                            onPressed: () => onDeleteMedication(med.id),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFB45353),
                            ),
                            tooltip: l10n.tr('delete'),
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
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FCFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE9E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F4EC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.schedule_rounded,
                    color: Color(0xFF1E5F49), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.tr('med_empty_title'),
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
            l10n.tr('med_empty_subtitle'),
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onAddMedication,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.tr('med_add_medication')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E5F49),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
