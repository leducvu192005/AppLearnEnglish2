import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/data/seed_vocabulary.dart';
import 'config/firebase_options.dart';
import 'core/route/app_route.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Cần thiết khi có async trong main

  // ✅ Khởi tạo Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Seed data (tạo sẵn bộ từ vựng)
  await seedVocabularyTopics();

  // ✅ Chạy ứng dụng
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
      routes: AppRoute.routes,
    );
  }
}
