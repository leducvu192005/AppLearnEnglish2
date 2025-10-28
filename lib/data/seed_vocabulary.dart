import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedVocabularyTopics() async {
  final firestore = FirebaseFirestore.instance;
  final topicsRef = firestore.collection('Vocabulary_topics');

  final topics = {
    'Animals': {
      'description': 'Các con vật thường gặp',
      'words': {
        'w1': {'en': 'dog', 'vi': 'con chó'},
        'w2': {'en': 'cat', 'vi': 'con mèo'},
        'w3': {'en': 'bird', 'vi': 'con chim'},
        'w4': {'en': 'elephant', 'vi': 'con voi'},
        'w5': {'en': 'tiger', 'vi': 'con hổ'},
        'w6': {'en': 'lion', 'vi': 'con sư tử'},
        'w7': {'en': 'fish', 'vi': 'con cá'},
        'w8': {'en': 'chicken', 'vi': 'con gà'},
        'w9': {'en': 'cow', 'vi': 'con bò'},
        'w10': {'en': 'monkey', 'vi': 'con khỉ'},
      },
    },
    'Food': {
      'description': 'Từ vựng về đồ ăn',
      'words': {
        'w1': {'en': 'rice', 'vi': 'cơm'},
        'w2': {'en': 'bread', 'vi': 'bánh mì'},
        'w3': {'en': 'meat', 'vi': 'thịt'},
        'w4': {'en': 'egg', 'vi': 'trứng'},
        'w5': {'en': 'milk', 'vi': 'sữa'},
        'w6': {'en': 'noodles', 'vi': 'mì'},
        'w7': {'en': 'apple', 'vi': 'quả táo'},
        'w8': {'en': 'banana', 'vi': 'quả chuối'},
        'w9': {'en': 'carrot', 'vi': 'cà rốt'},
        'w10': {'en': 'orange', 'vi': 'quả cam'},
      },
    },
    'Travel': {
      'description': 'Từ vựng chủ đề du lịch',
      'words': {
        'w1': {'en': 'airport', 'vi': 'sân bay'},
        'w2': {'en': 'ticket', 'vi': 'vé'},
        'w3': {'en': 'passport', 'vi': 'hộ chiếu'},
        'w4': {'en': 'hotel', 'vi': 'khách sạn'},
        'w5': {'en': 'luggage', 'vi': 'hành lý'},
        'w6': {'en': 'map', 'vi': 'bản đồ'},
        'w7': {'en': 'taxi', 'vi': 'xe taxi'},
        'w8': {'en': 'bus', 'vi': 'xe buýt'},
        'w9': {'en': 'beach', 'vi': 'bãi biển'},
        'w10': {'en': 'mountain', 'vi': 'núi'},
      },
    },
    'School': {
      'description': 'Từ vựng trường học',
      'words': {
        'w1': {'en': 'teacher', 'vi': 'giáo viên'},
        'w2': {'en': 'student', 'vi': 'học sinh'},
        'w3': {'en': 'book', 'vi': 'sách'},
        'w4': {'en': 'pen', 'vi': 'bút'},
        'w5': {'en': 'desk', 'vi': 'bàn học'},
        'w6': {'en': 'chair', 'vi': 'ghế'},
        'w7': {'en': 'classroom', 'vi': 'lớp học'},
        'w8': {'en': 'homework', 'vi': 'bài tập về nhà'},
        'w9': {'en': 'exam', 'vi': 'kỳ thi'},
        'w10': {'en': 'lesson', 'vi': 'bài học'},
      },
    },
  };

  for (var entry in topics.entries) {
    await topicsRef.doc(entry.key).set({
      'name': entry.key,
      'description': entry.value['description'],
      'words': entry.value['words'],
    });
  }

  print("✅ Seeded Vocabulary Topics successfully!");
}
