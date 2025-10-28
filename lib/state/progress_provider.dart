import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ProgressProvider extends StatefulWidget {
  const ProgressProvider({super.key});

  @override
  State<ProgressProvider> createState() => _ProgressProviderState();
}

class _ProgressProviderState extends State<ProgressProvider> {
  final _firestore = FirebaseFirestore.instance;

  int totalQuizzes = 0;
  int completedQuizzes = 0;
  double progressPercent = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      // 1️⃣ Đếm tổng số quiz trong Firestore
      final quizSnap = await _firestore.collection('quizzes').get();
      totalQuizzes = quizSnap.docs.length;

      // 2️⃣ Lấy danh sách user progress
      final progressSnap = await _firestore.collection('user_progress').get();

      // Giả sử bạn chỉ có 1 user hiện tại (userId123)
      int count = 0;
      for (var doc in progressSnap.docs) {
        final data = doc.data();
        if (data.containsKey('userId123')) {
          // Truy cập mảng userId123
          final userProgressList = data['userId123'] as List<dynamic>;
          count += userProgressList.length;
        }
      }

      completedQuizzes = count;

      // 3️⃣ Tính phần trăm
      if (totalQuizzes > 0) {
        progressPercent = completedQuizzes / totalQuizzes;
      }

      setState(() => isLoading = false);
    } catch (e) {
      print("⚠️ Lỗi khi tải tiến độ: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tiến độ học tập"), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Bạn đã hoàn thành $completedQuizzes / $totalQuizzes quiz",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 30),

                  // 🔵 Biểu đồ vòng tròn tiến độ
                  CircularPercentIndicator(
                    radius: 90.0,
                    lineWidth: 12.0,
                    percent: progressPercent.clamp(0.0, 1.0),
                    center: Text(
                      "${(progressPercent * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    progressColor: Colors.blueAccent,
                    backgroundColor: Colors.grey[300]!,
                    circularStrokeCap: CircularStrokeCap.round,
                    animation: true,
                    animationDuration: 1200,
                  ),
                  const SizedBox(height: 30),

                  ElevatedButton.icon(
                    onPressed: _loadProgress,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Làm mới tiến độ"),
                  ),
                ],
              ),
            ),
    );
  }
}
