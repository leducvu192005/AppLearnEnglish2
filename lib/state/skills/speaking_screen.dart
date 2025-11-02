import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'speaking_detail_screen.dart'; // ⚠️ import trang chi tiết

class SpeakingScreen extends StatelessWidget {
  const SpeakingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text("Speaking Practice")),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('skills')
            .doc('speaking')
            .collection('topics')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final topics = snapshot.data!.docs;

          if (topics.isEmpty) {
            return const Center(child: Text("Chưa có chủ đề nào."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];
              final data = topic.data() as Map<String, dynamic>;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      data['image'] ?? '',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image_not_supported),
                    ),
                  ),
                  title: Text(
                    data['name'] ?? 'Không có tên',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    // 👉 Khi nhấn, chuyển sang trang chi tiết
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SpeakingDetailScreen(topicId: topic.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
