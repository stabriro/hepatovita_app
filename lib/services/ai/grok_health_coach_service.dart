import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app/config/grok_config.dart';

class GrokHealthCoachService {
  const GrokHealthCoachService();

  Future<String?> generateMealCoachSummary({
    required String mealName,
    required Map<String, dynamic> analysis,
    required bool isAr,
  }) async {
    if (!GrokConfig.isConfigured) {
      return null;
    }

    final prompt = _buildPrompt(
      mealName: mealName,
      analysis: analysis,
      isAr: isAr,
    );

    final response = await http
        .post(
          Uri.parse(GrokConfig.baseUrl),
          headers: {
            'Authorization': 'Bearer ${GrokConfig.apiKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': GrokConfig.model,
            'temperature': 0.3,
            'max_tokens': 120,
            'messages': [
              {
                'role': 'system',
                'content': isAr
                    ? 'أنت مساعد تثقيف صحي. قدم ملخصا قصيرا وآمنا فقط. لا تشخّص ولا تكتب وصفة ولا تدّعِ أنك طبيب. إذا لم تكن المعلومات كافية، اطلب مراجعة مختص.'
                    : 'You are a health education assistant. Provide a short, safe summary only. Do not diagnose, prescribe, or claim to be a doctor. If the data is insufficient, ask the user to consult a professional.',
              },
              {
                'role': 'user',
                'content': prompt,
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      return null;
    }

    final firstChoice = choices.first;
    if (firstChoice is! Map<String, dynamic>) {
      return null;
    }

    final message = firstChoice['message'];
    if (message is! Map<String, dynamic>) {
      return null;
    }

    final content = (message['content'] as String?)?.trim();
    if (content == null || content.isEmpty) {
      return null;
    }

    return content;
  }

  String _buildPrompt({
    required String mealName,
    required Map<String, dynamic> analysis,
    required bool isAr,
  }) {
    final score = (analysis['score'] ?? '').toString();
    final reason = (analysis['reason'] ?? '').toString();
    final confidence = (analysis['confidence'] ?? '').toString();
    final caveat = (analysis['caveat'] ?? '').toString();
    final tips = (analysis['tips'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => e.toString())
        .take(3)
        .toList();

    if (isAr) {
      return '''
أريد ملخص تثقيفي قصير لوجبة اسمها: $mealName.

التحليل الحالي:
- التقييم: $score
- مستوى الثقة: $confidence
- السبب: $reason
- الملاحظة: $caveat
- النقاط المهمة: ${tips.isEmpty ? 'لا يوجد' : tips.join(' | ')}

المطلوب:
- سطر واحد أو سطرين فقط
- بلغة عربية بسيطة
- يوضح إن كانت الوجبة مناسبة أو تحتاج تعديلًا بسيطًا
- لا تذكر تشخيصًا أو علاجًا أو وصفة
- لا تستخدم نبرة سريرية، فقط توجيه غذائي عام''';
    }

    return '''
I need a short educational summary for a meal named: $mealName.

Current analysis:
- Score: $score
- Confidence: $confidence
- Reason: $reason
- Caveat: $caveat
- Key tips: ${tips.isEmpty ? 'None' : tips.join(' | ')}

Requirements:
- Keep it to one or two lines
- Use simple English
- Say whether the meal seems suitable or needs a small adjustment
- Do not diagnose, prescribe, or sound clinical
- Keep it educational only''';
  }
}