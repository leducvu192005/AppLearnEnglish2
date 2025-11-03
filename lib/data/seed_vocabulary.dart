import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedVocabularyTopics() async {
  final firestore = FirebaseFirestore.instance;
  final topicsRef = firestore.collection('Vocabulary_topics');

  // ✅ Xóa sạch dữ liệu cũ (nếu có)
  final snapshot = await topicsRef.get();
  for (var doc in snapshot.docs) {
    await doc.reference.delete();
  }

  // ✅ Dữ liệu mẫu có thêm ảnh & âm thanh
  final topics = {
    'Animals': {
      'description': 'Các con vật thường gặp',
      'words': {
        'w1': {
          'en': 'dog',
          'vi': 'con chó',
          'image': 'https://example.com/images/dog.jpg',
          'audio': 'https://example.com/audio/dog.mp3',
        },
        'w2': {
          'en': 'cat',
          'vi': 'con mèo',
          'image': 'https://example.com/images/cat.jpg',
          'audio': 'https://example.com/audio/cat.mp3',
        },
        'w3': {
          'en': 'bird',
          'vi': 'con chim',
          'image': 'https://example.com/images/bird.jpg',
          'audio': 'https://example.com/audio/bird.mp3',
        },
      },
    },
    'Food': {
      'description': 'Từ vựng về đồ ăn',
      'words': {
        'w1': {
          'en': 'rice',
          'vi': 'cơm',
          'image': 'https://example.com/images/rice.jpg',
          'audio': 'https://example.com/audio/rice.mp3',
        },
        'w2': {
          'en': 'bread',
          'vi': 'bánh mì',
          'image': 'https://example.com/images/bread.jpg',
          'audio': 'https://example.com/audio/bread.mp3',
        },
        'w3': {
          'en': 'milk',
          'vi': 'sữa',
          'image': 'https://example.com/images/milk.jpg',
          'audio': 'https://example.com/audio/milk.mp3',
        },
      },
    },
    'Travel': {
      'description': 'Từ vựng chủ đề du lịch',
      'words': {
        'w1': {
          'en': 'airport',
          'vi': 'sân bay',
          'image': 'https://example.com/images/airport.jpg',
          'audio': 'https://example.com/audio/airport.mp3',
        },
        'w2': {
          'en': 'passport',
          'vi': 'hộ chiếu',
          'image': 'https://example.com/images/passport.jpg',
          'audio': 'https://example.com/audio/passport.mp3',
        },
        'w3': {
          'en': 'hotel',
          'vi': 'khách sạn',
          'image': 'https://example.com/images/hotel.jpg',
          'audio': 'https://example.com/audio/hotel.mp3',
        },
      },
    },
    'School': {
      'description': 'Từ vựng chủ đề trường học',
      'words': {
        'w1': {
          'en': 'teacher',
          'vi': 'giáo viên',
          'image': 'https://example.com/images/teacher.jpg',
          'audio': 'https://example.com/audio/teacher.mp3',
        },
        'w2': {
          'en': 'student',
          'vi': 'học sinh',
          'image': 'https://example.com/images/student.jpg',
          'audio': 'https://example.com/audio/student.mp3',
        },
        'w3': {
          'en': 'book',
          'vi': 'sách',
          'image': 'https://example.com/images/book.jpg',
          'audio': 'https://example.com/audio/book.mp3',
        },
      },
    },
  };

  // ✅ Ghi dữ liệu vào Firestore
  for (var entry in topics.entries) {
    await topicsRef.doc(entry.key).set({
      'name': entry.key,
      'description': entry.value['description'],
      'words': entry.value['words'],
    });
  }

  print("✅ Seeded Vocabulary Topics with images & audio successfully!");
}
