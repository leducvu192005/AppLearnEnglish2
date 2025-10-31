import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _firestore = FirebaseFirestore.instance;
  int totalQuizzes = 0;
  int totalUsers = 0;
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

      final now = DateTime.now();
      final Map<String, int> growth = {};

      for (var doc in users.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        if (createdAt == null) continue;

        final monthKey = "${createdAt.month}-${createdAt.year}";
        growth[monthKey] = (growth[monthKey] ?? 0) + 1;
      }

      final last3Months = List.generate(3, (i) {
        final date = DateTime(now.year, now.month - i, 1);
        return "${date.month}-${date.year}";
      }).reversed.toList();

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
                  // --- Quản lý ---
                  Card(
                    margin: const EdgeInsets.only(top: 10),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '⚙️ Quản lý từ vựng và quiz',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Hai card con nằm trên 1 hàng
                          Row(
                            children: [
                              Expanded(
                                child: _buildManageCard(
                                  color: Colors.blueAccent,
                                  icon: Icons.book,
                                  title: "Thêm bộ từ vựng",
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/admin/vocabulary',
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildManageCard(
                                  color: Colors.lightGreen,
                                  icon: Icons.quiz,
                                  title: "Thêm bộ quiz",
                                  onTap: () {
                                    Navigator.pushNamed(context, '/admin/quiz');
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // --- Biểu đồ tăng trưởng ---
                  Card(
                    margin: const EdgeInsets.only(top: 1),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "📈 Tăng trưởng người dùng (3 tháng gần nhất)",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 200,
                            child: UserGrowthChart(data: userGrowth),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  _buildLogsSection(),
                ],
              ),
            ),
    );
  }

  // --- Nhật ký hoạt động ---
  Widget _buildLogsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('logs')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final logs = snapshot.data!.docs;

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "🕒 Nhật ký hoạt động gần đây",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  separatorBuilder: (_, __) =>
                      Divider(color: Colors.grey.shade300),
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
                      leading: const Icon(Icons.history, color: Colors.blue),
                      title: Text(activity),
                      subtitle: Text("$username • $time"),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Ô thống kê tổng ---
  Widget _buildStatCard(String title, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 40),
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

Widget _buildManageCard({
  required Color color,
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      height: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    ),
  );
}

/// --- Widget biểu đồ tăng trưởng ---
class UserGrowthChart extends StatelessWidget {
  final Map<String, int> data;

  const UserGrowthChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final keys = data.keys.toList();
    final values = data.values.toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, _) {
                final index = value.toInt();
                if (index >= 0 && index < keys.length) {
                  return Text(
                    keys[index],
                    style: const TextStyle(fontSize: 12),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
          ),
        ),
        barGroups: List.generate(values.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: values[i].toDouble(),
                color: Colors.blueAccent,
                width: 22,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
      ),
    );
  }
}
