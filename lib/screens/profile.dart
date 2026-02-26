import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finwise/firestore.dart';
import 'package:logger/logger.dart';

// One instance to rule them all
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,    // Number of method calls to be displayed
    errorMethodCount: 8, // Number of method calls if stacktrace is provided
    lineLength: 120,   // Width of the output
    colors: true,      // Colorful log messages
    printEmojis: true, // Print an emoji for each log message
  ),
);

class Profile extends StatefulWidget {
  final String uid;
  const Profile({super.key, required this.uid});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _monthlyEarningsController =
      TextEditingController();
  final TextEditingController _creditDateController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  int? _creditDay;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _ageController.dispose();
    _monthlyEarningsController.dispose();
    _creditDateController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
  setState(() => _isLoading = true);

  try {
    // 1. Fetching Data
    final snapshot = await _firestoreService.userDoc(widget.uid).get();
    final data = snapshot.data();

    if (data != null) {
      _usernameController.text = _asText(data['username']);
      _ageController.text = _asText(data['age']);
      _monthlyEarningsController.text = _asText(
        data['monthly_earnings'] ?? data['monthly earnings'],
      );
      _creditDay = _parseCreditDay(
        data['credit_day'] ?? data['credit date'],
      );
      _creditDateController.text = _formatCreditDay(_creditDay);
    }
  } catch (e, stackTrace) {
    // 2. Logging instead of printing
    logger.e("Firestore error", error: e, stackTrace: stackTrace);
  } finally {
    // 3. Safe cleanup: Check mounted status without using 'return'
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  String _asText(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    if (value is num) return value.toString();
    return value.toString();
  }

  int? _parseCreditDay(dynamic value) {
    if (value is int && value >= 1 && value <= 31) {
      return value;
    }
    if (value is Timestamp) {
      final day = value.toDate().day;
      return day >= 1 && day <= 31 ? day : null;
    }
    if (value is DateTime) {
      final day = value.day;
      return day >= 1 && day <= 31 ? day : null;
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      final plainDay = int.tryParse(trimmed);
      if (plainDay != null && plainDay >= 1 && plainDay <= 31) {
        return plainDay;
      }
      final parsedDate = _parseCreditDate(trimmed);
      if (parsedDate != null) {
        return parsedDate.day;
      }
    }
    return null;
  }

  String _formatCreditDay(int? day) {
    if (day == null) return '';
    return day.toString().padLeft(2, '0');
  }

  DateTime? _parseCreditDate(String value) {
    if (value.isEmpty) return null;

    final slashParts = value.split('/');
    if (slashParts.length == 3) {
      final day = int.tryParse(slashParts[0]);
      final month = int.tryParse(slashParts[1]);
      final year = int.tryParse(slashParts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return DateTime.tryParse(value);
  }

  Future<void> _pickCreditDate() async {
    final now = DateTime.now();
    final existingDate = _creditDay != null
        ? DateTime(now.year, now.month, _creditDay!)
        : _parseCreditDate(_creditDateController.text);
    final initialDate = existingDate ?? now;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) return;
    _creditDay = selectedDate.day;
    _creditDateController.text = _formatCreditDay(_creditDay);
  }

  Future<void> _saveProfile() async {
    final username = _usernameController.text.trim();
    final ageText = _ageController.text.trim();
    final earningsText = _monthlyEarningsController.text.trim();
    final parsedAge = ageText.isEmpty ? null : int.tryParse(ageText);
    final parsedEarnings = earningsText.isEmpty
        ? null
        : num.tryParse(earningsText);
    final parsedCreditDay = _creditDay ??
        (int.tryParse(_creditDateController.text.trim()));

    if (parsedAge == null || parsedAge < 0) {
      _showSnack('Enter a valid age.');
      return;
    }
    if (parsedEarnings == null || parsedEarnings < 0) {
      _showSnack('Enter valid monthly earnings.');
      return;
    }
    if (parsedCreditDay == null || parsedCreditDay < 1 || parsedCreditDay > 31) {
      _showSnack('Select a valid credit day (1-31).');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _firestoreService.userDoc(widget.uid).set({
        'username': username.isEmpty ? 'User' : username,
        'age': parsedAge,
        'monthly_earnings': parsedEarnings,
        'credit_day': parsedCreditDay,
      }, SetOptions(merge: true));
      await _firestoreService.applyDueMonthlyCredits(uid: widget.uid);
      if (!mounted) return;
      _showSnack('Profile saved.');
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/wrapper',
          (route) => false,
        );
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('Failed to save profile.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Section(title: "Personal Information", children: [
                  _InputTile(
                    icon: Icons.person_outline,
                    label: "Name",
                    hint: "Enter your name",
                    keyboardType: TextInputType.name,
                    controller: _usernameController,
                  ),
                  _InputTile(
                    icon: Icons.cake_outlined,
                    label: "Age",
                    hint: "Enter your age",
                    keyboardType: TextInputType.number,
                    controller: _ageController,
                  ),
                ]),
                const SizedBox(height: 16),
                _Section(title: "Financial Information", children: [
                  _InputTile(
                    icon: Icons.currency_rupee,
                    label: "Monthly Earnings",
                    hint: " 0.00",
                    keyboardType: TextInputType.number,
                    controller: _monthlyEarningsController,
                  ),
                  _InputTile(
                    icon: Icons.calendar_today_outlined,
                    label: "Credit date",
                    hint: "DD",
                    keyboardType: TextInputType.number,
                    controller: _creditDateController,
                    readOnly: true,
                    onTap: _pickCreditDate,
                  ),
                  const _NavigationTile(
                    icon: Icons.bar_chart,
                    label: "Monthly Reports",
                  ),
                ]),
                const SizedBox(height: 16),
                const _Section(title: "Security", children: [
                  _NavigationTile(
                    icon: Icons.lock_outline,
                    label: "Change Password",
                  ),
                  _DangerTile(
                    icon: Icons.delete_outline,
                    label: "Delete Account",
                  ),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    child: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Save Profile"),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InputTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final TextEditingController controller;
  final bool readOnly;
  final VoidCallback? onTap;

  const _InputTile({
    required this.icon,
    required this.label,
    required this.hint,
    required this.keyboardType,
    required this.controller,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          icon: Icon(icon),
          labelText: label,
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _NavigationTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}


class _DangerTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DangerTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.red),
      title: Text(
        label,
        style: const TextStyle(color: Colors.red),
      ),
      onTap: () {
        // show confirmation dialog
      },
    );
  }

}


