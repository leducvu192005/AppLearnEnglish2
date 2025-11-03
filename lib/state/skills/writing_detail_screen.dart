import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class WritingDetailScreen extends StatefulWidget {
  final String topicId;

  const WritingDetailScreen({super.key, required this.topicId});

  @override
  State<WritingDetailScreen> createState() => _WritingDetailScreenState();
}

class _WritingDetailScreenState extends State<WritingDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;
  Map<String, dynamic>? _result;

  Future<void> _submitWriting() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("⚠️ Bạn chưa viết gì!")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Lấy câu hỏi đầu tiên
      final topicRef = FirebaseFirestore.instance
          .collection('skills')
          .doc('writing')
          .collection('topics')
          .doc(widget.topicId);

      final promptsSnapshot = await topicRef
          .collection('prompts')
          .limit(1)
          .get();
      String question = '';
      if (promptsSnapshot.docs.isNotEmpty) {
        final firstPrompt =
            promptsSnapshot.docs.first.data() as Map<String, dynamic>;
        question = firstPrompt['question'] ?? '';
      }

      // gửi request lên server AI
      final uri = Uri.parse("http://10.0.2.2:8000/evaluate-writing/");
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'topicId': widget.topicId,
              'question': question,
              'text': text,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() => _result = jsonData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Đã chấm điểm thành công!")),
        );
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            final docRef = await FirebaseFirestore.instance
                .collection('user_progress')
                .add({
                  'userId': user.uid,
                  'username': user.displayName ?? user.email ?? 'Unknown',
                  'topicId': widget.topicId,
                  'skill': 'writing',
                  'text': text,
                  'evaluation': jsonData['evaluation'] ?? '',
                  'timestamp': FieldValue.serverTimestamp(),
                });

            // ✅ Xác nhận lưu thành công
            print("✅ Đã lưu user_progress (writing) với ID: ${docRef.id}");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Lưu tiến độ viết thành công ✅")),
            );
          } catch (e) {
            print("❌ Lỗi khi lưu user_progress (writing): $e");
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Lỗi khi lưu tiến độ: $e")));
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "❌ Lỗi server: ${response.statusCode}\n${response.body}",
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("⚠️ Lỗi kết nối server: $e")));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topicRef = FirebaseFirestore.instance
        .collection('skills')
        .doc('writing')
        .collection('topics')
        .doc(widget.topicId);

    return Scaffold(
      appBar: AppBar(title: const Text("Writing Detail")),
      body: FutureBuilder<DocumentSnapshot>(
        future: topicRef.get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return const Center(child: Text("Không tìm thấy chủ đề."));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data['image'] != null)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          data['image'],
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    data['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data['description'] ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const Text(
                    "Các câu hỏi gợi ý:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: topicRef.collection('prompts').snapshots(),
                    builder: (context, promptSnap) {
                      if (!promptSnap.hasData)
                        return const Center(child: CircularProgressIndicator());
                      final prompts = promptSnap.data!.docs;

                      if (prompts.isEmpty)
                        return const Text("Chưa có câu hỏi nào.");

                      return Column(
                        children: prompts.map((promptDoc) {
                          final prompt =
                              promptDoc.data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(prompt['question'] ?? ''),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:
                                  (prompt['tips'] as List?)
                                      ?.map((tip) => Text("• $tip"))
                                      .toList() ??
                                  [],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: "Viết bài của bạn ở đây...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: _isSubmitting
                          ? const Text("Đang gửi...")
                          : const Text("Nộp bài viết"),
                      onPressed: (_isSubmitting) ? null : _submitWriting,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  if (_result != null) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const Text(
                      "🎯 Kết quả đánh giá:",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("${_result!['evaluation'] ?? ''}"),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
