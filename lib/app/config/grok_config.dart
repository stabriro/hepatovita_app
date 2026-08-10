class GrokConfig {
  GrokConfig._();

  // Pass with: --dart-define=GROK_API_KEY=your_key
  static const String apiKey = String.fromEnvironment('GROK_API_KEY');
  static const String model = 'grok-3-mini';
  static const String baseUrl = 'https://api.x.ai/v1/chat/completions';

  static bool get isConfigured => apiKey.trim().isNotEmpty;
}