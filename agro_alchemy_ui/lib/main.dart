import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:agro_alchemy_ui/config.dart';
import 'package:agro_alchemy_ui/firebase_options.dart';
import 'package:agro_alchemy_ui/login_page.dart';
import 'package:agro_alchemy_ui/flutter_gen/gen_l10n/app_localizations.dart';

import 'services/weather_theme.dart';
import 'locale_provider.dart';

// Screens
import 'dashboard.dart';
import 'fertilizer_prediction.dart';
import 'crop_health_analysis.dart';
import 'pest_management.dart';
import 'about_help.dart';
import 'chatbot.dart';
import 'crop_history.dart';
import 'user_profile.dart';
import 'review.dart';

/// =====================
/// THEME PROVIDER
/// =====================
class ThemeProvider extends ChangeNotifier {
  ThemeData _currentTheme = WeatherTheme.getThemeForWeather('default');
  bool _isDarkMode = false;

  ThemeData get currentTheme =>
      _isDarkMode ? _darkModeTheme : _currentTheme;

  ThemeData get _darkModeTheme => ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF81C784),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: Color(0xFF81C784),
          secondary: Color(0xFF4CAF50),
        ),
      );

  void setTheme(String? weatherCondition) {
    _currentTheme = WeatherTheme.getThemeForWeather(weatherCondition);
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppConfig.instance.init();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);

  // ✅ CORRECT INITIALIZATION (WEB SAFE)
  if (!kIsWeb) {
    await notificationsPlugin.initialize(settings: initSettings);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

/// =====================
/// ROOT APP
/// =====================
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'AgroAlchemy',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.currentTheme,
      locale: localeProvider.locale,

      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const LoginScreen(),

      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const Dashboard(),
        '/crops': (context) => const CropHistoryPage(),
        '/analytics': (context) => const _AnalyticsPlaceholder(),
        '/settings': (context) => const UserProfilePage(),
        '/help': (context) => const AboutHelpPage(),
        '/fertilizer': (context) => const FertilizerPredictionPage(),
        '/cropHealth': (context) => const CropHealthAnalysisPage(),
        '/pest': (context) => const PestManagementPage(),
        '/about': (context) => const AboutHelpPage(),
        '/chat': (context) => const MessageScreen(),
        '/history': (context) => const CropHistoryPage(),
        '/profile': (context) => const UserProfilePage(),
        '/review': (context) => const WriteReviewScreen(),
      },
    );
  }
}

/// =====================
/// ANALYTICS PLACEHOLDER
/// =====================
class _AnalyticsPlaceholder extends StatelessWidget {
  const _AnalyticsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.bar_chart, size: 64),
            SizedBox(height: 16),
            Text('Analytics'),
            SizedBox(height: 8),
            Text('Charts and insights will appear here.'),
          ],
        ),
      ),
    );
  }
}
