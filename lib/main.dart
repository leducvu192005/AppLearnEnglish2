import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_options.dart';
import 'core/route/app_route.dart';

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
      routes: AppRoute.routes,
    );
  }
}
