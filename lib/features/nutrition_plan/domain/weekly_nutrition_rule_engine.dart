class NutritionLabSignal {
  final String metric;
  final double value;
  final String status;

  const NutritionLabSignal({
    required this.metric,
    required this.value,
    required this.status,
  });
}

class PlannedMeal {
  final String type;
  final String name;
  final String reason;

  const PlannedMeal({
    required this.type,
    required this.name,
    required this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'name': name,
      'reason': reason,
    };
  }

  static PlannedMeal fromMap(Map<String, dynamic> map) {
    return PlannedMeal(
      type: map['type'] as String? ?? '',
      name: map['name'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
    );
  }
}

class PlateSegment {
  final String label;
  final int percent;
  final int grams;
  final int colorValue;

  const PlateSegment({
    required this.label,
    required this.percent,
    required this.grams,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'percent': percent,
      'grams': grams,
      'colorValue': colorValue,
    };
  }

  static PlateSegment fromMap(Map<String, dynamic> map) {
    return PlateSegment(
      label: map['label'] as String? ?? '',
      percent: (map['percent'] as num?)?.toInt() ?? 0,
      grams: (map['grams'] as num?)?.toInt() ?? 0,
      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFF9CA3AF,
    );
  }
}

class PlateNutritionValues {
  final int calories;
  final double carbs;
  final double protein;
  final double fats;
  final double fiber;

  const PlateNutritionValues({
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fats,
    required this.fiber,
  });

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'carbs': carbs,
      'protein': protein,
      'fats': fats,
      'fiber': fiber,
    };
  }

  static PlateNutritionValues fromMap(Map<String, dynamic> map) {
    return PlateNutritionValues(
      calories: (map['calories'] as num?)?.toInt() ?? 0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0,
      fats: (map['fats'] as num?)?.toDouble() ?? 0,
      fiber: (map['fiber'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PlateComposition {
  final String dishName;
  final String? dishImageUrl;
  final int totalWeightGrams;
  final List<PlateSegment> segments;
  final PlateNutritionValues values;

  const PlateComposition({
    required this.dishName,
    required this.dishImageUrl,
    required this.totalWeightGrams,
    required this.segments,
    required this.values,
  });

  PlateComposition copyWith({
    String? dishName,
    String? dishImageUrl,
  }) {
    return PlateComposition(
      dishName: dishName ?? this.dishName,
      dishImageUrl: dishImageUrl ?? this.dishImageUrl,
      totalWeightGrams: totalWeightGrams,
      segments: segments,
      values: values,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dishName': dishName,
      'dishImageUrl': dishImageUrl,
      'totalWeightGrams': totalWeightGrams,
      'segments': segments.map((e) => e.toMap()).toList(),
      'values': values.toMap(),
    };
  }

  static PlateComposition fromMap(Map<String, dynamic> map) {
    final segments = (map['segments'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => PlateSegment.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return PlateComposition(
      dishName: map['dishName'] as String? ?? '',
      dishImageUrl: map['dishImageUrl'] as String?,
      totalWeightGrams: (map['totalWeightGrams'] as num?)?.toInt() ?? 0,
      segments: segments,
      values: PlateNutritionValues.fromMap(
        Map<String, dynamic>.from(map['values'] as Map? ?? const <String, dynamic>{}),
      ),
    );
  }
}

class DailyNutritionPlan {
  final String dayLabel;
  final String focus;
  final List<PlannedMeal> meals;
  final PlateComposition composition;

  const DailyNutritionPlan({
    required this.dayLabel,
    required this.focus,
    required this.meals,
    required this.composition,
  });

  DailyNutritionPlan copyWith({
    PlateComposition? composition,
  }) {
    return DailyNutritionPlan(
      dayLabel: dayLabel,
      focus: focus,
      meals: meals,
      composition: composition ?? this.composition,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayLabel': dayLabel,
      'focus': focus,
      'meals': meals.map((e) => e.toMap()).toList(),
      'composition': composition.toMap(),
    };
  }

  static DailyNutritionPlan fromMap(Map<String, dynamic> map) {
    final meals = (map['meals'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => PlannedMeal.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return DailyNutritionPlan(
      dayLabel: map['dayLabel'] as String? ?? '',
      focus: map['focus'] as String? ?? '',
      meals: meals,
      composition: PlateComposition.fromMap(
        Map<String, dynamic>.from(map['composition'] as Map? ?? const <String, dynamic>{}),
      ),
    );
  }
}

class WeeklyNutritionPlan {
  final String generatedAtIso;
  final List<String> ruleFlags;
  final List<DailyNutritionPlan> days;

  const WeeklyNutritionPlan({
    required this.generatedAtIso,
    required this.ruleFlags,
    required this.days,
  });

  WeeklyNutritionPlan copyWith({
    String? generatedAtIso,
    List<String>? ruleFlags,
    List<DailyNutritionPlan>? days,
  }) {
    return WeeklyNutritionPlan(
      generatedAtIso: generatedAtIso ?? this.generatedAtIso,
      ruleFlags: ruleFlags ?? this.ruleFlags,
      days: days ?? this.days,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'generatedAtIso': generatedAtIso,
      'ruleFlags': ruleFlags,
      'days': days.map((e) => e.toMap()).toList(),
    };
  }

  static WeeklyNutritionPlan fromMap(Map<String, dynamic> map) {
    final days = (map['days'] as List<dynamic>? ?? const <dynamic>[])
        .map(
          (e) => DailyNutritionPlan.fromMap(Map<String, dynamic>.from(e as Map)),
        )
        .toList();

    return WeeklyNutritionPlan(
      generatedAtIso: map['generatedAtIso'] as String? ?? '',
      ruleFlags: ((map['ruleFlags'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => e.toString())
          .toList()),
      days: days,
    );
  }
}

class WeeklyNutritionRuleEngine {
  WeeklyNutritionPlan generate({
    required bool isAr,
    required List<NutritionLabSignal> labs,
  }) {
    final flags = _deriveFlags(labs: labs);
    final dayNames = isAr
        ? const ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة']
        : const ['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

    final days = <DailyNutritionPlan>[];
    for (int i = 0; i < 7; i++) {
      days.add(
        DailyNutritionPlan(
          dayLabel: dayNames[i],
          focus: _focusForDay(flags: flags, isAr: isAr, index: i),
          meals: _mealsForDay(flags: flags, isAr: isAr, index: i),
          composition: _compositionForDay(flags: flags, isAr: isAr, index: i),
        ),
      );
    }

    return WeeklyNutritionPlan(
      generatedAtIso: DateTime.now().toIso8601String(),
      ruleFlags: flags,
      days: days,
    );
  }

  List<String> _deriveFlags({required List<NutritionLabSignal> labs}) {
    bool highLiverRisk = false;
    bool highGlycemicRisk = false;
    bool lowVitaminD = false;

    for (final lab in labs) {
      final metric = lab.metric.toLowerCase();
      final status = lab.status.toLowerCase();
      final isOffTarget = status.contains('high') ||
          status.contains('low') ||
          status.contains('off') ||
          status.contains('خارج');

      if ((metric.contains('alt') || metric.contains('ast') || metric.contains('ggt') || metric.contains('alp')) && isOffTarget) {
        highLiverRisk = true;
      }

      if ((metric.contains('a1c') || metric.contains('hba1c') || metric.contains('glucose') || metric.contains('sugar')) && isOffTarget) {
        highGlycemicRisk = true;
      }

      if ((metric.contains('vitamin d') || metric.contains('vit d') || metric.contains('d3') || metric.contains('فيتامين د')) && (isOffTarget || lab.value < 30)) {
        lowVitaminD = true;
      }
    }

    final flags = <String>[];
    if (highLiverRisk) {
      flags.add('liver_protect');
    }
    if (highGlycemicRisk) {
      flags.add('low_gi');
    }
    if (lowVitaminD) {
      flags.add('vit_d_support');
    }
    if (flags.isEmpty) {
      flags.add('balanced_maintenance');
    }
    return flags;
  }

  String _focusForDay({
    required List<String> flags,
    required bool isAr,
    required int index,
  }) {
    final isLiver = flags.contains('liver_protect');
    final isGlycemic = flags.contains('low_gi');
    final isVitD = flags.contains('vit_d_support');

    if (isAr) {
      final pool = <String>[
        if (isLiver) 'تقليل الدهون المشبعة وحماية الكبد',
        if (isGlycemic) 'خفض الحمل السكري وتوزيع الكربوهيدرات',
        if (isVitD) 'دعم فيتامين د بالغذاء والتعرض المناسب للشمس',
        'ترطيب ثابت وألياف يومية',
      ];
      return pool[index % pool.length];
    }

    final pool = <String>[
      if (isLiver) 'Lower saturated fat and liver protection',
      if (isGlycemic) 'Lower glycemic load and carb distribution',
      if (isVitD) 'Vitamin D supportive choices and sunlight routine',
      'Stable hydration and daily fiber target',
    ];
    return pool[index % pool.length];
  }

  List<PlannedMeal> _mealsForDay({
    required List<String> flags,
    required bool isAr,
    required int index,
  }) {
    final breakfast = isAr
        ? [
            'شوفان + زبادي يوناني + بذور الشيا',
            'بيض مسلوق + خبز حبوب كاملة + خيار',
            'لبنة قليلة الدسم + زيت زيتون + خبز أسمر',
          ]
        : [
            'Oats + Greek yogurt + chia seeds',
            'Boiled eggs + whole-grain bread + cucumber',
            'Low-fat labneh + olive oil + whole wheat bread',
          ];

    final lunch = isAr
        ? [
            'دجاج مشوي + كينوا + سلطة خضراء',
            'سمك مشوي + أرز بني + خضار مطهية',
            'عدس مطبوخ + سلطة + لبن قليل الدسم',
          ]
        : [
            'Grilled chicken + quinoa + green salad',
            'Grilled fish + brown rice + cooked vegetables',
            'Lentil stew + salad + low-fat yogurt',
          ];

    final dinner = isAr
        ? [
            'شوربة خضار + تونة بالماء + خبز أسمر',
            'ديك رومي مشوي + بروكلي + بطاطا مشوية',
            'سلطة حمص + خضار مشوية',
          ]
        : [
            'Vegetable soup + tuna in water + whole-grain bread',
            'Roasted turkey + broccoli + baked potato',
            'Chickpea salad + roasted vegetables',
          ];

    final snack = isAr
        ? [
            'لوز غير مملح + تفاحة',
            'زبادي قليل الدسم + قرفة',
            'خيار وجزر + حمص',
          ]
        : [
            'Unsalted almonds + apple',
            'Low-fat yogurt + cinnamon',
            'Cucumber and carrot + hummus',
          ];

    final liverReason = isAr
        ? 'لتقليل إجهاد الكبد والدهون المشبعة.'
        : 'To reduce liver strain and saturated fat.';
    final glycemicReason = isAr
        ? 'لتثبيت سكر الدم وخفض الارتفاعات الحادة.'
        : 'To stabilize blood sugar and reduce spikes.';
    final maintenanceReason = isAr
        ? 'لدعم الالتزام الغذائي الأسبوعي.'
        : 'To support weekly consistency.';

    final reason = flags.contains('liver_protect')
        ? liverReason
        : (flags.contains('low_gi') ? glycemicReason : maintenanceReason);

    return [
      PlannedMeal(
        type: isAr ? 'الفطور' : 'Breakfast',
        name: breakfast[index % breakfast.length],
        reason: reason,
      ),
      PlannedMeal(
        type: isAr ? 'الغداء' : 'Lunch',
        name: lunch[index % lunch.length],
        reason: reason,
      ),
      PlannedMeal(
        type: isAr ? 'العشاء' : 'Dinner',
        name: dinner[index % dinner.length],
        reason: reason,
      ),
      PlannedMeal(
        type: isAr ? 'سناك' : 'Snack',
        name: snack[index % snack.length],
        reason: maintenanceReason,
      ),
    ];
  }

  PlateComposition _compositionForDay({
    required List<String> flags,
    required bool isAr,
    required int index,
  }) {
    final liver = flags.contains('liver_protect');
    final lowGi = flags.contains('low_gi');
    final vitD = flags.contains('vit_d_support');

    final baseDishNamesAr = <String>[
      'طبق كبد صحي بالخضار',
      'سلطة بروتين متوازنة',
      'سمك مشوي مع طبق أخضر',
      'طبق ألياف وطاقة خفيفة',
    ];
    final baseDishNamesEn = <String>[
      'Liver-Friendly Veg Plate',
      'Balanced Protein Salad Plate',
      'Grilled Fish Green Plate',
      'Fiber and Light Energy Plate',
    ];

    const int total = 360;

    int vegPercent = 35;
    int leanProteinPercent = 30;
    int wholeCarbPercent = 20;
    int healthyFatPercent = 10;
    int extrasPercent = 5;

    if (liver) {
      vegPercent = 40;
      leanProteinPercent = 30;
      wholeCarbPercent = 18;
      healthyFatPercent = 8;
      extrasPercent = 4;
    }

    if (lowGi) {
      vegPercent += 3;
      wholeCarbPercent -= 3;
    }

    if (vitD) {
      leanProteinPercent += 2;
      extrasPercent -= 2;
    }

    final segments = <PlateSegment>[
      PlateSegment(
        label: isAr ? 'خضار' : 'Vegetables',
        percent: vegPercent,
        grams: (total * vegPercent / 100).round(),
        colorValue: 0xFF7ED957,
      ),
      PlateSegment(
        label: isAr ? 'بروتين' : 'Protein',
        percent: leanProteinPercent,
        grams: (total * leanProteinPercent / 100).round(),
        colorValue: 0xFFFFC658,
      ),
      PlateSegment(
        label: isAr ? 'كربوهيدرات' : 'Complex Carbs',
        percent: wholeCarbPercent,
        grams: (total * wholeCarbPercent / 100).round(),
        colorValue: 0xFF67D2FF,
      ),
      PlateSegment(
        label: isAr ? 'دهون صحية' : 'Healthy Fats',
        percent: healthyFatPercent,
        grams: (total * healthyFatPercent / 100).round(),
        colorValue: 0xFFFF8F8F,
      ),
      PlateSegment(
        label: isAr ? 'إضافات' : 'Extras',
        percent: extrasPercent,
        grams: (total * extrasPercent / 100).round(),
        colorValue: 0xFFC4B5FD,
      ),
    ];

    final carbs = lowGi ? 31.0 : 38.0;
    final protein = vitD ? 30.0 : 27.0;
    final fats = liver ? 11.0 : 14.0;
    final fiber = 11.0 + (lowGi ? 2.0 : 0.0);
    final calories = (carbs * 4 + protein * 4 + fats * 9).round();

    final dishPool = isAr ? baseDishNamesAr : baseDishNamesEn;

    return PlateComposition(
      dishName: dishPool[index % dishPool.length],
      dishImageUrl: null,
      totalWeightGrams: total,
      segments: segments,
      values: PlateNutritionValues(
        calories: calories,
        carbs: carbs,
        protein: protein,
        fats: fats,
        fiber: fiber,
      ),
    );
  }
}
