import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:percent_indicator/percent_indicator.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _firestore = FirebaseFirestore.instance;

  int totalUsers = 0;
  int totalQuizzes = 0;
  int totalWords = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final users = await _firestore.collection('users').get();
      final quizzes = await _firestore.collection('quizzes').get();
      final words = await _firestore.collection('vocabulary').get();

      setState(() {
        totalUsers = users.size;
        totalQuizzes = quizzes.size;
        totalWords = words.size;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Lỗi tải thống kê: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🧑‍💼 Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.purple.withOpacity(0.2),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          size: 40,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        "Xin chào, Quản trị viên 👋",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // 📊 Tổng quan số liệu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard("Người dùng", totalUsers, Colors.blue),
                      _buildStatCard("Quiz", totalQuizzes, Colors.orange),
                      _buildStatCard("Từ vựng", totalWords, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // 📈 Tỷ lệ phát triển (ví dụ ước lượng)
                  Center(
                    child: CircularPercentIndicator(
                      radius: 80,
                      lineWidth: 10,
                      percent: (totalUsers / 100).clamp(0.0, 1.0),
                      progressColor: Colors.deepPurple,
                      backgroundColor: Colors.grey.shade300,
                      animation: true,
                      center: Text(
                        "${totalUsers > 100 ? 100 : totalUsers}%",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  const Text(
                    "⚙️ Quản lý hệ thống",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  _buildCard(
                    context,
                    title: "Quản lý Quiz",
                    icon: Icons.quiz,
                    colors: [Colors.orangeAccent, Colors.deepOrange],
                    onTap: () {
                      Navigator.pushNamed(context, '/admin/quiz');
                    },
                  ),
                  _buildCard(
                    context,
                    title: "Quản lý Từ vựng",
                    icon: Icons.book,
                    colors: [Colors.greenAccent, Colors.teal],
                    onTap: () {
                      Navigator.pushNamed(context, '/admin/vocabulary');
                    },
                  ),
                  _buildCard(
                    context,
                    title: "Quản lý Người dùng",
                    icon: Icons.people,
                    colors: [Colors.blueAccent, Colors.indigo],
                    onTap: () {
                      Navigator.pushNamed(context, '/admin/users');
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, int value, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            "$value",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: colors.last.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.3),
                radius: 28,
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 20),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
