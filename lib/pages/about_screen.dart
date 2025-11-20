import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.grey[300] : Colors.grey[800];
    final subTextColor = isDark ? Colors.grey[500] : Colors.grey[600];
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About App'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),


            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.blue.shade600,
            ),
            const SizedBox(height: 10),


            Text(
              'Health App',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 5),


            Text(
              'Version 1.0.0 ',
              style: TextStyle(
                fontSize: 16,
                color: subTextColor,
              ),
            ),

            const SizedBox(height: 40),


            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(isDark ? 0.05 : 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Our Mission',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Health App is designed to help you monitor and manage your key health indicators, including heart rate, blood pressure, sleep, and medication schedules. We empower you to take control of your well-being with simple, accessible tools.',
                    style: TextStyle(fontSize: 15, color: subTextColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Text(
              '© 2025 HealthUp. Made by Natalia Solokha, student of CS-31',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}