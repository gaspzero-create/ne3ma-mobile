import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GraphQLClient {
  GraphQLClient._();

  static const String _baseUrl =
      'https://ne3ma-backend-production-d671.up.railway.app/graphql';
  static const _storage = FlutterSecureStorage();
  static Dio? _dio;

  static String get graphqlUrl => _baseUrl;

  static String get backendBaseUrl {
    final uri = Uri.parse(_baseUrl);
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }

  static Dio get dio {
    if (_dio != null) {
      return _dio!;
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 300),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshed = await _tryRefreshToken(dio);
            if (refreshed) {
              final opts = error.requestOptions;
              final token = await _storage.read(key: 'access_token');
              opts.headers['Authorization'] = 'Bearer $token';
              final response = await dio.fetch(opts);
              return handler.resolve(response);
            }
          }
          handler.next(error);
        },
      ),
    );

    _dio = dio;
    return dio;
  }

  // ── Query / Mutation helper ────────────────────────
  static Future<Map<String, dynamic>> query({
    required String document,
    Map<String, dynamic>? variables,
  }) async {
    try {
      final response = await dio.post(
        '',
        data: {
          'query': document,
          if (variables != null) 'variables': variables,
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data['errors'] != null) {
        final errors = data['errors'] as List;
        final errorMessage = errors.first['message'] ?? 'Unknown error';
        print('📢 GraphQL Server Error: $errorMessage');
        if (errors.first['extensions'] != null) {
          print('📋 Error Details: ${errors.first['extensions']}');
        }
        throw GraphQLException(errorMessage);
      }

      return data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      print('🌐 Network Error:');
      print('Status Code: ${e.response?.statusCode}');
      print('Status Message: ${e.response?.statusMessage}');
      print('Response Data: ${e.response?.data}');
      throw GraphQLException('Network error: ${e.message}');
    } catch (e) {
      print('⚠️ Unexpected Error: $e');
      rethrow;
    }
  }

  // ── Token storage helpers ──────────────────────────
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  static Future<String?> getAccessToken() => _storage.read(key: 'access_token');

  static Future<String?> getRefreshToken() =>
      _storage.read(key: 'refresh_token');

  // ── Refresh token ──────────────────────────────────
  static Future<bool> _tryRefreshToken(Dio dioInstance) async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final response = await dioInstance.post(
        '',
        data: {
          'query': '''
            mutation RefreshToken(\$input: RefreshTokenInput!) {
              refreshToken(input: \$input) {
                accessToken
                refreshToken
              }
            }
          ''',
          'variables': {
            'input': {'refreshToken': refreshToken},
          },
        },
      );

      final data = response.data['data']['refreshToken'];
      await saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
      return true;
    } catch (_) {
      await clearTokens();
      return false;
    }
  }
}

// ── Custom exception ───────────────────────────────────
class GraphQLException implements Exception {
  final String message;
  const GraphQLException(this.message);

  @override
  String toString() => message;
}
