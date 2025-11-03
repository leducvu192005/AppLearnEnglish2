import 'package:flutter/material.dart';
import 'package:flutter_application_1/state/user_provider.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/screens/register_screen.dart';
import 'package:flutter_application_1/admin/admin_screen.dart';
import 'package:flutter_application_1/screens/layouts_main.dart';
import 'package:flutter_application_1/admin/quiz_management.dart';
import 'package:flutter_application_1/admin/user_management.dart';
import 'package:flutter_application_1/admin/vocabulary_management.dart';
import 'package:flutter_application_1/admin/reports.dart';
import 'package:flutter_application_1/admin/setting.dart';
import 'package:flutter_application_1/state/quiz_provider.dart';
import 'package:flutter_application_1/state/vocabulary_page.dart';
import 'package:flutter_application_1/state/skills/listening_screen.dart';
import 'package:flutter_application_1/state/skills/speaking_screen.dart';
import 'package:flutter_application_1/state/skills/reading_screen.dart';
import 'package:flutter_application_1/state/skills/writing_screen.dart';

class AppRoute {
  static final Map<String, WidgetBuilder> routes = {
    '/login': (context) => const LoginScreen(),
    '/register': (context) => const RegisterScreen(),
    '/home': (context) => const HomePage(),
    '/admin': (context) => const AdminScreen(),
    '/layouts': (context) => const LayoutsMain(),
    '/profile': (context) => const UserProviderPage(),
    '/admin/quiz': (context) => const QuizManagement(),
    '/admin/users': (context) => const UserManagement(),
    '/admin/vocabulary': (context) => const VocabularyManagement(),
    'reports': (context) => const Reports(),
    '/settings': (context) => const Setting(),
    '/quiz': (context) => const QuizProvider(),
    '/vocabulary': (context) => const VocabularyPage(),
    '/skills/listening': (context) => const ListeningScreen(),
    '/skills/speaking': (context) => const SpeakingScreen(),
    '/skills/reading': (context) => const ReadingScreen(),
    '/skills/writing': (context) => const WritingScreen(),
  };
}
