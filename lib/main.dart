import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:health_up/pages/add_data/add_data_screen.dart';
import 'package:health_up/pages/doctor_visits_screen.dart';
import 'package:health_up/pages/files_screen.dart';
import 'package:health_up/pages/medication_schedule.dart';
import 'package:health_up/pages/profile/profile_screen.dart';
import 'package:health_up/pages/sleep_screen.dart';
import 'package:health_up/pages/welcome_screen.dart';
import 'package:health_up/services/user_data_service.dart';
import 'package:health_up/services/sleep_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode') ?? 0;
    setState(() {
      _themeMode = ThemeMode.values[themeIndex];
    });
  }

  void changeTheme(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', themeMode.index);

    setState(() {
      _themeMode = themeMode;
    });
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        cardColor: Colors.white,
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue[600],
          unselectedItemColor: Colors.grey[600],
        ),
        dividerColor: Colors.grey[300],
        iconTheme: const IconThemeData(color: Colors.black54),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black54),
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
          surface: Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        cardColor: const Color(0xFF1E1E1E),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
        ),
        dividerColor: Colors.grey[700]!,
        iconTheme: const IconThemeData(color: Colors.white70),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2D2D2D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueAccent),
          ),
          hintStyle: const TextStyle(color: Colors.grey),
          labelStyle: const TextStyle(color: Colors.white70),
        ),
      ),
      themeMode: _themeMode,
      home: const WelcomeScreen(),
    );
  }
}


class MainScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const MainScreen({
    required this.userId,
    required this.userName,
    super.key,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;

  AverageUserData? _averageData;
  late String _currentUserId;
  late String _currentUserName;
  int? _userAge;
  String? _userProfilePic;

  final SleepService _sleepService = SleepService();
  double _sleepScore = 0;
  String _sleepStatus = "No data";
  bool _isSleepLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.userId;
    _currentUserName = widget.userName;
    _fetchUserData();
    _fetchSleepData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        UserDataService.getAverageData(userId: _currentUserId),
        UserDataService.getUserData(_currentUserId),
      ]);

      final healthDataResponse = results[0];
      final userDataResponse = results[1];

      if (healthDataResponse["success"] == true) {
        setState(() {
          _averageData = healthDataResponse["data"] as AverageUserData;
        });
      } else {
        setState(() {
          _errorMessage = healthDataResponse["message"] ?? 'Failed to load health data';
        });
      }

      if (userDataResponse["success"] == true) {
        final userData = userDataResponse["data"] as Map<String, dynamic>;

        final dynamic ageValue = userData['age'];
        int? parsedAge;

        if (ageValue != null) {
          if (ageValue is int) {
            parsedAge = ageValue;
          } else if (ageValue is double) {
            parsedAge = ageValue.toInt();
          } else if (ageValue is String) {
            parsedAge = int.tryParse(ageValue);
          }
        }

        setState(() {
          _userAge = parsedAge;
          _userProfilePic = userData['profilePictureUrl'];
          if (userData['userName'] != null) {
            _currentUserName = userData['userName'];
          }
        });
      } else {
        if (_errorMessage == null) {
          setState(() {
            _errorMessage = userDataResponse["message"] ?? 'Failed to load user profile data';
          });
        }
      }

      if (healthDataResponse["success"] != true && userDataResponse["success"] != true) {
        setState(() {
          _errorMessage = 'Failed to load both health and profile data';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSleepData() async {
    if (_isSleepLoading) return;

    setState(() {
      _isSleepLoading = true;
    });

    try {
      final data = await _sleepService.getSleepHistoryWithStats(_currentUserId);
      final sleepHistory = data['sleepHistory'] as Map<DateTime, SleepEntry>;

      if (sleepHistory.isNotEmpty) {
        final sleepEntries = sleepHistory.values.toList();
        sleepEntries.sort((a, b) => b.date.compareTo(a.date));

        final latestEntry = sleepEntries.first;

        setState(() {
          _sleepScore = latestEntry.sleepScore.toDouble();
          _sleepStatus = latestEntry.sleepStatus;
        });
      } else {
        setState(() {
          _sleepScore = 0;
          _sleepStatus = "No data";
        });
      }
    } catch (e) {
      setState(() {
        _sleepScore = 0;
        _sleepStatus = "Error";
      });
    } finally {
      setState(() {
        _isSleepLoading = false;
      });
    }
  }

  Future<void> _onReturnFromSleepPage() async {
    await _fetchSleepData();
    await _fetchUserData();
  }

  ImageProvider? _getAvatarImage() {
    if (_userProfilePic != null && _userProfilePic!.isNotEmpty) {
      if (_userProfilePic!.startsWith('http')) {
        return NetworkImage(_userProfilePic!);
      } else {
        try {
          return MemoryImage(base64Decode(_userProfilePic!));
        } catch (e) {
          return null;
        }
      }
    }
    return null;
  }

  Widget _buildHomeBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load data',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchUserData,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_averageData == null) {
      return Center(
        child: Text(
          'No data available.',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      );
    }

    final data = _averageData!;
    final avatarImage = _getAvatarImage();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                backgroundImage: avatarImage,
                child: avatarImage == null
                    ? Text(
                  _currentUserName.isNotEmpty ? _currentUserName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 22,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome back,",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    _currentUserName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              )
            ],
          ),

          const SizedBox(height: 25),

          Text(
            "Smart Health Metrics",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricCard(
                icon: Icons.favorite,
                title: "Avg HR",
                value: "${data.averageHeartRate.toStringAsFixed(1)} bpm",
              ),
              _metricCard(
                icon: Icons.bloodtype,
                title: "Avg BP",
                value: "${data.averageSystolic}/${data.averageDiastolic}",
              ),
              _metricCard(
                icon: Icons.monitor_weight,
                title: "BMI",
                value: data.imt.toStringAsFixed(1),
              ),
            ],
          ),
          const SizedBox(height: 30),

          _sleepScoreCard(),

          const SizedBox(height: 30),

          Text(
            "Daily Health Stats",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 14),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.35,
            children: [
              _dataCard(Icons.favorite, "Heart Rate", "${data.latestHeartRate} bpm"),
              _dataCard(
                Icons.bloodtype,
                "Blood Pressure",
                "${data.averageSystolic}/${data.averageDiastolic}",
              ),
              _dataCard(
                Icons.local_drink,
                "Sugar Level",
                data.latestSugar > 0
                    ? "${data.latestSugar.toStringAsFixed(1)} mmol/L"
                    : "N/A",
              ),
              _addDataCard(),
            ],
          ),

          const SizedBox(height: 30),

          Text(
            "Body Parameters",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 14),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.35,
            children: [
              _dataCard(Icons.height, "Height", "${data.latestHeight} cm"),
              _dataCard(Icons.monitor_weight, "Weight", "${data.latestWeight} kg"),
              _dataCard(Icons.bloodtype, "Blood Group",
                  data.bloodGroup.isEmpty ? "N/A" : data.bloodGroup),
              _dataCard(Icons.cake_outlined, "Age",
                  _userAge != null && _userAge! > 0 ? "$_userAge years" : "N/A"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sleepScoreCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isSleepLoading)
                const SizedBox(
                  width: 60,
                  height: 40,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                )
              else
                Text(
                  _sleepScore > 0 ? _sleepScore.toStringAsFixed(0) : "--",
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                _sleepStatus,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SleepPage(userId: _currentUserId),
                ),
              );

              if (result == true) {
                await _onReturnFromSleepPage();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 26,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _dataCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 26,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addDataCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddDataScreen(userId: _currentUserId),
          ),
        );
        if (result == true) _fetchUserData();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle,
              color: Theme.of(context).colorScheme.primary,
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              "Add/Update Data",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeBody();
      case 1:
        return const ReportsScreen();
      case 2:
        return const DoctorVisitsScreen();
      case 3:
        return MedicationSchedule(userId: _currentUserId);
      case 4:
        return ProfileScreen(
          userId: _currentUserId,
          userName: _currentUserName,
        );
      default:
        return _buildHomeBody();
    }
  }

  Widget _buildAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return const SizedBox.shrink();
      case 1:
        return Text(
          'Files & Notes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        );
      case 2:
        return Text(
          'Doctor Visits',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        );
      case 3:
        return Text(
          'Schedule',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        );
      case 4:
        return Text(
          'My Account',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _buildAppBarTitle(),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () {
              _fetchUserData();
              _fetchSleepData();
            },
          ),
        ],
      ),
      body: _buildPageContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.file_copy),
            activeIcon: Icon(Icons.file_copy),
            label: 'Files',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            activeIcon: Icon(Icons.medical_services),
            label: 'Visits',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}