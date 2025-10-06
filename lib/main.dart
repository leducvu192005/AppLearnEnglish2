import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart'; // 👈 thêm import màn hình đăng ký
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'admin/admin_screen.dart';
import 'user/user_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // cần thiết khi gọi async trong main
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const EnglishApp());
}

class EnglishApp extends StatelessWidget {
  const EnglishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Learning App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) =>
            const RegisterScreen(), // 👈 thêm route đăng ký
        '/home': (context) => const HomeScreen(),
        '/admin': (context) => const AdminScreen(), // route cho admin
        '/user': (context) => const UserScreen(), // route cho người dùng
      },
    );
  }
}
