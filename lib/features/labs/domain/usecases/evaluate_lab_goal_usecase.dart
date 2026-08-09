import '../entities/lab_entity.dart';

enum GoalRangeType { between, upper, lower }

class GoalRange {
  final GoalRangeType type;
  final double? min;
  final double? max;
  final double? upper;
  final double? lower;

  const GoalRange._({
    required this.type,
    this.min,
    this.max,
    this.upper,
    this.lower,
  });

  factory GoalRange.between({required double min, required double max}) {
    return GoalRange._(type: GoalRangeType.between, min: min, max: max);
  }

  factory GoalRange.upper({required double threshold}) {
    return GoalRange._(type: GoalRangeType.upper, upper: threshold);
  }

  factory GoalRange.lower({required double threshold}) {
    return GoalRange._(type: GoalRangeType.lower, lower: threshold);
  }

  bool isWithin(double value) {
    switch (type) {
      case GoalRangeType.between:
        return value >= min! && value <= max!;
      case GoalRangeType.upper:
        return value <= upper!;
      case GoalRangeType.lower:
        return value >= lower!;
    }
  }
}

class LabGoalEvaluation {
  final String status;
  final String targetLabel;

  const LabGoalEvaluation({required this.status, required this.targetLabel});
}

class EvaluateLabGoalUseCase {
  static final RegExp _rangePattern =
      RegExp(r'(-?\\d+(?:\\.\\d+)?)\\s*-\\s*(-?\\d+(?:\\.\\d+)?)');
  static final RegExp _ltPattern = RegExp(r'<\\s*(-?\\d+(?:\\.\\d+)?)');
  static final RegExp _gtPattern = RegExp(r'>\\s*(-?\\d+(?:\\.\\d+)?)');

  GoalRange? parseRange(String refRange) {
    final rangeMatch = _rangePattern.firstMatch(refRange);
    if (rangeMatch != null) {
      final min = double.tryParse(rangeMatch.group(1)!);
      final max = double.tryParse(rangeMatch.group(2)!);
      if (min != null && max != null) {
        return GoalRange.between(min: min, max: max);
      }
    }

    final ltMatch = _ltPattern.firstMatch(refRange);
    if (ltMatch != null) {
      final threshold = double.tryParse(ltMatch.group(1)!);
      if (threshold != null) {
        return GoalRange.upper(threshold: threshold);
      }
    }

    final gtMatch = _gtPattern.firstMatch(refRange);
    if (gtMatch != null) {
      final threshold = double.tryParse(gtMatch.group(1)!);
      if (threshold != null) {
        return GoalRange.lower(threshold: threshold);
      }
    }

    return null;
  }

  LabGoalEvaluation call(LabEntity lab) {
    final range = parseRange(lab.refRange);
    if (range == null) {
      return const LabGoalEvaluation(status: 'Unknown', targetLabel: 'Target Unknown');
    }

    if (range.isWithin(lab.value)) {
      return const LabGoalEvaluation(status: 'Normal', targetLabel: 'On Target');
    }

    if (range.type == GoalRangeType.upper) {
      return const LabGoalEvaluation(status: 'High', targetLabel: 'Off Target');
    }
    if (range.type == GoalRangeType.lower) {
      return const LabGoalEvaluation(status: 'Low', targetLabel: 'Off Target');
    }

    return LabGoalEvaluation(
      status: lab.value < range.min! ? 'Low' : 'High',
      targetLabel: 'Off Target',
    );
  }
}
