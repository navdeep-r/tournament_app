import 'package:dio/dio.dart';
import 'package:tournament_app/core/constants/api_constants.dart';
import 'package:tournament_app/core/storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;
  final List<RequestOptions> _pendingRequests = [];

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
        _pendingRequests.add(err.requestOptions);
        return;
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

        final newAccessToken = refreshResponse.data['access_token'] as String;
        final newRefreshToken =
            refreshResponse.data['refresh_token'] as String?;

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

        _isRefreshing = false;
        // Retry pending requests
        for (final pending in _pendingRequests) {
          pending.headers['Authorization'] = 'Bearer $newAccessToken';
          _dio.request(pending.path,
              data: pending.data,
              queryParameters: pending.queryParameters,
              options: Options(method: pending.method, headers: pending.headers));
        }
        _pendingRequests.clear();

        return handler.resolve(retryResponse);
      } catch (_) {
        _isRefreshing = false;
        _pendingRequests.clear();
        _handleLogout();
        return handler.reject(err);
      }
    }
    handler.next(err);
  }

  void _handleLogout() async {
    await SecureStorage.clearAll();
    // Navigation handled by GoRouter redirect watching auth state
  }
}
