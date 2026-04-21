import 'package:dio/dio.dart';
import 'package:tournament_app/core/constants/api_constants.dart';
import 'package:tournament_app/core/storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;

  AuthInterceptor(this._dio);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      if (_isRefreshing) {
        return handler.reject(err);
      }
      _isRefreshing = true;
      try {
        final refreshToken = await SecureStorage.getRefreshToken();
        if (refreshToken == null) {
          _handleLogout();
          return handler.reject(err);
        }

        final refreshResponse = await _dio.post(
          ApiConstants.authRefresh,
          data: {'refresh_token': refreshToken},
          options: Options(headers: {'Authorization': null}),
        );

        final refreshData = refreshResponse.data['data'] as Map<String, dynamic>;
        final newAccessToken = refreshData['access_token'] as String;
        final newRefreshToken =
            refreshData['refresh_token'] as String?;

        await SecureStorage.saveAccessToken(newAccessToken);
        if (newRefreshToken != null) {
          await SecureStorage.saveRefreshToken(newRefreshToken);
        }

        // Retry original request with new token
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.request(
          opts.path,
          data: opts.data,
          queryParameters: opts.queryParameters,
          options: Options(method: opts.method, headers: opts.headers),
        );

        return handler.resolve(retryResponse);
      } catch (_) {
        _handleLogout();
        return handler.reject(err);
      } finally {
        _isRefreshing = false;
      }
    }
    handler.next(err);
  }

  void _handleLogout() async {
    await SecureStorage.clearAll();
    // Navigation handled by GoRouter redirect watching auth state
  }
}
