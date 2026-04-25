import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();
  
  // Singleton instance
  static final AppConfig _instance = AppConfig._();
  
  // Getter for the singleton instance
  static AppConfig get instance => _instance;
  
  // Flag to check if environment is initialized
  bool _initialized = false;
  
  // Initialize environment variables
  Future<void> init() async {
    if (!_initialized) {
      await dotenv.load(fileName: ".env");
      _initialized = true;
    }
  }

  // API Base URL
  String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://192.168.1.47:5000';
  
  // Email configuration
  String get emailAddress => dotenv.env['EMAIL_ADDRESS'] ?? 'biradartejas842@gmail.com';
  String get emailPassword => dotenv.env['EMAIL_PASSWORD'] ?? 'ggwk sady jrfv nihh';
  String get emailSmtpServer => dotenv.env['EMAIL_SMTP_SERVER'] ?? 'smtp.gmail.com';
  int get emailSmtpPort => int.tryParse(dotenv.env['EMAIL_SMTP_PORT'] ?? '') ?? 587;
  

  /// Google Gemini API key for the chatbot. Set GEMINI_API_KEY in .env to override.
  String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? 'AIzaSyCJeQ_OKcV8IGASfe2GS_4FlCh8NFEPc9Y';
}
