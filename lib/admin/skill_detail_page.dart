import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🔹 Trang hiển thị danh sách topic theo từng kỹ năng
class SkillDetailPage extends StatefulWidget {
  final String skillId;
  const SkillDetailPage({super.key, required this.skillId});

  @override
  State<SkillDetailPage> createState() => _SkillDetailPageState();
}

class _SkillDetailPageState extends State<SkillDetailPage> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final skillRef = FirebaseFirestore.instance
        .collection('skills')
        .doc(widget.skillId)
        .collection('topics');

    return Scaffold(
      appBar: AppBar(
        title: Text('Kỹ năng: ${widget.skillId.toUpperCase()}'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // 🔍 Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Tìm chủ đề...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => searchQuery = value.toLowerCase());
              },
            ),
          ),

          // 📋 Danh sách topic
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: skillRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final topics = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  return name.contains(searchQuery);
                }).toList();

                if (topics.isEmpty) {
                  return const Center(child: Text('Không có chủ đề nào.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    final topic = topics[index];
                    final data = topic.data() as Map<String, dynamic>;

                    return Card(
                      child: ListTile(
                        title: Text(data['name'] ?? 'Không có tên'),
                        subtitle: Text(data['description'] ?? ''),
                        leading: data['image'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  data['image'],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image),
                                ),
                              )
                            : const Icon(Icons.image_outlined),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showTopicDialog(
                                edit: true,
                                id: topic.id,
                                data: data,
                              );
                            } else if (value == 'delete') {
                              _deleteTopic(topic.id);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('✏️ Sửa'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('🗑️ Xóa'),
                            ),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TopicDetailPage(
                              skillId: widget.skillId,
                              topicId: topic.id,
                              topicName: data['name'] ?? '',
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () => _showTopicDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showTopicDialog({
    bool edit = false,
    String? id,
    Map<String, dynamic>? data,
  }) {
    final nameCtrl = TextEditingController(text: data?['name'] ?? '');
    final descCtrl = TextEditingController(text: data?['description'] ?? '');
    final imageCtrl = TextEditingController(text: data?['image'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(edit ? 'Sửa chủ đề' : 'Thêm chủ đề'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên chủ đề'),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Mô tả'),
              ),
              TextField(
                controller: imageCtrl,
                decoration: const InputDecoration(labelText: 'Link ảnh'),
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
              final topicData = {
                'name': nameCtrl.text,
                'description': descCtrl.text,
                'image': imageCtrl.text,
              };

              final ref = FirebaseFirestore.instance
                  .collection('skills')
                  .doc(widget.skillId)
                  .collection('topics');

              if (edit && id != null) {
                await ref.doc(id).update(topicData);
              } else {
                await ref.add(topicData);
              }

              Navigator.pop(context);
            },
            child: Text(edit ? 'Cập nhật' : 'Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTopic(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa chủ đề này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('skills')
          .doc(widget.skillId)
          .collection('topics')
          .doc(id)
          .delete();
    }
  }
}

/// =======================================
/// 🔹 TRANG CHI TIẾT TOPIC - CRUD NỘI DUNG
/// =======================================
class TopicDetailPage extends StatefulWidget {
  final String skillId;
  final String topicId;
  final String topicName;

  const TopicDetailPage({
    super.key,
    required this.skillId,
    required this.topicId,
    required this.topicName,
  });

  @override
  State<TopicDetailPage> createState() => _TopicDetailPageState();
}

class _TopicDetailPageState extends State<TopicDetailPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final topicRef = FirebaseFirestore.instance
        .collection('skills')
        .doc(widget.skillId)
        .collection('topics')
        .doc(widget.topicId);

    final subCollection = {
      'reading': 'lessons',
      'listening': 'audios',
      'speaking': 'prompts',
      'writing': 'prompts',
    }[widget.skillId]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topicName),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Tìm kiếm nội dung...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) =>
                  setState(() => searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: topicRef.collection(subCollection).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final text =
                      (data['question'] ??
                              data['passage'] ??
                              data['transcript'] ??
                              '')
                          .toString()
                          .toLowerCase();
                  return text.contains(searchQuery);
                }).toList();

                if (items.isEmpty) {
                  return const Center(child: Text('Không có dữ liệu.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final doc = items[index];
                    final data = doc.data() as Map<String, dynamic>;

                    String title =
                        data['question'] ??
                        data['passage'] ??
                        data['transcript'] ??
                        'Không có nội dung';
                    String subtitle = '';

                    if (widget.skillId == 'reading') {
                      final questions = data['questions'] as List?;
                      if (questions != null) {
                        subtitle = questions
                            .map((q) {
                              return "• ${q['question']} (${q['correctAnswer']})";
                            })
                            .join('\n');
                      }
                    } else if (widget.skillId == 'speaking' ||
                        widget.skillId == 'writing') {
                      subtitle =
                          (data['tips'] as List?)?.join('\n• ') ??
                          'Không có gợi ý';
                    } else if (widget.skillId == 'listening') {
                      subtitle = data['transcript'] ?? '';
                    }

                    return Card(
                      child: ListTile(
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(subtitle),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              _showItemDialog(
                                edit: true,
                                id: doc.id,
                                data: data,
                                subCollection: subCollection,
                              );
                            } else if (value == 'delete') {
                              await topicRef
                                  .collection(subCollection)
                                  .doc(doc.id)
                                  .delete();
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('✏️ Sửa'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('🗑️ Xóa'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () => _showItemDialog(subCollection: subCollection),
        child: const Icon(Icons.add),
      ),
    );
  }

  // 🧩 HỘP THOẠI THÊM / SỬA NỘI DUNG
  void _showItemDialog({
    bool edit = false,
    String? id,
    Map<String, dynamic>? data,
    required String subCollection,
  }) {
    final passageCtrl = TextEditingController(text: data?['passage'] ?? '');
    final transcriptCtrl = TextEditingController(
      text: data?['transcript'] ?? '',
    );
    final questionCtrl = TextEditingController(text: data?['question'] ?? '');
    final audioUrlCtrl = TextEditingController(text: data?['audioUrl'] ?? '');
    final tipsCtrl = TextEditingController(
      text: (data?['tips'] as List?)?.join('\n') ?? '',
    );

    List<Map<String, dynamic>> questions =
        (data?['questions'] as List?)?.cast<Map<String, dynamic>>() ??
        [
          {
            'question': '',
            'options': ['', '', '', ''],
            'correctAnswer': '',
          },
        ];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(edit ? 'Sửa nội dung' : 'Thêm nội dung'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  if (widget.skillId == 'reading') ...[
                    TextField(
                      controller: passageCtrl,
                      decoration: const InputDecoration(labelText: 'Đoạn văn'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    const Text('Danh sách câu hỏi:'),
                    ...questions.asMap().entries.map((entry) {
                      final i = entry.key;
                      final q = entry.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: TextEditingController(
                              text: q['question'],
                            ),
                            onChanged: (val) => questions[i]['question'] = val,
                            decoration: InputDecoration(
                              labelText: 'Câu hỏi ${i + 1}',
                            ),
                          ),
                          for (int j = 0; j < 4; j++)
                            TextField(
                              controller: TextEditingController(
                                text: q['options'][j],
                              ),
                              onChanged: (val) =>
                                  questions[i]['options'][j] = val,
                              decoration: InputDecoration(
                                labelText: 'Đáp án ${j + 1}',
                              ),
                            ),
                          TextField(
                            controller: TextEditingController(
                              text: q['correctAnswer'],
                            ),
                            onChanged: (val) =>
                                questions[i]['correctAnswer'] = val,
                            decoration: const InputDecoration(
                              labelText: 'Đáp án đúng',
                            ),
                          ),
                          const Divider(),
                        ],
                      );
                    }),
                    TextButton.icon(
                      onPressed: () {
                        setStateDialog(() {
                          questions.add({
                            'question': '',
                            'options': ['', '', '', ''],
                            'correctAnswer': '',
                          });
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm câu hỏi'),
                    ),
                  ] else if (widget.skillId == 'listening') ...[
                    TextField(
                      controller: audioUrlCtrl,
                      decoration: const InputDecoration(labelText: 'Audio URL'),
                    ),
                    TextField(
                      controller: transcriptCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Transcript',
                      ),
                      maxLines: 3,
                    ),
                  ] else if (widget.skillId == 'speaking' ||
                      widget.skillId == 'writing') ...[
                    TextField(
                      controller: questionCtrl,
                      decoration: const InputDecoration(labelText: 'Câu hỏi'),
                    ),
                    TextField(
                      controller: tipsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Gợi ý (mỗi dòng 1 gợi ý)',
                      ),
                      maxLines: 4,
                    ),
                  ],
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
                  Map<String, dynamic> newData = {};
                  if (widget.skillId == 'reading') {
                    newData = {
                      'passage': passageCtrl.text,
                      'questions': questions,
                    };
                  } else if (widget.skillId == 'listening') {
                    newData = {
                      'audioUrl': audioUrlCtrl.text,
                      'transcript': transcriptCtrl.text,
                    };
                  } else {
                    newData = {
                      'question': questionCtrl.text,
                      'tips': tipsCtrl.text
                          .split('\n')
                          .where((t) => t.trim().isNotEmpty)
                          .toList(),
                    };
                  }

                  final ref = FirebaseFirestore.instance
                      .collection('skills')
                      .doc(widget.skillId)
                      .collection('topics')
                      .doc(widget.topicId)
                      .collection(subCollection);

                  if (edit && id != null) {
                    await ref.doc(id).update(newData);
                  } else {
                    await ref.add(newData);
                  }

                  Navigator.pop(context);
                },
                child: Text(edit ? 'Cập nhật' : 'Thêm'),
              ),
            ],
          );
        },
      ),
    );
  }
}
