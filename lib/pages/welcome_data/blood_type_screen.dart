import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OnboardingPageBloodType extends StatelessWidget {
  final String initialType;
  final String initialRh;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onRhChanged;

  const OnboardingPageBloodType({
    super.key,
    required this.initialType,
    required this.initialRh,
    required this.onTypeChanged,
    required this.onRhChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, int> typeMap = {'A': 0, 'B': 1, 'AB': 2, 'O': 3};
    final Map<String, int> rhMap = {'+': 0, '-': 1};

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "What's your official\nblood type?",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "$initialType$initialRh",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 200,
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: typeMap[initialType] ?? 0,
                ),
                itemExtent: 50.0,
                onSelectedItemChanged: (index) {
                  onTypeChanged(typeMap.keys.elementAt(index));
                },
                children: typeMap.keys.map((type) {
                  return Center(
                    child: Text(
                      type,
                      style: TextStyle(
                        fontSize: 28,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(
              width: 100,
              height: 200,
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: rhMap[initialRh] ?? 0,
                ),
                itemExtent: 50.0,
                onSelectedItemChanged: (index) {
                  onRhChanged(rhMap.keys.elementAt(index));
                },
                children: rhMap.keys.map((rh) {
                  return Center(
                    child: Text(
                      rh,
                      style: TextStyle(
                        fontSize: 28,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}