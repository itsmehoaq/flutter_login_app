// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/welcome.dart';
import 'screens/signin.dart';
import 'screens/signup.dart';
import 'screens/print.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;

  void _handleLogin() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  void _handleLogout() {
    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Login Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomeScreen(
          isLoggedIn: _isLoggedIn,
          onLogout: _handleLogout,
        ),
        '/signin': (context) => SignInScreen(
          onLogin: _handleLogin,
        ),
        '/signup': (context) => const SignUpScreen(),
        '/print': (context) => const PrintScreen(),
      },
    );
  }
}
