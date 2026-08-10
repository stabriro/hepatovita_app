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
    final normalized = text.replaceAll(',', '.');
    final lines = normalized
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return null;
    }

    final metricAliases = <String, List<String>>{
      'ALT (SGPT)': ['alt', 'sgpt'],
      'AST (SGOT)': ['ast', 'sgot'],
      'Vitamin D (25-OH)': ['vitamin d', '25-oh', '25 oh'],
      'Hemoglobin (Hgb)': ['hemoglobin', 'hgb'],
      'HbA1C': ['hba1c', 'a1c'],
    };

    String metric = '';
    String value = '';
    String unit = '';
    String refRange = '';

    String candidateLine = lines.first;
    for (final line in lines) {
      final lower = line.toLowerCase();
      for (final entry in metricAliases.entries) {
        final hasAlias = entry.value.any(lower.contains);
        if (hasAlias) {
          metric = entry.key;
          candidateLine = line;
          break;
        }
      }
      if (metric.isNotEmpty) {
        break;
      }
    }

    final numberRegex = RegExp(r'(-?\d+(?:\.\d+)?)');
    final unitRegex = RegExp(r'(U/L|IU/L|mg/dL|mmol/L|ng/mL|g/dL|%)', caseSensitive: false);
    final rangeRegex = RegExp(
      r'((?:<|>)\s*\d+(?:\.\d+)?\s*[%A-Za-z/]+?|\d+(?:\.\d+)?\s*-\s*\d+(?:\.\d+)?\s*[%A-Za-z/]+?)',
      caseSensitive: false,
    );

    final valueMatch = numberRegex.firstMatch(candidateLine);
    if (valueMatch != null) {
      value = valueMatch.group(1) ?? '';
    }

    final unitMatch = unitRegex.firstMatch(candidateLine);
    if (unitMatch != null) {
      unit = unitMatch.group(1)?.toUpperCase() ?? '';
    }

    final rangeMatch = rangeRegex.firstMatch(normalized);
    if (rangeMatch != null) {
      refRange = rangeMatch.group(1) ?? '';
    }

    if (metric.isEmpty) {
      metric = candidateLine.split(RegExp(r'\s{2,}|:')).first.trim();
    }

    final dateMatch = RegExp(r'(\d{4}[-/]\d{1,2}[-/]\d{1,2})').firstMatch(normalized);
    final parsedDate = dateMatch?.group(1)?.replaceAll('/', '-') ??
        DateTime.now().toIso8601String().split('T').first;

    if (metric.isEmpty || value.isEmpty) {
      return null;
    }

    return LabDraft(
      metric: metric,
      value: value,
      unit: unit,
      refRange: refRange,
      date: parsedDate,
    );
  }
}
