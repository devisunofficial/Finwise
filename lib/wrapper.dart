import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finwise/authenticate/auth.dart';
import 'package:finwise/authenticate/login.dart';
import 'package:finwise/firestore.dart';
import 'package:finwise/screens/add_trans.dart';
import 'package:finwise/screens/goals.dart';
import 'package:finwise/screens/home.dart';
import 'package:finwise/screens/investment.dart';
import 'package:finwise/screens/signup_profile.dart';
import 'package:finwise/screens/transactions.dart';
import 'package:flutter/material.dart';

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

              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: firestoreService.userDocStream(user.uid),
                builder: (context, profileSnapshot) {
                  if (!profileSnapshot.hasData) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final userData = profileSnapshot.data?.data();
                  final isProfileCompleted =
                      userData?['profile_completed'] == true;

                  if (!isProfileCompleted) {
                    return SignupProfilePage(uid: user.uid);
                  }

                  return HomePage(uid: user.uid);
                },
              );
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
  bool _isFabMenuOpen = false;
  final FirestoreService _firestoreService = FirestoreService();
  final GlobalKey<GoalsPageState> _goalsPageKey = GlobalKey<GoalsPageState>();
  final GlobalKey<InvestmentPageState> _investmentPageKey =
      GlobalKey<InvestmentPageState>();

  List<Widget> get _screens => [
    Home(uid: widget.uid),
    Transactions(uid: widget.uid),
    GoalsPage(key: _goalsPageKey, uid: widget.uid),
    Investment(key: _investmentPageKey, uid: widget.uid),
  ];

  @override
  void initState() {
    super.initState();
    _applyDueMonthlyCreditsOnce();
  }

  Future<void> _applyDueMonthlyCreditsOnce() async {
    try {
      await _firestoreService.applyDueMonthlyCredits(uid: widget.uid);
    } catch (_) {
      // Ignore transient failures; this can run again on next app open.
    }
  }

  void _closeFabMenu() {
    if (_isFabMenuOpen) {
      setState(() => _isFabMenuOpen = false);
    }
  }

  void _toggleFabMenu() {
    setState(() => _isFabMenuOpen = !_isFabMenuOpen);
  }

  void _selectTab(int index) {
    _closeFabMenu();
    setState(() => _currentIndex = index);
  }

  Future<void> _openAddTransaction() async {
    _closeFabMenu();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTransactionPage(uid: widget.uid),
      ),
    );
  }

  void _openAddGoal() {
    _closeFabMenu();
    setState(() => _currentIndex = 2);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goalsPageKey.currentState?.openAddGoalSheet();
    });
  }

  void _openAddInvestment() {
    _closeFabMenu();
    setState(() => _currentIndex = 3);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _investmentPageKey.currentState?.openAddInvestmentSheet();
    });
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isActive = _currentIndex == index;
    final color = isActive ? const Color(0xFF0B1B3B) : Colors.grey.shade600;

    return Expanded(
      child: InkWell(
        onTap: () => _selectTab(index),
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 70,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isActive ? activeIcon : icon, color: color, size: 23),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFabMenu() {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FabMenuItem(
            icon: Icons.receipt_long_rounded,
            label: 'Add transaction',
            onTap: _openAddTransaction,
          ),
          _FabMenuItem(
            icon: Icons.flag_circle_rounded,
            label: 'Add goal',
            onTap: _openAddGoal,
          ),
          _FabMenuItem(
            icon: Icons.trending_up_rounded,
            label: 'Add new investment',
            onTap: _openAddInvestment,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          if (_isFabMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeFabMenu,
                child: Container(color: Colors.black54),
              ),
            ),
          if (_isFabMenuOpen)
            Positioned(
              left: 0,
              right: 0,
              bottom: 94,
              child: Center(child: _buildFabMenu()),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 66,
        height: 66,
        child: FloatingActionButton(
          onPressed: _toggleFabMenu,
          backgroundColor: const Color(0xFF0B1B3B),
          shape: const CircleBorder(),
          elevation: 6,
          child: AnimatedRotation(
            turns: _isFabMenuOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 220),
            child: const Icon(Icons.add, color: Colors.white, size: 34),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 10,
        color: Colors.white,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              _buildNavItem(
                index: 0,
                label: 'Home',
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
              ),
              _buildNavItem(
                index: 1,
                label: 'Transaction',
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
              ),
              const SizedBox(width: 70),
              _buildNavItem(
                index: 2,
                label: 'Goals',
                icon: Icons.flag_outlined,
                activeIcon: Icons.flag_rounded,
              ),
              _buildNavItem(
                index: 3,
                label: 'Investment',
                icon: Icons.trending_up_outlined,
                activeIcon: Icons.trending_up_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FabMenuItem extends StatelessWidget {
  const _FabMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0x1A0B1B3B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 19, color: const Color(0xFF0B1B3B)),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF0B1B3B),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
