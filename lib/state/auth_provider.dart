import 'package:flutter/material.dart';

class AuthProvider extends StatefulWidget {
  const AuthProvider({super.key});

  @override
  State<AuthProvider> createState() => _AuthProviderState();
}

class _AuthProviderState extends State<AuthProvider> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Auth Provider Screen')));
  }
}
