import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedQuizzes() async {
  final firestore = FirebaseFirestore.instance;

  final quizzes = {
    'set1': {
      'title': 'Basic Vocabulary',
      'description': 'Học 10 từ vựng cơ bản',
      'totalQuestions': 3,
      'questions': [
        {
          'id': 'q1',
          'question': "What is the meaning of 'apple'?",
          'options': ['A fruit', 'An animal', 'A car', 'A country'],
          'correctAnswer': 'A fruit',
        },
        {
          'id': 'q2',
          'question': "What color is the sky?",
          'options': ['Blue', 'Green', 'Yellow', 'Red'],
          'correctAnswer': 'Blue',
        },
        {
          'id': 'q3',
          'question': "Which one is an animal?",
          'options': ['Dog', 'Chair', 'Car', 'Book'],
          'correctAnswer': 'Dog',
        },
      ],
    },
    'set2': {
      'title': 'Basic Grammar',
      'description': 'Luyện ngữ pháp cơ bản',
      'totalQuestions': 3,
      'questions': [
        {
          'id': 'q1',
          'question': "Choose the correct form: She ___ to school every day.",
          'options': ['go', 'goes', 'going', 'gone'],
          'correctAnswer': 'goes',
        },
        {
          'id': 'q2',
          'question': "What is the plural of 'child'?",
          'options': ['childs', 'children', 'childes', 'childrens'],
          'correctAnswer': 'children',
        },
        {
          'id': 'q3',
          'question':
              "Select the correct article: ___ apple a day keeps the doctor away.",
          'options': ['A', 'An', 'The', 'No article'],
          'correctAnswer': 'An',
        },
      ],
    },
  };

  for (var entry in quizzes.entries) {
    final setId = entry.key;
    final setData = entry.value;

    await firestore.collection('quizzes').doc(setId).set({
      'title': setData['title'],
      'description': setData['description'],
      'totalQuestions': setData['totalQuestions'],
    });

    final questions = setData['questions'] as List;
    for (var q in questions) {
      await firestore
          .collection('quizzes')
          .doc(setId)
          .collection('questions')
          .doc(q['id'])
          .set({
            'question': q['question'],
            'options': q['options'],
            'correctAnswer': q['correctAnswer'],
          });
    }
  }

  print('✅ Seed quizzes thành công!');
}
