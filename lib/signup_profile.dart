import 'package:flutter/material.dart';

class SignupProfilePage extends StatefulWidget {
  const SignupProfilePage({super.key});

  @override
  State<SignupProfilePage> createState() => _SignupProfilePageState();
}

class _SignupProfilePageState extends State<SignupProfilePage> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final salaryController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text(
          "Set up your profile",
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
            title: "Personal Information",
            children: [
              _InputTile(
                controller: nameController,
                icon: Icons.person_outline,
                label: "Full Name",
                hint: "Enter your name",
                keyboardType: TextInputType.name,
              ),
              _InputTile(
                controller: ageController,
                icon: Icons.cake_outlined,
                label: "Age",
                hint: "Enter your age",
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: "Financial Information",
            children: [
              _InputTile(
                controller: salaryController,
                icon: Icons.currency_rupee,
                label: "Monthly Earnings",
                hint: "₹ 0.00",
                keyboardType: TextInputType.number,
              ),
              const _DateTile(
                icon: Icons.calendar_month_outlined,
                label: "Salary Credit Date",
              ),
            ],
          ),
          const SizedBox(height: 32),
          const _ContinueButton(),
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
class _DateTile extends StatefulWidget {
  final IconData icon;
  final String label;

  const _DateTile({
    required this.icon,
    required this.label,
  });

  @override
  State<_DateTile> createState() => _DateTileState();
}

class _DateTileState extends State<_DateTile> {
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(widget.icon),
      title: Text(widget.label),
      subtitle: Text(
        selectedDate == null
            ? "Select date"
            : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );

        if (!mounted) return;

        if (date != null) {
          setState(() {
            selectedDate = date;
          });
        }
      },
    );
  }
}
class _ContinueButton extends StatelessWidget {
  const _ContinueButton();

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
        onPressed: () {
        },
        child: const Text(
          "Continue",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
