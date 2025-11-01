import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';

class ListeningScreen extends StatefulWidget {
  const ListeningScreen({super.key});

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> {
  final firestore = FirebaseFirestore.instance;
  final player = AudioPlayer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Listening Practice")),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('skills')
            .doc('listening')
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
                    stream: topic.reference.collection('audios').snapshots(),
                    builder: (context, audioSnap) {
                      if (!audioSnap.hasData)
                        return const CircularProgressIndicator();
                      final audios = audioSnap.data!.docs;

                      return Column(
                        children: audios.map((audioDoc) {
                          final audio = audioDoc.data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(audio['transcript']),
                            trailing: IconButton(
                              icon: const Icon(Icons.play_arrow),
                              onPressed: () async {
                                await player.play(UrlSource(audio['audioUrl']));
                              },
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
