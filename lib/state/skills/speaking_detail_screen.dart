import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SpeakingDetailScreen extends StatefulWidget {
  final String topicId;

  const SpeakingDetailScreen({super.key, required this.topicId});

  @override
  State<SpeakingDetailScreen> createState() => _SpeakingDetailScreenState();
}

class _SpeakingDetailScreenState extends State<SpeakingDetailScreen> {
  final Record _recorder = Record();
  bool _isRecording = false;
  String? _recordPath;
  bool _isSubmitting = false;
  Map<String, dynamic>? _result;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Future<void> _startRecording() async {
    if (_isSubmitting) return;

    bool hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Ứng dụng chưa có quyền ghi âm!")),
      );
      return;
    }

    if (await _recorder.isRecording()) return;

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

  // 🔥 Hàm submitRecording mới: gửi audio + topicId + question
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

      // gửi audio
      request.files.add(
        await http.MultipartFile.fromPath('audio', _recordPath!),
      );

      // gửi topicId
      request.fields['topicId'] = widget.topicId;

      // lấy câu hỏi đầu tiên trong Firestore và gửi
      final topicRef = FirebaseFirestore.instance
          .collection('skills')
          .doc('speaking')
          .collection('topics')
          .doc(widget.topicId);

      final promptsSnapshot = await topicRef
          .collection('prompts')
          .limit(1)
          .get();
      if (promptsSnapshot.docs.isNotEmpty) {
        final firstPrompt =
            promptsSnapshot.docs.first.data() as Map<String, dynamic>;
        request.fields['question'] = firstPrompt['question'] ?? '';
      }

      // gửi request
      final response = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonData = json.decode(respStr);
        setState(() => _result = jsonData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Đã chấm điểm thành công!")),
        );
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            await FirebaseFirestore.instance.collection('user_progress').add({
              'userId': user.uid,
              'username': user.displayName ?? user.email ?? 'Unknown',
              'topicId': widget.topicId,
              'skill': 'speaking',
              'transcript': jsonData['transcript'] ?? '',
              'evaluation': jsonData['evaluation'] ?? '',
              'timestamp': FieldValue.serverTimestamp(),
            });

            // ✅ Xác nhận lưu thành công (hiện trong console + thông báo)
            print("✅ Đã lưu user_progress cho ${user.uid}");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Lưu tiến độ nói thành công ✅")),
            );
          } catch (e) {
            print("❌ Lỗi khi lưu user_progress: $e");
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Lỗi khi lưu tiến độ: $e")));
          }
        }
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

  Future<void> _playRecording() async {
    if (_recordPath == null) return;

    if (_isPlaying) {
      await _audioPlayer.stop();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.play(DeviceFileSource(_recordPath!));
      setState(() => _isPlaying = true);

      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() => _isPlaying = false);
      });
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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  StreamBuilder<QuerySnapshot>(
                    stream: topicRef.collection('prompts').snapshots(),
                    builder: (context, promptSnap) {
                      if (!promptSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final prompts = promptSnap.data!.docs;

                      if (prompts.isEmpty) {
                        return const Text("Chưa có câu hỏi nào.");
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: prompts.length,
                        itemBuilder: (context, index) {
                          final prompt =
                              prompts[index].data() as Map<String, dynamic>;
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
                        },
                      );
                    },
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
                          onPressed: _isSubmitting
                              ? null
                              : (_isRecording
                                    ? _stopRecording
                                    : _startRecording),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: Icon(
                            _isPlaying ? Icons.stop : Icons.play_arrow,
                          ),
                          label: Text(_isPlaying ? "Dừng nghe" : "Nghe lại"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 14,
                            ),
                          ),
                          onPressed: (_recordPath == null || _isSubmitting)
                              ? null
                              : _playRecording,
                        ),

                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.send),
                          label: _isSubmitting
                              ? const Text("Đang gửi...")
                              : const Text("Nộp bài nói"),
                          onPressed: (_isSubmitting || _recordPath == null)
                              ? null
                              : _submitRecording,
                        ),
                      ],
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
                    Text("🗣 Transcript: ${_result!['transcript'] ?? ''}"),
                    const SizedBox(height: 6),
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
