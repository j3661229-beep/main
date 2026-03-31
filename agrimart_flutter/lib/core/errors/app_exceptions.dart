import 'package:dio/dio.dart';

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

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppException exception;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        exception = NetworkException('Slow internet connection. Please check your network.');
        break;
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode;
        final data = err.response?.data;
        final msg = data is Map ? (data['message'] ?? data['error']) : null;

        if (status == 401) {
          exception = UnauthorizedException();
        } else if (status == 400 || status == 422) {
          exception = ValidationException(msg ?? 'Invalid request details');
        } else if (status == 503) {
          exception = ServerException('Server is under maintenance. Please try in 2 minutes.');
        } else if (status! >= 500) {
          exception = ServerException('Server is busy (Error $status). Trying to fix it!');
        } else {
          exception = AppException(msg ?? 'Something went wrong', status.toString());
        }
        break;
      case DioExceptionType.cancel:
        return handler.next(err);
      default:
        exception = AppException('Unexpected error occurred');
    }

    // We pass the custom exception inside a new DioException to keep the flow consistent
    return handler.next(DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: exception,
      message: exception.message,
    ));
  }
}
