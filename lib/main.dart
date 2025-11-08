
import 'package:flutter/material.dart';
import 'package:health_up/pages/add_data/add_data_screen.dart';
import 'package:health_up/pages/profile/profile_screen.dart';
import 'package:health_up/pages/reports_screen.dart';
import 'package:health_up/pages/sign_in_screen.dart';
import 'package:health_up/pages/welcome_screen.dart';
import 'package:health_up/services/user_data_service.dart';


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
  void changeTheme(ThemeMode themeMode) {
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
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[50],
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.grey[800]),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        cardColor: Colors.white,
      ),

      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF121212),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.grey[300]),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[300],
          ),
        ),
        cardColor: const Color(0xFF1E1E1E),
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

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.userId;
    _currentUserName = widget.userName;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response =
    await UserDataService.getAverageData(userId: _currentUserId);

    if (response["success"] == true) {
      setState(() {
        _averageData = response["data"] as AverageUserData;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = response["message"] ??
            'Failed to load user health data for ID: $_currentUserId. Check server connection/data.';
        _isLoading = false;
      });
    }
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
              Text(
                'Failed to load data:\n$_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
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
      return const Center(child: Text('No health data found.'));
    }

    final data = _averageData!;
    final avgHeartRate = data.averageHeartRate.toStringAsFixed(1);
    final avgSystolic = data.averageSystolic;
    final avgDiastolic = data.averageDiastolic;
    final latestHeartRate = data.latestHeartRate;
    final latestHeight = data.latestHeight;
    final bloodGroup = data.bloodGroup;
    final latestWeight = data.latestWeight;
    final imt = data.imt.toStringAsFixed(1);
    final latestSugar = data.latestSugar;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Smart Health Metrics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16.0),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricColumn('Avg. Heart Rate', '$avgHeartRate BPM'),
                _buildMetricColumn('Avg. BP', '$avgSystolic/$avgDiastolic mmHg'),
                _buildMetricColumn('IMT', imt),
              ],
            ),
          ),
          const SizedBox(height: 24.0),
          Text(
            'Personal Health Data',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16.0),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            childAspectRatio: 1.5,
            children: [
              _buildDataCard('Heart Rate', '$latestHeartRate BPM'),
              _buildDataCard('Height', '$latestHeight cm'),
              _buildDataCard('Blood Group',
                  bloodGroup == 'N/A' || bloodGroup.isEmpty ? 'N/A' : bloodGroup),
              _buildDataCard('Weight', '$latestWeight kg'),
              _buildDataCard(
                  'Sugar Level',
                  latestSugar > 0
                      ? '${latestSugar.toStringAsFixed(1)} mmol/L'
                      : 'N/A'),
              _buildAddDataCard(),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildMetricColumn(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildDataCard(String title, String value) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddDataCard() {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddDataScreen(userId: _currentUserId),
          ),
        );
        if (result == true) {
          _fetchUserData();
        }
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.blue[100]!),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: Colors.blue[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Add data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
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
        return const Center(child: Text('Notification Page (Coming Soon)'));
      case 3:
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, $_currentUserName!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        );
      case 3:
        return Text(
          'My Account',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _buildAppBarTitle(),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.grey[700]),
            onPressed: () {
              // TODO: Handle notification tap
            },
          ),
        ],
      ),
      body: _buildPageContent(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue[600],
          unselectedItemColor: Colors.grey[600],
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Notification',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}