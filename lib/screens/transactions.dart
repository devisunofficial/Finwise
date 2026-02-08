import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finwise/firestore.dart';
import 'add_trans.dart';

Widget monthHeader(DateTime date) {
  const months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: months[date.month - 1],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const TextSpan(text: " "),
          TextSpan(
            text: date.year.toString(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withValues(alpha: .5),
            ),
          ),
        ],
      ),
    ),
  );
}

class Transactions extends StatefulWidget {
  const Transactions({super.key, required this.uid});

  final String uid;

  @override
  State<Transactions> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<Transactions> {
  int? expandedIndex;
  String? expandedDocId;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Transactions",
          style: TextStyle(
            fontSize: 24, // 👈 increase this
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestoreService.transactionsStream(widget.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
          grouped = {};

          for (var doc in docs) {
            final data = doc.data();
            final date = (data['timestamp'] as Timestamp).toDate();

            final key = monthKey(date);

            grouped.putIfAbsent(key, () => []).add(doc);
          }

          return ListView(
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 👇 DEFINE firstDate BEFORE using it
                  Builder(
                    builder: (context) {
                      final firstDoc = entry.value.first;
                      final firstDate =
                          ((firstDoc.data())['timestamp']
                                  as Timestamp)
                              .toDate();

                      return monthHeader(firstDate);
                    },
                  ),

                  /// 📦 TRANSACTIONS
                  ...entry.value.map((doc) {
                    final data = doc.data();

                    return TransactionTile(
                      docId: doc.id,
                      data: data,
                      isExpanded: expandedDocId == doc.id,
                      onTap: () {
                        setState(() {
                          expandedDocId = expandedDocId == doc.id
                              ? null
                              : doc.id;
                        });
                      },
                      onLongPress: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddTransactionPage(
                              uid: widget.uid,
                              docId: doc.id,
                              existingData: data,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              );
            }).toList(),
          );
        },
      ),

      /// ➕ ADD BUTTON (RESTORED)
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0B7D6E),
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTransactionPage(uid: widget.uid),
            ),
          );
        },
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const TransactionTile({
    super.key,
    required this.docId,
    required this.data,
    required this.isExpanded,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = data['timestamp'] as Timestamp;
    final dateTime = timestamp.toDate();

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(backgroundColor: _getColor(data['color'])),
            title: Text(
              data['title'],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              "${dateTime.day}/${dateTime.month}/${dateTime.year}",
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "₹${data['amount']}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),

                /// 🔄 Arrow animation
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down),
                ),
              ],
            ),
          ),

          /// 📦 Expandable content
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _info("Amount", "₹${data['amount']}"),
                        _info("Category", data['category']),
                        _info(
                          "Date & Time",
                          "${dateTime.day}/${dateTime.month}/${dateTime.year} • "
                              "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}",
                        ),
                        _info(
                          "Status",
                          data['status'],
                          color: data['status'] == "Overspend"
                              ? Colors.red
                              : Colors.green,
                        ),

                        if (data['note'] != null &&
                            data['note'].toString().isNotEmpty)
                          _info("Note", data['note']),
                      ],
                    ),
                  )
                : const SizedBox(),
          ),

          const Divider(),
        ],
      ),
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

String dateHeader(DateTime date) {
  final now = DateTime.now();

  if (DateUtils.isSameDay(date, now)) {
    return "Today";
  } else if (DateUtils.isSameDay(date, now.subtract(const Duration(days: 1)))) {
    return "Yesterday";
  } else {
    return "${date.day}/${date.month}/${date.year}";
  }
}

String monthKey(DateTime date) {
  return "${date.year}-${date.month}";
}

Map<String, String> monthLabel(DateTime date) {
  const months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

  return {"month": months[date.month - 1], "year": date.year.toString()};
}
