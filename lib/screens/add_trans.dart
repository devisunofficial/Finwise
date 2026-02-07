import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  String selectedCategory = "Food";
  DateTime selectedDateTime = DateTime.now();

  final List<String> categories = [
    "Grocery",
    "Food",
    "Travel",
    "Shopping"
  ];

  /// 🔹 Pick Date
  Future<void> pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
    );

    if (time == null) return;

    setState(() {
      selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  /// 🔹 Save to Firestore
  Future<void> saveTransaction() async {
    if (amountController.text.isEmpty) return;

    final amount = int.parse(amountController.text);

    await FirebaseFirestore.instance.collection('transactions').add({
      "title": selectedCategory,
      "amount": amount,
      "category": selectedCategory,
      "note": noteController.text,
      "timestamp": selectedDateTime,
      "status": amount > 2000 ? "Overspend" : "Normal",
      "color": amount > 2000 ? "red" : "green",
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Transactions"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 💰 AMOUNT
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                prefixText: "₹ ",
                hintText: "0.00",
                border: InputBorder.none,
              ),
            ),

            const SizedBox(height: 24),

            /// 📂 CATEGORY
            const Text("Select Category",
                style: TextStyle(fontWeight: FontWeight.w600)),

            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: categories.map((cat) {
                final isSelected = selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: const Color(0xFF0B7D6E),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                  onSelected: (_) {
                    setState(() => selectedCategory = cat);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            /// ⏰ DATE & TIME
            const Text("Date & Time"),
            const SizedBox(height: 8),
            InkWell(
              onTap: pickDateTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year} • "
                  "${selectedDateTime.hour}:${selectedDateTime.minute.toString().padLeft(2, '0')}",
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// 📝 NOTE
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: "Add a short note (e.g. groceries, fuel)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 40),

            /// ✅ SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Add Transaction",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
