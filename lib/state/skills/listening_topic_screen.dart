import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';

class ListeningTopicScreen extends StatefulWidget {
  final String topicId;
  const ListeningTopicScreen({super.key, required this.topicId});

  @override
  State<ListeningTopicScreen> createState() => _ListeningTopicScreenState();
}

class _ListeningTopicScreenState extends State<ListeningTopicScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _player = AudioPlayer();

  // selectedAnswers[audioId][questionIndex] = selectedAnswer
  Map<String, Map<int, String>> selectedAnswers = {};

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _submitAnswers(List<QueryDocumentSnapshot> audios) {
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

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Kết quả"),
        content: Text(
          "Bạn đúng $totalCorrect/$totalQuestions câu\nĐiểm: $score%",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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

    return Scaffold(
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
                    // Hiển thị thông tin topic
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

                    // 🔥 Lặp qua từng audio
                    ...audios.asMap().entries.map((entry) {
                      final index = entry.key;
                      final audioDoc = entry.value;
                      final audioData = audioDoc.data() as Map<String, dynamic>;
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

                          // Nút phát & dừng audio
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

                          // 🔹 Danh sách câu hỏi cho từng audio
                          ...questions.asMap().entries.map((qEntry) {
                            final qIndex = qEntry.key;
                            final q = qEntry.value;
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
                                      "Câu ${qIndex + 1}: ${q['question']}",
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

                    // Nút nộp bài chung
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
    );
  }
}
