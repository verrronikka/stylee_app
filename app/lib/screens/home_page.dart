import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stylee_app/components/drawer.dart';
import 'package:stylee_app/components/text_filed.dart';
import 'package:stylee_app/components/wall_post.dart';
import 'package:stylee_app/screens/chat_page.dart';
import 'package:stylee_app/screens/editor_page.dart';
import 'package:stylee_app/screens/edit_profile_page.dart';
import 'package:stylee_app/screens/profile_page.dart';
import 'package:stylee_app/screens/wardrobe_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final currentUser = FirebaseAuth.instance.currentUser!;
  final textController = TextEditingController();

  void signOut() {
    FirebaseAuth.instance.signOut();
  }

  void postMessage() {
    if (textController.text.isNotEmpty) {
      FirebaseFirestore.instance.collection("User Posts").add({
        'UserEmail': currentUser.email,
        'Message': textController.text,
        'TimeStamp': Timestamp.now(),
        'Likes': [],
      });

      setState(() {
        textController.clear();
      });
    }
  }

  void goToProfilePage() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showProfileMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Настройки'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Выйти', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  signOut();
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
    Widget currentPage;
    switch (_selectedIndex) {
      case 0:
        currentPage = _buildWallFeed();
        break;
      case 1:
        currentPage = const WardrobePage();
        break;
      case 2:
        currentPage = const EditorPage();
        break;
      case 3:
        currentPage = const ChatPage();
        break;
      case 4:
        currentPage = const ProfilePage();
        break;
      default:
        currentPage = _buildWallFeed();
    }

    final isProfile = _selectedIndex == 4;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5E6E8),
        extendBodyBehindAppBar: isProfile,
        appBar: isProfile
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: TextButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfilePage()),
                    );
                    if (result == true && mounted) {
                      setState(() {}); // Обновляем профиль
                    }
                  },
                  child: Text(
                    'Edit',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
                title: Text(
                  'Stylee',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: Icon(Icons.menu, color: Colors.black87),
                    onPressed: () => _showProfileMenu(context),
                  ),
                ],
              )
            : null,
        drawer: _selectedIndex == 0
            ? MyDrawer(onProfileTap: goToProfilePage, onSignOut: signOut)
            : null,
        body: currentPage,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(0, -5),
              ),
            ],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onBottomNavTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Colors.black87,
            unselectedItemColor: Colors.grey.shade600,
            selectedLabelStyle: const TextStyle(fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: [
              _buildNavItem(Icons.local_fire_department_outlined, 'Feed', 0),
              _buildNavItem(Icons.checkroom_outlined, 'Wardrobe', 1),
              _buildNavItem(Icons.auto_fix_high_outlined, 'Editor', 2),
              _buildNavItem(Icons.auto_awesome_outlined, 'AI Stylist', 3),
              _buildNavItem(Icons.person_outline, 'Profile', 4),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    String label,
    int index,
  ) {
    final isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: Stack(
        alignment: Alignment.center,
        children: [
          if (isSelected)
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE91E63).withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFFE91E63) : const Color(0xFF666666),
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? const Color(0xFFE91E63) : const Color(0xFF666666),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
      label: '',
    );
  }

  Widget _buildWallFeed() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection("User Posts")
          .orderBy("TimeStamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final posts = snapshot.data!.docs;
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_fire_department_outlined,
                    size: 80,
                    color: Colors.pink.shade300,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Лента пуста',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Подпишитесь на стилистов\nили создайте первый пост',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }
          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return _TikTokStylePost(
                post: post,
                currentIndex: index,
                totalPosts: posts.length,
              );
            },
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _TikTokStylePost extends StatefulWidget {
  final QueryDocumentSnapshot post;
  final int currentIndex;
  final int totalPosts;

  const _TikTokStylePost({
    required this.post,
    required this.currentIndex,
    required this.totalPosts,
  });

  @override
  State<_TikTokStylePost> createState() => _TikTokStylePostState();
}

class _TikTokStylePostState extends State<_TikTokStylePost> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  bool isLiked = false;
  late List<String> likes;

  @override
  void initState() {
    super.initState();
    likes = List<String>.from(widget.post['Likes'] ?? []);
    isLiked = likes.contains(currentUser.email);
  }

  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
      if (isLiked) {
        likes.add(currentUser.email!);
      } else {
        likes.remove(currentUser.email);
      }
    });

    DocumentReference postRef = FirebaseFirestore.instance
        .collection("User Posts")
        .doc(widget.post.id);

    postRef.update({
      'Likes': isLiked
          ? FieldValue.arrayUnion([currentUser.email])
          : FieldValue.arrayRemove([currentUser.email]),
    });
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = widget.post['UserEmail'] ?? 'Anonymous';
    final message = widget.post['Message'] ?? '';
    final timestamp = widget.post['TimeStamp'] as Timestamp?;
    
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Основное изображение (карусель из 3 фото)
          _buildImageCarousel(),
          
          // Градиент снизу для читаемости текста
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // Боковая панель справа (как в TikTok)
          Positioned(
            right: 12,
            bottom: 120,
            child: _buildSideActions(),
          ),
          
          // Информация о посте снизу
          Positioned(
            left: 16,
            right: 80,
            bottom: 24,
            child: _buildPostInfo(userEmail, message, timestamp),
          ),
          
          // Счётчик постов сверху
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${widget.currentIndex + 1}/${widget.totalPosts}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    // Демо: 3 placeholder изображения одежды
    final images = [
      'https://images.unsplash.com/photo-1434389677669-e08b4cda3a98?w=400&h=600&fit=crop',
      'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=400&h=600&fit=crop',
      'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=400&h=600&fit=crop',
    ];

    return PageView.builder(
      itemCount: images.length,
      itemBuilder: (context, imgIndex) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(images[imgIndex]),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSideActions() {
    return Column(
      children: [
        // Аватар пользователя
        _buildUserAvatar(),
        const SizedBox(height: 20),
        
        // Лайк
        _buildActionButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          color: isLiked ? Colors.red : Colors.white,
          label: '${likes.length}',
          onTap: toggleLike,
        ),
        const SizedBox(height: 16),
        
        // Комментарии
        _buildActionButton(
          icon: Icons.chat_bubble_outline,
          color: Colors.white,
          label: '0',
          onTap: () {},
        ),
        const SizedBox(height: 16),
        
        // Поделиться
        _buildActionButton(
          icon: Icons.share_outlined,
          color: Colors.white,
          label: 'Share',
          onTap: () {},
        ),
        const SizedBox(height: 16),
        
        // Сохранить
        _buildActionButton(
          icon: Icons.bookmark_border,
          color: Colors.white,
          label: 'Save',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child: Container(
          color: Colors.grey.shade400,
          child: const Icon(Icons.person, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.3),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostInfo(String userEmail, String message, Timestamp? timestamp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Имя пользователя
        Row(
          children: [
            Text(
              '@${userEmail.split('@').first}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Follow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Описание поста
        if (message.isNotEmpty)
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 12),
        
        // Время
        if (timestamp != null)
          Text(
            _formatTimestamp(timestamp),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final postDate = timestamp.toDate();
    final diff = now.difference(postDate);

    if (diff.inMinutes < 1) return 'только что';
    if (diff.inHours < 1) return '${diff.inMinutes} мин. назад';
    if (diff.inDays < 1) return '${diff.inHours} ч. назад';
    if (diff.inDays < 7) return '${diff.inDays} дн. назад';
    
    return '${postDate.day}.${postDate.month}.${postDate.year}';
  }
}