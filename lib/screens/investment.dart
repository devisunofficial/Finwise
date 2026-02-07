import 'package:flutter/material.dart';

class Investment extends StatelessWidget {
  const Investment({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('InvestMent'),
          backgroundColor: Colors.blue,
        ),
        body: const Center(
          child: Text(
            'Hello, InvestMent',
            style: TextStyle(fontSize: 24.0),
          ),
        ),
      ),
    );
  }
}