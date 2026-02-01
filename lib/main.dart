import 'package:flutter/material.dart';
import 'home.dart';
import 'transactions.dart';
import 'goals.dart';
import 'investment.dart';
import 'login.dart';
import 'add.dart';
import 'splash_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FinWise',
      // Set the Splash Screen as the starting point
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const Login(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  List<Widget> widgetList = const [
    Home(),
    Transactions(),
    Add(),
    Goals(),
    Investment(),
  ];
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
