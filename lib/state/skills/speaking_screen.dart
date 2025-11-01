import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final topics = snapshot.data!.docs;

          return ListView.builder(
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];
              final data = topic.data() as Map<String, dynamic>;

              return ExpansionTile(
                leading: Image.network(
                  data['image'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
                title: Text(data['name']),
                subtitle: Text(data['description']),
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: topic.reference.collection('prompts').snapshots(),
                    builder: (context, promptSnap) {
                      if (!promptSnap.hasData)
                        return const CircularProgressIndicator();
                      final prompts = promptSnap.data!.docs;

                      return Column(
                        children: prompts.map((promptDoc) {
                          final prompt =
                              promptDoc.data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(prompt['question']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: (prompt['tips'] as List)
                                  .map<Widget>((tip) => Text("• $tip"))
                                  .toList(),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
