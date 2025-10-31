import 'package:cloud_firestore/cloud_firestore.dart';

class AppLogger {
  // Singleton pattern
  static final AppLogger _instance = AppLogger._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory AppLogger() => _instance;
  AppLogger._internal();

  /// Ghi log vào Firestore (collection: logs)
  Future<void> log({required String username, required String activity}) async {
    try {
      final time = DateTime.now();

      await _firestore.collection('logs').add({
        'username': username,
        'activity': activity,
        'timestamp': time,
      });

      print("✅ Log saved: $username | $activity | $time");
    } catch (e) {
      // Nếu ghi log thất bại (ví dụ offline), in ra console
      print("❌ Failed to write log: $e");
    }
  }

  /// Lấy danh sách logs (mới nhất trước)
  Stream<QuerySnapshot> getLogsStream() {
    return _firestore
        .collection('logs')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
