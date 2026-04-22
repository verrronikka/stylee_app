import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stylee_app/screens/edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final usersCollection = FirebaseFirestore.instance.collection("Users");
  final ImagePicker _picker = ImagePicker();
  
  String? _profileImagePath;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      final doc = await usersCollection.doc(currentUser.email).get().timeout(
        const Duration(seconds: 5),
      );
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['profileImagePath'] != null && mounted) {
          setState(() {
            _profileImagePath = data['profileImagePath'];
          });
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading profile image: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 75,
      ).timeout(
        const Duration(seconds: 30),
      );

      if (image != null && mounted) {
        setState(() => _isUploading = true);
        
        await _saveImageLocally(image.path);
        
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error picking image: $e');
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка при выборе фото'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _saveImageLocally(String imagePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${currentUser.email!.replaceAll('@', '_').replaceAll('.', '_')}.jpg';
      final savedPath = '${directory.path}/$fileName';
      
      final file = File(imagePath);
      if (!file.existsSync()) {
        throw Exception('Файл не существует');
      }
      
      await file.copy(savedPath);

      await usersCollection.doc(currentUser.email).update({
        'profileImagePath': savedPath,
      }).timeout(const Duration(seconds: 5));

      if (mounted) {
        setState(() => _profileImagePath = savedPath);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Фото обновлено!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error saving image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _showImagePicker() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выбрать фото'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.pink),
                title: const Text('Галерея'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
          ],
        );
      },
    );
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
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("Users")
              .doc(currentUser.email)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final userData = snapshot.data!.data() as Map<String, dynamic>;

              return CustomScrollView(
                slivers: [
                  // Profile Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 80, left: 20, right: 20),
                      child: Column(
                        children: [
                          // Avatar
                          GestureDetector(
                            onTap: _isUploading ? null : _showImagePicker,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: const Color(0xFFF8E8EA),
                                  backgroundImage: _profileImagePath != null && File(_profileImagePath!).existsSync()
                                      ? FileImage(File(_profileImagePath!))
                                      : null,
                                  child: (_profileImagePath == null || !File(_profileImagePath!).existsSync()) && !_isUploading
                                      ? Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.pink.shade200,
                                        )
                                      : null,
                                ),
                                if (_isUploading)
                                  const Positioned.fill(
                                    child: CircleAvatar(
                                      radius: 50,
                                      backgroundColor: Colors.black26,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
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
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.white,
                                      child: Icon(
                                        _isUploading ? Icons.hourglass_empty : Icons.add,
                                        size: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (!_isUploading)
                            Text(
                              'Нажмите для выбора фото',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          const SizedBox(height: 16),
                          // Username
                          Text(
                            '@${userData['username'] ?? currentUser.email!.split('@')[0]}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Bio
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  userData['bio'] ?? 'Fashion dreamer | OOTD everyday ✨',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const EditProfilePage(),
                                    ),
                                  );
                                  if (result == true && mounted) {
                                    setState(() {});
                                  }
                                },
                                child: Icon(
                                  Icons.edit_rounded,
                                  size: 16,
                                  color: Colors.pink.shade400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Stories Highlights
                          Text(
                            'Stories Highlights',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Highlights Row
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                children: [
                                  _buildHighlight('Summer'),
                                  const SizedBox(width: 16),
                                  _buildHighlight('OOTD'),
                                  const SizedBox(width: 16),
                                  _buildHighlight('Date Night'),
                                  const SizedBox(width: 16),
                                  _buildHighlight('Workwear'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Разделительная линия
                          Divider(
                            thickness: 1,
                            color: Colors.black.withOpacity(0.1),
                            indent: 0,
                            endIndent: 0,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Grid of Posts
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    sliver: SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              size: 80,
                              color: Colors.pink.shade200,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Пока ничего нет',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Делитесь своими образами ✨',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildHighlight(String label) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE91E63),
                  Color(0xFFFF6B9D),
                  Color(0xFFFFB6C1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFF5E6E8),
              child: CircleAvatar(
                radius: 27,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
