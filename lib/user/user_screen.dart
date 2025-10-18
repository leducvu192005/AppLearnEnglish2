import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/home_screen.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Học tiếng Anh cùng App'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Chào mừng bạn đến với ứng dụng học tiếng Anh!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.book),
            label: const Text('Bắt đầu học'),
            onPressed: () {
              // Thêm chức năng học ở đây
            },
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.quiz),
            label: const Text('Làm bài kiểm tra'),
            onPressed: () {
              // Thêm chức năng làm bài kiểm tra ở đây
            },
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.leaderboard),
            label: const Text('Xem bảng xếp hạng'),
            onPressed: () {
              // Thêm chức năng xem bảng xếp hạng ở đây
            },
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
            child: const Text('Đến trang chủ '),
          ),
        ],
      ),
    );
  }
}
