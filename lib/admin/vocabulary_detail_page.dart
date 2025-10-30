import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  Future<Map<String, dynamic>> _fetchWords() async {
    final doc = await _firestore
        .collection('Vocabulary_topics')
        .doc(widget.topicId)
        .get();
    final data = doc.data() ?? {};
    // ✅ Đọc từ trường 'words'
    final words = Map<String, dynamic>.from(data['words'] ?? {});
    return words;
  }

  void _showAddOrEditWord({String? wordId, Map<String, dynamic>? wordData}) {
    final enController = TextEditingController(text: wordData?['en'] ?? '');
    final viController = TextEditingController(text: wordData?['vi'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(wordId == null ? 'Thêm từ mới' : 'Chỉnh sửa từ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: enController,
              decoration: const InputDecoration(labelText: 'Từ tiếng Anh'),
            ),
            TextField(
              controller: viController,
              decoration: const InputDecoration(labelText: 'Nghĩa tiếng Việt'),
            ),
          ],
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
              };

              await docRef.update({'words': words});
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
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final words = snapshot.data!;
          if (words.isEmpty)
            return const Center(
              child: Text('Chưa có từ nào trong chủ đề này.'),
            );

          final entries = words.entries.toList();

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final wordId = entries[index].key;
              final wordData = Map<String, dynamic>.from(entries[index].value);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  title: Text(wordData['en'] ?? ''),
                  subtitle: Text(wordData['vi'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
