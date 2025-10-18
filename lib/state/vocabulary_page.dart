import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class VocabularyPage extends StatefulWidget {
  const VocabularyPage({super.key});

  @override
  State<VocabularyPage> createState() => _VocabularyPageState();
}

class _VocabularyPageState extends State<VocabularyPage> {
  List<String> recentWords = [];
  final userId =
      "demoUser"; // 🔹 sau này thay bằng FirebaseAuth.instance.currentUser!.uid

  @override
  void initState() {
    super.initState();
    _loadRecentWords();
  }

  Future<void> _loadRecentWords() async {
    setState(() {
      recentWords = ["apple", "journey", "computer"];
    });
  }

  Future<void> _createNewTopic() async {
    final TextEditingController nameController = TextEditingController();
    final CollectionReference userTopicsRef = FirebaseFirestore.instance
        .collection('user_vocabularies')
        .doc(userId)
        .collection('topics');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create New Vocabulary Set"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: "Enter topic name (e.g. Travel)",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                await userTopicsRef.add({
                  'name': name,
                  'progress': 0.0,
                  'words': {}, // ✅ lưu map rỗng thay vì list
                });
              }
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
            },
            child: const Text("Create"),
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
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Create your own vocabulary set",
            onPressed: _createNewTopic,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // 🔍 Search bar
            TextField(
              decoration: InputDecoration(
                hintText: "Search vocabulary...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) async {
                if (value.isEmpty) return;

                // 🔹 Lưu lịch sử tìm kiếm
                setState(() {
                  if (!recentWords.contains(value)) {
                    recentWords.insert(0, value);
                  }
                });

                // 🔹 Lấy dữ liệu từ Firestore
                final defaultSnapshot = await defaultTopicsRef.get();
                final userSnapshot = await userTopicsRef.get();

                String? foundMeaning;

                // Hàm tìm kiếm
                String? searchInTopics(List<QueryDocumentSnapshot> docs) {
                  for (var doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final words = data['words'];
                    if (words == null) continue;

                    if (words is Map) {
                      for (var w in words.values) {
                        if (w is Map) {
                          // Kiểu {'en': 'apple', 'vi': 'quả táo'}
                          if ((w['en']?.toString().toLowerCase() ?? '') ==
                              value.toLowerCase()) {
                            return w['vi']?.toString();
                          }
                        } else if (w is Map<String, dynamic> == false) {
                          // Kiểu {'Dog': 'Con chó'}
                          final wordMap = w as Map;
                          for (var entry in wordMap.entries) {
                            if (entry.key.toString().toLowerCase() ==
                                value.toLowerCase()) {
                              return entry.value.toString();
                            }
                          }
                        }
                      }
                    }
                  }
                  return null;
                }

                foundMeaning =
                    searchInTopics(defaultSnapshot.docs) ??
                    searchInTopics(userSnapshot.docs);

                // 🔹 Hiển thị kết quả
                if (foundMeaning != null) {
                  // ignore: use_build_context_synchronously
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text("Nghĩa của '$value'"),
                      content: Text(foundMeaning!),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                } else {
                  // ignore: use_build_context_synchronously
                  showDialog(
                    context: context,
                    builder: (_) => const AlertDialog(
                      title: Text("Không tìm thấy"),
                      content: Text("Từ này chưa có trong bộ từ vựng."),
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 24),

            // 🕓 Recent Searches
            if (recentWords.isNotEmpty) ...[
              const Text(
                "Recent Searches",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentWords.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    return Chip(
                      label: Text(recentWords[index]),
                      backgroundColor: Colors.blue.shade100,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 🧠 Custom user topics
            const Text(
              "Your Vocabulary Sets",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: userTopicsRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final userTopics = snapshot.data!.docs;

                if (userTopics.isEmpty) {
                  return const Text("You haven't created any custom sets yet.");
                }

                return Column(
                  children: userTopics.map((topic) {
                    final data = topic.data() as Map<String, dynamic>;
                    final name = data['name'] ?? "Unnamed";
                    final progress = (data['progress'] ?? 0.0) * 100;

                    return Card(
                      child: ListTile(
                        title: Text(name),
                        subtitle: LinearProgressIndicator(
                          value: (data['progress'] ?? 0.0),
                          minHeight: 6,
                          backgroundColor: Colors.grey[300],
                          color: Colors.blue,
                        ),
                        trailing: Text("${progress.toStringAsFixed(0)}%"),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TopicDetailPage(topic: topic),
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

            // 📚 Default topics
            const Text(
              "Vocabulary Topics (Default)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: defaultTopicsRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("No topics found");
                }

                final topics = snapshot.data!.docs;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topics.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final topic = topics[index];
                    final topicData =
                        topic.data() as Map<String, dynamic>? ?? {};
                    final topicName = topicData['name'] ?? topic.id;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TopicDetailPage(topic: topic),
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
                            topicName,
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

// ===============================
// 🔹 Trang chi tiết Topic
// ===============================
class TopicDetailPage extends StatefulWidget {
  final QueryDocumentSnapshot topic;
  const TopicDetailPage({super.key, required this.topic});

  @override
  State<TopicDetailPage> createState() => _TopicDetailPageState();
}

class _TopicDetailPageState extends State<TopicDetailPage> {
  late Map<String, dynamic> wordsMap;
  late String topicId;
  late String topicName;
  late DocumentReference topicRef;

  @override
  void initState() {
    super.initState();
    final topicData = widget.topic.data() as Map<String, dynamic>;
    topicName = topicData['name'] ?? widget.topic.id;
    topicId = widget.topic.id;
    topicRef = widget.topic.reference;
    wordsMap = Map<String, dynamic>.from(topicData['words'] ?? {});
  }

  Future<void> _addNewWord() async {
    final TextEditingController enController = TextEditingController();
    final TextEditingController viController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Word"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: enController,
              decoration: const InputDecoration(labelText: "English"),
            ),
            TextField(
              controller: viController,
              decoration: const InputDecoration(labelText: "Vietnamese"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final en = enController.text.trim();
              final vi = viController.text.trim();
              if (en.isNotEmpty && vi.isNotEmpty) {
                final newKey = DateTime.now().millisecondsSinceEpoch.toString();
                wordsMap[newKey] = {'en': en, 'vi': vi};
                await topicRef.update({'words': wordsMap});
              }
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final words = wordsMap.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(topicName),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addNewWord),
        ],
      ),
      body: words.isEmpty
          ? const Center(child: Text("No words found in this topic"))
          : ListView.builder(
              itemCount: words.length,
              itemBuilder: (context, index) {
                final word = jsonDecode(words[index]) as Map<String, dynamic>;

                return ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(word['en'] ?? "Unknown"),
                  subtitle: Text(word['vi'] ?? ""),
                );
              },
            ),
    );
  }
}
