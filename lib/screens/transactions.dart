import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_trans.dart';

class Transactions extends StatelessWidget {
  const Transactions({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Transactions",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        shape: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: .3),)),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No transactions found"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final data =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;

              return TransactionTile(data: data);
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0B7D6E),
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionPage()),
          );
        },
      ),
    );
  }
}

class TransactionTile extends StatefulWidget {
  final Map<String, dynamic> data;

  const TransactionTile({super.key, required this.data});

  @override
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final color = _getColor(widget.data['color']);
    final timestamp = widget.data['timestamp'] as Timestamp;
    final dateTime = timestamp.toDate();

    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(backgroundColor: color),
          title: Text(
            widget.data['title'],
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text("${dateTime.day} Jan ${dateTime.year}"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "\$₹{widget.data['amount']}",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
                onPressed: () {
                  setState(() {
                    expanded = !expanded;
                  });
                },
              ),
            ],
          ),
        ),

        /// 🔹 EXPANDED DETAILS
        AnimatedCrossFade(
          firstChild: const SizedBox(),
          secondChild: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _info("Amount", "\$${widget.data['amount']}"),
                _info("Category", widget.data['category']),
                _info(
                  "Date & Time",
                  "${dateTime.day} Jan ${dateTime.year} • "
                      "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}",
                ),
                _info(
                  "Status",
                  widget.data['status'],
                  color: widget.data['status'] == "Overspend"
                      ? Colors.red
                      : Colors.green,
                ),
              ],
            ),
          ),
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),

        const Divider(),
      ],
    );
  }

  Widget _info(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text("$label: $value", style: TextStyle(color: color)),
    );
  }

  Color _getColor(String value) {
    switch (value) {
      case "green":
        return Colors.green;
      case "red":
        return Colors.red;
      case "yellow":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
