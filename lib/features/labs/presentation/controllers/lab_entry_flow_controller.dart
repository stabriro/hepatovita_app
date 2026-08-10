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
    final normalized = text.replaceAll(',', '.');
    final lines = normalized
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const <LabDraft>[];
    }

    final numberRegex = RegExp(r'(-?\d+(?:\.\d+)?)');
    final unitRegex = RegExp(
      r'(U/L|IU/L|mg/dL|mmol/L|ng/mL|g/dL|%|10\^9/L|x10\^9/L)',
      caseSensitive: false,
    );
    final rangeRegex = RegExp(
      r'((?:<|>)\s*\d+(?:\.\d+)?\s*[%A-Za-z/]+?|\d+(?:\.\d+)?\s*-\s*\d+(?:\.\d+)?\s*[%A-Za-z/]+?)',
      caseSensitive: false,
    );
    final dateRegex = RegExp(r'(\d{4}[-/]\d{1,2}[-/]\d{1,2})');

    final allDates = dateRegex
        .allMatches(normalized)
        .map((m) => m.group(1) ?? '')
        .where((e) => e.isNotEmpty)
        .map(_normalizeDateToken)
        .toList();

    String currentDate = allDates.isNotEmpty
        ? allDates.first
        : DateTime.now().toIso8601String().split('T').first;

    final drafts = <LabDraft>[];

    for (final line in lines) {
      final dateMatch = dateRegex.firstMatch(line);
      if (dateMatch != null) {
        currentDate = _normalizeDateToken(dateMatch.group(1) ?? currentDate);
      }

      final metric = _resolveMetricName(line);
      if (metric == null) {
        continue;
      }

      final cleanLine = line.replaceAll(dateRegex, ' ');
      final numericMatches = numberRegex
          .allMatches(cleanLine)
          .map((m) => m.group(1) ?? '')
          .where((s) => s.isNotEmpty)
          .toList();

      if (numericMatches.isEmpty) {
        continue;
      }

      final value = numericMatches.first;
      final unit = (unitRegex.firstMatch(line)?.group(1) ?? '').toUpperCase();
      final refRange = rangeRegex.firstMatch(line)?.group(1) ?? '';

      drafts.add(
        LabDraft(
          metric: metric,
          value: value,
          unit: unit,
          refRange: refRange,
          date: currentDate,
        ),
      );
    }

    final dedup = <String, LabDraft>{};
    for (final draft in drafts) {
      final key = '${canonicalMetricKey(draft.metric)}|${draft.date}';
      dedup[key] = draft;
    }

    return dedup.values.toList();
  }

  static String? _resolveMetricName(String line) {
    final lower = line.toLowerCase();
    for (final entry in _metricAliases.entries) {
      final hasAlias = entry.value.any((alias) => lower.contains(alias));
      if (hasAlias) {
        return entry.key;
      }
    }
    return null;
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
}
