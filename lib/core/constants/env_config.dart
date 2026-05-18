/// Environment configuration loaded at app startup.
/// Values come from --dart-define flags or .env file.
class EnvConfig {
  /// API base URL — set via: --dart-define=API_BASE_URL=https://api.syncup.app
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000', // Android emulator → host machine
  );

  /// Google OAuth web client ID (for google_sign_in)
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  /// Firebase project ID
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: '',
  );
}
