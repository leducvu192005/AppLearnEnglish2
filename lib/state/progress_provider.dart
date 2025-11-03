import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ProgressProvider extends StatefulWidget {
  const ProgressProvider({super.key});

  @override
  State<ProgressProvider> createState() => _ProgressProviderState();
}

class _ProgressProviderState extends State<ProgressProvider> {
  final _firestore = FirebaseFirestore.instance;
  String userId = '';

  int quizCount = 0;
  Map<String, int> skillCounts = {
    'listening': 0,
    'speaking': 0,
    'reading': 0,
    'writing': 0,
  };

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  /// 🔹 Tải dữ liệu quiz và kỹ năng
  Future<void> _loadProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      userId = user?.uid ?? 'demoUser';

      // --- Lấy dữ liệu quiz từ users/{uid}/progress ---
      final progressSnap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('progress')
          .get();

      int totalCompleted = 0;
      int totalAvailable = 0;

      for (var doc in progressSnap.docs) {
        final data = doc.data();
        totalCompleted += (data['completed'] ?? 0) as int;
        totalAvailable += (data['total'] ?? 0) as int;
      }

      // --- Lấy dữ liệu kỹ năng từ user_progress ---
      final skillSnap = await _firestore
          .collection('user_progress')
          .where('userId', isEqualTo: userId)
          .get();

      Map<String, int> skillTemp = {
        'listening': 0,
        'speaking': 0,
        'reading': 0,
        'writing': 0,
      };

      for (var doc in skillSnap.docs) {
        final data = doc.data();
        final skill = (data['skill'] ?? '').toString().toLowerCase();

        if (skillTemp.containsKey(skill)) {
          skillTemp[skill] = skillTemp[skill]! + 1;
        }
      }

      setState(() {
        quizCount = totalCompleted;
        skillCounts = skillTemp;
        isLoading = false;
      });

      print("✅ Quiz=$quizCount | Skills=$skillCounts");
    } catch (e) {
      print("⚠️ Lỗi khi tải tiến độ: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPercent = (quizCount / 20).clamp(
      0.0,
      1.0,
    ); // ví dụ 20 bài quiz tổng

    return Scaffold(
      appBar: AppBar(
        title: const Text("📊 Thống kê học tập"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProgress,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // 🔹 Biểu đồ tổng tiến độ quiz
                  Center(
                    child: CircularPercentIndicator(
                      radius: 90.0,
                      lineWidth: 12.0,
                      percent: totalPercent,
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${(totalPercent * 100).toStringAsFixed(1)}%",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "Quiz",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      progressColor: Colors.purple,
                      backgroundColor: Colors.grey[300]!,
                      circularStrokeCap: CircularStrokeCap.round,
                      animation: true,
                      animationDuration: 1000,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 🔹 Thông tin số bài Quiz
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    child: ListTile(
                      leading: const Icon(Icons.quiz, color: Colors.blueAccent),
                      title: const Text("Số bài Quiz đã làm"),
                      trailing: Text(
                        "$quizCount",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 🔹 Thống kê kỹ năng
                  const Text(
                    "Kỹ năng đã luyện:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 12),

                  ...skillCounts.entries.map((entry) {
                    final color = _getSkillColor(entry.key);
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ListTile(
                        leading: Icon(_getSkillIcon(entry.key), color: color),
                        title: Text(
                          "${entry.key[0].toUpperCase()}${entry.key.substring(1)}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        trailing: Text(
                          "${entry.value} bài",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: color,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Color _getSkillColor(String skill) {
    switch (skill) {
      case 'listening':
        return Colors.blueAccent;
      case 'speaking':
        return Colors.orangeAccent;
      case 'reading':
        return Colors.green;
      case 'writing':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getSkillIcon(String skill) {
    switch (skill) {
      case 'listening':
        return Icons.hearing;
      case 'speaking':
        return Icons.record_voice_over;
      case 'reading':
        return Icons.menu_book;
      case 'writing':
        return Icons.edit;
      default:
        return Icons.star_border;
    }
  }
}
