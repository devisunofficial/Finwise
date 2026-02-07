import 'package:flutter/material.dart';

class Goals extends StatelessWidget {
  const Goals({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Goals'),
          backgroundColor: Colors.blue,
        ),
        body: const Center(
          child: Text(
            'Hello, Goals',
            style: TextStyle(fontSize: 24.0),
          ),
        ),
      ),
    );
  }
}