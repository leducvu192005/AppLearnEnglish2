import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProviderPage extends StatefulWidget {
  const UserProviderPage({super.key});

  @override
  State<UserProviderPage> createState() => _UserProviderPageState();
}

class _UserProviderPageState extends State<UserProviderPage> {
  final user = FirebaseAuth.instance.currentUser;

  int quizCount = 0;
  int skillTestCount = 0;
  bool isLoadingStats = true;

  bool isDarkMode = false;
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    if (user == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('user_progress')
          .where('userId', isEqualTo: user!.uid)
          .get();

      int quiz = 0;
      int skills = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final skill = (data['skill'] ?? '').toString().toLowerCase();

        if (skill == 'quiz') {
          quiz++;
        } else if ([
          'speaking',
          'listening',
          'reading',
          'writing',
        ].contains(skill)) {
          skills++;
        }
      }

      setState(() {
        quizCount = quiz;
        skillTestCount = skills;
        isLoadingStats = false;
      });

      print("✅ Đã tải thống kê: Quiz=$quizCount | SkillTest=$skillTestCount");
    } catch (e) {
      print("❌ Lỗi khi tải thống kê: $e");
      setState(() => isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = user?.displayName ?? 'Người dùng';
    final initials = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ người dùng'), centerTitle: true),
      body: ListView(
        children: [
          const SizedBox(height: 20),

          // 👤 Ảnh hoặc chữ cái đầu
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.email ?? 'Không có email',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Học viên",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          const Divider(),

          // 📊 Thống kê học tập
          // 📊 Thống kê học tập
          _sectionTitle("THỐNG KÊ HỌC TẬP"),
          isLoadingStats
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.quiz, color: Colors.purple),
                      title: const Text('Số bài Quiz đã làm'),
                      subtitle: Text('$quizCount bài'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.star, color: Colors.orange),
                      title: const Text('Số bài test kỹ năng đã làm'),
                      subtitle: Text('$skillTestCount bài'),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.date_range,
                        color: Colors.green,
                      ),
                      title: const Text('Ngày tham gia'),
                      subtitle: Text(
                        user?.metadata.creationTime != null
                            ? DateFormat(
                                'dd/MM/yyyy',
                              ).format(user!.metadata.creationTime!)
                            : 'Không rõ',
                      ),
                    ),
                  ],
                ),

          const Divider(),

          // 🌗 Tùy chỉnh chế độ giao diện và thông báo
          _sectionTitle("TÙY CHỌN GIAO DIỆN"),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Chế độ tối '),
            value: themeNotifier.value == ThemeMode.dark,
            onChanged: (value) {
              setState(() {
                themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value ? "Đã bật chế độ tối 🌙" : "Đã tắt chế độ tối ☀️",
                  ),
                ),
              );
            },
          ),

          const Divider(),

          // 📚 Liên kết đến các trang học
          _sectionTitle("HOẠT ĐỘNG HỌC TẬP"),
          ListTile(
            leading: const Icon(Icons.quiz, color: Colors.purple),
            title: const Text('Làm bài Quiz'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/quiz'),
          ),
          ListTile(
            leading: const Icon(Icons.book, color: Colors.teal),
            title: const Text('Học từ vựng'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/vocabulary'),
          ),

          const Divider(),

          // ⚙️ Cài đặt tài khoản
          _sectionTitle("TÀI KHOẢN"),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Đổi mật khẩu'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChangePasswordDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        fontSize: 13,
      ),
    ),
  );

  // 🔐 Đổi mật khẩu
  void _showChangePasswordDialog(BuildContext context) {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
            ),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPass = newPasswordController.text.trim();
              final confirm = confirmPasswordController.text.trim();

              if (newPass.isEmpty || confirm.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng nhập đầy đủ thông tin'),
                  ),
                );
                return;
              }
              if (newPass != confirm) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mật khẩu không khớp')),
                );
                return;
              }

              try {
                await user?.updatePassword(newPass);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đổi mật khẩu thành công!')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // 🚪 Đăng xuất
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
