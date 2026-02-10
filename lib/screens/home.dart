import 'package:finwise/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'profile.dart';
import 'chat.dart';

class Home extends StatelessWidget {
  const Home({super.key, required this.uid});

  final String uid;

  String _getGreeting(String username) {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, $username';
    if (hour < 18) return 'Good afternoon, $username';
    return 'Good evening, $username';
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFFE7E9ED),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: firestoreService.userDocStream(uid),
          builder: (context, userSnapshot) {
            final userData = userSnapshot.data?.data();
            final username = (userData?['username'] as String?)?.trim();
            final displayName = (username != null && username.isNotEmpty)
                ? username
                : 'User';

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: firestoreService.transactionsStream(uid),
              builder: (context, txSnapshot) {
                final docs = txSnapshot.data?.docs ?? [];
                final balance = docs.fold<double>(0, (sum, doc) {
                  final amount = doc.data()['amount'];
                  if (amount is num) return sum + amount.toDouble();
                  if (amount is String) {
                    return sum + (double.tryParse(amount) ?? 0);
                  }
                  return sum;
                });

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting('').replaceAll(', ', ''),
                        style: const TextStyle(
                          fontSize: 20,
                          color: Color(0xFF4D5F7A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),

                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Profile(uid: uid),
                            ),
                          );
                        },
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 46,
                            color: Color(0xFF121B30),
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 26,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF06163A),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Available balance',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFFB5C2DB),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '₹${balance.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 46,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 34),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GeminiChatPage(),
                            ),
                          );
                        },
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(22),
                        ),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFA1C7C7),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  18,
                                  14,
                                  16,
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'ASK AI COACH',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 36,
                                      width: 36,
                                      // Placeholder icon path for AI widget header.
                                      child: SvgPicture.asset(
                                        'assets/Icons/google.svg',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF9BAEBB),
                                  borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(22),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Ask me anything about your money...',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF24313D),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Icon(
                                      Icons.send,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
