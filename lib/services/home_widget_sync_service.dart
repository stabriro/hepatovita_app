import 'package:flutter/services.dart';

class HomeWidgetPendingActions {
  final int waterDeltaMl;
  final int taskCompletions;

  const HomeWidgetPendingActions({
    required this.waterDeltaMl,
    required this.taskCompletions,
  });

  bool get hasActions => waterDeltaMl > 0 || taskCompletions > 0;
}

class HomeWidgetSyncService {
  static const MethodChannel _channel = MethodChannel('itmain/home_widget');

  static String _todayKey(DateTime now) {
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  static Future<void> syncDashboardSnapshot({
    required bool isAr,
    required int waterAmount,
    required int waterGoal,
    required int greenTeaCount,
    required int teaGoal,
    required bool chkVitD,
    required bool walk30,
    required bool sun15,
    required bool lowFatDay,
    required int score,
    required int medicationTakenCount,
    required int medicationTotalCount,
    required String latestLabText,
    required String nextActionText,
  }) async {
    final now = DateTime.now();
    final checklistDone =
        [chkVitD, walk30, sun15, lowFatDay].where((v) => v).length;
    final hydrationPercent =
        ((waterAmount / (waterGoal == 0 ? 1 : waterGoal)) * 100)
            .round()
            .clamp(0, 100);

    await _channel.invokeMethod<void>('syncHomeWidget', {
      'itmain_water_text': '$waterAmount/$waterGoal mL',
      'itmain_tasks_text': '$checklistDone/4',
      'itmain_score_text': '$score%',
      'itmain_score_value': score,
      'itmain_hydration_percent': hydrationPercent,
      'itmain_today_key': _todayKey(now),
      'itmain_water_amount': waterAmount,
      'itmain_water_goal': waterGoal,
      'itmain_green_tea_count': greenTeaCount,
      'itmain_tea_goal': teaGoal,
      'itmain_chk_vit_d': chkVitD,
      'itmain_walk30': walk30,
      'itmain_sun15': sun15,
      'itmain_low_fat_day': lowFatDay,
      'itmain_lang': isAr ? 'ar' : 'en',
      'itmain_med_taken_count': medicationTakenCount,
      'itmain_med_total_count': medicationTotalCount,
      'itmain_latest_lab_text': latestLabText,
      'itmain_next_action_text': nextActionText,
    });
  }

  static Future<void> requestRefreshOnly() async {
    await _channel.invokeMethod<void>('refreshHomeWidget');
  }

  static Future<HomeWidgetPendingActions> consumePendingActions() async {
    final map =
        await _channel.invokeMapMethod<String, dynamic>('consumeWidgetActions');
    final waterDelta = (map?['waterDeltaMl'] as num?)?.toInt() ?? 0;
    final taskCompletions = (map?['taskCompletions'] as num?)?.toInt() ?? 0;
    return HomeWidgetPendingActions(
      waterDeltaMl: waterDelta,
      taskCompletions: taskCompletions,
    );
  }
}
