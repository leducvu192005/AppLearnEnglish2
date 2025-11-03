import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';

class VocabularyPage extends StatefulWidget {
  const VocabularyPage({super.key});

  @override
  State<VocabularyPage> createState() => _VocabularyPageState();
}

class _VocabularyPageState extends State<VocabularyPage> {
  List<String> recentWords = [];
  final userId =
      "demoUser"; // 🔹 thay bằng FirebaseAuth.instance.currentUser!.uid khi có auth

  @override
  void initState() {
    super.initState();
    _loadRecentWords();
  }

  void _loadRecentWords() {
    setState(() {
      recentWords = ["apple", "journey", "computer"];
    });
  }

  // 🔍 Hàm tìm kiếm từ vựng
  Future<void> _searchWord(String query) async {
    if (query.trim().isEmpty) return;

    final defaultTopicsRef = FirebaseFirestore.instance.collection(
      'Vocabulary_topics',
    );
    final userTopicsRef = FirebaseFirestore.instance
        .collection('user_vocabularies')
        .doc(userId)
        .collection('topics');

    final defaultSnapshot = await defaultTopicsRef.get();
    final userSnapshot = await userTopicsRef.get();

    String? foundMeaning;

    String? searchInTopics(List<QueryDocumentSnapshot> docs) {
      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        final words = data['words'];
        if (words == null) continue;

        if (words is Map) {
          for (var w in words.values) {
            if (w is Map) {
              final en = (w['en'] ?? '').toString().toLowerCase();
              final vi = (w['vi'] ?? '').toString();
              if (en == query.toLowerCase()) return vi;
            }
          }
        }
      }
      return null;
    }

    foundMeaning =
        searchInTopics(defaultSnapshot.docs) ??
        searchInTopics(userSnapshot.docs);

    if (!mounted) return;
    setState(() {
      if (!recentWords.contains(query)) recentWords.insert(0, query);
    });

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Kết quả cho '$query'"),
        content: Text(
          foundMeaning != null
              ? "Nghĩa: $foundMeaning"
              : "Không tìm thấy từ này trong cơ sở dữ liệu.",
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

  Future<void> _createNewTopic() async {
    final TextEditingController nameController = TextEditingController();
    final CollectionReference userTopicsRef = FirebaseFirestore.instance
        .collection('user_vocabularies')
        .doc(userId)
        .collection('topics');

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tạo bộ từ mới"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: "Tên topic (e.g. Travel)",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                await userTopicsRef.add({
                  'name': name,
                  'progress': 0.0,
                  'words': {},
                });
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Tạo"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CollectionReference defaultTopicsRef = FirebaseFirestore.instance
        .collection('Vocabulary_topics');
    final CollectionReference userTopicsRef = FirebaseFirestore.instance
        .collection('user_vocabularies')
        .doc(userId)
        .collection('topics');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vocabulary"),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _createNewTopic),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Search vocabulary...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: _searchWord,
            ),
            const SizedBox(height: 24),
            if (recentWords.isNotEmpty) ...[
              const Text(
                "Recent Searches",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: recentWords
                    .map(
                      (word) => Chip(
                        label: Text(word),
                        backgroundColor: Colors.blue.shade100,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
            const Text(
              "Your Vocabulary Sets",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: userTopicsRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final topics = snapshot.data!.docs;
                if (topics.isEmpty) return const Text("No custom sets yet.");
                return Column(
                  children: topics.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unnamed';
                    final progress = (data['progress'] ?? 0.0) * 100;
                    return Card(
                      child: ListTile(
                        title: Text(name),
                        subtitle: LinearProgressIndicator(
                          value: data['progress'] ?? 0.0,
                          minHeight: 6,
                          backgroundColor: Colors.grey[300],
                          color: Colors.blue,
                        ),
                        trailing: Text("${progress.toStringAsFixed(0)}%"),
                        onTap: () {
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TopicDetailPage(topicDoc: doc),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              "Vocabulary Topics ",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: defaultTopicsRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final topics = snapshot.data!.docs;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topics.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemBuilder: (context, index) {
                    final doc = topics[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? doc.id;
                    return GestureDetector(
                      onTap: () {
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TopicDetailPage(topicDoc: doc),
                          ),
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        child: Center(
                          child: Text(
                            name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// 🔹 Trang chi tiết topic (ảnh + âm thanh, an toàn context)
// =====================================================
class TopicDetailPage extends StatefulWidget {
  final QueryDocumentSnapshot topicDoc;
  const TopicDetailPage({super.key, required this.topicDoc});

  @override
  State<TopicDetailPage> createState() => _TopicDetailPageState();
}

class _TopicDetailPageState extends State<TopicDetailPage> {
  late Map<String, dynamic> wordsMap;
  late String topicName;

  @override
  void initState() {
    super.initState();
    final data = widget.topicDoc.data() as Map<String, dynamic>;
    topicName = data['name'] ?? widget.topicDoc.id;
    final rawWords = data['words'];
    if (rawWords is List) {
      wordsMap = {
        for (int i = 0; i < rawWords.length; i++)
          'w${i + 1}': rawWords[i] as Map<String, dynamic>,
      };
    } else if (rawWords is Map) {
      wordsMap = Map<String, dynamic>.from(rawWords);
    } else {
      wordsMap = {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = wordsMap.values.toList();

    return Scaffold(
      appBar: AppBar(title: Text(topicName)),
      body: words.isEmpty
          ? const Center(child: Text("No words found in this topic"))
          : ListView.builder(
              itemCount: words.length,
              itemBuilder: (context, index) {
                final word = words[index] as Map<String, dynamic>;
                final imageUrl = word['image'] ?? word['imageUrl'] ?? '';
                final audioUrl = word['audio'] ?? word['audioUrl'] ?? '';

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
                    title: Text(word['en'] ?? ''),
                    subtitle: Text(word['vi'] ?? ''),
                    trailing: audioUrl.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.volume_up),
                            onPressed: () async {
                              try {
                                final player = AudioPlayer();
                                await player.play(UrlSource(audioUrl));
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Không thể phát âm thanh: $e",
                                    ),
                                  ),
                                );
                              }
                            },
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
