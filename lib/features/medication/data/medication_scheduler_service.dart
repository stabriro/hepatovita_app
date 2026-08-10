import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../presentation/models/medication_schedule_model.dart';

class MedicationSchedulerService {
  static const _kMedicationList = 'medication_schedule_list_v1';

  Future<List<MedicationSchedule>> loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kMedicationList);
    if (raw == null || raw.trim().isEmpty) {
      return <MedicationSchedule>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => MedicationSchedule.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveSchedules(List<MedicationSchedule> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((e) => e.toMap()).toList());
    await prefs.setString(_kMedicationList, encoded);
  }
}
