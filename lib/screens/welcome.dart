import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  final bool isLoggedIn;
  final VoidCallback onLogout;

  const WelcomeScreen({
    Key? key,
    required this.isLoggedIn,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: onLogout,
              tooltip: 'Logout',
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoggedIn) ...[
              const Text(
                'Welcome Koson',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/print');  // Add this button
                },
                child: const Text('Go to Print Screen'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: onLogout,
                child: const Text('Logout'),
              ),
            ] else ...[
              const Text(
                'Please sign in',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signin');
                },
                child: const Text('Sign In'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                child: const Text('Sign Up'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
