import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OnboardingPageAge extends StatelessWidget {
  final int initialAge;
  final ValueChanged<int> onAgeChanged;

  const OnboardingPageAge({
    super.key,
    required this.initialAge,
    required this.onAgeChanged,
  });

  @override
  Widget build(BuildContext context) {
    int initialIndex = initialAge - 1;
    if (initialIndex < 0) initialIndex = 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "What is your age?",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "$initialAge",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(
          height: 250,
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(initialItem: initialIndex),
            itemExtent: 50.0,
            onSelectedItemChanged: (index) {
              onAgeChanged(index + 1);
            },
            children: List.generate(120, (index) {
              return Center(
                child: Text(
                  "${index + 1}",
                  style: TextStyle(
                    fontSize: 28,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}