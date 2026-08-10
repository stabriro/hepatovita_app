import 'package:flutter/foundation.dart';

class DashboardViewModel extends ChangeNotifier {
  int _waterAmount = 0;
  final int waterGoal = 3000;
  int _greenTeaCount = 0;
  final int teaGoal = 3;

  bool _chkVitD = false;
  bool _walk30 = false;
  bool _sun15 = false;
  bool _lowFatDay = false;
  String _hydrationDayKey = _dayKey(DateTime.now());

  int get waterAmount => _waterAmount;
  int get greenTeaCount => _greenTeaCount;
  bool get chkVitD => _chkVitD;
  bool get walk30 => _walk30;
  bool get sun15 => _sun15;
  bool get lowFatDay => _lowFatDay;

  int get score {
    final waterPct = (_waterAmount / waterGoal).clamp(0.0, 1.0);
    int chkDone = 0;
    if (_chkVitD) chkDone++;
    if (_walk30) chkDone++;
    if (_sun15) chkDone++;
    if (_lowFatDay) chkDone++;
    final chkPct = chkDone / 4.0;
    final teaPct = (_greenTeaCount / teaGoal).clamp(0.0, 1.0);

    return ((waterPct * 40) + (chkPct * 40) + (teaPct * 20)).round();
  }

  void hydrateFromSnapshot({
    required int waterAmount,
    required int greenTeaCount,
    required bool chkVitD,
    required bool walk30,
    required bool sun15,
    required bool lowFatDay,
    DateTime? updatedAt,
  }) {
    _waterAmount = waterAmount;
    _greenTeaCount = greenTeaCount;
    _chkVitD = chkVitD;
    _walk30 = walk30;
    _sun15 = sun15;
    _lowFatDay = lowFatDay;
    _hydrationDayKey = _dayKey(updatedAt ?? DateTime.now());
    notifyListeners();
  }

  bool resetDailyTrackersIfNeeded({DateTime? now}) {
    final todayKey = _dayKey(now ?? DateTime.now());
    if (_hydrationDayKey == todayKey) {
      return false;
    }

    _hydrationDayKey = todayKey;
    _waterAmount = 0;
    _greenTeaCount = 0;
    _chkVitD = false;
    _walk30 = false;
    _sun15 = false;
    _lowFatDay = false;
    notifyListeners();
    return true;
  }

  void addWater(int delta) {
    _waterAmount = (_waterAmount + delta).clamp(0, 5000);
    notifyListeners();
  }

  void changeTea(int delta) {
    _greenTeaCount = (_greenTeaCount + delta).clamp(0, 10);
    notifyListeners();
  }

  void setChecklistValue({
    bool? chkVitD,
    bool? walk30,
    bool? sun15,
    bool? lowFatDay,
  }) {
    if (chkVitD != null) _chkVitD = chkVitD;
    if (walk30 != null) _walk30 = walk30;
    if (sun15 != null) _sun15 = sun15;
    if (lowFatDay != null) _lowFatDay = lowFatDay;
    notifyListeners();
  }

  static String _dayKey(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '${dateTime.year}-$month-$day';
  }
}
