import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OnboardingPageHeight extends StatelessWidget {
  final int initialHeight;
  final ValueChanged<int> onHeightChanged;

  const OnboardingPageHeight({
    super.key,
    required this.initialHeight,
    required this.onHeightChanged,
  });

  @override
  Widget build(BuildContext context) {
    int initialIndex = initialHeight - 100;
    if (initialIndex < 0) initialIndex = 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "What is your height?",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "$initialHeight cm",
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
              onHeightChanged(index + 100);
            },
            children: List.generate(151, (index) {
              return Center(
                child: Text(
                  "${index + 100}",
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