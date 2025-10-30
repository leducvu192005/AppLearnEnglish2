import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/percent_indicator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  double progress = 0.0;
  int completed = 0;
  int total = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final quizSnapshot = await _firestore.collection('quizzes').get();
      total = quizSnapshot.docs.length;

      int done = 0;
      final userProgress = await _firestore
          .collection('users')
          .doc(uid)
          .collection('progress')
          .get();

      for (var doc in userProgress.docs) {
        final data = doc.data();
        if ((data['percent'] ?? 0) > 0) done++;
      }

      setState(() {
        completed = done;
        progress = total == 0 ? 0 : completed / total;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Lỗi tải tiến độ: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(title: const Text('Welcome to English Learning App!')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 👋 Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.blueAccent.withOpacity(0.2),
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Xin chào, ${user?.email ?? 'Người học'} 👋",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              "Chào mừng bạn quay lại học hôm nay!",
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // 🔵 Thanh tiến độ
                  Center(
                    child: CircularPercentIndicator(
                      radius: 90,
                      lineWidth: 12,
                      percent: progress.clamp(0.0, 1.0),
                      animation: true,
                      animationDuration: 1200,
                      progressColor: Colors.blueAccent,
                      backgroundColor: Colors.grey.shade300,
                      circularStrokeCap: CircularStrokeCap.round,
                      center: Text(
                        "${(progress * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      "$completed / $total bài quiz đã hoàn thành",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 📚 Danh mục học tập
                  const Text(
                    "📚 Danh mục học tập",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  _buildCard(
                    context,
                    title: "Từ vựng",
                    icon: Icons.book_rounded,
                    colors: [Colors.greenAccent, Colors.teal],
                    onTap: () {
                      Navigator.pushNamed(context, '/vocabulary');
                    },
                  ),
                  _buildCard(
                    context,
                    title: "Làm bài Quiz",
                    icon: Icons.quiz_rounded,
                    colors: [Colors.orangeAccent, Colors.deepOrange],
                    onTap: () {
                      Navigator.pushNamed(context, '/quiz');
                    },
                  ),
                  _buildCard(
                    context,
                    title: "Trang cá nhân",
                    icon: Icons.person_rounded,
                    colors: [Colors.purpleAccent, Colors.deepPurple],
                    onTap: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                ],
              ),
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
