import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reading_detail_screen.dart';

class ReadingScreen extends StatelessWidget {
  const ReadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text("Reading Practice")),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('skills')
            .doc('reading')
            .collection('topics')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final topics = snapshot.data!.docs;

          return ListView.builder(
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];
              final data = topic.data() as Map<String, dynamic>;

              return ListTile(
                leading: Image.network(
                  data['image'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
                title: Text(data['name']),
                subtitle: Text(data['description']),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReadingDetailScreen(
                        topicId: topic.id,
                        topicData: data,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
