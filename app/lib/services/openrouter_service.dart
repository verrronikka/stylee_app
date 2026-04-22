import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenRouterService {
  final String _apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';

  /// Текстовый запрос к ИИ-стилисту
  Future<String> getStyleAdvice(String userMessage) async {
    if (_apiKey.isEmpty) {
      return '❌ Ошибка: API ключ не настроен. Добавьте OPENROUTER_API_KEY в файл .env';
    }

    const String model = 'qwen/qwen-vl-plus';

    print('🔍 DEBUG: Отправляю запрос к Qwen-VL (текст)...');

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
            'content': _systemPrompt
          },
          {'role': 'user', 'content': userMessage},
        ],
        'temperature': 0.7,
        'max_tokens': 1000,
      }),
    );

    print('📡 DEBUG: Статус код: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      return '❌ Ошибка ${response.statusCode}: ${response.body}';
    }
  }

  /// Запрос к ИИ-стилисту с изображением
  Future<String> getStyleAdviceWithImage({
    required String userMessage,
    required String imagePath,
  }) async {
    if (_apiKey.isEmpty) {
      return '❌ Ошибка: API ключ не настроен. Добавьте OPENROUTER_API_KEY в файл .env';
    }

    const String model = 'qwen/qwen-vl-plus';

    print('🔍 DEBUG: Отправляю запрос к Qwen-VL с изображением...');

    // Конвертируем изображение в base64
    final file = File(imagePath);
    if (!file.existsSync()) {
      return '❌ Ошибка: файл изображения не найден';
    }

    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);

    // Определяем формат изображения
    String mimeType = 'image/jpeg';
    if (imagePath.toLowerCase().endsWith('.png')) {
      mimeType = 'image/png';
    } else if (imagePath.toLowerCase().endsWith('.webp')) {
      mimeType = 'image/webp';
    }

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
            'content': _systemPrompt
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:$mimeType;base64,$base64Image',
                },
              },
              {
                'type': 'text',
                'text': userMessage.isEmpty
                    ? 'Опиши эту одежду и дай стилистические рекомендации. Что подойдёт к этому образу?'
                    : userMessage,
              },
            ],
          },
        ],
        'temperature': 0.7,
        'max_tokens': 1000,
      }),
    );

    print('📡 DEBUG: Статус код: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      return '❌ Ошибка ${response.statusCode}: ${response.body}';
    }
  }

  static const String _systemPrompt = '''Ты ИИ-стилист для приложения Stylee. Отвечай ТОЛЬКО на русском языке.

Твоя задача — анализировать одежду на фото и помогать подбирать образы.

ПРАВИЛА:
1. Если получено фото — опиши что видишь (цвет, фасон, стиль, тип одежды)
2. Давай конкретные рекомендации по сочетанию
3. Учитывай occasion (мероприятие), сезон, погоду
4. Предлагай дополнительные элементы гардероба
5. Будь дружелюбной и стильной 😊
6. Используй эмодзи для наглядности

Пример ответа на фото:
"Вижу синее платье миди с V-образным вырезом 👗

Отлично подойдёт для:
🍷 Свидания в ресторане
🎉 Вечеринки с друзьями
💼 Офиса (с пиджаком)

Рекомендую дополнить:
👠 Бежевые лодочки на каблуке
👜 Маленькая сумочка-кроссбоди
✨ Минималистичные серьги-пусеты

Цветовая гамма: синий + бежевый + золото ✨"
''';
}
