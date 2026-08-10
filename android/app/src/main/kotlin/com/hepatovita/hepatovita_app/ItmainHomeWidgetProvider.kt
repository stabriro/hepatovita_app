package com.itmain.itmain_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import java.util.Calendar

abstract class BaseItmainHomeWidgetProvider : AppWidgetProvider() {
  protected abstract val layoutId: Int
  protected abstract val isCompact: Boolean

  override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
    updateWidgets(context, appWidgetManager, appWidgetIds, layoutId, isCompact)
  }

  override fun onReceive(context: Context, intent: Intent) {
    super.onReceive(context, intent)

    when (intent.action) {
      ACTION_ADD_WATER_250 -> {
        applyAddWater(context)
        refreshAllWidgetInstances(context)
      }

      ACTION_MARK_NEXT_TASK -> {
        applyMarkNextTask(context)
        refreshAllWidgetInstances(context)
      }
    }
  }

  companion object {
    const val ACTION_ADD_WATER_250 = "com.itmain.itmain_app.ACTION_ADD_WATER_250"
    const val ACTION_MARK_NEXT_TASK = "com.itmain.itmain_app.ACTION_MARK_NEXT_TASK"

    private fun updateWidgets(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      layoutId: Int,
      isCompact: Boolean,
    ) {
      val prefs = context.getSharedPreferences("itmain_widget_prefs", Context.MODE_PRIVATE)

      val lang = prefs.getString("itmain_lang", "en") ?: "en"
      val waterAmount = prefs.getInt("itmain_water_amount", 0)
      val waterGoal = prefs.getInt("itmain_water_goal", 3000).coerceAtLeast(1)
      val teaCount = prefs.getInt("itmain_green_tea_count", 0)
      val teaGoal = prefs.getInt("itmain_tea_goal", 3).coerceAtLeast(1)
      val chkVitD = prefs.getBoolean("itmain_chk_vit_d", false)
      val walk30 = prefs.getBoolean("itmain_walk30", false)
      val sun15 = prefs.getBoolean("itmain_sun15", false)
      val lowFatDay = prefs.getBoolean("itmain_low_fat_day", false)

      val checklistDone = listOf(chkVitD, walk30, sun15, lowFatDay).count { it }
      val hydrationPercent = ((waterAmount.toDouble() / waterGoal.toDouble()) * 100)
        .toInt()
        .coerceIn(0, 100)
      val score = computeScore(
        waterAmount = waterAmount,
        waterGoal = waterGoal,
        teaCount = teaCount,
        teaGoal = teaGoal,
        checklistDone = checklistDone,
      )

      val title = if (lang == "ar") "اطمئن" else "Itmain"
      val subtitle = if (lang == "ar") "الماء والمهام اليومية" else "Daily Water & Tasks"
      val waterLabel = if (lang == "ar") "الترطيب" else "Hydration"
      val tasksLabel = if (lang == "ar") "المهام" else "Tasks"
      val quickWater = if (lang == "ar") "+250 ماء" else "+250 mL"
      val quickTask = if (lang == "ar") "إنجاز مهمة" else "Done Task"
      val scoreLabel = if (lang == "ar") "الالتزام: $score%" else "Score: $score%"

      val highlightColor = resolveHighlightColor(hydrationPercent, checklistDone)
      val status = resolveStatus(lang, hydrationPercent, checklistDone, score)

      appWidgetIds.forEach { widgetId ->
        val launchIntent = Intent(context, MainActivity::class.java).apply {
          flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppIntent = PendingIntent.getActivity(
          context,
          widgetId,
          launchIntent,
          PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val addWaterIntent = Intent(context, ItmainHomeWidgetProvider::class.java).apply {
          action = ACTION_ADD_WATER_250
        }
        val markTaskIntent = Intent(context, ItmainHomeWidgetProvider::class.java).apply {
          action = ACTION_MARK_NEXT_TASK
        }

        val addWaterPendingIntent = PendingIntent.getBroadcast(
          context,
          widgetId + 1000,
          addWaterIntent,
          PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val markTaskPendingIntent = PendingIntent.getBroadcast(
          context,
          widgetId + 2000,
          markTaskIntent,
          PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val views = RemoteViews(context.packageName, layoutId).apply {
          setTextViewText(R.id.text_app_title, title)
          setTextViewText(R.id.text_subtitle, subtitle)
          setTextViewText(R.id.text_water_label, waterLabel)
          setTextViewText(R.id.text_tasks_label, tasksLabel)
          setTextViewText(R.id.text_water_value, "$waterAmount/$waterGoal mL")
          setTextViewText(R.id.text_tasks_value, "$checklistDone/4")
          setTextViewText(R.id.text_status_chip, status.chip)
          setTextViewText(R.id.text_motivation, status.message)
          setTextViewText(R.id.btn_add_water, quickWater)
          setTextViewText(R.id.btn_mark_task, quickTask)
          setInt(R.id.highlight_bar, "setBackgroundColor", highlightColor)
          setInt(R.id.text_status_chip, "setBackgroundColor", status.chipBg)
          setTextColor(R.id.text_status_chip, status.chipFg)
          setTextColor(R.id.text_motivation, status.messageColor)
          setTextColor(R.id.text_water_value, status.waterValueColor)
          setTextColor(R.id.text_tasks_value, status.tasksValueColor)
          setOnClickPendingIntent(R.id.widget_root, openAppIntent)
          setOnClickPendingIntent(R.id.btn_add_water, addWaterPendingIntent)
          setOnClickPendingIntent(R.id.btn_mark_task, markTaskPendingIntent)

          if (!isCompact) {
            setProgressBar(R.id.progress_hydration, 100, hydrationPercent, false)
            setTextViewText(R.id.text_score, scoreLabel)
          }
        }

        appWidgetManager.updateAppWidget(widgetId, views)
      }
    }

    private fun computeScore(
      waterAmount: Int,
      waterGoal: Int,
      teaCount: Int,
      teaGoal: Int,
      checklistDone: Int,
    ): Int {
      val waterPct = (waterAmount.toDouble() / waterGoal.toDouble()).coerceIn(0.0, 1.0)
      val teaPct = (teaCount.toDouble() / teaGoal.toDouble()).coerceIn(0.0, 1.0)
      val checklistPct = (checklistDone.toDouble() / 4.0).coerceIn(0.0, 1.0)
      return ((waterPct * 40.0) + (checklistPct * 40.0) + (teaPct * 20.0)).toInt()
    }

    private fun resolveHighlightColor(hydrationPercent: Int, checklistDone: Int): Int {
      val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)

      return if (hour in 6..11 && hydrationPercent < 45) {
        Color.parseColor("#F59E0B")
      } else if (hour >= 18 && checklistDone < 4) {
        Color.parseColor("#DC2626")
      } else {
        Color.parseColor("#0EA5E9")
      }
    }

    private data class WidgetStatusUi(
      val chip: String,
      val message: String,
      val chipBg: Int,
      val chipFg: Int,
      val messageColor: Int,
      val waterValueColor: Int,
      val tasksValueColor: Int,
    )

    private fun resolveStatus(
      lang: String,
      hydrationPercent: Int,
      checklistDone: Int,
      score: Int,
    ): WidgetStatusUi {
      val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)

      if (hour in 6..11 && hydrationPercent < 45) {
        return if (lang == "ar") {
          WidgetStatusUi(
            chip = "صباحي",
            message = "الآن أفضل وقت لرفع الترطيب",
            chipBg = Color.parseColor("#FEF3C7"),
            chipFg = Color.parseColor("#92400E"),
            messageColor = Color.parseColor("#B45309"),
            waterValueColor = Color.parseColor("#B45309"),
            tasksValueColor = Color.parseColor("#166534"),
          )
        } else {
          WidgetStatusUi(
            chip = "Morning",
            message = "Best time to boost hydration",
            chipBg = Color.parseColor("#FEF3C7"),
            chipFg = Color.parseColor("#92400E"),
            messageColor = Color.parseColor("#B45309"),
            waterValueColor = Color.parseColor("#B45309"),
            tasksValueColor = Color.parseColor("#166534"),
          )
        }
      }

      if (hour >= 18 && checklistDone < 4) {
        return if (lang == "ar") {
          WidgetStatusUi(
            chip = "مساء",
            message = "أكمل المهام قبل نهاية اليوم",
            chipBg = Color.parseColor("#FEE2E2"),
            chipFg = Color.parseColor("#991B1B"),
            messageColor = Color.parseColor("#B91C1C"),
            waterValueColor = Color.parseColor("#0369A1"),
            tasksValueColor = Color.parseColor("#B91C1C"),
          )
        } else {
          WidgetStatusUi(
            chip = "Evening",
            message = "Finish your tasks before day-end",
            chipBg = Color.parseColor("#FEE2E2"),
            chipFg = Color.parseColor("#991B1B"),
            messageColor = Color.parseColor("#B91C1C"),
            waterValueColor = Color.parseColor("#0369A1"),
            tasksValueColor = Color.parseColor("#B91C1C"),
          )
        }
      }

      if (score >= 80) {
        return if (lang == "ar") {
          WidgetStatusUi(
            chip = "ممتاز",
            message = "التزامك اليوم رائع استمر",
            chipBg = Color.parseColor("#DCFCE7"),
            chipFg = Color.parseColor("#166534"),
            messageColor = Color.parseColor("#166534"),
            waterValueColor = Color.parseColor("#0369A1"),
            tasksValueColor = Color.parseColor("#166534"),
          )
        } else {
          WidgetStatusUi(
            chip = "Great",
            message = "Strong streak today keep going",
            chipBg = Color.parseColor("#DCFCE7"),
            chipFg = Color.parseColor("#166534"),
            messageColor = Color.parseColor("#166534"),
            waterValueColor = Color.parseColor("#0369A1"),
            tasksValueColor = Color.parseColor("#166534"),
          )
        }
      }

      return if (lang == "ar") {
        WidgetStatusUi(
          chip = "ثابت",
          message = "خطوات صغيرة ترفع نتيجتك بسرعة",
          chipBg = Color.parseColor("#DBEAFE"),
          chipFg = Color.parseColor("#1D4ED8"),
          messageColor = Color.parseColor("#1E293B"),
          waterValueColor = Color.parseColor("#0369A1"),
          tasksValueColor = Color.parseColor("#166534"),
        )
      } else {
        WidgetStatusUi(
          chip = "Steady",
          message = "Small wins now level up your score",
          chipBg = Color.parseColor("#DBEAFE"),
          chipFg = Color.parseColor("#1D4ED8"),
          messageColor = Color.parseColor("#1E293B"),
          waterValueColor = Color.parseColor("#0369A1"),
          tasksValueColor = Color.parseColor("#166534"),
        )
      }
    }

    private fun applyAddWater(context: Context) {
      val prefs = context.getSharedPreferences("itmain_widget_prefs", Context.MODE_PRIVATE)
      val water = prefs.getInt("itmain_water_amount", 0)
      val waterGoal = prefs.getInt("itmain_water_goal", 3000).coerceAtLeast(1)
      val updatedWater = (water + 250).coerceAtMost(5000)
      val hydrationPercent = ((updatedWater.toDouble() / waterGoal.toDouble()) * 100)
        .toInt()
        .coerceIn(0, 100)

      val pendingDelta = prefs.getInt("itmain_pending_water_delta_ml", 0)

      prefs.edit()
        .putInt("itmain_water_amount", updatedWater)
        .putInt("itmain_hydration_percent", hydrationPercent)
        .putInt("itmain_pending_water_delta_ml", pendingDelta + 250)
        .apply()
    }

    private fun applyMarkNextTask(context: Context) {
      val prefs = context.getSharedPreferences("itmain_widget_prefs", Context.MODE_PRIVATE)
      val editor = prefs.edit()
      var changed = false

      val chkVitD = prefs.getBoolean("itmain_chk_vit_d", false)
      val walk30 = prefs.getBoolean("itmain_walk30", false)
      val sun15 = prefs.getBoolean("itmain_sun15", false)
      val lowFatDay = prefs.getBoolean("itmain_low_fat_day", false)

      when {
        !chkVitD -> {
          editor.putBoolean("itmain_chk_vit_d", true)
          changed = true
        }
        !walk30 -> {
          editor.putBoolean("itmain_walk30", true)
          changed = true
        }
        !sun15 -> {
          editor.putBoolean("itmain_sun15", true)
          changed = true
        }
        !lowFatDay -> {
          editor.putBoolean("itmain_low_fat_day", true)
          changed = true
        }
      }

      if (changed) {
        val pendingTasks = prefs.getInt("itmain_pending_task_completions", 0)
        editor.putInt("itmain_pending_task_completions", pendingTasks + 1)
      }

      editor.apply()
    }

    fun refreshAllWidgetInstances(context: Context) {
      val manager = AppWidgetManager.getInstance(context)

      val detailedComponent = android.content.ComponentName(
        context,
        ItmainHomeWidgetProvider::class.java,
      )
      val detailedIds = manager.getAppWidgetIds(detailedComponent)
      if (detailedIds.isNotEmpty()) {
        updateWidgets(context, manager, detailedIds, R.layout.itmain_home_widget, false)
      }

      val compactComponent = android.content.ComponentName(
        context,
        ItmainCompactHomeWidgetProvider::class.java,
      )
      val compactIds = manager.getAppWidgetIds(compactComponent)
      if (compactIds.isNotEmpty()) {
        updateWidgets(context, manager, compactIds, R.layout.itmain_home_widget_compact, true)
      }
    }
  }
}

class ItmainHomeWidgetProvider : BaseItmainHomeWidgetProvider() {
  override val layoutId: Int = R.layout.itmain_home_widget
  override val isCompact: Boolean = false
}

class ItmainCompactHomeWidgetProvider : BaseItmainHomeWidgetProvider() {
  override val layoutId: Int = R.layout.itmain_home_widget_compact
  override val isCompact: Boolean = true
}
