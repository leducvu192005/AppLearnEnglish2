import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// import 4 file kỹ năng
import 'skills/listening_screen.dart';
import 'skills/speaking_screen.dart';
import 'skills/reading_screen.dart';
import 'skills/writing_screen.dart';

class QuizProvider extends StatefulWidget {
  const QuizProvider({super.key});

  @override
  State<QuizProvider> createState() => _QuizProviderState();
}

class _QuizProviderState extends State<QuizProvider> {
  final userId = FirebaseAuth.instance.currentUser?.uid ?? "demoUser";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('quizzes').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final quizzes = snapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                "Flashcard",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // -----------------------------
              // 🔹 Danh sách Quiz cũ
              // -----------------------------
              ...quizzes.map((quiz) {
                final data = quiz.data() as Map<String, dynamic>;
                final quizId = quiz.id;

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('progress')
                      .doc(quizId)
                      .snapshots(),
                  builder: (context, progressSnap) {
                    double percent = 0;
                    int completed = 0;
                    int total = data['totalQuestions'] ?? 10;

                    if (progressSnap.hasData && progressSnap.data!.exists) {
                      final p =
                          progressSnap.data!.data() as Map<String, dynamic>;
                      percent = p['percent'] ?? 0;
                      completed = p['completed'] ?? 0;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          data['title'] ?? 'Quiz Set',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['description'] ?? ''),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: percent,
                              backgroundColor: Colors.grey.shade300,
                              color: Colors.blue,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$completed / $total completed",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuizDetailPage(
                                quizId: quizId,
                                title: data['title'] ?? 'Quiz',
                                totalQuestions: total,
                                userId: userId,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              }),

              const SizedBox(height: 24),
              const Divider(thickness: 1.5),
              const SizedBox(height: 16),

              // -----------------------------
              // 🔹 Thêm 4 kỹ năng dưới dạng lưới
              // -----------------------------
              const Text(
                "Practice by Skills",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _buildSkillCard(
                    context,
                    title: "Listening",
                    icon: Icons.headphones,
                    color: Colors.blue.shade100,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ListeningScreen(),
                      ),
                    ),
                  ),
                  _buildSkillCard(
                    context,
                    title: "Speaking",
                    icon: Icons.mic,
                    color: Colors.green.shade100,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SpeakingScreen()),
                    ),
                  ),
                  _buildSkillCard(
                    context,
                    title: "Reading",
                    icon: Icons.menu_book,
                    color: Colors.orange.shade100,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReadingScreen()),
                    ),
                  ),
                  _buildSkillCard(
                    context,
                    title: "Writing",
                    icon: Icons.edit,
                    color: Colors.purple.shade100,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WritingScreen()),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSkillCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.black87),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuizDetailPage extends StatefulWidget {
  final String quizId;
  final String title;
  final int totalQuestions;
  final String userId;

  const QuizDetailPage({
    super.key,
    required this.quizId,
    required this.title,
    required this.totalQuestions,
    required this.userId,
  });

  @override
  State<QuizDetailPage> createState() => _QuizDetailPageState();
}

class _QuizDetailPageState extends State<QuizDetailPage> {
  int currentIndex = 0;
  int correctCount = 0;
  bool answered = false;
  String? selectedAnswer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('quizzes')
            .doc(widget.quizId)
            .collection('questions')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final questions = snapshot.data!.docs;
          if (questions.isEmpty) {
            return const Center(child: Text("No questions available"));
          }

          final question = questions[currentIndex];
          final qData = question.data() as Map<String, dynamic>;
          final options = (qData['options'] as List<dynamic>).cast<String>();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Question ${currentIndex + 1}/${questions.length}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  qData['question'] ?? '',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                ...options.map(
                  (opt) => Card(
                    color: selectedAnswer == opt
                        ? (opt == qData['correctAnswer']
                              ? Colors.green.shade100
                              : Colors.red.shade100)
                        : null,
                    child: ListTile(
                      title: Text(opt),
                      onTap: answered
                          ? null
                          : () {
                              _checkAnswer(
                                opt,
                                qData['correctAnswer'],
                                questions.length,
                              );
                            },
                    ),
                  ),
                ),
                const Spacer(),
                if (answered && currentIndex + 1 < questions.length)
                  ElevatedButton(
                    onPressed: _nextQuestion,
                    child: const Text("Next Question"),
                  ),
                if (answered && currentIndex + 1 == questions.length)
                  ElevatedButton(
                    onPressed: _finishQuiz,
                    child: const Text("Finish Quiz"),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _checkAnswer(String selected, String correct, int total) {
    setState(() {
      selectedAnswer = selected;
      answered = true;
      if (selected == correct) correctCount++;
    });
  }

  void _nextQuestion() {
    setState(() {
      currentIndex++;
      answered = false;
      selectedAnswer = null;
    });
  }

  Future<void> _finishQuiz() async {
    final total = widget.totalQuestions;
    final percent = correctCount / total;

    // ✅ 1. Lưu tiến độ riêng cho từng user
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('progress')
        .doc(widget.quizId)
        .set({
          'completed': correctCount,
          'total': total,
          'percent': percent,
          'completedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    // ✅ 2. Lưu vào user_progress cho admin xem
    await FirebaseFirestore.instance.collection('user_progress').add({
      'userId': widget.userId,
      'quizId': widget.quizId,
      'score': correctCount,
      'total': total,
      'percent': percent,
      'completedAt': FieldValue.serverTimestamp(),
    });
    // ghi lại log hoàn thành quiz
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? user?.email ?? "Unknown";
    await FirebaseFirestore.instance.collection('logs').add({
      'username': name,
      'activity':
          "Hoàn thành quiz: ${widget.title} với điểm $correctCount / $total câu đúng (${(percent * 100).toStringAsFixed(1)}%)",
      'timestamp': FieldValue.serverTimestamp(),
    });
    // ✅ 3. Thông báo kết quả
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("🎉 Hoàn thành quiz!"),
          content: Text("Bạn trả lời đúng $correctCount / $total câu."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/quiz'),
              child: const Text("Về danh sách Quiz"),
            ),
          ],
        ),
      );
    }
  }
}
