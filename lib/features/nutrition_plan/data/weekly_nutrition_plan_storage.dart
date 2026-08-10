import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/weekly_nutrition_rule_engine.dart';

class WeeklyNutritionPlanStorage {
  static const _kWeeklyNutritionPlan = 'weekly_nutrition_plan_v1';

  Future<WeeklyNutritionPlan?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kWeeklyNutritionPlan);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return WeeklyNutritionPlan.fromMap(decoded);
  }

  Future<void> save(WeeklyNutritionPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWeeklyNutritionPlan, jsonEncode(plan.toMap()));
  }
}
