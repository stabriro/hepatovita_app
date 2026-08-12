package com.itmain.itmain_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import java.util.Calendar
import java.text.SimpleDateFormat
import java.util.Locale

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

      ACTION_SCAN_FOOD -> {
        applyScanFood(context)
        refreshAllWidgetInstances(context)
      }
    }
  }

  companion object {
    const val ACTION_ADD_WATER_250 = "com.itmain.itmain_app.ACTION_ADD_WATER_250"
    const val ACTION_MARK_NEXT_TASK = "com.itmain.itmain_app.ACTION_MARK_NEXT_TASK"
    const val ACTION_SCAN_FOOD = "com.itmain.itmain_app.ACTION_SCAN_FOOD"

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
      val medTakenCount = prefs.getInt("itmain_med_taken_count", 0)
      val medTotalCount = prefs.getInt("itmain_med_total_count", 0)
      val latestLabText = prefs.getString("itmain_latest_lab_text", "") ?: ""
      val nextActionText = prefs.getString("itmain_next_action_text", "") ?: ""

      val checklistDone = listOf(chkVitD, walk30, sun15, lowFatDay).count { it }
      val hydrationPercent = ((waterAmount.toDouble() / waterGoal.toDouble()) * 100)
        .toInt()
        .coerceIn(0, 100)
      val streakCount = prefs.getInt("itmain_streak_count", 0)
      val phase = prefs.getInt("itmain_widget_phase", 0)
      val score = computeScore(
        waterAmount = waterAmount,
        waterGoal = waterGoal,
        teaCount = teaCount,
        teaGoal = teaGoal,
        checklistDone = checklistDone,
      )

      val title = if (lang == "ar") "اطمئن" else "Itmain"
      val tagline = if (lang == "ar") "لقطة يومك الصحية" else "Live health snapshot"
      val subtitlePrefix = if (lang == "ar") "مختبر" else "Lab"
      val subtitle = if (latestLabText.isBlank()) {
        if (lang == "ar") "مختبر: لا توجد تحاليل بعد" else "Lab: No labs yet"
      } else {
        "$subtitlePrefix: $latestLabText"
      }
      val waterLabel = if (lang == "ar") "الترطيب" else "Hydration"
      val tasksLabel = if (lang == "ar") "أدوية اليوم" else "Meds today"
      val quickWater = if (lang == "ar") "+250 ماء" else "+250 mL"
      val quickTask = if (lang == "ar") "أنهِ التالي" else "Next done"
      val quickScan = if (lang == "ar") "مسح طعام" else "Scan food"
      val scoreLabel = if (lang == "ar") "الالتزام: $score%" else "Score: $score%"
      val streakLabel = if (lang == "ar") "سلسلة $streakCount" else "Streak ${streakCount}d"
      val actionPrefix = if (lang == "ar") "الآن" else "Now"
      val nextAction = if (nextActionText.isBlank()) {
        if (lang == "ar") "الآن: واصل يومك الصحي" else "Now: keep your healthy day moving"
      } else {
        "$actionPrefix: $nextActionText"
      }

      val highlightColor = resolveHighlightColor(hydrationPercent, checklistDone)
      val status = resolveStatus(lang, hydrationPercent, checklistDone, score, phase)
      val palette = resolvePalette()

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
        val scanFoodIntent = Intent(context, ItmainHomeWidgetProvider::class.java).apply {
          action = ACTION_SCAN_FOOD
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
        val scanFoodPendingIntent = PendingIntent.getBroadcast(
          context,
          widgetId + 3000,
          scanFoodIntent,
          PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val views = RemoteViews(context.packageName, layoutId).apply {
          setTextViewText(R.id.text_app_title, title)
          setTextViewText(R.id.text_subtitle, subtitle)
          setTextViewText(R.id.text_water_label, waterLabel)
          setTextViewText(R.id.text_tasks_label, tasksLabel)
          setTextViewText(R.id.text_water_value, "$waterAmount/$waterGoal mL")
          setTextViewText(R.id.text_tasks_value, "$medTakenCount/$medTotalCount")
          setTextViewText(R.id.text_streak_badge, streakLabel)
          setTextViewText(R.id.text_status_chip, status.chip)
          setTextViewText(R.id.text_motivation, nextAction)
          setTextViewText(R.id.btn_add_water, quickWater)
          setTextViewText(R.id.btn_mark_task, quickTask)
          setTextViewText(R.id.btn_scan_food, quickScan)
          setInt(R.id.highlight_bar, "setBackgroundColor", highlightColor)
          setTextColor(R.id.btn_add_water, palette.waterBtnFg)
          setTextColor(R.id.btn_mark_task, palette.taskBtnFg)
          setTextColor(R.id.text_streak_badge, palette.streakFg)
          setTextColor(R.id.text_status_chip, status.chipFg)
          setTextColor(R.id.text_motivation, status.messageColor)
          setTextColor(R.id.text_water_value, status.waterValueColor)
          setTextColor(R.id.text_tasks_value, status.tasksValueColor)
          setOnClickPendingIntent(R.id.widget_root, openAppIntent)
          setOnClickPendingIntent(R.id.btn_add_water, addWaterPendingIntent)
          setOnClickPendingIntent(R.id.btn_mark_task, markTaskPendingIntent)
          setOnClickPendingIntent(R.id.btn_scan_food, scanFoodPendingIntent)

          if (!isCompact) {
            setTextViewText(R.id.text_tagline, tagline)
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
        Color.parseColor("#F97316")
      } else if (hour >= 18 && checklistDone < 4) {
        Color.parseColor("#F43F5E")
      } else {
        Color.parseColor("#22C1F1")
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

    private data class WidgetPalette(
      val rootBg: Int,
      val waterBtnBg: Int,
      val waterBtnFg: Int,
      val taskBtnBg: Int,
      val taskBtnFg: Int,
      val streakBg: Int,
      val streakFg: Int,
    )

    private fun resolveStatus(
      lang: String,
      hydrationPercent: Int,
      checklistDone: Int,
      score: Int,
      phase: Int,
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
        val message = if (phase % 2 == 0) {
          if (lang == "ar") "التزامك اليوم رائع استمر" else "Strong streak today keep going"
        } else {
          if (lang == "ar") "أداء ممتاز حافظ على الإيقاع" else "Excellent pace keep momentum"
        }
        return if (lang == "ar") {
          WidgetStatusUi(
            chip = "ممتاز",
            message = message,
            chipBg = Color.parseColor("#DCFCE7"),
            chipFg = Color.parseColor("#166534"),
            messageColor = Color.parseColor("#166534"),
            waterValueColor = Color.parseColor("#0369A1"),
            tasksValueColor = Color.parseColor("#166534"),
          )
        } else {
          WidgetStatusUi(
            chip = "Great",
            message = message,
            chipBg = Color.parseColor("#DCFCE7"),
            chipFg = Color.parseColor("#166534"),
            messageColor = Color.parseColor("#166534"),
            waterValueColor = Color.parseColor("#0369A1"),
            tasksValueColor = Color.parseColor("#166534"),
          )
        }
      }

      val steadyMessage = if (phase % 3 == 0) {
        if (lang == "ar") "خطوات صغيرة ترفع نتيجتك بسرعة" else "Small wins now level up your score"
      } else if (phase % 3 == 1) {
        if (lang == "ar") "دفعة واحدة الآن تصنع فرق" else "One quick action makes a difference"
      } else {
        if (lang == "ar") "أنت قريب من مستوى أعلى" else "You are close to the next level"
      }

      return if (lang == "ar") {
        WidgetStatusUi(
          chip = "ثابت",
          message = steadyMessage,
          chipBg = Color.parseColor("#DBEAFE"),
          chipFg = Color.parseColor("#1D4ED8"),
          messageColor = Color.parseColor("#1E293B"),
          waterValueColor = Color.parseColor("#0369A1"),
          tasksValueColor = Color.parseColor("#166534"),
        )
      } else {
        WidgetStatusUi(
          chip = "Steady",
          message = steadyMessage,
          chipBg = Color.parseColor("#DBEAFE"),
          chipFg = Color.parseColor("#1D4ED8"),
          messageColor = Color.parseColor("#1E293B"),
          waterValueColor = Color.parseColor("#0369A1"),
          tasksValueColor = Color.parseColor("#166534"),
        )
      }
    }

    private fun resolvePalette(): WidgetPalette {
      val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
      return when {
        hour in 6..11 -> WidgetPalette(
          rootBg = Color.parseColor("#FFF7ED"),
          waterBtnBg = Color.parseColor("#FED7AA"),
          waterBtnFg = Color.parseColor("#9A3412"),
          taskBtnBg = Color.parseColor("#D9F99D"),
          taskBtnFg = Color.parseColor("#3F6212"),
          streakBg = Color.parseColor("#FEF3C7"),
          streakFg = Color.parseColor("#92400E"),
        )

        hour in 12..17 -> WidgetPalette(
          rootBg = Color.parseColor("#ECFEFF"),
          waterBtnBg = Color.parseColor("#BAE6FD"),
          waterBtnFg = Color.parseColor("#0C4A6E"),
          taskBtnBg = Color.parseColor("#BBF7D0"),
          taskBtnFg = Color.parseColor("#14532D"),
          streakBg = Color.parseColor("#DBEAFE"),
          streakFg = Color.parseColor("#1E40AF"),
        )

        else -> WidgetPalette(
          rootBg = Color.parseColor("#F8FAFC"),
          waterBtnBg = Color.parseColor("#CFFAFE"),
          waterBtnFg = Color.parseColor("#155E75"),
          taskBtnBg = Color.parseColor("#DCFCE7"),
          taskBtnFg = Color.parseColor("#166534"),
          streakBg = Color.parseColor("#EDE9FE"),
          streakFg = Color.parseColor("#5B21B6"),
        )
      }
    }

    private fun dayKeyNow(): String {
      val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.US)
      return sdf.format(Calendar.getInstance().time)
    }

    private fun dayKeyYesterday(): String {
      val cal = Calendar.getInstance()
      cal.add(Calendar.DAY_OF_YEAR, -1)
      val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.US)
      return sdf.format(cal.time)
    }

    fun updateStreakOnSync(context: Context, score: Int, todayKey: String?) {
      val prefs = context.getSharedPreferences("itmain_widget_prefs", Context.MODE_PRIVATE)
      val resolvedToday = todayKey ?: dayKeyNow()
      val lastStreakDay = prefs.getString("itmain_streak_last_day", "") ?: ""
      val currentStreak = prefs.getInt("itmain_streak_count", 0)

      var updatedStreak = currentStreak
      var updatedDay = lastStreakDay

      if (score >= 70) {
        if (lastStreakDay != resolvedToday) {
          updatedStreak = if (lastStreakDay == dayKeyYesterday()) {
            (currentStreak + 1).coerceAtLeast(1)
          } else {
            1
          }
          updatedDay = resolvedToday
        }
      }

      val oldPhase = prefs.getInt("itmain_widget_phase", 0)
      val nextPhase = (oldPhase + 1) % 6

      prefs.edit()
        .putInt("itmain_streak_count", updatedStreak)
        .putString("itmain_streak_last_day", updatedDay)
        .putInt("itmain_widget_phase", nextPhase)
        .apply()
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
        .putInt("itmain_widget_phase", (prefs.getInt("itmain_widget_phase", 0) + 1) % 6)
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

      editor.putInt("itmain_widget_phase", (prefs.getInt("itmain_widget_phase", 0) + 1) % 6)

      editor.apply()
    }

    private fun applyScanFood(context: Context) {
      val prefs = context.getSharedPreferences("itmain_widget_prefs", Context.MODE_PRIVATE)
      prefs.edit()
        .putBoolean("itmain_pending_scan_food", true)
        .putInt("itmain_widget_phase", (prefs.getInt("itmain_widget_phase", 0) + 1) % 6)
        .apply()
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
