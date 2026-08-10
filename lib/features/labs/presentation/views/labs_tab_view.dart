import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../presenters/lab_alert_presenter.dart';

class LabsTabLabItem {
  final String metric;
  final double value;
  final String unit;
  final String refRange;
  final String status;
  final String target;
  final double progressVal;
  final String targetLabel;
  final String trendLabel;

  const LabsTabLabItem({
    required this.metric,
    required this.value,
    required this.unit,
    required this.refRange,
    required this.status,
    required this.target,
    required this.progressVal,
    required this.targetLabel,
    required this.trendLabel,
  });
}

class LabsTabHistoryItem {
  final double value;
  final String unit;
  final String date;
  final String status;
  final String createdAt;

  const LabsTabHistoryItem({
    required this.value,
    required this.unit,
    required this.date,
    required this.status,
    required this.createdAt,
  });
}

class LabsTimelineEvent {
  final String metric;
  final double value;
  final String unit;
  final String status;
  final String date;

  const LabsTimelineEvent({
    required this.metric,
    required this.value,
    required this.unit,
    required this.status,
    required this.date,
  });
}

class LabsTabView extends StatelessWidget {
  final bool isAr;
  final List<LabsTabLabItem> labs;
  final Map<String, List<LabsTabHistoryItem>> historyByMetric;
  final List<LabsTimelineEvent> timelineEvents;
  final List<LabAlertUiModel> alerts;
  final VoidCallback onExportBackup;
  final VoidCallback onRestoreBackup;
  final VoidCallback onAddLab;
  final ValueChanged<int> onEditLab;
  final ValueChanged<int> onDeleteLab;
  final ValueChanged<int> onAddResult;

  const LabsTabView({
    super.key,
    required this.isAr,
    required this.labs,
    required this.historyByMetric,
    required this.timelineEvents,
    required this.alerts,
    required this.onExportBackup,
    required this.onRestoreBackup,
    required this.onAddLab,
    required this.onEditLab,
    required this.onDeleteLab,
    required this.onAddResult,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        final cardPadding = compact ? 16.0 : 20.0;

        return Column(
          children: [
            _SectionEntrance(
              duration: const Duration(milliseconds: 420),
              yOffset: compact ? 14 : 20,
              child: Container(
                padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE2EDE6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F2E22),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'مركز الفحوصات والمؤشرات الحيوية' : 'Biomarker & Clinical Lab Hub',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3B2B)),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: compact ? 6 : 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onExportBackup,
                      icon: const Icon(Icons.download_rounded),
                      label: Text(l10n.tr('backup')),
                    ),
                    OutlinedButton.icon(
                      onPressed: onRestoreBackup,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: Text(l10n.tr('restore')),
                    ),
                    ElevatedButton.icon(
                      onPressed: onAddLab,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.tr('add_lab')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B3B2B),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.tr('sqlite_backup_hint'),
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              _AlertsPanel(alerts: alerts),
              const SizedBox(height: 8),
              _LabsTimelinePanel(
                events: timelineEvents,
              ),
              const SizedBox(height: 6),
              const SizedBox(height: 4),
              if (labs.isEmpty)
                _RichEmptyLabsState(
                  isAr: isAr,
                  onAddLab: onAddLab,
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: labs.length,
                  separatorBuilder: (_, __) => const Divider(height: 20),
                  itemBuilder: (context, index) {
                    final lab = labs[index];
                    final isNormal = lab.status == 'Normal';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(lab.metric, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isNormal ? Colors.green.shade50 : Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isNormal ? Colors.green.shade300 : Colors.amber.shade300),
                                  ),
                                  child: Text(
                                    lab.status,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isNormal ? Colors.green.shade900 : Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => onEditLab(index),
                                  icon: const Icon(Icons.edit_rounded, size: 18),
                                  constraints: BoxConstraints.tightFor(width: compact ? 32 : 36, height: compact ? 32 : 36),
                                  padding: EdgeInsets.zero,
                                  tooltip: 'Update lab',
                                ),
                                IconButton(
                                  onPressed: () => onDeleteLab(index),
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                  constraints: BoxConstraints.tightFor(width: compact ? 32 : 36, height: compact ? 32 : 36),
                                  padding: EdgeInsets.zero,
                                  tooltip: 'Delete lab',
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${lab.value} ${lab.unit}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B3B2B)),
                            ),
                            Text(lab.refRange, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: lab.progressVal,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            color: isNormal ? Colors.green : Colors.amber.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(lab.target, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                        _LabTrendCard(
                          lab: lab,
                          history: historyByMetric[lab.metric] ?? const <LabsTabHistoryItem>[],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: () => onAddResult(index),
                            icon: const Icon(Icons.show_chart_rounded, size: 16),
                            label: Text(isAr ? 'إضافة نتيجة' : 'Add Result'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LabsTimelinePanel extends StatelessWidget {
  final List<LabsTimelineEvent> events;

  const _LabsTimelinePanel({
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shown = events.take(10).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6E3EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F3EA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.timeline_rounded,
                  color: Color(0xFF1B3B2B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.tr('labs_timeline_title'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tr('labs_timeline_hint'),
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          if (shown.isEmpty)
            Text(
              l10n.tr('labs_timeline_empty'),
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: shown.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final event = shown[index];
                final statusColor = _statusColor(event.status);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 86,
                      child: Text(
                        event.date,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (index != shown.length - 1)
                          Container(
                            width: 2,
                            height: 34,
                            color: const Color(0xFFCBD5E1),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                event.metric,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${event.value} ${event.unit}'.trim(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('normal') || normalized.contains('ضمن')) {
      return const Color(0xFF16A34A);
    }
    if (normalized.contains('high') || normalized.contains('low')) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFFDC2626);
  }
}

class _RichEmptyLabsState extends StatelessWidget {
  final bool isAr;
  final VoidCallback onAddLab;

  const _RichEmptyLabsState({
    required this.isAr,
    required this.onAddLab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E3EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F3EA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.science_rounded, color: Color(0xFF1B3B2B), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAr ? 'ابدأ سجل الفحوصات الآن' : 'Start your biomarker timeline',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isAr
                ? 'أضف أول نتيجة تحليل لتتبع الاتجاهات والحصول على تنبيهات علاجية تلقائية.'
                : 'Add your first lab result to unlock trend lines and clinical alerts.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 10),
          Text(
            isAr ? '• ابدأ بتحليل ALT أو AST\n• ثم أضف القيم الجديدة مع التاريخ' : '• Start with ALT or AST\n• Add follow-up values with dates',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.5),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: onAddLab,
              icon: const Icon(Icons.add_rounded),
              label: Text(isAr ? 'إضافة أول فحص' : 'Add first lab'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B3B2B),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionEntrance extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final double yOffset;

  const _SectionEntrance({
    required this.child,
    required this.duration,
    this.yOffset = 18,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, builtChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * yOffset),
            child: builtChild,
          ),
        );
      },
    );
  }
}

class _AlertsPanel extends StatelessWidget {
  final List<LabAlertUiModel> alerts;

  const _AlertsPanel({required this.alerts});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (alerts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Text(
          l10n.tr('alerts_none'),
          style: TextStyle(fontSize: 11, color: Colors.green.shade900, fontWeight: FontWeight.w600),
        ),
      );
    }

    return Column(
      children: alerts.map((alert) {
        final style = _alertVisuals(alert.severity);
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: style.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: style.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(style.icon, color: style.foreground, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: style.foreground),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alert.message,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  _AlertVisuals _alertVisuals(LabAlertUiSeverity severity) {
    switch (severity) {
      case LabAlertUiSeverity.critical:
        return const _AlertVisuals(
          icon: Icons.warning_amber_rounded,
          background: Color(0xFFFFF1F2),
          border: Color(0xFFFDA4AF),
          foreground: Color(0xFFB91C1C),
        );
      case LabAlertUiSeverity.warning:
        return const _AlertVisuals(
          icon: Icons.error_outline_rounded,
          background: Color(0xFFFFF7ED),
          border: Color(0xFFFDBA74),
          foreground: Color(0xFF9A3412),
        );
      case LabAlertUiSeverity.info:
        return const _AlertVisuals(
          icon: Icons.check_circle_outline_rounded,
          background: Color(0xFFECFEFF),
          border: Color(0xFF67E8F9),
          foreground: Color(0xFF155E75),
        );
    }
  }
}

class _LabTrendCard extends StatelessWidget {
  final LabsTabLabItem lab;
  final List<LabsTabHistoryItem> history;

  const _LabTrendCard({
    required this.lab,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final values = history.map((e) => e.value).toList();

    final isOnTarget = lab.targetLabel == l10n.tr('on_target');
    final isImproving = lab.trendLabel == l10n.tr('improving');
    final isWorsening = lab.trendLabel == l10n.tr('worsening');

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOnTarget ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  lab.targetLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isOnTarget ? Colors.green.shade800 : Colors.orange.shade800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isImproving
                      ? Colors.blue.shade50
                      : (isWorsening ? Colors.red.shade50 : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  lab.trendLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isImproving
                        ? Colors.blue.shade800
                        : (isWorsening ? Colors.red.shade800 : Colors.grey.shade700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.tr('trend_history'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF1E293B)),
              ),
              Text(
                l10n.tr('records_count', args: {'count': '${history.length}'}),
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (values.isEmpty)
            Text(
              l10n.tr('no_history'),
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            )
          else
            SizedBox(
              height: 60,
              width: double.infinity,
              child: CustomPaint(
                painter: _MiniTrendPainter(
                  values: values,
                  lineColor: const Color(0xFF0284C7),
                ),
              ),
            ),
          if (history.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l10n.tr(
                  'latest_value',
                  args: {
                    'value': '${history.last.value}',
                    'unit': history.last.unit,
                    'date': history.last.date,
                  },
                ),
                style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniTrendPainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;

  _MiniTrendPainter({
    required this.values,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final span = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = values.length == 1 ? size.width / 2 : (i / (values.length - 1)) * size.width;
      final y = size.height - ((values[i] - minVal) / span) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniTrendPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.lineColor != lineColor;
  }
}

class _AlertVisuals {
  final IconData icon;
  final Color background;
  final Color border;
  final Color foreground;

  const _AlertVisuals({
    required this.icon,
    required this.background,
    required this.border,
    required this.foreground,
  });
}
