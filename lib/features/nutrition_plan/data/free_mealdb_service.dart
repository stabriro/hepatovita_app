import 'dart:convert';

import 'package:http/http.dart' as http;

class FreeMealDbMeal {
  final String name;
  final String imageUrl;

  const FreeMealDbMeal({
    required this.name,
    required this.imageUrl,
  });
}

class FreeMealDbService {
  static const String _base = 'https://www.themealdb.com/api/json/v1/1';

  Future<List<FreeMealDbMeal>> fetchMealsByCategory(String category) async {
    final uri = Uri.parse('$_base/filter.php?c=$category');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      return const <FreeMealDbMeal>[];
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final meals = (decoded['meals'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map(
          (e) => FreeMealDbMeal(
            name: e['strMeal'] as String? ?? '',
            imageUrl: e['strMealThumb'] as String? ?? '',
          ),
        )
        .where((e) => e.name.isNotEmpty && e.imageUrl.isNotEmpty)
        .toList();

    return meals;
  }
}
