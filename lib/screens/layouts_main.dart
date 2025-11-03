import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/state/quiz_provider.dart';
import 'package:flutter_application_1/state/user_provider.dart';
import 'package:flutter_application_1/state/vocabulary_page.dart';
import 'package:flutter_application_1/state/progress_provider.dart';

class LayoutsMain extends StatefulWidget {
  const LayoutsMain({super.key});

  @override
  State<LayoutsMain> createState() => _LayoutsMainState();
}

class _LayoutsMainState extends State<LayoutsMain> {
  int _selectedIndex = 0;

  // Danh sách các trang/tab
  final List<Widget> _pages = [
    const HomePage(),
    const VocabularyPage(),
    const QuizProvider(),
    const ProgressProvider(),
    const UserProviderPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80), // Chiều cao AppBar
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: AppBar(
            title: const Text(
              'English Learning App\nKeep learning english every day!',
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

      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Vocabulary'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            label: 'Practice',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Progress',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}
