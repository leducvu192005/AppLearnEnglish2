import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class VocabularyDetailPage extends StatefulWidget {
  final String topicId;
  final String topicName;

  const VocabularyDetailPage({
    super.key,
    required this.topicId,
    required this.topicName,
  });

  @override
  State<VocabularyDetailPage> createState() => _VocabularyDetailPageState();
}

class _VocabularyDetailPageState extends State<VocabularyDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AudioPlayer _player = AudioPlayer();

  Future<Map<String, dynamic>> _fetchWords() async {
    final doc = await _firestore
        .collection('Vocabulary_topics')
        .doc(widget.topicId)
        .get();
    final data = doc.data() ?? {};
    final words = Map<String, dynamic>.from(data['words'] ?? {});
    return words;
  }

  void _showAddOrEditWord({String? wordId, Map<String, dynamic>? wordData}) {
    final enController = TextEditingController(text: wordData?['en'] ?? '');
    final viController = TextEditingController(text: wordData?['vi'] ?? '');
    final imageController = TextEditingController(
      text: wordData?['image'] ?? '',
    );
    final audioController = TextEditingController(
      text: wordData?['audio'] ?? '',
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(wordId == null ? 'Thêm từ mới' : 'Chỉnh sửa từ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: enController,
                decoration: const InputDecoration(labelText: 'Từ tiếng Anh'),
              ),
              TextField(
                controller: viController,
                decoration: const InputDecoration(
                  labelText: 'Nghĩa tiếng Việt',
                ),
              ),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(labelText: 'Link ảnh (URL)'),
              ),
              TextField(
                controller: audioController,
                decoration: const InputDecoration(
                  labelText: 'Link phát âm (URL)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final docRef = _firestore
                  .collection('Vocabulary_topics')
                  .doc(widget.topicId);
              final doc = await docRef.get();
              final data = doc.data() ?? {};
              final words = Map<String, dynamic>.from(data['words'] ?? {});

              final newWordId =
                  wordId ?? 'w${DateTime.now().millisecondsSinceEpoch}';
              words[newWordId] = {
                'en': enController.text.trim(),
                'vi': viController.text.trim(),
                'image': imageController.text.trim(),
                'audio': audioController.text.trim(),
              };

              await docRef.update({'words': words});
              if (!mounted) return;
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _deleteWord(String wordId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa từ này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final docRef = _firestore
                  .collection('Vocabulary_topics')
                  .doc(widget.topicId);
              final doc = await docRef.get();
              final data = doc.data() ?? {};
              final words = Map<String, dynamic>.from(data['words'] ?? {});
              words.remove(wordId);

              await docRef.update({'words': words});
              if (!mounted) return;
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chủ đề: ${widget.topicName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddOrEditWord(),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchWords(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final words = snapshot.data!;
          if (words.isEmpty) {
            return const Center(
              child: Text('Chưa có từ nào trong chủ đề này.'),
            );
          }

          final entries = words.entries.toList();

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final wordId = entries[index].key;
              final wordData = Map<String, dynamic>.from(entries[index].value);

              final imageUrl = wordData['image'] ?? '';
              final audioUrl = wordData['audio'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  leading: imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image_not_supported),
                          ),
                        )
                      : const Icon(Icons.image, size: 40),
                  title: Text(wordData['en'] ?? ''),
                  subtitle: Text(wordData['vi'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (audioUrl.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.volume_up),
                          onPressed: () async {
                            try {
                              await _player.play(UrlSource(audioUrl));
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Không thể phát âm thanh: $e"),
                                ),
                              );
                            }
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showAddOrEditWord(
                          wordId: wordId,
                          wordData: wordData,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteWord(wordId),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
