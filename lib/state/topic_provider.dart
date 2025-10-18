import 'package:flutter/material.dart';

class TopicProvider extends StatelessWidget {
  const TopicProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Card(
        margin: EdgeInsets.all(3),
        shadowColor: Colors.black,
        borderOnForeground: false,
        elevation: 15,
        child: ListTile(title: Text('Common Verbs')),
      ),
    );
  }
}
