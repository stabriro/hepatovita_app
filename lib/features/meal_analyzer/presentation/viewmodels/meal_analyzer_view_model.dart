import 'package:flutter/foundation.dart';

import '../../data/open_food_facts_service.dart';
import '../../../../services/ai/grok_health_coach_service.dart';

class MealAnalyzerViewModel extends ChangeNotifier {
  MealAnalyzerViewModel({
    OpenFoodFactsService? nutritionService,
    GrokHealthCoachService? coachService,
  })
      : _nutritionService = nutritionService ?? OpenFoodFactsService(),
        _coachService = coachService ?? const GrokHealthCoachService();

  Map<String, dynamic>? _analyzedResult;
  bool _isAnalyzing = false;
  bool _isGeneratingCoachSummary = false;
  String? _coachSummary;
  final OpenFoodFactsService _nutritionService;
  final GrokHealthCoachService _coachService;

  Map<String, dynamic>? get analyzedResult => _analyzedResult;
  bool get isAnalyzing => _isAnalyzing;
  bool get isGeneratingCoachSummary => _isGeneratingCoachSummary;
  String? get coachSummary => _coachSummary;

  void hydrateFromSnapshot(Map<String, dynamic>? analyzedResult) {
    _analyzedResult = analyzedResult;
    _coachSummary = null;
    notifyListeners();
  }

  Future<void> analyzeMeal({
    required String mealName,
    required bool isAr,
  }) async {
    if (mealName.trim().isEmpty) {
      return;
    }

    _isAnalyzing = true;
    _coachSummary = null;
    notifyListeners();

    try {
      final barcode = _extractBarcodeCandidate(mealName);
      final nutrients = barcode != null
          ? await _nutritionService.searchByBarcode(barcode) ??
              await _nutritionService.searchMeal(mealName)
          : await _nutritionService.searchMeal(mealName);
      if (nutrients != null) {
        _analyzedResult = _buildFromApi(mealName: mealName, nutrients: nutrients, isAr: isAr);
        await _generateCoachSummary(mealName: mealName, isAr: isAr);
        return;
      }

      _analyzedResult = _buildKeywordFallback(mealName: mealName, isAr: isAr);
      await _generateCoachSummary(mealName: mealName, isAr: isAr);
    } catch (_) {
      _analyzedResult = _buildKeywordFallback(mealName: mealName, isAr: isAr);
      await _generateCoachSummary(mealName: mealName, isAr: isAr);
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<void> _generateCoachSummary({
    required String mealName,
    required bool isAr,
  }) async {
    final analysis = _analyzedResult;
    if (analysis == null) {
      return;
    }

    _isGeneratingCoachSummary = true;
    notifyListeners();

    try {
      _coachSummary = await _coachService.generateMealCoachSummary(
        mealName: mealName,
        analysis: analysis,
        isAr: isAr,
      );
    } catch (_) {
      _coachSummary = null;
    } finally {
      _isGeneratingCoachSummary = false;
      notifyListeners();
    }
  }

  String? _extractBarcodeCandidate(String input) {
    final digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 8 || digitsOnly.length > 14) {
      return null;
    }
    return digitsOnly;
  }

  Map<String, dynamic> _buildFromApi({
    required String mealName,
    required MealNutrients nutrients,
    required bool isAr,
  }) {
    final sodium = nutrients.sodiumMgPer100g ?? 0;
    final sugar = nutrients.sugarPer100g ?? 0;
    final saturatedFat = nutrients.saturatedFatPer100g ?? 0;
    final protein = nutrients.proteinPer100g ?? 0;
    final totalFat = nutrients.fatPer100g ?? 0;

    int risk = 0;
    if (sodium >= 600) {
      risk += 2;
    } else if (sodium >= 300) {
      risk += 1;
    }

    if (sugar >= 10) {
      risk += 2;
    } else if (sugar >= 5) {
      risk += 1;
    }

    if (saturatedFat >= 5) {
      risk += 2;
    } else if (saturatedFat >= 2) {
      risk += 1;
    }

    if (totalFat >= 20) {
      risk += 1;
    }

    final score = risk >= 4
        ? 'LOW'
        : (risk >= 2 ? 'MEDIUM' : 'HIGH');

    final availableMetrics = <double?>[
      nutrients.caloriesPer100g,
      nutrients.proteinPer100g,
      nutrients.fatPer100g,
      nutrients.saturatedFatPer100g,
      nutrients.sugarPer100g,
      nutrients.sodiumMgPer100g,
    ].where((v) => v != null).length;

    final confidence = availableMetrics >= 5
      ? (isAr ? 'ثقة عالية' : 'High confidence')
      : (availableMetrics >= 3
        ? (isAr ? 'ثقة متوسطة' : 'Moderate confidence')
        : (isAr ? 'ثقة محدودة' : 'Limited confidence'));

    final reason = score == 'LOW'
      ? (isAr
        ? 'النتيجة منخفضة لأن السكر/الصوديوم/الدهون المشبعة مرتفعة لكل 100غ.'
        : 'Low suitability due to elevated sugar/sodium/saturated fat per 100g.')
      : (score == 'MEDIUM'
        ? (isAr
          ? 'النتيجة متوسطة: بعض المؤشرات الغذائية تحتاج تعديل في الطلب.'
          : 'Moderate suitability: some nutrients need ordering modifications.')
        : (isAr
          ? 'النتيجة عالية: الملف الغذائي مناسب غالبا لكل 100غ.'
          : 'High suitability: nutrient profile is generally favorable per 100g.'));

    final caveat = isAr
      ? 'القيم لكل 100غ وقد تختلف عن الحصة الفعلية، وبيانات المصدر مجتمعية.'
      : 'Values are per 100g and may differ from your actual serving; source data is community contributed.';

    final proteinLabel = protein >= 15
        ? (isAr ? 'بروتين جيد لكل 100غ' : 'Good Protein per 100g')
        : (isAr ? 'بروتين منخفض لكل 100غ' : 'Low Protein per 100g');

    final fatLabel = saturatedFat >= 5
        ? (isAr ? 'دهون مشبعة مرتفعة' : 'High Saturated Fat')
        : (saturatedFat >= 2
            ? (isAr ? 'دهون مشبعة متوسطة' : 'Moderate Saturated Fat')
            : (isAr ? 'دهون مشبعة منخفضة' : 'Low Saturated Fat'));

    final tips = <String>[];
    if (sodium >= 600) {
      tips.add(
        isAr
            ? 'الصوديوم مرتفع. اختر أقل ملحا واطلب الصلصات جانبا.'
            : 'Sodium is high. Ask for less salt and keep sauces on the side.',
      );
    }
    if (sugar >= 10) {
      tips.add(
        isAr
            ? 'السكر مرتفع. قلل العصائر والمشروبات المحلاة مع هذه الوجبة.'
            : 'Sugar is high. Avoid sweetened drinks with this meal.',
      );
    }
    if (saturatedFat >= 5) {
      tips.add(
        isAr
            ? 'الدهون المشبعة مرتفعة. فضّل خيارا مشويا أو بحصة أصغر.'
            : 'Saturated fat is high. Prefer grilled options or a smaller portion.',
      );
    }
    if (tips.isEmpty) {
      tips.add(
        isAr
            ? 'الخيار مناسب غالبا. حافظ على توازن الوجبة مع خضار وماء.'
            : 'This looks generally suitable. Pair it with vegetables and water.',
      );
    }

    final kcalText = nutrients.caloriesPer100g == null
        ? (isAr ? 'غير متاح' : 'Not available')
        : '${nutrients.caloriesPer100g!.toStringAsFixed(0)} kcal/100g';

    tips.add(
      isAr
          ? 'المصدر: Open Food Facts (${nutrients.displayName}) • الطاقة: $kcalText'
          : 'Source: Open Food Facts (${nutrients.displayName}) • Energy: $kcalText',
    );

    return {
      'dish': mealName,
      'score': score,
      'reason': reason,
      'confidence': confidence,
      'matched_name': nutrients.displayName,
      'kcal_per_100g': nutrients.caloriesPer100g,
      'protein_per_100g': nutrients.proteinPer100g,
      'fat_per_100g': nutrients.fatPer100g,
      'sat_fat_per_100g': nutrients.saturatedFatPer100g,
      'sugar_per_100g': nutrients.sugarPer100g,
      'sodium_mg_per_100g': nutrients.sodiumMgPer100g,
      'caveat': caveat,
      'protein': proteinLabel,
      'fat': fatLabel,
      'tips': tips,
      'source': 'open_food_facts',
    };
  }

  Map<String, dynamic> _buildKeywordFallback({
    required String mealName,
    required bool isAr,
  }) {
    final textLower = mealName.toLowerCase();

    bool hasRed = false;
    bool hasGreen = false;

    final redKeywords = [
      'fried',
      'shawarma',
      'burger',
      'mayo',
      'fries',
      'crispy',
      'مقلي',
      'شاورما',
      'برجر',
      'مايونيز',
      'ثومية',
    ];
    final greenKeywords = [
      'grilled',
      'salmon',
      'salad',
      'steamed',
      'quinoa',
      'olive oil',
      'مشوي',
      'سلمون',
      'سلطة',
      'مسلوق',
      'كينوا',
      'زيت زيتون',
    ];

    for (final keyword in redKeywords) {
      if (textLower.contains(keyword)) hasRed = true;
    }
    for (final keyword in greenKeywords) {
      if (textLower.contains(keyword)) hasGreen = true;
    }

    String score = 'HIGH';
    if (hasRed) {
      score = 'LOW';
    } else if (!hasGreen) {
      score = 'MEDIUM';
    }

    final tips = <String>[];
    if (textLower.contains('shawarma') || textLower.contains('شاورما')) {
      tips.add(
        isAr
            ? 'اطلب الثومية أو المايونيز جانباً واستبدلهما بالليمون والطحينة الخفيفة.'
            : 'Request garlic paste / mayo on the side; substitute with lemon & tahini.',
      );
      tips.add(
        isAr
            ? 'اختر صحن دجاج مشوي بدلاً من الساندويتش المحشو بالبطاطس المقلية.'
            : 'Opt for grilled chicken platter over fries-stuffed wrap.',
      );
    } else if (textLower.contains('fried') || textLower.contains('مقلي')) {
      tips.add(
        isAr
            ? 'اسأل عن إمكانية تحضير خيار مشوي أو مسلوق بدلاً من المقلي.'
            : 'Ask for a grilled or baked alternative.',
      );
      tips.add(
        isAr
            ? 'أزل الجلد المقرمش المقلي لتقليل 60% من الدهون المتحولة الضارة بالإجهاد الكبدي.'
            : 'Remove crispy fried skin to cut 60%+ trans-fats.',
      );
    } else {
      tips.add(
        isAr
            ? 'وجبة ممتازة وصديقة للكبد! لا تتطلب تعديلات رئيسية.'
            : 'Excellent liver friendly option! Requires zero modifications.',
      );
    }

    tips.add(
      isAr
          ? 'تم استخدام تحليل محلي عند عدم توفر بيانات API.'
          : 'Local fallback analysis used when API data is unavailable.',
    );

    final reason = score == 'LOW'
      ? (isAr
        ? 'النتيجة منخفضة اعتمادا على كلمات تدل على أطعمة عالية الخطورة.'
        : 'Low suitability from high-risk meal keywords.')
      : (score == 'MEDIUM'
        ? (isAr
          ? 'النتيجة متوسطة: الوجبة تحتاج تعديلات صحية بسيطة.'
          : 'Moderate suitability: meal likely needs minor healthy modifications.')
        : (isAr
          ? 'النتيجة عالية بناء على كلمات تدل على خيارات صحية.'
          : 'High suitability based on healthy meal keywords.'));

    return {
      'dish': mealName,
      'score': score,
      'reason': reason,
      'confidence': isAr ? 'ثقة محدودة' : 'Limited confidence',
      'matched_name': mealName,
      'caveat': isAr
        ? 'هذا تحليل احتياطي محلي وليس بيانات غذائية مخبرية من API.'
        : 'This is local fallback analysis, not full nutrient API data.',
      'protein': (textLower.contains('salmon') ||
              textLower.contains('chicken') ||
              textLower.contains('دجاج') ||
              textLower.contains('سلمون'))
          ? (isAr ? 'بروتين صافي ممتاز' : 'Lean Protein')
          : (isAr ? 'بروتين متوسط' : 'Moderate Protein'),
      'fat': score == 'LOW'
          ? (isAr ? 'دهون مشبعة مرتفعة' : 'High Saturated Trans-Fat')
          : (isAr ? 'دهون غير مشبعة منخفضة' : 'Low Saturated Fat'),
      'tips': tips,
      'source': 'local_fallback',
    };
  }
}
