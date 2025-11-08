import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OnboardingPageSugar extends StatelessWidget {
  final double initialSugar;
  final ValueChanged<double> onSugarChanged;

  const OnboardingPageSugar({
    super.key,
    required this.initialSugar,
    required this.onSugarChanged,
  });

  @override
  Widget build(BuildContext context) {
    int initialIndex = (initialSugar * 10).toInt() - 20;
    if (initialIndex < 0) initialIndex = 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "What is your sugar level?",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          "${initialSugar.toStringAsFixed(1)} mmol/L",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        SizedBox(
          height: 250,
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(initialItem: initialIndex),
            itemExtent: 50.0,
            onSelectedItemChanged: (index) {
              onSugarChanged((index + 20) / 10.0);
            },
            children: List.generate(181, (index) {
              final value = (index + 20) / 10.0;
              return Center(
                child: Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 28),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}