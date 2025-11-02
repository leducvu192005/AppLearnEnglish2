import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

class SpeakingDetailScreen extends StatefulWidget {
  final String topicId;

  const SpeakingDetailScreen({super.key, required this.topicId});

  @override
  State<SpeakingDetailScreen> createState() => _SpeakingDetailScreenState();
}

class _SpeakingDetailScreenState extends State<SpeakingDetailScreen> {
  final Record _recorder = Record(); // ✅ đúng kiểu cho version 4.4.4
  bool _isRecording = false;
  String? _recordPath;
  bool _isSubmitting = false;
  Map<String, dynamic>? _result;

  // 🎙️ Bắt đầu ghi âm
  Future<void> _startRecording() async {
    bool hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Ứng dụng chưa có quyền ghi âm!")),
      );
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/record_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      path: path,
      encoder: AudioEncoder.aacLc,
      bitRate: 128000,
      samplingRate: 44100,
    );

    setState(() {
      _isRecording = true;
      _recordPath = path;
    });
  }

  // ⏹ Dừng ghi âm
  Future<void> _stopRecording() async {
    final path = await _recorder.stop();

    setState(() {
      _isRecording = false;
      _recordPath = path;
    });

    if (_recordPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🎙️ Ghi âm đã lưu: $_recordPath")),
      );
    }
  }

  // 📤 Gửi file tới backend để AI chấm điểm
  Future<void> _submitRecording() async {
    if (_recordPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Bạn chưa ghi âm bài nói!")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uri = Uri.parse("http://10.0.2.2:8000/evaluate-speaking/");

      final request = http.MultipartRequest("POST", uri);
      request.files.add(
        await http.MultipartFile.fromPath('audio', _recordPath!),
      );

      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonData = json.decode(respStr);
        setState(() {
          _result = jsonData;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Đã chấm điểm thành công!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Lỗi: ${response.statusCode}\n$respStr")),
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
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topicRef = FirebaseFirestore.instance
        .collection('skills')
        .doc('speaking')
        .collection('topics')
        .doc(widget.topicId);

    return Scaffold(
      appBar: AppBar(title: const Text("Speaking Detail")),
      body: FutureBuilder<DocumentSnapshot>(
        future: topicRef.get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return const Center(child: Text("Không tìm thấy chủ đề."));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🖼 Ảnh chủ đề
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      data['image'] ?? '',
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

                // 🗣 Danh sách câu hỏi
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: topicRef.collection('prompts').snapshots(),
                    builder: (context, promptSnap) {
                      if (!promptSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final prompts = promptSnap.data!.docs;

                      if (prompts.isEmpty) {
                        return const Text("Chưa có câu hỏi nào.");
                      }

                      return ListView(
                        children: prompts.map((promptDoc) {
                          final prompt =
                              promptDoc.data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text(prompt['question'] ?? ''),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:
                                    (prompt['tips'] as List?)
                                        ?.map<Widget>((tip) => Text("• $tip"))
                                        .toList() ??
                                    [],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),
                Center(
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                        label: Text(
                          _isRecording ? "Dừng ghi âm" : "Bắt đầu nói",
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRecording
                              ? Colors.red
                              : Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 14,
                          ),
                        ),
                        onPressed: _isRecording
                            ? _stopRecording
                            : _startRecording,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.send),
                        label: _isSubmitting
                            ? const Text("Đang gửi...")
                            : const Text("Nộp bài nói"),
                        onPressed: _isSubmitting ? null : _submitRecording,
                      ),
                    ],
                  ),
                ),

                // 🎯 Hiển thị kết quả đánh giá
                if (_result != null) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const Text(
                    "🎯 Kết quả đánh giá:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text("🗣 Transcript: ${_result!['transcript'] ?? ''}"),
                  const SizedBox(height: 6),
                  Text("${_result!['evaluation'] ?? ''}"),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
