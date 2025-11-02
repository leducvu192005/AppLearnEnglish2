import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart'; // 🎆 Thêm package pháo hoa

class ListeningTopicScreen extends StatefulWidget {
  final String topicId;
  const ListeningTopicScreen({super.key, required this.topicId});

  @override
  State<ListeningTopicScreen> createState() => _ListeningTopicScreenState();
}

class _ListeningTopicScreenState extends State<ListeningTopicScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _player = AudioPlayer();
  final _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  ); // 🎆

  Map<String, Map<int, String>> selectedAnswers = {};

  @override
  void dispose() {
    _player.dispose();
    _confettiController.dispose(); // 🎆 Hủy pháo hoa
    super.dispose();
  }

  Future<void> _submitAnswers(List<QueryDocumentSnapshot> audios) async {
    int totalCorrect = 0;
    int totalQuestions = 0;

    for (var audio in audios) {
      final audioData = audio.data() as Map<String, dynamic>;
      final audioId = audio.id;
      final questions = List<Map<String, dynamic>>.from(
        audioData['questions'] ?? [],
      );

      totalQuestions += questions.length;

      for (int i = 0; i < questions.length; i++) {
        final correct = questions[i]['correctAnswer'];
        final selected = selectedAnswers[audioId]?[i];
        if (selected == correct) totalCorrect++;
      }
    }

    final score = (totalCorrect / totalQuestions * 100).toStringAsFixed(1);

    // 🎆 Nếu điểm >= 50 thì bắn pháo hoa
    if (double.tryParse(score)! >= 50) {
      _confettiController.play();
    }
    //lấy tên của người dùng hiện tại
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? user?.email ?? "Unknown";
    // Ghi log kết quả
    try {
      await FirebaseFirestore.instance.collection('logs').add({
        'username': name,
        'activity':
            "Hoàn thành bài nghe: ${widget.topicId} với điểm $totalCorrect / $totalQuestions câu đúng (${score}%)",
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("Ghi log thành công");
    } catch (e) {
      print("Lỗi ghi log: $e");
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🎉 Kết quả"),
        content: Text(
          "Bạn đúng $totalCorrect/$totalQuestions câu\nĐiểm: $score%",
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // đóng dialog
              Navigator.pop(context); // quay lại trang ListeningScreen
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topicRef = _firestore
        .collection('skills')
        .doc('listening')
        .collection('topics')
        .doc(widget.topicId);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text("Listening Practice")),
          body: FutureBuilder<DocumentSnapshot>(
            future: topicRef.get(),
            builder: (context, topicSnap) {
              if (!topicSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final topicData = topicSnap.data!.data() as Map<String, dynamic>?;

              if (topicData == null) {
                return const Center(child: Text("Không tìm thấy chủ đề."));
              }

              return StreamBuilder<QuerySnapshot>(
                stream: topicRef.collection('audios').snapshots(),
                builder: (context, audioSnap) {
                  if (!audioSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final audios = audioSnap.data!.docs;
                  if (audios.isEmpty) {
                    return const Center(child: Text("Chưa có audio nào."));
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Image.network(
                                topicData['image'] ?? '',
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                topicData['name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...audios.asMap().entries.map((entry) {
                          final index = entry.key;
                          final audioDoc = entry.value;
                          final audioData =
                              audioDoc.data() as Map<String, dynamic>;
                          final questions = List<Map<String, dynamic>>.from(
                            audioData['questions'] ?? [],
                          );
                          final audioId = audioDoc.id;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(thickness: 2),
                              Text(
                                "Audio ${index + 1}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await _player.play(
                                        UrlSource(audioData['audioUrl'] ?? ''),
                                      );
                                    },
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text("Phát"),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await _player.stop();
                                    },
                                    icon: const Icon(Icons.stop),
                                    label: const Text("Dừng"),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...questions.asMap().entries.map((qEntry) {
                                final qIndex = qEntry.key;
                                final q = qEntry.value;
                                final options = List<String>.from(
                                  q['options'] ?? [],
                                );

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Câu hỏi: ${q['question']}",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        ...options.map(
                                          (opt) => RadioListTile<String>(
                                            title: Text(opt),
                                            value: opt,
                                            groupValue:
                                                selectedAnswers[audioId]?[qIndex],
                                            onChanged: (val) {
                                              setState(() {
                                                selectedAnswers[audioId] ??= {};
                                                selectedAnswers[audioId]![qIndex] =
                                                    val!;
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
                            onPressed: () => _submitAnswers(audios),
                            child: const Text("Nộp bài"),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),

        // 🎆 Hiệu ứng pháo hoa bay tung tóe
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
