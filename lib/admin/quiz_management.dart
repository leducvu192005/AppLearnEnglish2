import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'quiz_edit_screen.dart';
import 'skill_detail_page.dart';

class QuizManagement extends StatefulWidget {
  const QuizManagement({Key? key}) : super(key: key);

  @override
  State<QuizManagement> createState() => _QuizManagementState();
}

class _QuizManagementState extends State<QuizManagement> {
  final CollectionReference quizzes = FirebaseFirestore.instance.collection(
    'quizzes',
  );

  String _searchTerm = '';

  Future<void> _deleteQuiz(String id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc muốn xóa quiz '$title' không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
    if (confirm == true) await quizzes.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý Quiz"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const QuizEditScreen(isEditing: false),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // 🔹 Thanh tìm kiếm
            TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm quiz...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) =>
                  setState(() => _searchTerm = val.toLowerCase()),
            ),
            const SizedBox(height: 12),

            // 🔹 Danh sách quiz
            StreamBuilder<QuerySnapshot>(
              stream: quizzes.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!.docs.where((doc) {
                  final title = doc['title'].toString().toLowerCase();
                  return title.contains(_searchTerm);
                }).toList();

                if (data.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text("Không tìm thấy quiz nào"),
                    ),
                  );
                }

                return Column(
                  children: data.map((quiz) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(
                          quiz['title'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(quiz['description']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QuizEditScreen(
                                      isEditing: true,
                                      quizId: quiz.id,
                                      existingData:
                                          quiz.data() as Map<String, dynamic>,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _deleteQuiz(quiz.id, quiz['title']),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 20),
            const Divider(thickness: 1),

            // 🔹 Phần hiển thị 4 kỹ năng
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Kỹ năng luyện tập",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(), // tránh conflict scroll
              padding: const EdgeInsets.all(8),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _buildSkillCard(
                  context,
                  'Listening',
                  Icons.headphones,
                  Colors.blue,
                  'listening',
                ),
                _buildSkillCard(
                  context,
                  'Speaking',
                  Icons.mic,
                  Colors.redAccent,
                  'speaking',
                ),
                _buildSkillCard(
                  context,
                  'Reading',
                  Icons.book,
                  Colors.green,
                  'reading',
                ),
                _buildSkillCard(
                  context,
                  'Writing',
                  Icons.edit,
                  Colors.orange,
                  'writing',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Hàm tạo thẻ kỹ năng
  Widget _buildSkillCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String skillId,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SkillDetailPage(skillId: skillId)),
        );
      },
      child: Card(
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
