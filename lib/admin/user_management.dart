import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  final CollectionReference users = FirebaseFirestore.instance.collection(
    'users',
  );
  final CollectionReference userProgress = FirebaseFirestore.instance
      .collection('user_progress');

  String _searchTerm = '';

  // 🧹 Hàm xóa user với xác nhận
  Future<void> _deleteUser(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc muốn xóa user '$name' không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
    if (confirm == true) await users.doc(id).delete();
  }

  // 📊 Lấy điểm trung bình quiz của 1 user
  Future<double> _getUserProgress(String userId) async {
    final snapshot = await userProgress
        .where('userId', isEqualTo: userId)
        .get();

    if (snapshot.docs.isEmpty) return 0;

    double totalPercent = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalPercent += (data['percent'] ?? 0.0).toDouble();
    }

    return totalPercent / snapshot.docs.length;
  }

  // 🏆 Lấy top 3 người dùng có điểm trung bình cao nhất
  Future<List<Map<String, dynamic>>> _fetchTopUsers() async {
    final allProgress = await userProgress.get();
    final Map<String, List<double>> userScores = {};

    for (var doc in allProgress.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final userId = data['userId'];
      final percent = (data['percent'] ?? 0.0).toDouble();
      if (userId != null) {
        userScores.putIfAbsent(userId, () => []).add(percent);
      }
    }

    // Tính trung bình
    final List<Map<String, dynamic>> averages = userScores.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return {'userId': e.key, 'average': avg};
    }).toList();

    // Sắp xếp giảm dần
    averages.sort((a, b) => b['average'].compareTo(a['average']));

    // Lấy top 3
    final top3 = averages.take(3).toList();

    // Lấy thông tin user
    for (var user in top3) {
      final doc = await users.doc(user['userId']).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        user['name'] = data['name'] ?? 'Unknown';
        user['email'] = data['email'] ?? '';
      } else {
        user['name'] = 'Unknown';
        user['email'] = '';
      }
    }

    return top3;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 🏆 Hiển thị top 3 người dùng
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchTopUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Chưa có dữ liệu quiz của người dùng."),
                );
              }

              final topUsers = snapshot.data!;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "🏆 Top 3 người dùng có điểm trung bình cao nhất",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (int i = 0; i < topUsers.length; i++)
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Text(
                              "${i + 1}",
                              style: const TextStyle(
                                color: Color.fromARGB(255, 233, 230, 230),
                              ),
                            ),
                          ),
                          title: Text(topUsers[i]['name'] ?? 'Unknown'),
                          subtitle: Text(topUsers[i]['email']),
                          trailing: Text(
                            "${(topUsers[i]['average'] * 100).toStringAsFixed(1)}%",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 🔍 Ô tìm kiếm người dùng
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: ' 🔍 Tìm kiếm người dùng',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchTerm = value.toLowerCase();
                });
              },
            ),
          ),

          // 📋 Danh sách người dùng
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: users.where('role', isEqualTo: 'user').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Lỗi tải dữ liệu người dùng'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  return name.contains(_searchTerm) ||
                      email.contains(_searchTerm);
                }).toList();

                if (userDocs.isEmpty) {
                  return const Center(child: Text("Không có người dùng nào"));
                }

                return ListView.builder(
                  itemCount: userDocs.length,
                  itemBuilder: (context, index) {
                    final doc = userDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final userId = doc.id;

                    return FutureBuilder<double>(
                      future: _getUserProgress(userId),
                      builder: (context, progressSnap) {
                        final progress = progressSnap.data ?? 0;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            title: Text(
                              data['name'] ?? 'No Name',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['email'] ?? 'No Email'),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey.shade300,
                                  color: Colors.blue,
                                  minHeight: 6,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${(progress * 100).toStringAsFixed(1)}% quiz đã làm",
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteUser(
                                doc.id,
                                data['name'] ?? 'No Name',
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
