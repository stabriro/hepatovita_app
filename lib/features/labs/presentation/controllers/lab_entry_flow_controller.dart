import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../l10n/app_localizations.dart';
import '../models/lab_entry_models.dart';

enum LabEntryMethod {
  image,
  manual,
}

class LabEntryFlowController {
  const LabEntryFlowController._();

  static const Map<String, List<String>> _metricAliases = <String, List<String>>{
    'ALT (SGPT)': <String>['alt', 'sgpt'],
    'AST (SGOT)': <String>['ast', 'sgot'],
    'ALP': <String>['alp', 'alkaline phosphatase'],
    'GGT': <String>['ggt', 'gamma gt'],
    'HbA1C': <String>['hba1c', 'a1c'],
    'Fasting Glucose': <String>['glucose', 'fasting glucose', 'fbs'],
    'Vitamin D (25-OH)': <String>['vitamin d', '25-oh', '25 oh', 'd3'],
    'Hemoglobin (Hgb)': <String>['hemoglobin', 'hgb'],
    'Creatinine': <String>['creatinine', 'cr'],
    'Bilirubin Total': <String>['bilirubin total', 'total bilirubin'],
    'Albumin': <String>['albumin'],
    'INR': <String>['inr'],
    'Platelets': <String>['platelet', 'plt'],
  };

  static Future<LabEntryMethod?> chooseLabEntryMethod(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return showModalBottomSheet<LabEntryMethod>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.document_scanner_rounded),
                title: Text(l10n.tr('add_lab_from_image')),
                onTap: () => Navigator.of(sheetContext).pop(LabEntryMethod.image),
              ),
              ListTile(
                leading: const Icon(Icons.edit_note_rounded),
                title: Text(l10n.tr('add_lab_manual')),
                onTap: () => Navigator.of(sheetContext).pop(LabEntryMethod.manual),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<ImageSource?> chooseImageSource(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: Text(l10n.tr('image_source_camera')),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: Text(l10n.tr('image_source_gallery')),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  static LabDraft? parseLabDraftFromText(String text) {
    final drafts = parseLabDraftsFromText(text);
    if (drafts.isEmpty) {
      return null;
    }
    return drafts.first;
  }

  static List<LabDraft> parseLabDraftsFromText(String text) {
    final raw = text.replaceAll('\u00A0', ' ');
    final lines = raw
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const <LabDraft>[];
    }

    final drafts = <LabDraft>[];
    String currentDate = DateTime.now().toIso8601String().split('T').first;

    String? currentMetric;
    String currentValue = '';
    String currentUnit = '';
    String currentRefRange = '';
    String currentDraftDate = '';

    void pushCurrentDraft() {
      if (currentMetric == null) {
        return;
      }
      final metric = _resolveMetricName(currentMetric);
      final parsedNumeric = _extractNumericValue(currentValue);
      if (metric == null || parsedNumeric == null) {
        return;
      }

      drafts.add(
        LabDraft(
          metric: metric,
          value: parsedNumeric,
          unit: currentUnit,
          refRange: currentRefRange,
          date: currentDraftDate.isEmpty ? currentDate : currentDraftDate,
        ),
      );
    }

    for (final line in lines) {
      final normalizedLine = line.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (normalizedLine.isEmpty) {
        continue;
      }

      final dateFromLine = _extractDateFromLine(normalizedLine);
      if (dateFromLine != null) {
        currentDate = dateFromLine;
        if (currentMetric != null) {
          currentDraftDate = dateFromLine;
        }
      }

      if (_isNoiseLine(normalizedLine)) {
        continue;
      }

      if (_isMetricLine(normalizedLine)) {
        pushCurrentDraft();
        currentMetric = normalizedLine;
        currentValue = '';
        currentUnit = '';
        currentRefRange = '';
        currentDraftDate = '';
        continue;
      }

      if (currentMetric == null) {
        continue;
      }

      final lower = normalizedLine.toLowerCase();
      if (lower.startsWith('value:')) {
        final valueText = normalizedLine.substring(6).trim();
        final parsed = _extractNumericAndUnit(valueText);
        if (parsed != null) {
          currentValue = parsed.$1;
          currentUnit = parsed.$2;
        }
        continue;
      }

      if (lower.startsWith('reference range:')) {
        currentRefRange = normalizedLine.substring(16).trim();
        continue;
      }

      if (lower.startsWith('pending until')) {
        // Pending results are non-numeric and should not overwrite current value.
        continue;
      }

      // OCR can split range/date/value across lines without labels.
      if (currentRefRange.isEmpty && _looksLikeReferenceRange(normalizedLine)) {
        currentRefRange = normalizedLine;
        continue;
      }

      if (currentValue.isEmpty) {
        final parsed = _extractNumericAndUnit(normalizedLine);
        if (parsed != null) {
          currentValue = parsed.$1;
          currentUnit = parsed.$2;
        }
      }
    }

    pushCurrentDraft();

    final dedup = <String, LabDraft>{};
    for (final draft in drafts) {
      final key = '${canonicalMetricKey(draft.metric)}|${draft.date}';
      dedup[key] = draft;
    }

    return dedup.values.toList();
  }

  static String? _resolveMetricName(String line) {
    final cleaned = line
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\s*[:\-–]+\s*$'), '')
        .trim();

    if (cleaned.isEmpty) {
      return null;
    }

    final lower = line.toLowerCase();
    for (final entry in _metricAliases.entries) {
      final hasAlias = entry.value.any((alias) => lower.contains(alias));
      if (hasAlias) {
        return entry.key;
      }
    }

    // Keep unknown metrics instead of dropping them, to support wider clinic schemas.
    return cleaned;
  }

  static String canonicalMetricKey(String metric) {
    final lower = metric.toLowerCase().trim();

    for (final entry in _metricAliases.entries) {
      final canonical = entry.key.toLowerCase();
      if (lower == canonical) {
        return canonical;
      }

      for (final alias in entry.value) {
        if (lower == alias || lower.contains(alias)) {
          return canonical;
        }
      }
    }

    return lower.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  static String _normalizeDateToken(String token) {
    final normalized = token.replaceAll('/', '-');
    final parts = normalized.split('-');
    if (parts.length != 3) {
      return normalized;
    }
    final year = parts[0];
    final month = parts[1].padLeft(2, '0');
    final day = parts[2].padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String normalizeDateInput(String raw, {String? fallbackIso}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return fallbackIso ?? DateTime.now().toIso8601String().split('T').first;
    }

    final extracted = _extractDateFromLine(trimmed);
    if (extracted != null) {
      return extracted;
    }

    final yyyyMmDd = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (yyyyMmDd.hasMatch(trimmed)) {
      return trimmed;
    }

    return fallbackIso ?? DateTime.now().toIso8601String().split('T').first;
  }

  static bool _isNoiseLine(String line) {
    final lower = line.toLowerCase();
    return lower == 'lab results' || lower == 'help' || lower == 'value';
  }

  static bool _isMetricLine(String line) {
    if (line.endsWith(':')) {
      return false;
    }

    final lower = line.toLowerCase();
    if (lower.startsWith('value:') ||
        lower.startsWith('reference range:') ||
        lower.startsWith('pending until')) {
      return false;
    }

    if (_extractDateFromLine(line) != null) {
      return false;
    }

    if (RegExp(r'^[-+]?\d').hasMatch(line)) {
      return false;
    }

    // Most metric names have letters and are short title-like lines.
    final hasLetters = RegExp(r'[A-Za-z]').hasMatch(line);
    final wordCount = line.split(RegExp(r'\s+')).length;
    return hasLetters && wordCount <= 8 && line.length <= 64;
  }

  static String? _extractNumericValue(String text) {
    final match = RegExp(r'(-?\d+(?:\.\d+)?)').firstMatch(text);
    return match?.group(1);
  }

  static (String, String)? _extractNumericAndUnit(String text) {
    final numberMatch = RegExp(r'(-?\d+(?:\.\d+)?)').firstMatch(text);
    if (numberMatch == null) {
      return null;
    }

    final value = numberMatch.group(1) ?? '';
    final unitPart = text.substring(numberMatch.end).trim();
    final unit = unitPart
        .replaceAll(RegExp(r'^(\)|\]|\}|,|;)+'), '')
        .trim();
    return (value, unit);
  }

  static bool _looksLikeReferenceRange(String line) {
    return RegExp(
      r'(<\s*\d+(?:\.\d+)?|>\s*\d+(?:\.\d+)?|\d+(?:\.\d+)?\s*-\s*\d+(?:\.\d+)?)',
      caseSensitive: false,
    ).hasMatch(line);
  }

  static String? _extractDateFromLine(String line) {
    final isoLike = RegExp(r'(\d{4}[-/]\d{1,2}[-/]\d{1,2})').firstMatch(line);
    if (isoLike != null) {
      return _normalizeDateToken(isoLike.group(1) ?? '');
    }

    final namedMonth = RegExp(
      r'\b(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)\w*\s+(\d{4})\b',
      caseSensitive: false,
    ).firstMatch(line);
    if (namedMonth == null) {
      return null;
    }

    final day = int.tryParse(namedMonth.group(1) ?? '');
    final monthRaw = (namedMonth.group(2) ?? '').toLowerCase();
    final year = int.tryParse(namedMonth.group(3) ?? '');
    final monthMap = <String, int>{
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'sept': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    final month = monthMap[monthRaw];
    if (day == null || month == null || year == null) {
      return null;
    }

    return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }
}
