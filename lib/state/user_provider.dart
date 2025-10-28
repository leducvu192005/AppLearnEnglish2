import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  int totalQuiz = 0;
  double avgScore = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('progress')
        .get();

    totalQuiz = snapshot.docs.length;

    double totalPercent = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      totalPercent += (data['percent'] ?? 0);
    }
    avgScore = totalQuiz == 0 ? 0 : totalPercent / totalQuiz;

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("👤 Hồ sơ cá nhân"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blueAccent.withOpacity(0.2),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.email ?? "Người dùng ẩn danh",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),

                  _buildInfoTile("Số bài quiz đã làm", "$totalQuiz"),
                  const SizedBox(height: 10),
                  _buildInfoTile(
                    "Điểm trung bình",
                    "${(avgScore * 100).toStringAsFixed(1)}%",
                  ),
                  const SizedBox(height: 40),

                  ElevatedButton.icon(
                    onPressed: () async {
                      await _auth.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Đăng xuất"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(2, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }
}
