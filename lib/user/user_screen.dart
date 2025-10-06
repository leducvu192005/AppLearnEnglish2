import 'package:flutter/material.dart';

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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Xin chào, học viên!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.book_online),
              title: const Text('Học từ vựng'),
              subtitle: const Text('Ôn luyện từ mới mỗi ngày'),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.mic),
              title: const Text('Luyện nghe nói'),
              subtitle: const Text('Cải thiện phát âm của bạn'),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.quiz),
              title: const Text('Làm bài kiểm tra'),
              subtitle: const Text('Đánh giá kỹ năng hiện tại'),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
