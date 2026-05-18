import 'env_config.dart';

class AppConstants {
  static String get apiBaseUrl => EnvConfig.apiBaseUrl;
  static const Duration apiTimeout = Duration(seconds: 30);

  static const Duration accessTokenExpiry = Duration(minutes: 15);
  static const Duration refreshTokenExpiry = Duration(days: 30);

  static const int syncBatchSize = 5;
  static const int syncMaxRetries = 3;
  static const Duration syncMinDelay = Duration(milliseconds: 500);

  static const int defaultThresholdPct = 75;
  static const int maxBackdateDays = 30;
  static const int defaultPageSize = 20;
  static const int friendRequestDailyLimit = 20;
  static const Duration groupInviteExpiry = Duration(days: 7);
}
