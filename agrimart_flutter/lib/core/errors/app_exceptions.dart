import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AppException implements Exception {
  final String message;
  final String? code;
  AppException(this.message, [this.code]);
  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException([String? message]) : super(message ?? 'No Internet Connection', 'NETWORK_ERROR');
}

class ServerException extends AppException {
  ServerException([String? message, String? code]) : super(message ?? 'Server error, please try again later', code ?? 'SERVER_ERROR');
}

class ValidationException extends AppException {
  ValidationException(String message) : super(message, 'VALIDATION_ERROR');
}

class UnauthorizedException extends AppException {
  UnauthorizedException() : super('Session expired, please login again', 'UNAUTHORIZED');
}

/// Global utility: extract a clean error message from any exception/error object.
/// Prevents full DioClientException or SocketException stack traces leaking to users.
String extractUserFacingError(Object e) {
  // If it's already an AppException, use it directly
  if (e is AppException) return e.message;

  // If it's a DioException, get our AppException from .error if possible
  if (e is DioException) {
    if (e.error is AppException) return (e.error as AppException).message;
    if (e.message != null && e.message!.isNotEmpty && e.message!.length < 200) {
      final msg = e.message!;
      if (!msg.contains('DioException') && !msg.contains('ClientException') && !msg.contains('SocketException')) {
        return msg;
      }
    }
    // Network-type errors
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'No internet connection. Please check your network.';
    }
    // Try response body
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'] ?? data['error'];
      if (msg != null && msg.toString().isNotEmpty) return msg.toString();
    }
    return 'Server error. Please try again.';
  }

  final s = e.toString();
  if (s.contains('SocketException') || s.contains('ClientException')) {
    return 'No internet connection. Please check your network.';
  }
  if (s.length < 150 && !s.contains('Exception: Exception:')) return s;
  return 'Something went wrong. Please retry.';
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppException exception;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        exception = NetworkException('No internet connection. Please check your network.');
        break;
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode;
        final data = err.response?.data;
        final msg = data is Map ? (data['message'] ?? data['error']) : null;

        if (status == 401) {
          exception = UnauthorizedException();
        } else if (status == 400 || status == 422) {
          exception = ValidationException(msg?.toString() ?? 'Invalid request details');
        } else if (status == 503) {
          exception = ServerException('Server is under maintenance. Please try in 2 minutes.');
        } else if ((status ?? 0) >= 500) {
          exception = ServerException('Server is busy. Please try again.');
        } else {
          exception = AppException(msg?.toString() ?? 'Something went wrong', status?.toString());
        }
        break;
      case DioExceptionType.cancel:
        return handler.next(err);
      default:
        final inner = err.error;
        final detail = err.message ?? inner?.toString() ?? '';
        if (detail.contains('SocketException') ||
            detail.contains('Connection reset') ||
            detail.contains('Failed host lookup') ||
            detail.contains('Network is unreachable')) {
          exception = NetworkException('Cannot reach server. Check Wi‑Fi and that backend is running.');
        } else if (inner is FormatException) {
          exception = ServerException('Invalid response from server');
        } else if (detail.isNotEmpty && !detail.contains('DioException')) {
          exception = AppException(detail.length > 120 ? 'Unexpected error occurred' : detail);
        } else {
          if (kDebugMode) {
            debugPrint(
              'Dio unknown: type=${err.type} error=${err.error?.runtimeType} '
              'inner=$inner message=${err.message}',
            );
          }
          exception = AppException(
            'Cannot connect to server at ${err.requestOptions.baseUrl}. '
            'Use the same Wi‑Fi as your PC, or run: adb reverse tcp:3000 tcp:3000',
          );
        }
    }

    return handler.next(DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: exception,
      message: exception.message,
    ));
  }
}

