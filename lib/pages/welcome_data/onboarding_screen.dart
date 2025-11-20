import 'package:flutter/material.dart';
import 'package:health_up/pages/welcome_data/sugar_screen.dart';
import 'package:health_up/pages/welcome_data/weight_screen.dart';
import 'package:health_up/services/user_data_service.dart';
import '../../main.dart';
import 'age_screen.dart';
import 'blood_type_screen.dart';
import 'height_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const OnboardingScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  final int _numPages = 5;

  int _age = 16;
  int _weight = 70;
  int _height = 170;
  double _sugar = 5.5;
  String _bloodType = 'A';
  String _bloodRh = '+';

  void _showSnackBar(String message, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(context).colorScheme.error : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _numPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      _submitData();
    }
  }

  void _skipOnboarding() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(
          userId: widget.userId,
          userName: widget.userName,
        ),
      ),
          (route) => false,
    );
  }

  Future<void> _submitData() async {
    setState(() => _isLoading = true);

    final String bloodTypeString =
        "${_bloodType}_${_bloodRh == '+' ? 'Positive' : 'Negative'}";

    final response = await UserDataService.addAnthropometry(
      userId: widget.userId,
      measuredAt: DateTime.now(),
      weight: _weight.toDouble(),
      height: _height.toDouble(),
      sugar: _sugar,
      bloodType: bloodTypeString,
      age: _age,
    );

    setState(() => _isLoading = false);

    if (response['success'] == true) {
      _skipOnboarding();
    } else {
      _showSnackBar(response['message'] ?? "Failed to save data");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: _currentPage == 0
            ? null
            : IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _skipOnboarding,
            child: Text(
              'Skip',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            Row(
              children: List.generate(_numPages, (index) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: _currentPage >= index
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                );
              }),
            ),


            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  OnboardingPageAge(
                    initialAge: _age,
                    onAgeChanged: (val) => setState(() => _age = val),
                  ),
                  OnboardingPageWeight(
                    initialWeight: _weight,
                    onWeightChanged: (val) => setState(() => _weight = val),
                  ),
                  OnboardingPageHeight(
                    initialHeight: _height,
                    onHeightChanged: (val) => setState(() => _height = val),
                  ),
                  OnboardingPageSugar(
                    initialSugar: _sugar,
                    onSugarChanged: (val) => setState(() => _sugar = val),
                  ),
                  OnboardingPageBloodType(
                    initialType: _bloodType,
                    initialRh: _bloodRh,
                    onTypeChanged: (val) => setState(() => _bloodType = val),
                    onRhChanged: (val) => setState(() => _bloodRh = val),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  elevation: 2,
                ),
                onPressed: _isLoading ? null : _nextPage,
                child: _isLoading
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
                    : Text(
                  _currentPage == _numPages - 1 ? 'Finish' : 'Continue',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}