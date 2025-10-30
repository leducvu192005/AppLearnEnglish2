import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizEditScreen extends StatefulWidget {
  final bool isEditing;
  final String? quizId;
  final Map<String, dynamic>? existingData;

  const QuizEditScreen({
    Key? key,
    required this.isEditing,
    this.quizId,
    this.existingData,
  }) : super(key: key);

  @override
  State<QuizEditScreen> createState() => _QuizEditScreenState();
}

class _QuizEditScreenState extends State<QuizEditScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.existingData != null) {
      _titleController.text = widget.existingData!['title'];
      _descController.text = widget.existingData!['description'];
      _loadQuestions();
    }
  }

  Future<void> _loadQuestions() async {
    final ref = FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizId)
        .collection('questions');
    final snap = await ref.get();
    setState(() {
      _questions = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    });
  }

  Future<void> _saveQuiz() async {
    final quizRef = FirebaseFirestore.instance.collection('quizzes');
    DocumentReference docRef;

    if (widget.isEditing) {
      docRef = quizRef.doc(widget.quizId);
      await docRef.update({
        'title': _titleController.text,
        'description': _descController.text,
      });
    } else {
      docRef = await quizRef.add({
        'title': _titleController.text,
        'description': _descController.text,
        'totalQuestions': _questions.length,
      });
    }

    final qRef = docRef.collection('questions');
    for (var q in _questions) {
      if (q['id'] == null) {
        await qRef.add({
          'question': q['question'],
          'options': q['options'],
          'correctAnswer': q['correctAnswer'],
        });
      } else {
        await qRef.doc(q['id']).update({
          'question': q['question'],
          'options': q['options'],
          'correctAnswer': q['correctAnswer'],
        });
      }
    }

    await docRef.update({'totalQuestions': _questions.length});
    Navigator.pop(context);
  }

  void _addQuestionDialog({Map<String, dynamic>? existingQ}) {
    final questionCtrl = TextEditingController(text: existingQ?['question']);
    final optionCtrls = List.generate(
      4,
      (i) => TextEditingController(text: existingQ?['options']?[i] ?? ''),
    );
    String correct = existingQ?['correctAnswer'] ?? '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existingQ == null ? "Thêm câu hỏi" : "Sửa câu hỏi"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: questionCtrl,
                decoration: const InputDecoration(labelText: 'Câu hỏi'),
              ),
              for (int i = 0; i < 4; i++)
                TextField(
                  controller: optionCtrls[i],
                  decoration: InputDecoration(labelText: 'Lựa chọn ${i + 1}'),
                ),
              TextField(
                decoration: const InputDecoration(labelText: 'Đáp án đúng'),
                onChanged: (val) => correct = val,
                controller: TextEditingController(text: correct),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              final newQ = {
                'question': questionCtrl.text,
                'options': optionCtrls.map((c) => c.text).toList(),
                'correctAnswer': correct,
              };
              setState(() {
                if (existingQ == null) {
                  _questions.add(newQ);
                } else {
                  final index = _questions.indexOf(existingQ);
                  _questions[index] = newQ;
                }
              });
              Navigator.pop(context);
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  void _deleteQuestion(Map<String, dynamic> q) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xác nhận"),
        content: const Text("Bạn có chắc muốn xóa câu hỏi này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() => _questions.remove(q));
              Navigator.pop(context);
            },
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? "Sửa Quiz" : "Thêm Quiz"),
        actions: [
          IconButton(onPressed: _saveQuiz, icon: const Icon(Icons.save)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Tên quiz'),
              ),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Mô tả'),
              ),
              const SizedBox(height: 20),
              const Text(
                "Danh sách câu hỏi",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              for (var q in _questions)
                Card(
                  child: ListTile(
                    title: Text(q['question']),
                    subtitle: Text("Đáp án đúng: ${q['correctAnswer']}"),
                    trailing: Wrap(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _addQuestionDialog(existingQ: q),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteQuestion(q),
                        ),
                      ],
                    ),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: () => _addQuestionDialog(),
                icon: const Icon(Icons.add),
                label: const Text("Thêm câu hỏi"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
