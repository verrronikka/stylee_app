import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stylee_app/components/drawer.dart';
import 'package:stylee_app/components/text_filed.dart';
import 'package:stylee_app/components/wall_post.dart';
import 'package:stylee_app/screens/profile_page.dart';
import 'package:stylee_app/screens/chat_page.dart';

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

  // Метод для переключения вкладок
  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Определяем, какой экран показывать
    Widget currentPage;
    switch (_selectedIndex) {
      case 0:
        currentPage = _buildWallFeed(); // Лента
        break;
      case 1:
        currentPage = const Center(child: Text('Избранное'));
        break;
      case 2:
        currentPage = _buildWallFeed();
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

    return Scaffold(
      backgroundColor: Colors.pink.shade100,
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? "The Wall" : "Stylee"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      drawer: _selectedIndex == 0 ? MyDrawer(onProfileTap: goToProfilePage, onSignOut: signOut) : null,
      body: currentPage,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        iconSize: 24,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.rss_feed), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_rounded), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: ''),
        ],
      ),
    );
  }

  Widget _buildWallFeed() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("User Posts")
                .orderBy("TimeStamp", descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final post = snapshot.data!.docs[index];
                    return WallPost(
                      message: post['Message'],
                      user: post['UserEmail'],
                      postId: post.id,
                      likes: List<String>.from(post['Likes'] ?? []),
                      time: post['TimeStamp'].toString(),
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return Center(child: Text('Error:${snapshot.error}'));
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(25.0),
          child: Row(
            children: [
              Expanded(
                child: MyTextField(
                  controller: textController,
                  hintText: "Write something on the wall..",
                  obsureText: false,
                ),
              ),
              IconButton(
                onPressed: postMessage,
                icon: const Icon(Icons.arrow_circle_up),
              ),
            ],
          ),
        ),
      ],
    );
  }
}