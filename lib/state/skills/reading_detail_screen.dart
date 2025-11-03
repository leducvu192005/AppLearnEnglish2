import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';

class ReadingDetailScreen extends StatefulWidget {
  final String topicId;
  final Map<String, dynamic> topicData;

  const ReadingDetailScreen({
    super.key,
    required this.topicId,
    required this.topicData,
  });

  @override
  State<ReadingDetailScreen> createState() => _ReadingDetailScreenState();
}

class _ReadingDetailScreenState extends State<ReadingDetailScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );

  /// Lưu key = "lessonIndex-questionIndex", value = "đáp án chọn"
  Map<String, String> selectedAnswers = {};

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _submitAnswers(List<QueryDocumentSnapshot> lessons) async {
    int totalCorrect = 0;
    int totalQuestions = 0;

    for (int lIndex = 0; lIndex < lessons.length; lIndex++) {
      final data = lessons[lIndex].data() as Map<String, dynamic>;
      final questions = List<Map<String, dynamic>>.from(
        data['questions'] ?? [],
      );

      for (int qIndex = 0; qIndex < questions.length; qIndex++) {
        totalQuestions++;
        final q = questions[qIndex];
        final correct = q['correctAnswer'];
        final key = '$lIndex-$qIndex'; // key an toàn
        final selected = selectedAnswers[key];
        if (selected == correct) totalCorrect++;
      }
    }

    final score = (totalQuestions == 0)
        ? "0"
        : (totalCorrect / totalQuestions * 100).toStringAsFixed(1);

    if (double.tryParse(score)! >= 50) _confettiController.play();

    // 📝 Ghi log kết quả
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? user?.email ?? "Unknown";

    await _firestore.collection('logs').add({
      'username': name,
      'activity':
          "Hoàn thành bài đọc: ${widget.topicId} với điểm $totalCorrect/$totalQuestions (${score}%)",
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Hiển thị kết quả
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("📖 Kết quả"),
        content: Text(
          "Bạn đúng $totalCorrect/$totalQuestions câu\nĐiểm: $score%",
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Đóng dialog
              Navigator.pop(context); // Quay lại ReadingScreen
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
    // 🟢 Ghi kết quả vào bảng userprogress
    if (user != null) {
      try {
        await _firestore.collection('user_progress').add({
          'userId': user.uid,
          'username': name,
          'topicId': widget.topicId,
          'correct': totalCorrect,
          'total': totalQuestions,
          'score': score,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // ✅ Xác nhận lưu thành công (hiển thị console)
        print("✅ Đã lưu userprogress cho ${user.uid}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lưu tiến độ thành công ✅")),
        );
      } catch (e) {
        print("❌ Lỗi khi lưu userprogress: $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi khi lưu tiến độ: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topicRef = _firestore
        .collection('skills')
        .doc('reading')
        .collection('topics')
        .doc(widget.topicId);

    final topicData = widget.topicData;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text("Reading Detail")),
          body: StreamBuilder<QuerySnapshot>(
            stream: topicRef.collection('lessons').snapshots(),
            builder: (context, lessonSnap) {
              if (!lessonSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final lessons = lessonSnap.data!.docs;
              if (lessons.isEmpty) {
                return const Center(child: Text("Chưa có bài đọc nào."));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              topicData['image'] ?? '',
                              height: 160,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            topicData['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            topicData['description'] ?? '',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...lessons.asMap().entries.map((lessonEntry) {
                      final lIndex = lessonEntry.key;
                      final lesson =
                          lessonEntry.value.data() as Map<String, dynamic>;
                      final questions = List<Map<String, dynamic>>.from(
                        lesson['questions'] ?? [],
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(thickness: 2),
                          Text(
                            "Bài đọc ${lIndex + 1}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            lesson['passage'] ?? '',
                            style: const TextStyle(fontSize: 16, height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          ...questions.asMap().entries.map((qEntry) {
                            final qIndex = qEntry.key;
                            final q = qEntry.value;
                            final key = '$lIndex-$qIndex';
                            final options = List<String>.from(
                              q['options'] ?? [],
                            );

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      q['question'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ...options.map(
                                      (opt) => RadioListTile<String>(
                                        title: Text(opt),
                                        value: opt,
                                        groupValue: selectedAnswers[key],
                                        onChanged: (val) {
                                          setState(() {
                                            selectedAnswers[key] = val!;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => _submitAnswers(lessons),
                        child: const Text("Nộp bài"),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // 🎆 Hiệu ứng pháo hoa
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
            gravity: 0.3,
          ),
        ),
      ],
    );
  }
}
