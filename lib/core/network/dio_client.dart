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
        // Content-Type is deliberately not forced here. Dio already sets
        // application/json when a body is present and omits it when there is
        // none; declaring it globally made every bodyless POST and DELETE
        // announce a JSON body it never sent, which Fastify rejects outright
        // (FST_ERR_CTP_EMPTY_JSON_BODY).
        //
        // Accept stays, since that describes what we want back, not what we send.
        headers: {'Accept': 'application/json'},
      ),
    );
    dio.interceptors.addAll([
      authInterceptor,
      LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }
}
