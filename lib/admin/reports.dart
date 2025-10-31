import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class Reports extends StatefulWidget {
  const Reports({super.key});

  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  final CollectionReference userProgress = FirebaseFirestore.instance
      .collection('user_progress');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('logs')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Chưa có log nào."));
          }

          final logs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final username = log['username'] ?? 'Unknown';
              final activity = log['activity'] ?? '';
              final time = log['timestamp'] != null
                  ? DateFormat(
                      'dd/MM/yyyy HH:mm:ss',
                    ).format((log['timestamp'] as Timestamp).toDate())
                  : 'N/A';

              return ListTile(
                leading: const Icon(Icons.history, color: Colors.blueAccent),
                title: Text(activity),
                subtitle: Text("$username • $time"),
              );
            },
          );
        },
      ),
    );
  }
}
