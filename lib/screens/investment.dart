import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finwise/firestore.dart';

class InvestmentEntry {
  InvestmentEntry({
    required this.name,
    required this.amount,
    required this.type,
  });

  final String name;
  final double amount;
  final String type;
}

class Investment extends StatefulWidget {
  const Investment({super.key, required this.uid});

  final String uid;

  @override
  State<Investment> createState() => InvestmentPageState();
}

class InvestmentPageState extends State<Investment> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedType = 'Mutual Fund';

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void openAddInvestmentSheet() {
    _nameController.clear();
    _amountController.clear();
    _selectedType = 'Mutual Fund';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF2F3F7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Investment',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B1B3B),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Investment name',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Amount',
                      prefixText: 'Rs ',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedType,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'Mutual Fund',
                            child: Text('Mutual Fund'),
                          ),
                          DropdownMenuItem(
                            value: 'Stocks',
                            child: Text('Stocks'),
                          ),
                          DropdownMenuItem(value: 'ETF', child: Text('ETF')),
                          DropdownMenuItem(value: 'Gold', child: Text('Gold')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => _selectedType = value);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveInvestment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B1B3B),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Save Investment'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveInvestment() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (name.isEmpty || amount == null || amount <= 0) return;

    await _firestoreService.addInvestment(
      uid: widget.uid,
      data: {
        'name': name,
        'amount': amount,
        'type': _selectedType,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      appBar: AppBar(
        title: const Text('Investments'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openAddInvestmentSheet,
        backgroundColor: const Color(0xFF0B1B3B),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestoreService.investmentsStream(widget.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data!.docs
              .map((doc) {
                final data = doc.data();
                final name = (data['name'] as String?)?.trim();
                final amountRaw = data['amount'];
                final type = (data['type'] as String?)?.trim();

                final amount = amountRaw is num
                    ? amountRaw.toDouble()
                    : amountRaw is String
                    ? double.tryParse(amountRaw)
                    : null;

                if (name == null ||
                    name.isEmpty ||
                    type == null ||
                    type.isEmpty ||
                    amount == null ||
                    amount <= 0) {
                  return null;
                }

                return InvestmentEntry(name: name, amount: amount, type: type);
              })
              .whereType<InvestmentEntry>()
              .toList();

          if (entries.isEmpty) {
            return const Center(
              child: Text(
                'No investments yet',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0x1A0B1B3B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        color: Color(0xFF0B1B3B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            entry.type,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rs ${entry.amount.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
