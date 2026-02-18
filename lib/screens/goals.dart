import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finwise/firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Goal {
  Goal({
    required this.title,
    required this.targetAmount,
    required this.years,
    required this.months,
  });

  final String title;
  final double targetAmount;
  final int years;
  final int months;

  int get totalMonths => (years * 12) + months;
}

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key, required this.uid});

  final String uid;

  @override
  State<GoalsPage> createState() => GoalsPageState();
}

class GoalsPageState extends State<GoalsPage> {
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _yearsController = TextEditingController(
    text: '0',
  );
  final TextEditingController _monthsController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _yearsController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  Future<void> _addGoal() async {
    if (_titleController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _monthsController.text.isEmpty) {
      return;
    }

    final years = int.tryParse(_yearsController.text) ?? 0;
    final months = int.tryParse(_monthsController.text) ?? 0;

    if (months < 0 || months > 11) return;
    if (years == 0 && months == 0) return;

    final goal = Goal(
      title: _titleController.text,
      targetAmount: double.parse(_amountController.text),
      years: years,
      months: months,
    );

    await _firestoreService.addGoal(
      uid: widget.uid,
      data: {
        'title': goal.title,
        'targetAmount': goal.targetAmount,
        'years': goal.years,
        'months': goal.months,
        'totalMonths': goal.totalMonths,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    _titleController.clear();
    _amountController.clear();
    _yearsController.text = '0';
    _monthsController.clear();

    Navigator.pop(context);
  }

  double _calculateProgress(double target, double totalSavings) {
    if (target == 0) return 0;
    return (totalSavings / target).clamp(0, 1);
  }

  Widget _inputField(
    String hint,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters:
            isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  void openAddGoalSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF2F3F7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Goal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B1B3B),
                ),
              ),
              const SizedBox(height: 20),
              _inputField('Goal Title', _titleController),
              _inputField('Target Amount', _amountController, isNumber: true),
              Row(
                children: [
                  Expanded(
                    child: _inputField(
                      'Years (optional)',
                      _yearsController,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _inputField(
                      'Months (0-11)',
                      _monthsController,
                      isNumber: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B1B3B),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _addGoal,
                child: const Text('Save Goal'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _goalCard(Goal goal, int number, double totalSavings) {
    final progress = _calculateProgress(goal.targetAmount, totalSavings);
    final durationText = goal.years == 0
        ? '${goal.months} months'
        : '${goal.years}y ${goal.months}m';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1B3B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ${goal.title}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Target: Rs ${goal.targetAmount.toStringAsFixed(0)} | $durationText',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF7F9C9B)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(progress * 100).toStringAsFixed(1)}% achieved',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userDocStream = _firestoreService.userDocStream(widget.uid);
    final goalsStream = _firestoreService.goalsStream(widget.uid);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Goals',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0B1B3B),
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0B1B3B),
        onPressed: openAddGoalSheet,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: userDocStream,
          builder: (context, userSnapshot) {
            final userData = userSnapshot.data?.data();
            final totalSavingsValue =
                userData?['totalSavings'] ?? userData?['total_savings'] ?? 0;
            final totalSavings = totalSavingsValue is num
                ? totalSavingsValue.toDouble()
                : totalSavingsValue is String
                ? (double.tryParse(totalSavingsValue) ?? 0)
                : 0.0;

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: goalsStream,
              builder: (context, goalsSnapshot) {
                if (!goalsSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final goals = goalsSnapshot.data!.docs
                    .map((doc) {
                      final data = doc.data();
                      final title = (data['title'] as String?)?.trim();
                      final targetAmountRaw = data['targetAmount'];
                      final yearsRaw = data['years'];
                      final monthsRaw = data['months'];

                      if (title == null || title.isEmpty) return null;

                      final targetAmount = targetAmountRaw is num
                          ? targetAmountRaw.toDouble()
                          : targetAmountRaw is String
                          ? double.tryParse(targetAmountRaw)
                          : null;
                      final years = yearsRaw is int
                          ? yearsRaw
                          : int.tryParse('$yearsRaw');
                      final months = monthsRaw is int
                          ? monthsRaw
                          : int.tryParse('$monthsRaw');

                      if (targetAmount == null ||
                          targetAmount <= 0 ||
                          years == null ||
                          months == null ||
                          months < 0 ||
                          months > 11) {
                        return null;
                      }

                      return Goal(
                        title: title,
                        targetAmount: targetAmount,
                        years: years,
                        months: months,
                      );
                    })
                    .whereType<Goal>()
                    .toList();

                goals.sort((a, b) {
                  final timeCompare = a.totalMonths.compareTo(b.totalMonths);
                  if (timeCompare != 0) return timeCompare;
                  return a.targetAmount.compareTo(b.targetAmount);
                });

                if (goals.isEmpty) {
                  return const Center(
                    child: Text(
                      'No Goals Added',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    return _goalCard(goals[index], index + 1, totalSavings);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
