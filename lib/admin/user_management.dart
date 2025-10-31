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

  // Hàm xóa user với xác nhận
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

  // Tính phần trăm quiz đã làm
  Future<double> _getUserProgress(String userId) async {
    final snapshot = await userProgress
        .where('userId', isEqualTo: userId)
        .get();

    if (snapshot.docs.isEmpty) return 0;

    // Trung bình percent của tất cả quiz mà user đã làm
    double totalPercent = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalPercent += (data['percent'] ?? 0.0).toDouble();
    }

    return totalPercent / snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quản lý người dùng")),
      body: Column(
        children: [
          // Ô tìm kiếm
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Tìm kiếm người dùng',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchTerm = value.toLowerCase();
                });
              },
            ),
          ),
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
