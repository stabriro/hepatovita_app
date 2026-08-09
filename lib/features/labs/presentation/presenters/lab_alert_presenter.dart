import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/lab_alert_entity.dart' as domain_alert;
import '../../domain/entities/lab_entity.dart';

enum LabAlertUiSeverity { critical, warning, info }

class LabAlertUiModel {
  final String metric;
  final LabAlertUiSeverity severity;
  final String title;
  final String message;

  const LabAlertUiModel({
    required this.metric,
    required this.severity,
    required this.title,
    required this.message,
  });
}

class LabAlertPresenter {
  const LabAlertPresenter();

  List<LabAlertUiModel> mapToUi({
    required AppLocalizations l10n,
    required List<domain_alert.LabAlertEntity> domainAlerts,
    required List<LabEntity> labs,
  }) {
    return domainAlerts.map((a) {
      final matchingLab = labs.where((l) => l.metric == a.metric).toList();
      final lab = matchingLab.isEmpty ? null : matchingLab.first;

      switch (a.code) {
        case 'OFF_TARGET_WORSENING':
          return LabAlertUiModel(
            metric: a.metric,
            severity: _mapSeverity(a.severity),
            title: l10n.tr('alert_worsening_title', args: {'metric': a.metric}),
            message: l10n.tr(
              'alert_worsening_message',
              args: {
                'value': '${lab?.value ?? ''}',
                'unit': lab?.unit ?? '',
              },
            ),
          );
        case 'OFF_TARGET':
          return LabAlertUiModel(
            metric: a.metric,
            severity: _mapSeverity(a.severity),
            title: l10n.tr('alert_off_target_title', args: {'metric': a.metric}),
            message: l10n.tr('alert_off_target_message'),
          );
        case 'TARGET_UNKNOWN':
          return LabAlertUiModel(
            metric: a.metric,
            severity: _mapSeverity(a.severity),
            title: l10n.tr('alert_unknown_target_title', args: {'metric': a.metric}),
            message: l10n.tr('alert_unknown_target_message'),
          );
        case 'ON_TARGET_IMPROVING':
          return LabAlertUiModel(
            metric: a.metric,
            severity: _mapSeverity(a.severity),
            title: l10n.tr('alert_good_title', args: {'metric': a.metric}),
            message: l10n.tr('alert_good_message'),
          );
        default:
          return LabAlertUiModel(
            metric: a.metric,
            severity: LabAlertUiSeverity.info,
            title: a.metric,
            message: a.code,
          );
      }
    }).toList();
  }

  LabAlertUiSeverity _mapSeverity(domain_alert.LabAlertSeverity severity) {
    switch (severity) {
      case domain_alert.LabAlertSeverity.critical:
        return LabAlertUiSeverity.critical;
      case domain_alert.LabAlertSeverity.warning:
        return LabAlertUiSeverity.warning;
      case domain_alert.LabAlertSeverity.info:
        return LabAlertUiSeverity.info;
    }
  }
}
