import 'package:flutter/material.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.blue,
        ),
        body: const Center(
          child: Text(
            'Hello, Profile',
            style: TextStyle(fontSize: 24.0),
          ),
        ),
      ),
    );
  }
}