import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/state/ai_chat_screen.dart';
import 'package:flutter_application_1/state/vocabulary_page.dart';
import 'package:flutter_application_1/state/quiz_provider.dart';
import 'package:flutter_application_1/state/user_provider.dart';

class LayoutsMain extends StatefulWidget {
  const LayoutsMain({super.key});

  @override
  State<LayoutsMain> createState() => _LayoutsMainState();
}

class _LayoutsMainState extends State<LayoutsMain> {
  int _selectedIndex = 0;

  // 🔹 Danh sách các trang tương ứng với từng tab (đã bỏ Progress)
  final List<Widget> _pages = [
    const HomePage(), // 0. Home
    const AiChatScreen(), // 1. ChatBox
    const VocabularyPage(), // 2. Vocabulary
    const QuizProvider(), // 3. Practice
    const UserProviderPage(), // 4. Profile
  ];

  // 🔹 Khi người dùng nhấn vào tab
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: AppBar(
            title: const Text(
              'English Learning App\nKeep learning English every day!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.left,
            ),
            automaticallyImplyLeading: false,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.lightBlueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),
      ),

      // 🔹 Hiển thị trang tương ứng
      body: _pages[_selectedIndex],

      // 🔹 Thanh điều hướng dưới cùng
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'ChatBox'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Vocabulary'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            label: 'Practice',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
