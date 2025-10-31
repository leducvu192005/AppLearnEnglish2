import 'package:flutter/material.dart';
import 'package:flutter_application_1/admin/admin_screen.dart';
import 'package:flutter_application_1/admin/reports.dart';
import 'package:flutter_application_1/admin/setting.dart';
import 'package:flutter_application_1/admin/user_management.dart';

class LayoutsAdmin extends StatefulWidget {
  const LayoutsAdmin({super.key});

  @override
  State<LayoutsAdmin> createState() => _LayoutsAdminState();
}

class _LayoutsAdminState extends State<LayoutsAdmin> {
  int _selectedIndex = 0;

  // Danh sách các trang
  final List<Widget> _pages = [
    AdminScreen(), // Tổng quan
    Reports(), //  trang báo cáo
    UserManagement(), // Quản lý người dùng
    Setting(), // Cài đặt
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar kiểu gradient và bo 2 góc dưới
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80), // Chiều cao AppBar
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: AppBar(
            title: const Text(
              'Admin Dashboard\nQuản lý hệ thống học tiếng Anh',
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
          BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Báo cáo'),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: 'Người dùng',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
        ],
      ),
    );
  }
}
