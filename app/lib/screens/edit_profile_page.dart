import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final usersCollection = FirebaseFirestore.instance.collection("Users");
  final _picker = ImagePicker();
  
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  
  String? _profileImagePath;
  String? _newImagePath;
  bool _isLoading = false;
  String? _usernameError;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final doc = await usersCollection.doc(currentUser.email).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _usernameController.text = data['username'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _profileImagePath = data['profileImagePath'];
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading profile: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() => _newImagePath = image.path);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error picking image: $e');
    }
  }

  Future<bool> _checkUsername(String username) async {
    if (username.isEmpty) return false;
    
    final currentDoc = await usersCollection.doc(currentUser.email).get();
    final currentUsername = currentDoc.data()?['username'];
    
    // Если ник не менялся, считаем доступным
    if (username == currentUsername) return true;
    
    final snapshot = await usersCollection
        .where('username', isEqualTo: username)
        .get();
    
    return snapshot.docs.isEmpty;
  }

  Future<void> _validateUsername() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _usernameError = null);
      return;
    }

    final isAvailable = await _checkUsername(username);
    
    setState(() {
      _usernameError = isAvailable ? null : 'Этот ник уже занят';
    });
  }

  Future<void> _saveProfile() async {
    final username = _usernameController.text.trim();
    final bio = _bioController.text.trim();

    if (username.isEmpty) {
      setState(() => _usernameError = 'Введите ник');
      return;
    }

    final isAvailable = await _checkUsername(username);
    if (!isAvailable) {
      setState(() => _usernameError = 'Этот ник уже занят');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? savedImagePath = _profileImagePath;
      
      if (_newImagePath != null) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'profile_${currentUser.email!.replaceAll('@', '_').replaceAll('.', '_')}.jpg';
        savedImagePath = '${directory.path}/$fileName';
        
        final file = File(_newImagePath!);
        if (file.existsSync()) {
          await file.copy(savedImagePath);
        }
      }

      await usersCollection.doc(currentUser.email).update({
        'username': username,
        'bio': bio,
        'profileImagePath': savedImagePath,
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль обновлён!')),
        );
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
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Редактировать профиль',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Сохранить',
                    style: TextStyle(
                      color: Color(0xFFE91E63),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Аватарка
            Center(
              child: GestureDetector(
                onTap: _isLoading ? null : _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFFF8E8EA),
                      backgroundImage: _newImagePath != null
                          ? FileImage(File(_newImagePath!))
                          : _profileImagePath != null
                              ? FileImage(File(_profileImagePath!))
                              : null,
                      child: (_newImagePath == null && _profileImagePath == null)
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.pink,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Нажмите для изменения фото',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Username
            const Text(
              'Никнейм',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _usernameController,
              onChanged: (value) => _validateUsername(),
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: 'Введите ваш ник',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _usernameError != null
                    ? const Icon(Icons.error, color: Colors.red)
                    : _usernameController.text.isNotEmpty && _usernameError == null
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                errorText: _usernameError,
              ),
            ),
            const SizedBox(height: 24),
            // Bio
            const Text(
              'О себе',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              enabled: !_isLoading,
              maxLines: 4,
              maxLength: 150,
              decoration: InputDecoration(
                hintText: 'Fashion dreamer | OOTD everyday ✨',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
