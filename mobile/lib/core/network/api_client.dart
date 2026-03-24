import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: AppConstants.connectionTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.addAll([
      _AuthInterceptor(_storage, _dio),
      _LanguageInterceptor(_storage),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('[API] $obj'),
      ),
    ]);
  }

  Dio get dio => _dio;

  // GET
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.get(path, queryParameters: queryParameters, options: options);

  // POST
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.post(path, data: data, queryParameters: queryParameters, options: options);

  // PUT
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.put(path, data: data, queryParameters: queryParameters, options: options);

  // PATCH
  Future<Response> patch(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _dio.patch(path, data: data, options: options);

  // DELETE
  Future<Response> delete(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _dio.delete(path, data: data, options: options);

  // Upload file
  Future<Response> uploadFile(
    String path, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? data,
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
      ...?data,
    });
    return _dio.post(path, data: formData);
  }
}

class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;
  bool _isRefreshing = false;

  _AuthInterceptor(this._storage, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
        if (refreshToken == null) {
          _isRefreshing = false;
          handler.next(err);
          return;
        }

        final response = await _dio.post(
          ApiConstants.refreshToken,
          data: {'refresh_token': refreshToken},
          options: Options(headers: {'Authorization': ''}),
        );

        final newAccessToken = response.data['access_token'];
        final newRefreshToken = response.data['refresh_token'];

        await _storage.write(key: AppConstants.accessTokenKey, value: newAccessToken);
        await _storage.write(key: AppConstants.refreshTokenKey, value: newRefreshToken);

        // Retry original request
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(retryOptions);

        _isRefreshing = false;
        handler.resolve(retryResponse);
      } catch (e) {
        _isRefreshing = false;
        // Clear tokens on refresh failure
        await _storage.delete(key: AppConstants.accessTokenKey);
        await _storage.delete(key: AppConstants.refreshTokenKey);
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }
}

class _LanguageInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  _LanguageInterceptor(this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final lang = await _storage.read(key: AppConstants.languageKey) ?? 'en';
    options.headers['Accept-Language'] = lang;
    handler.next(options);
  }
}

// API Error model
class ApiError {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiError({required this.message, this.statusCode, this.errors});

  factory ApiError.fromDioException(DioException e) {
    if (e.response != null && e.response?.data is Map) {
      return ApiError(
        message: e.response?.data['error'] ?? 'Unknown error',
        statusCode: e.response?.statusCode,
        errors: e.response?.data['errors'],
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiError(message: 'Connection timeout', statusCode: 408);
      case DioExceptionType.connectionError:
        return ApiError(message: 'No internet connection');
      default:
        return ApiError(message: 'Something went wrong');
    }
  }
}

// Result type for clean error handling
class ApiResult<T> {
  final T? data;
  final ApiError? error;

  ApiResult.success(this.data) : error = null;
  ApiResult.failure(this.error) : data = null;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;
}
