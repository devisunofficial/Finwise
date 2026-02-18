import 'package:finwise/screens/home.dart';
import 'package:finwise/authenticate/auth.dart';
import 'package:finwise/authenticate/login.dart';
import 'package:finwise/firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'screens/add.dart';
import 'screens/goals.dart';
import 'screens/investment.dart';
import 'screens/transactions.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();

    return StreamBuilder<User?>(
      stream: authService.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          return FutureBuilder<void>(
            future: firestoreService.ensureUserDoc(
              uid: user.uid,
              email: user.email ?? '',
            ),
            builder: (context, userDocSnapshot) {
              if (userDocSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              return HomePage(uid: user.uid);
            },
          );
        }

        return const Login();
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.uid});

  final String uid;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late final List<Widget> widgetList;

  @override
  void initState() {
    super.initState();
    widgetList = [
      Home(uid: widget.uid),
      Transactions(uid: widget.uid),
      const Add(),
      const GoalsPage(),
      const Investment(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widgetList[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_filled),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_outlined),
            activeIcon: Icon(Icons.inventory),
            label: 'Transaction',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            activeIcon: Icon(Icons.add_a_photo_outlined),
            label: 'Add',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.games_outlined),
            activeIcon: Icon(Icons.games_rounded),
            label: 'Goals',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.functions_rounded),
            activeIcon: Icon(Icons.mark_chat_read),
            label: 'InvestMents',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            // Assume the middle button triggers the menu
            _showPopupMenu(context);
            Icon(Icons.add);
          } else {
            setState(() => _currentIndex = index);
          }
        },
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

// PopUP Menu Of navigation Bar
void _showPopupMenu(BuildContext context) async {
  // This positions the menu above the bottom bar
  await showMenu(
    context: context,
    position: RelativeRect.fromLTRB(100.0, 600.0, 100.0, 0.0), // Adjust coordinates
    items: [
      const PopupMenuItem(value: 1, child: Text("Transaction")),
      const PopupMenuItem(value: 2, child: Text("Goal")),
      const PopupMenuItem(value: 2, child: Text("Investment")),
    ],
    elevation: 100.0,
  );
}
