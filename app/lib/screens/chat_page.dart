import 'package:flutter/material.dart';
import 'package:stylee_app/components/chat_message.dart';
import 'package:stylee_app/services/openrouter_service.dart'; // 🔥 Импорт сервиса
import 'package:velocity_x/velocity_x.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final OpenRouterService _apiService = OpenRouterService(); // 🔥 Создаем сервис
  bool _isLoading = false; // 🔥 Флаг загрузки

  void sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userText = _controller.text.trim();

    // 1. Добавляем сообщение пользователя
    setState(() {
      _messages.insert(0, ChatMessage(text: userText, sender: 'Ты'));
      _isLoading = true;
      _controller.clear();
    });

    try {
      final aiResponse = await _apiService.getStyleAdvice(userText);

      setState(() {
        _messages.insert(0, ChatMessage(text: aiResponse, sender: 'Stylee AI'));
        _isLoading = false;
      });
    } catch (e) {

      setState(() {
        _messages.insert(0, ChatMessage(text: 'Ошибка: $e', sender: 'Stylee AI'));
        _isLoading = false;
      });
    }
  }

  Widget _buildTextComposer() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            onSubmitted: (_) => sendMessage(),
            decoration: InputDecoration.collapsed(hintText: "Спроси стилиста..."),
          ),
        ),
        IconButton(
          onPressed: _isLoading ? null : sendMessage, 
          icon: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send),
        ),
      ],
    ).px8();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade100,

      body: Column(
        children: [
          Flexible(
            child: ListView.builder(
              reverse: true,
              padding: Vx.m8,
              itemCount: _messages.length + (_isLoading ? 1 : 0), // +1 для индикатора
              itemBuilder: (context, index) {
                // Показываем индикатор "печатает..." если ИИ думает
                if (_isLoading && index == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.pink,
                          child: Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Stylee AI думает...',
                          style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  );
                }
                // Сдвигаем индекс, если показываем индикатор
                final messageIndex = _isLoading ? index - 1 : index;
                if (messageIndex < 0) return const SizedBox.shrink();
                
                return _messages[messageIndex];
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }
}