import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OnboardingPageWeight extends StatelessWidget {
  final int initialWeight;
  final ValueChanged<int> onWeightChanged;

  const OnboardingPageWeight({
    super.key,
    required this.initialWeight,
    required this.onWeightChanged,
  });

  @override
  Widget build(BuildContext context) {
    int initialIndex = initialWeight - 30;
    if (initialIndex < 0) initialIndex = 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "What is your weight?",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "$initialWeight kg",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 48,
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
              onWeightChanged(index + 30);
            },
            children: List.generate(171, (index) {
              return Center(
                child: Text(
                  "${index + 30}",
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