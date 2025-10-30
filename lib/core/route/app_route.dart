import 'package:flutter/material.dart';
import 'package:flutter_application_1/state/user_provider.dart';
import 'package:flutter_application_1/user/user_screen.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/screens/register_screen.dart';
import 'package:flutter_application_1/admin/admin_screen.dart';
import 'package:flutter_application_1/screens/layouts_main.dart';
import 'package:flutter_application_1/admin/quiz_management.dart';
import 'package:flutter_application_1/admin/user_management.dart';
import 'package:flutter_application_1/admin/vocabulary_management.dart';
import 'package:flutter_application_1/admin/reports.dart';

class AppRoute {
  static final Map<String, WidgetBuilder> routes = {
    '/login': (context) => const LoginScreen(),
    '/register': (context) => const RegisterScreen(),
    '/home': (context) => const HomePage(),
    '/admin': (context) => const AdminScreen(),
    '/users': (context) => const UserScreen(),
    '/layouts': (context) => const LayoutsMain(),
    '/profile': (context) => const ProfilePage(),
    '/adminquiz': (context) => const QuizManagement(),
    '/adminuser': (context) => const UserManagement(),
    '/adminvocabulary': (context) => const VocabularyManagement(),
    'reports': (context) => const Reports(),
  };
}
