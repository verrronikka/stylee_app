import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stylee_app/services/openrouter_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _showSidebar = false;
  String? _selectedImagePath;
  
  String? _currentChatId;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadLastChat();
  }

  Future<void> _loadLastChat() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.email)
          .collection('Chats')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));
      
      if (snapshot.docs.isNotEmpty && mounted) {
        final lastChat = snapshot.docs.first;
        setState(() => _currentChatId = lastChat.id);
        _loadMessages(lastChat.id);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading last chat: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      ).timeout(const Duration(seconds: 30));

      if (image != null && mounted) {
        setState(() => _selectedImagePath = image.path);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error picking image: $e');
    }
  }

  Future<void> _attachImage() async {
    if (_selectedImagePath == null) return;
    await _sendMessage(isImage: true);
  }

  void _removeImage() {
    setState(() => _selectedImagePath = null);
  }

  Future<void> _loadMessages(String chatId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.email)
          .collection('Chats')
          .doc(chatId)
          .collection('Messages')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get()
          .timeout(const Duration(seconds: 5));
      
      if (mounted) {
        setState(() {
          _messages = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading messages: $e');
    }
  }

  Future<void> _createNewChat() async {
    try {
      final chatRef = await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.email)
          .collection('Chats')
          .add({
        'title': 'Новый чат',
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
      }).timeout(const Duration(seconds: 5));
      
      if (mounted) {
        setState(() {
          _currentChatId = chatRef.id;
          _messages = [];
          _showSidebar = false;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error creating chat: $e');
    }
  }

  Future<void> _openChat(String chatId) async {
    if (!mounted) return;
    setState(() {
      _currentChatId = chatId;
      _showSidebar = false;
      _messages = [];
    });
    await _loadMessages(chatId);
  }

  Future<void> _deleteChat(String chatId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.email)
          .collection('Chats')
          .doc(chatId)
          .delete()
          .timeout(const Duration(seconds: 5));
      
      if (mounted && _currentChatId == chatId) {
        setState(() {
          _currentChatId = null;
          _messages = [];
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting chat: $e');
    }
  }

  Future<void> _sendMessage({bool isImage = false}) async {
    final userText = _controller.text.trim();
    
    if (userText.isEmpty && _selectedImagePath == null) return;
    if (!mounted) return;
    
    if (_currentChatId == null) {
      await _createNewChat();
      if (_currentChatId == null) return;
    }
    
    setState(() => _isLoading = true);
    _controller.clear();

    try {
      String? savedImagePath;
      if (_selectedImagePath != null) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'chat_${DateTime.now().millisecondsSinceEpoch}.jpg';
        savedImagePath = '${directory.path}/$fileName';
        final file = File(_selectedImagePath!);
        if (file.existsSync()) {
          await file.copy(savedImagePath);
        }
      }

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.email)
          .collection('Chats')
          .doc(_currentChatId)
          .collection('Messages')
          .add({
        'type': isImage ? 'user_image' : 'user',
        'text': userText,
        'imagePath': savedImagePath,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 5));

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.email)
          .collection('Chats')
          .doc(_currentChatId)
          .update({
        'title': userText.isNotEmpty
            ? (userText.length > 30 ? '${userText.substring(0, 30)}...' : userText)
            : 'Фото',
        'lastMessage': isImage ? '📷 Фото' : userText,
        'lastMessageAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 5));

      if (!mounted) return;
      
      setState(() {
        _messages.insert(0, {
          'type': isImage ? 'user_image' : 'user',
          'text': userText,
          'imagePath': savedImagePath,
        });
        _selectedImagePath = null;
      });

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // Получаем ответ от ИИ
      final openRouterService = OpenRouterService();
      String aiText;

      if (isImage && savedImagePath != null) {
        // С изображением — используем Qwen-VL
        aiText = await openRouterService.getStyleAdviceWithImage(
          userMessage: userText,
          imagePath: savedImagePath,
        );
      } else {
        // Только текст
        aiText = await openRouterService.getStyleAdvice(userText);
      }

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUser.email)
          .collection('Chats')
          .doc(_currentChatId)
          .collection('Messages')
          .add({
        'type': 'ai',
        'title': 'AI Recommendation',
        'description': aiText,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          _messages.insert(0, {
            'type': 'ai',
            'title': 'AI Recommendation',
            'description': aiText,
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5E6E8),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              _showSidebar ? Icons.close : Icons.menu,
              color: Colors.black87,
            ),
            onPressed: () => setState(() => _showSidebar = !_showSidebar),
          ),
          title: const Text(
            'AI Stylist ✨',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          actions: [
            if (_currentChatId != null)
              IconButton(
                icon: const Icon(Icons.add_comment, color: Colors.black87),
                onPressed: _createNewChat,
              ),
          ],
        ),
        body: Row(
          children: [
            if (_showSidebar) _buildSidebar(),
            Expanded(child: _buildMainContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _createNewChat,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Создать чат'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(currentUser.email)
                  .collection('Chats')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final chats = snapshot.data!.docs;
                
                if (chats.isEmpty) {
                  return Center(
                    child: Text(
                      'Нет чатов',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index].data() as Map<String, dynamic>;
                    final chatId = chats[index].id;
                    final isSelected = chatId == _currentChatId;
                    
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: Colors.pink.shade50,
                      leading: const Icon(Icons.chat_bubble_outline, size: 20),
                      title: Text(
                        chat['title'] ?? 'Новый чат',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: Colors.grey.shade400,
                        onPressed: () => _deleteChat(chatId),
                      ),
                      onTap: () => _openChat(chatId),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_currentChatId == null || _messages.isEmpty) {
      return _buildEmptyState();
    }
    
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (_isLoading && index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFE91E63),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Stylee AI думает...',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              final messageIndex = _isLoading ? index - 1 : index;
              if (messageIndex < 0) return const SizedBox.shrink();
              
              final message = _messages[messageIndex];
              
              if (message['type'] == 'user') {
                return _buildUserMessage(message['text'] as String?);
              } else if (message['type'] == 'user_image') {
                return _buildUserImageMessage(message);
              } else {
                return _buildAIMessage(message);
              }
            },
          ),
        ),
        _buildInputField(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 80,
              color: Colors.pink.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'Чем могу помочь?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 32),
            if (_selectedImagePath != null && File(_selectedImagePath!).existsSync())
              Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: FileImage(File(_selectedImagePath!)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: _removeImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            if (_selectedImagePath != null && File(_selectedImagePath!).existsSync()) const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                      ),
                      child: Icon(
                        Icons.add,
                        color: Colors.grey.shade500,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _sendMessage(),
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Чем я могу помочь вам сегодня?',
                        border: InputBorder.none,
                        hintStyle: TextStyle(fontSize: 16),
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isLoading ? null : () {
                      if (_selectedImagePath != null && File(_selectedImagePath!).existsSync()) {
                        _attachImage();
                      } else {
                        _sendMessage();
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E63),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: _isLoading
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.arrow_upward_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Начните диалог с вашим AI-стилистом',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserMessage(String? text) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFC47A8A),
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomRight: const Radius.circular(4),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserImageMessage(Map<String, dynamic> message) {
    final imagePath = message['imagePath'] as String?;
    final text = message['text'] as String?;
    final fileExists = imagePath != null && File(imagePath).existsSync();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (text != null && text.isNotEmpty)
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.5,
              ),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFC47A8A),
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight: const Radius.circular(4),
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
          if (fileExists)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(imagePath),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.pink.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.pink,
                      size: 30,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAIMessage(Map<String, dynamic> message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomLeft: const Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.checkroom,
                    color: Colors.pink.shade300,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message['title'] ?? 'Recommendation',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message['description'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSmallButton(Icons.add, 'Wardrobe'),
              const SizedBox(width: 8),
              _buildSmallButton(Icons.favorite_border, 'Like'),
              const SizedBox(width: 8),
              _buildSmallButton(Icons.close, 'Dislike'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallButton(IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 16, color: Colors.black87),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey.shade200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_selectedImagePath != null && File(_selectedImagePath!).existsSync())
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: FileImage(File(_selectedImagePath!)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Фото прикреплено',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: _removeImage,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: Icon(
                    Icons.add,
                    color: Colors.grey.shade500,
                    size: 24,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Напишите сообщение...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: const Color(0xFFF5E6E8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _isLoading ? null : () {
                  if (_selectedImagePath != null && File(_selectedImagePath!).existsSync()) {
                    _attachImage();
                  } else {
                    _sendMessage();
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
