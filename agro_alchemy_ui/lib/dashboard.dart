import 'package:agro_alchemy_ui/main.dart';
import 'package:agro_alchemy_ui/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart'; // For animations
import 'package:percent_indicator/circular_percent_indicator.dart'; // For circular progress
import 'package:weather_icons/weather_icons.dart'; // For weather icons
import 'package:intl/intl.dart'; // For date formatting
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'services/weather_theme.dart'; // Path may vary depending on your project structure
import 'package:agro_alchemy_ui/flutter_gen/gen_l10n/app_localizations.dart';


class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  int _selectedIndex = 0;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;
  
  // Weather data variables
  Map<String, dynamic>? _weatherData;
  bool _isLoadingWeather = true;
  String? _weatherError;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchWeatherData();
    _setupUserDataListener(); // Add this line
    _tabController = TabController(length: 2, vsync: this);
    
    // Auto-scroll notifications
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _startAutoScroll();
      }
    });
  }
  
  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (_currentPage < 2) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
      
      if (mounted) {
        _startAutoScroll();
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Add this method to refresh weather data
  void refreshWeatherData() {
    setState(() {
      _isLoadingWeather = true;
    });
    _fetchWeatherData();
  }

  // Modified method to subscribe to user data changes and update theme
  void _setupUserDataListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            setState(() {
              _userData = snapshot.data();
            });
            // Refresh weather data which will also update the theme
            refreshWeatherData();
          }
        });
    }
  }

  Future<void> _loadUserData() async {
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _error =AppLocalizations.of(context)!.noUserLoggedIn;
        });
        return;
      }

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid);
      final doc = await userRef.get();

      if (!doc.exists) {
        // Create user doc from Auth (fixes post–Google sign-in when doc not yet created)
        try {
          await userRef.set({
            'displayName': currentUser.displayName ?? 'User',
            'photoURL': currentUser.photoURL,
            'email': currentUser.email,
            'createdAt': FieldValue.serverTimestamp(),
            'lastSignIn': FieldValue.serverTimestamp(),
            'isAnonymous': false,
          }, SetOptions(merge: true));
        } catch (_) {}
        final newDoc = await userRef.get();
        setState(() {
          _userData = newDoc.exists ? newDoc.data() : null;
          _isLoading = false;
          _error = _userData == null ? AppLocalizations.of(context)!.userDataNotFound : null;
        });
        return;
      }

      setState(() {
        _userData = doc.data();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = AppLocalizations.of(context)!.errorLoadingUserData;
      });
    }
  }

  // Modified method to fetch weather data and update theme
  Future<void> _fetchWeatherData() async {
  
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoadingWeather = false;
          _weatherError = AppLocalizations.of(context)!.noUserLoggedIn;
        });
        return;
      }

      // Get user location from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (!userDoc.exists) {
        setState(() {
          _isLoadingWeather = false;
          _weatherError = AppLocalizations.of(context)!.userDataNotFound;
          _weatherData = {
            'temp': 'N/A',
            'condition': 'Unknown',
            'humidity': 'N/A',
          };
        });
        return;
      }
      
      // Check if city is set in user profile
      final userData = userDoc.data()!;
      final city = userData['city'];
      
      if (city == null || city.isEmpty) {
        setState(() {
          _isLoadingWeather = false;
          _weatherError = 'City not set in profile';
          _weatherData = {
            'temp': 'N/A',
            'condition': 'Unknown',
            'humidity': 'N/A',
          };
        });
        return;
      }
      
      final location = city; // Use the city from user profile
      
      // Call weather API
      final apiKey = 'f4f87e7759984820add103838251105';
      final response = await http.get(Uri.parse(
          'http://api.weatherapi.com/v1/current.json?key=$apiKey&q=$location&aqi=no'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _weatherData = {
            'temp': data['current']['temp_c'],
            'condition': data['current']['condition']['text'],
            'humidity': data['current']['humidity'],
            'icon': data['current']['condition']['icon'],
          };
          _isLoadingWeather = false;
        });
        
        // Update the app theme based on the weather condition
        final weatherCondition = data['current']['condition']['text'];
        Provider.of<ThemeProvider>(context, listen: false).setTheme(weatherCondition);
      } else {
        setState(() {
          _isLoadingWeather = false;
          _weatherError = 'Failed to load weather data';
          _weatherData = {
            'temp': 'N/A',
            'condition': 'Unknown',
            'humidity': 'N/A',
          };
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingWeather = false;
        _weatherError = 'Error: $e';
        _weatherData = {
          'temp': 'N/A',
          'condition': 'Unknown',
          'humidity': 'N/A',
        };
      });
    }
  }

  // Helper method to get the appropriate weather icon
  IconData _getWeatherIcon(String condition) {
    condition = condition.toLowerCase();
    
    if (condition.contains('sunny') || condition.contains('clear')) {
      return WeatherIcons.day_sunny;
    } else if (condition.contains('rain') || condition.contains('drizzle')) {
      return WeatherIcons.rain;
    } else if (condition.contains('cloud')) {
      return WeatherIcons.cloud;
    } else if (condition.contains('snow')) {
      return WeatherIcons.snow;
    } else if (condition.contains('thunder') || condition.contains('lightning')) {
      return WeatherIcons.thunderstorm;
    } else if (condition.contains('fog') || condition.contains('mist')) {
      return WeatherIcons.fog;
    } else if (condition.contains('wind')) {
      return WeatherIcons.strong_wind;
    } else {
      return WeatherIcons.day_sunny;
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 1) Navigator.pushNamed(context, '/history');
    if (index == 2) Navigator.pushNamed(context, '/chat');
  }

  Widget _buildDrawer() {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final textOnPrimaryColor = theme.colorScheme.onPrimary;
    
    return Drawer(
      backgroundColor: primaryColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: (_userData?['photoURL'] != null && _userData!['photoURL'].isNotEmpty)
                      ? NetworkImage(_userData!['photoURL'])
                      : null,
                  child: _userData?['photoURL'] == null
                      ? Icon(Icons.person, color: primaryColor, size: 40)
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  _userData?['displayName'] ?? 'Farmer',
                  style: TextStyle(
                    color: textOnPrimaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _userData?['email'] ?? '',
                  style: TextStyle(
                    color: textOnPrimaryColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.home, loc.home, '/'),
          _buildDrawerItem(Icons.spa, loc.myCrops, '/crops'),
          _buildDrawerItem(Icons.bar_chart, loc.analytics, '/analytics'),
          _buildDrawerItem(Icons.settings, loc.settings, '/settings'),
          Divider(color: textOnPrimaryColor.withOpacity(0.24)),
          _buildDrawerItem(Icons.help_outline, loc.helpSupport, '/help'),
          _buildDrawerItem(Icons.logout, loc.logout, '/logout'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    // Get theme colors
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final scaffoldBackgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', height: 100)
                  .animate()
                  .fade(duration: const Duration(milliseconds: 600))
                  .scale(delay: const Duration(milliseconds: 200)),
              const SizedBox(height: 24),
              CircularProgressIndicator(
                color: primaryColor,
              ),
              const SizedBox(height: 16),
               Text(loc.loadingFarmData,
                  style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(loc.retry, style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final currentDate = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: scaffoldBackgroundColor,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.menu, color: primaryColor, size: 28),
                          onPressed: () => _scaffoldKey.currentState!.openDrawer(),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loc.appTitle,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                )),
                            Text(currentDate,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          border: Border.all(color: primaryColor, width: 2),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                          backgroundImage: (_userData?['photoURL'] != null && _userData!['photoURL'].isNotEmpty)
                              ? NetworkImage(_userData!['photoURL'])
                              : null,
                          child: _userData?['photoURL'] == null
                              ? Icon(Icons.person, color: primaryColor)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Weather and Welcome Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 2,
                  color: cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${loc.hello} ${_userData?['displayName']?.split(' ')[0] ?? loc.farmer}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                loc.checkCrops,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _isLoadingWeather 
                              ? const SizedBox(
                                  width: 60,
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                )
                              : Row(
                                  children: [
                                    _weatherData?['icon'] != null
                                        ? Image.network(
                                            'https:${_weatherData!['icon']}',
                                            width: 30,
                                            height: 30,
                                            errorBuilder: (context, error, stackTrace) => Icon(
                                              _getWeatherIcon(_weatherData?['condition'] ?? 'Unknown'),
                                              color: theme.colorScheme.onPrimaryContainer,
                                              size: 22,
                                            ),
                                          )
                                        : Icon(
                                            _getWeatherIcon(_weatherData?['condition'] ?? 'Unknown'),
                                            color: theme.colorScheme.onPrimaryContainer,
                                            size: 22,
                                          ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_weatherData?['temp'] ?? 'N/A'}°C',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: theme.colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: const Duration(milliseconds: 400)),
              
              const SizedBox(height: 16),
              
              // Growth Progress Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: cardColor,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(loc.growthProgress,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                )),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                CircularPercentIndicator(
                                  radius: 35.0,
                                  lineWidth: 10.0,
                                  animation: true,
                                  percent: 0.75,
                                  center: Text(
                                    loc.num,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                      color: textColor,
                                    ),
                                  ),
                                  circularStrokeCap: CircularStrokeCap.round,
                                  progressColor: theme.colorScheme.secondary,
                                  backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _progressItem(loc.wheat, 0.85),
                                    const SizedBox(height: 4),
                                    _progressItem(loc.rice, 0.65),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(loc.profitLoss,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                )),
                            const SizedBox(height: 12),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.trending_down, color: theme.colorScheme.error, size: 20),
                                  const SizedBox(width: 4),
                                  Text('-\$250',
                                      style: TextStyle(
                                        color: theme.colorScheme.error,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      )),
                                ],
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: const Duration(milliseconds: 500)),
              
              const SizedBox(height: 16),
              
              // Alerts & Reminders section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(loc.alertsReminders,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        )),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('3',
                          style: TextStyle(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Notification card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  color: cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: ListTile(
                    leading: Icon(Icons.notifications, color: theme.colorScheme.secondary),
                    title: Text(loc.reminder, style: TextStyle(color: textColor)),
                    subtitle: Text(loc.checkSoilMoisture),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Function cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFunctionCard(
                        Icons.bar_chart, loc.yieldPrediction, theme.colorScheme.secondary, '/cropHealth', loc.yieldPredictionTooltip),
                    _buildFunctionCard(
                        Icons.science, loc.fertilizerPredictionH, theme.colorScheme.tertiary, '/fertilizer', loc.fertilizerPredictionTooltip),
                    _buildFunctionCard(
                        Icons.bug_report, loc.pestPrediction, theme.colorScheme.primary, '/pest', loc.pestPredictionTooltip),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Reviews section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.reviews, 
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        )),
                    const SizedBox(height: 8),
                    Card(
                      color: cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer),
                        ),
                        title: Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 18),
                            Icon(Icons.star, color: Colors.amber, size: 18),
                            Icon(Icons.star, color: Colors.amber, size: 18),
                            Icon(Icons.star, color: Colors.amber, size: 18),
                            Icon(Icons.star, color: Colors.amber, size: 18),
                          ],
                        ),
                        subtitle: Text(loc.greatAppReview),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: primaryColor,
        selectedItemColor: theme.colorScheme.secondary,
        unselectedItemColor: theme.colorScheme.onPrimary,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: loc.home),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: loc.history),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: loc.chatbot),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, String route) {
    final theme = Theme.of(context);
    bool isSelected = route == '/' && _selectedIndex == 0;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? theme.colorScheme.secondary : theme.colorScheme.onPrimary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? theme.colorScheme.secondary : theme.colorScheme.onPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (route == '/logout') {
          AuthService().signOut();
          Navigator.pushReplacementNamed(context, '/login');
        } else if (route == '/') {
          // Home: replace with dashboard so we don't stack
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          Navigator.pushNamed(context, route);
        }
      },
      tileColor: isSelected ? theme.colorScheme.onPrimary.withOpacity(0.1) : null,
      shape: isSelected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            )
          : null,
    );
  }

  Widget _progressItem(String label, double value) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
            minHeight: 5,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }

  Widget _buildFunctionCard(
    IconData icon,
    String label,
    Color color,
    String route,
    String tooltip,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, route),
        child: Tooltip(
          message: tooltip,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 30,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _notificationCard(IconData icon, String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.grey),
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
  }

  Widget _reviewCard(String name, String review, int rating, String? imageUrl) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: imageUrl != null ? AssetImage(imageUrl) : null,
              backgroundColor: Colors.grey.shade200,
              child: imageUrl == null
                  ? Text(name[0],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Color(0xFF36522E)))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityItem(String title, String subtitle, IconData icon, Color color, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,    
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}