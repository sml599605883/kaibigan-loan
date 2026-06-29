import 'package:dio/dio.dart';

class ApiBusinessException implements Exception {
  ApiBusinessException(this.message, {this.code});

  final String message;
  final Object? code;

  @override
  String toString() => message;
}

class ApiErrorMessage {
  static String resolve(Object? error) {
    if (error == null) {
      return 'Network error';
    }
    if (error is ApiBusinessException) {
      return error.message;
    }
    if (error is DioException) {
      return error.message ?? 'Network error';
    }
    return error.toString();
  }
}
