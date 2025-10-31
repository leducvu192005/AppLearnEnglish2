import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _firestore = FirebaseFirestore.instance;

  int totalUsers = 0;
  int totalQuizzes = 0;
  bool isLoading = true;

  Map<String, int> userGrowth = {}; // Số người dùng theo tháng

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final users = await _firestore.collection('users').get();
      final quizzes = await _firestore.collection('quizzes').get();

      // Đếm người dùng theo tháng
      final now = DateTime.now();
      final Map<String, int> growth = {};

      for (var doc in users.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        if (createdAt == null) continue;

        final monthKey = "${createdAt.month}-${createdAt.year}";
        growth[monthKey] = (growth[monthKey] ?? 0) + 1;
      }

      // Lấy 3 tháng gần nhất
      final last3Months = List.generate(3, (i) {
        final date = DateTime(now.year, now.month - i, 1);
        return "${date.month}-${date.year}";
      }).reversed.toList();

      // Chỉ lấy 3 tháng gần nhất
      final filteredGrowth = {
        for (var key in last3Months) key: growth[key] ?? 0,
      };

      if (!mounted) return;
      setState(() {
        totalUsers = users.size;
        totalQuizzes = quizzes.size;
        userGrowth = filteredGrowth;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Lỗi tải thống kê: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          "Tổng người dùng",
                          totalUsers,
                          Colors.blueAccent,
                          Icons.person,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          "Tổng quiz",
                          totalQuizzes,
                          Colors.green,
                          Icons.quiz,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "📈 Biểu đồ người dùng trong 3 tháng gần nhất",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),

                  _buildBarChart(),
                  const SizedBox(height: 10),
                  const Text(
                    "⚙️ Quản lý hệ thống",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity, // ✅ Chiếm toàn bộ chiều ngang
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/admin/vocabulary');
                          },
                          icon: const Icon(Icons.book),
                          label: const Text(
                            "Quản lý từ vựng",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity, // ✅ Chiếm toàn bộ chiều ngang
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/admin/quiz');
                          },
                          icon: const Icon(Icons.book),
                          label: const Text(
                            "Quản lý quiz",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  // --- Biểu đồ cột người dùng ---
  Widget _buildBarChart() {
    final barGroups = <BarChartGroupData>[];
    final monthLabels = <String>[];

    int index = 0;
    userGrowth.forEach((month, count) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: Colors.blueAccent,
              width: 28,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
      );
      monthLabels.add(month); // ví dụ "10-2025"
      index++;
    });

    return Container(
      height: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          maxY:
              (userGrowth.values.isEmpty
                      ? 1
                      : (userGrowth.values.reduce((a, b) => a > b ? a : b) + 1))
                  .toDouble(),
          gridData: FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, _) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  if (value.toInt() >= 0 &&
                      value.toInt() < monthLabels.length) {
                    final parts = monthLabels[value.toInt()].split('-');
                    return Text(
                      "Th${parts[0]}",
                      style: const TextStyle(fontSize: 12),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          barGroups: barGroups,
          // 🟢 Animation khi biểu đồ hiển thị
          barTouchData: BarTouchData(enabled: true),
        ),
        swapAnimationDuration: const Duration(milliseconds: 800),
        swapAnimationCurve: Curves.easeOut,
      ),
    );
  }

  // --- Ô thống kê tổng ---
  Widget _buildStatCard(String title, int value, Color color, IconData icon) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 40), // 👈 icon ở đây
          const SizedBox(height: 8),
          Text(
            "$value",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
