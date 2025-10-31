import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
      appBar: AppBar(
        title: const Text("📊 Báo cáo quiz trong tháng"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: userProgress.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Chưa có dữ liệu."));
          }

          final data = snapshot.data!.docs;

          // Lấy danh sách user và tổng số quiz đã làm
          final List<Map<String, dynamic>> userQuizCounts = [];

          for (var doc in data) {
            final mapData = doc.data() as Map<String, dynamic>;
            final userId = mapData.keys.first;
            final userProgressData = mapData[userId];

            if (userProgressData is List) {
              final totalQuizzes = userProgressData.length;
              userQuizCounts.add({'user': userId, 'count': totalQuizzes});
            } else if (userProgressData is Map) {
              userQuizCounts.add({'user': userId, 'count': 1});
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < userQuizCounts.length) {
                          return Text(
                            userQuizCounts[index]['user'],
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                barGroups: userQuizCounts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: (item['count'] as num).toDouble(),
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.blueAccent,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
