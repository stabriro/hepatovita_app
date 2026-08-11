package com.itmain.itmain_app

import android.content.Context
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "itmain/home_widget")
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"syncHomeWidget" -> {
						val args = call.arguments as? Map<*, *>
						if (args == null) {
							result.error("invalid_args", "Expected a map payload", null)
							return@setMethodCallHandler
						}

						val prefs = getSharedPreferences("itmain_widget_prefs", Context.MODE_PRIVATE)
						val editor = prefs.edit()
						val hydrationPercent = ((args["itmain_hydration_percent"] as? Number)?.toInt()) ?: 0
						val scoreValue = ((args["itmain_score_value"] as? Number)?.toInt()) ?: 0
						val todayKey = args["itmain_today_key"] as? String
						val waterAmount = ((args["itmain_water_amount"] as? Number)?.toInt()) ?: 0
						val waterGoal = ((args["itmain_water_goal"] as? Number)?.toInt()) ?: 3000
						val greenTeaCount = ((args["itmain_green_tea_count"] as? Number)?.toInt()) ?: 0
						val teaGoal = ((args["itmain_tea_goal"] as? Number)?.toInt()) ?: 3
						val chkVitD = args["itmain_chk_vit_d"] as? Boolean ?: false
						val walk30 = args["itmain_walk30"] as? Boolean ?: false
						val sun15 = args["itmain_sun15"] as? Boolean ?: false
						val lowFatDay = args["itmain_low_fat_day"] as? Boolean ?: false
						editor.putString("itmain_water_text", args["itmain_water_text"] as? String ?: "0/3000 mL")
						editor.putString("itmain_tasks_text", args["itmain_tasks_text"] as? String ?: "0/4")
						editor.putString("itmain_score_text", args["itmain_score_text"] as? String ?: "0%")
						editor.putInt("itmain_hydration_percent", hydrationPercent)
						editor.putInt("itmain_water_amount", waterAmount)
						editor.putInt("itmain_water_goal", waterGoal)
						editor.putInt("itmain_green_tea_count", greenTeaCount)
						editor.putInt("itmain_tea_goal", teaGoal)
						editor.putBoolean("itmain_chk_vit_d", chkVitD)
						editor.putBoolean("itmain_walk30", walk30)
						editor.putBoolean("itmain_sun15", sun15)
						editor.putBoolean("itmain_low_fat_day", lowFatDay)
						editor.putInt("itmain_med_taken_count", ((args["itmain_med_taken_count"] as? Number)?.toInt()) ?: 0)
						editor.putInt("itmain_med_total_count", ((args["itmain_med_total_count"] as? Number)?.toInt()) ?: 0)
						editor.putString("itmain_latest_lab_text", args["itmain_latest_lab_text"] as? String ?: "")
						editor.putString("itmain_next_action_text", args["itmain_next_action_text"] as? String ?: "")
						editor.putString("itmain_lang", args["itmain_lang"] as? String ?: "en")
						editor.apply()

						BaseItmainHomeWidgetProvider.updateStreakOnSync(
							context = applicationContext,
							score = scoreValue,
							todayKey = todayKey,
						)

						BaseItmainHomeWidgetProvider.refreshAllWidgetInstances(applicationContext)
						result.success(true)
					}

					"refreshHomeWidget" -> {
						BaseItmainHomeWidgetProvider.refreshAllWidgetInstances(applicationContext)
						result.success(true)
					}

					"consumeWidgetActions" -> {
						val prefs = getSharedPreferences("itmain_widget_prefs", Context.MODE_PRIVATE)
						val waterDelta = prefs.getInt("itmain_pending_water_delta_ml", 0)
						val taskCompletions = prefs.getInt("itmain_pending_task_completions", 0)
						val scanFood = prefs.getBoolean("itmain_pending_scan_food", false)

						prefs.edit()
							.putInt("itmain_pending_water_delta_ml", 0)
							.putInt("itmain_pending_task_completions", 0)
							.putBoolean("itmain_pending_scan_food", false)
							.apply()

						result.success(
							mapOf(
								"waterDeltaMl" to waterDelta,
								"taskCompletions" to taskCompletions,
								"scanFood" to scanFood,
							),
						)
					}

					else -> result.notImplemented()
				}
			}
	}
}
