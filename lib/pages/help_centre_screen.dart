import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 10),

            _buildFaqSection(context),

            const SizedBox(height: 30),

            Text(
              'Need More Help?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 10),

            _buildContactSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqSection(BuildContext context) {
    return Column(
      children: const [
        _FaqTile(
          question: 'How do I add new health data?',
          answer: 'Go to the Home screen and tap the "Add Data" card, or use the "+" button in the bottom navigation bar to log new records.',
        ),
        _FaqTile(
          question: 'Where can I find my average health metrics?',
          answer: 'Your average heart rate, blood pressure, and BMI are displayed in the "Smart Health Metrics" section on the main Home screen.',
        ),
        _FaqTile(
          question: 'How do I update my medication schedule?',
          answer: 'Navigate to the "Schedule" tab (third icon in the navigation bar) to view, add, or modify your medication reminders.',
        ),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.email, color: Colors.blue),
            title: const Text('Send us an email'),
            subtitle: const Text('helpup@suport.com'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.phone, color: Colors.blue),
            title: const Text('Call our hotline'),
            subtitle: const Text('+38 (011) 123-4567'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}


class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}