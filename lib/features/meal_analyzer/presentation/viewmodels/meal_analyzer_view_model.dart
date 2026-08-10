import 'package:flutter/foundation.dart';

class MealAnalyzerViewModel extends ChangeNotifier {
  Map<String, dynamic>? _analyzedResult;

  Map<String, dynamic>? get analyzedResult => _analyzedResult;

  void hydrateFromSnapshot(Map<String, dynamic>? analyzedResult) {
    _analyzedResult = analyzedResult;
    notifyListeners();
  }

  void analyzeMeal({
    required String mealName,
    required bool isAr,
  }) {
    if (mealName.trim().isEmpty) {
      return;
    }

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

    _analyzedResult = {
      'dish': mealName,
      'score': score,
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
    };

    notifyListeners();
  }
}
