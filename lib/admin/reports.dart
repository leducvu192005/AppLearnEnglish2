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
  // 🔹 Biến để lọc
  String _searchText = '';
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummarySection(),
            const SizedBox(height: 20),
            _buildChartSection(),
            const SizedBox(height: 20),
            _buildLogsSection(),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // 🔹 PHẦN 1: Tổng quan
  // --------------------------------------------------------
  Widget _buildSummarySection() {
    return StreamBuilder<QuerySnapshot>(
      stream: userProgress.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        final totalQuizzes = docs.length;
        double avgPercent = 0;
        final uniqueUsers = <String>{};

        // ✅ Đếm quiz hoàn thành (có isCompleted = true hoặc percent >= 1.0)
        final completedCount = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['isCompleted'] == true || (data['percent'] ?? 0) >= 1.0;
        }).length;

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          avgPercent += (data['percent'] ?? 0.0);
          uniqueUsers.add(data['userId'] ?? '');
        }

        if (docs.isNotEmpty) avgPercent /= docs.length;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard("Tổng lượt làm quiz", "$totalQuizzes", Colors.blue),
            _buildStatCard(
              "Người dùng tham gia",
              "${uniqueUsers.length}",
              Colors.green,
            ),
            _buildStatCard(
              "Điểm trung bình",
              "${(avgPercent * 100).toStringAsFixed(1)}%",
              Colors.orange,
            ),
            _buildStatCard(
              "Quiz đã hoàn thành",
              "$completedCount",
              Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // 🔹 PHẦN 2: Biểu đồ trung bình điểm theo ngày trong tuần
  // --------------------------------------------------------
  Widget _buildChartSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: userProgress.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        // ✅ Gom dữ liệu theo ngày trong tuần
        final Map<int, List<double>> weeklyData = {
          1: [],
          2: [],
          3: [],
          4: [],
          5: [],
          6: [],
          7: [],
        };

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final percent = (data['percent'] ?? 0.0) * 100;
          final timestamp = (data['completedAt'] as Timestamp?)?.toDate();

          if (timestamp != null) {
            int weekday = timestamp.weekday; // 1 = Thứ 2, 7 = CN
            weeklyData[weekday]?.add(percent);
          }
        }

        // ✅ Tính trung bình mỗi ngày
        final barGroups = List.generate(7, (index) {
          final day = index + 1;
          final values = weeklyData[day]!;
          final avg = values.isNotEmpty
              ? values.reduce((a, b) => a + b) / values.length
              : 0.0;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: avg.clamp(0, 100), // Giới hạn tối đa 100
                color: Colors.blueAccent,
                width: 18,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        });

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "📊 Trung bình điểm theo ngày trong tuần",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 240,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100, // ✅ Giới hạn cột tối đa 100
                      gridData: FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value >= 0 && value < 7) {
                                return Text(
                                  weekdays[value.toInt()],
                                  style: const TextStyle(fontSize: 12),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (value, meta) =>
                                Text("${value.toInt()}%"),
                          ),
                        ),
                      ),
                      barGroups: barGroups,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //lọc theo thời gian và từ khóa
  Widget _buildLogsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('logs')
          .orderBy('timestamp', descending: true)
          .limit(200)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allLogs = snapshot.data!.docs;

        // ✅ Lọc dữ liệu theo từ khóa và ngày
        final filteredLogs = allLogs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final username = (data['username'] ?? '').toString().toLowerCase();
          final activity = (data['activity'] ?? '').toString().toLowerCase();
          final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

          bool matchesText =
              _searchText.isEmpty ||
              username.contains(_searchText.toLowerCase()) ||
              activity.contains(_searchText.toLowerCase());

          bool matchesDate = true;
          if (_startDate != null && timestamp != null) {
            matchesDate =
                timestamp.isAfter(_startDate!) ||
                timestamp.isAtSameMomentAs(_startDate!);
          }
          if (_endDate != null && timestamp != null) {
            matchesDate =
                matchesDate &&
                (timestamp.isBefore(_endDate!.add(const Duration(days: 1))) ||
                    timestamp.isAtSameMomentAs(_endDate!));
          }

          return matchesText && matchesDate;
        }).toList();

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
                  "🕒 Nhật ký hoạt động",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),

                // 🔹 Thanh tìm kiếm + chọn ngày
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: '🔍 Tìm theo người dùng hoặc hoạt động...',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _searchText = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.date_range, color: Colors.blue),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2023, 1, 1),
                          lastDate: DateTime.now(),
                          initialDateRange:
                              _startDate != null && _endDate != null
                              ? DateTimeRange(
                                  start: _startDate!,
                                  end: _endDate!,
                                )
                              : null,
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked.start;
                            _endDate = picked.end;
                          });
                        }
                      },
                    ),
                    if (_startDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // 🔹 Danh sách log đã lọc
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  separatorBuilder: (_, __) =>
                      Divider(color: Colors.grey.shade300),
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
                    final data = log.data() as Map<String, dynamic>;
                    final username = data['username'] ?? 'Unknown';
                    final activity = data['activity'] ?? '';
                    final time = data['timestamp'] != null
                        ? DateFormat(
                            'dd/MM/yyyy HH:mm:ss',
                          ).format((data['timestamp'] as Timestamp).toDate())
                        : 'N/A';

                    return ListTile(
                      leading: const Icon(
                        Icons.history,
                        color: Colors.blueAccent,
                      ),
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
}
