import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('HomePage'),
          backgroundColor: Colors.blue,
        ),
        body: const Center(
          child: Text(
            'Hello, HomePage',
            style: TextStyle(fontSize: 24.0),
          ),
        ),
      ),
    );
  }
}