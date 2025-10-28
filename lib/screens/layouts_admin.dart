import 'package:flutter/material.dart';
import 'package:flutter_application_1/admin/admin_screen.dart';
import 'package:flutter_application_1/admin/quiz_management.dart';
import 'package:flutter_application_1/admin/vocabulary_management.dart';
import 'package:flutter_application_1/admin/user_management.dart';

class LayoutsAdmin extends StatefulWidget {
  const LayoutsAdmin({super.key});

  @override
  State<LayoutsAdmin> createState() => _LayoutsAdminState();
}

class _LayoutsAdminState extends State<LayoutsAdmin> {
  int _selectedIndex = 0;

  // Danh sách các trang
  final List<Widget> _pages = const [
    AdminScreen(), // Tổng quan
    QuizManagement(), // Quản lý quiz
    VocabularyManagement(), // Quản lý từ vựng
    UserManagement(), // Quản lý người dùng
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar kiểu gradient giống bên user
      appBar: AppBar(
        title: Text(
          'Admin Dashboard\nQuản lý hệ thống học tiếng Anh',
          style: const TextStyle(
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
              colors: [Colors.blue, Color.fromARGB(255, 88, 3, 138)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      body: _pages[_selectedIndex],

      // Thanh điều hướng dưới
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_outlined),
            label: 'Quiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            label: 'Từ vựng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: 'Người dùng',
          ),
        ],
      ),
    );
  }
}
