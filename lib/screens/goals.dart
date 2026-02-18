import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Goal {
  String title;
  double targetAmount;
  int years;
  int months;

  Goal({
    required this.title,
    required this.targetAmount,
    required this.years,
    required this.months,
  });

  int get totalMonths => (years * 12) + months;
}

class GoalsPage extends StatefulWidget {
  const GoalsPage({Key? key}) : super(key: key);

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  final List<Goal> _goals = [];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _yearsController =
      TextEditingController(text: "0"); // Default 0
  final TextEditingController _monthsController = TextEditingController();

  double _totalSavings = 0;

  final String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _fetchTotalSavings();
  }

  Future<void> _fetchTotalSavings() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    setState(() {
      _totalSavings =
          (doc.data()?['totalSavings'] ?? 0).toDouble();
    });
  }

  void _addGoal() {
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

    setState(() {
      _goals.add(goal);
      _sortGoals();
    });

    _titleController.clear();
    _amountController.clear();
    _yearsController.text = "0"; // Reset to default
    _monthsController.clear();

    Navigator.pop(context);
  }

  void _sortGoals() {
    _goals.sort((a, b) {
      int timeCompare = a.totalMonths.compareTo(b.totalMonths);
      if (timeCompare != 0) return timeCompare;
      return a.targetAmount.compareTo(b.targetAmount);
    });
  }

  double _calculateProgress(double target) {
    if (target == 0) return 0;
    return (_totalSavings / target).clamp(0, 1);
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
        keyboardType:
            isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters:
            isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  void _showAddGoalSheet() {
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
              top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Add Goal",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B1B3B)),
              ),
              const SizedBox(height: 20),

              _inputField("Goal Title", _titleController),
              _inputField("Target Amount", _amountController,
                  isNumber: true),

              Row(
                children: [
                  Expanded(
                    child: _inputField(
                        "Years (optional)", _yearsController,
                        isNumber: true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _inputField(
                        "Months (0-11)", _monthsController,
                        isNumber: true),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B1B3B),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _addGoal,
                child: const Text("Save Goal"),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _goalCard(Goal goal, int number) {
    final progress = _calculateProgress(goal.targetAmount);

    String durationText;
    if (goal.years == 0) {
      durationText = "${goal.months} months";
    } else {
      durationText = "${goal.years}y ${goal.months}m";
    }

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
            "$number. ${goal.title}",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Target: ₹${goal.targetAmount.toStringAsFixed(0)} | $durationText",
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(
                Color(0xFF7F9C9B),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "${(progress * 100).toStringAsFixed(1)}% achieved",
            style: const TextStyle(color: Colors.white70),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Goals",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B1B3B)),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0B1B3B),
        onPressed: _showAddGoalSheet,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _goals.isEmpty
            ? const Center(
                child: Text(
                  "No Goals Added",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: _goals.length,
                itemBuilder: (context, index) {
                  return _goalCard(_goals[index], index + 1);
                },
              ),
      ),
    );
  }
}
