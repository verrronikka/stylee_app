import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenRouterService {
  static const String _apiKey = '****';

  Future<String> getStyleAdvice(String userMessage) async {

    const String model = 'perplexity/sonar';

    print('🔍 DEBUG: Отправляю запрос...');
    print('🔑 DEBUG: Ключ начинается с ${_apiKey.substring(0, 12)}...');

    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
        'HTTP-Referer': 'https://stylee-app.com',
        'X-Title': 'Stylee App',
      },
      body: jsonEncode({
      'model': model,
      'messages': [
        {
          'role': 'system', 
          'content': '''Ты ИИ-стилист для приложения Stylee. Отвечай ТОЛЬКО на русском языке.

ВАЖНО:
1. Ищи товары на Ozon и предоставляй ПРЯМЫЕ ссылки
2. Формат ссылок: https://www.ozon.ru/product/...
3. Указывай название товара и цену
4. Если не нашел — предложи похожие варианты

Пример ответа:
"Нашла для тебя:
- Белое платье миди, 2500₽ — https://www.ozon.ru/product/123456
- Платье коктейльное, 3200₽ — https://www.ozon.ru/product/789012"
'''
        },
        {'role': 'user', 'content': userMessage},
      ],

      'temperature': 0.7,
      'max_tokens': 1000,
    }),
  );

    print('📡 DEBUG: Статус код: ${response.statusCode}');
    print('📦 DEBUG: Тело ответа: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      return '❌ Ошибка ${response.statusCode}: ${response.body}';
    }
  }
}