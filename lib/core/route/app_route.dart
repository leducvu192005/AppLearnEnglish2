import 'package:flutter/material.dart';
import 'package:flutter_application_1/user/user_screen.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/screens/register_screen.dart';
import 'package:flutter_application_1/admin/admin_screen.dart';
import 'package:flutter_application_1/screens/layouts_main.dart';

class AppRoute {
  static final Map<String, WidgetBuilder> routes = {
    '/login': (context) => const LoginScreen(),
    '/register': (context) => const RegisterScreen(),
    '/home': (context) => const HomeScreen(),
    '/admin': (context) => const AdminScreen(),
    '/users': (context) => const UserScreen(),
    '/layouts': (context) => const LayoutsMain(),
  };
}
