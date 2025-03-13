// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/welcome.dart';
import 'screens/signin.dart';
import 'screens/signup.dart';
import 'screens/receipt.dart';
import 'screens/settings.dart';

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

  // Printer connection state that can be shared across screens
  bool _isPrinterConnected = false;
  Map<String, dynamic>? _connectedPrinter;

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

  void _handlePrinterConnection(bool isConnected, Map<String, dynamic>? printerDetails) {
    setState(() {
      _isPrinterConnected = isConnected;
      _connectedPrinter = printerDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Receipt App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
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
        '/print': (context) => const ReceiptScreen(),
        '/settings': (context) => PrinterSettings(
          onPrinterConnected: (printer, isConnected, deviceDetails) {
            _handlePrinterConnection(isConnected, deviceDetails);
          },
        ),
      },
    );
  }
}
