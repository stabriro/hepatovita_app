import 'package:flutter_test/flutter_test.dart';
import 'package:itmain_app/features/labs/presentation/controllers/lab_entry_flow_controller.dart';

void main() {
  group('LabEntryFlowController.parseLabDraftsFromText', () {
    test('ignores measurement noise that looks like a metric', () {
      const text = '''
2026-08-11
Albumin
Value 3.37 mmol/L
Reference Range: 3.5-5.2 g/dL
H Pylori Antigen
5.0
Value 83 U/mL
Reference Range: < 30
''';

      final drafts = LabEntryFlowController.parseLabDraftsFromText(text);

      expect(drafts, hasLength(2));
      expect(drafts[0].metric, 'Albumin');
      expect(drafts[0].value, '3.37');
      expect(drafts[0].unit, 'mmol/L');
      expect(drafts[0].refRange, '3.5-5.2 g/dL');
      expect(drafts[1].metric, 'H Pylori Antigen');
      expect(drafts[1].value, '5.0');
      expect(drafts[1].refRange, '< 30');
    });

    test('normalizes camel-cased OCR metric labels', () {
      const text = '''
2026-08-11
HPyloriAntigen
5.0
''';

      final drafts = LabEntryFlowController.parseLabDraftsFromText(text);

      expect(drafts, hasLength(1));
      expect(drafts.single.metric, 'H Pylori Antigen');
    });
  });
}
