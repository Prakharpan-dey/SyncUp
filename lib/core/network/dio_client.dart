import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'auth_interceptor.dart';

class DioClient {
  late final Dio dio;

  DioClient({required AuthInterceptor authInterceptor}) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.addAll([
      authInterceptor,
      LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }
}
