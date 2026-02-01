import 'package:flutter/material.dart';

class Transactions extends StatelessWidget {
  const Transactions({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Transaction'),
          backgroundColor: Colors.blue,
        ),
        body: const Center(
          child: Text(
            'Hello, Transaction',
            style: TextStyle(fontSize: 24.0),
          ),
        ),
      ),
    );
  }
}