import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finwise/firestore.dart';

class SignupProfilePage extends StatefulWidget {
  const SignupProfilePage({super.key, required this.uid});

  final String uid;

  @override
  State<SignupProfilePage> createState() => _SignupProfilePageState();
}

class _SignupProfilePageState extends State<SignupProfilePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController salaryController = TextEditingController();

  int? _creditDay;
  bool _isSaving = false;

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    salaryController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final username = nameController.text.trim().isEmpty
        ? 'User'
        : nameController.text.trim();
    final age = int.tryParse(ageController.text.trim());
    final monthlyEarnings = num.tryParse(salaryController.text.trim());

    if (age == null || age < 0) {
      _showSnack('Enter a valid age.');
      return;
    }

    if (monthlyEarnings == null || monthlyEarnings < 0) {
      _showSnack('Enter valid monthly earnings.');
      return;
    }

    if (_creditDay == null || _creditDay! < 1 || _creditDay! > 31) {
      _showSnack('Select a valid salary credit day.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _firestoreService.userDoc(widget.uid).set({
        'username': username,
        'age': age,
        'monthly_earnings': monthlyEarnings,
        'credit_day': _creditDay,
        'profile_completed': true,
      }, SetOptions(merge: true));

      await _firestoreService.applyDueMonthlyCredits(uid: widget.uid);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/wrapper', (route) => false);
    } catch (_) {
      if (mounted) {
        _showSnack('Failed to save profile.');
      }
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
          'Set up your profile',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'Personal Information',
            children: [
              _InputTile(
                controller: nameController,
                icon: Icons.person_outline,
                label: 'Full Name',
                hint: 'Enter your name',
                keyboardType: TextInputType.name,
              ),
              _InputTile(
                controller: ageController,
                icon: Icons.cake_outlined,
                label: 'Age',
                hint: 'Enter your age',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Financial Information',
            children: [
              _InputTile(
                controller: salaryController,
                icon: Icons.currency_rupee,
                label: 'Monthly Earnings',
                hint: '0.00',
                keyboardType: TextInputType.number,
              ),
              _DateTile(
                icon: Icons.calendar_month_outlined,
                label: 'Salary Credit Date',
                selectedDay: _creditDay,
                onDaySelected: (day) {
                  setState(() {
                    _creditDay = day;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          _ContinueButton(
            isSaving: _isSaving,
            onPressed: _saveProfile,
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
  final TextEditingController controller;
  final IconData icon;
  final String label;
  final String hint;
  final TextInputType keyboardType;

  const _InputTile({
    required this.controller,
    required this.icon,
    required this.label,
    required this.hint,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
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

class _DateTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? selectedDay;
  final ValueChanged<int> onDaySelected;

  const _DateTile({
    required this.icon,
    required this.label,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(
        selectedDay == null
            ? 'Select date'
            : 'Day ${selectedDay!.toString().padLeft(2, '0')}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final now = DateTime.now();
        final initialDay = selectedDay ?? now.day;
        final initialDate = DateTime(now.year, now.month, initialDay);

        final date = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );

        if (date != null) {
          onDaySelected(date.day);
        }
      },
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.onPressed,
    required this.isSaving,
  });

  final VoidCallback onPressed;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0A1A33),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: isSaving ? null : onPressed,
        child: isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
