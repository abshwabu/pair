/// Backend API envelope: { "data", "meta", "error" }.
class ApiResponse<T> {
  const ApiResponse({
    this.data,
    this.meta,
    this.error,
  });

  final T? data;
  final Map<String, dynamic>? meta;
  final ApiError? error;

  bool get isSuccess => error == null;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse(
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      meta: json['meta'] as Map<String, dynamic>?,
      error: json['error'] != null
          ? ApiError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ApiError {
  const ApiError({
    required this.message,
    required this.code,
  });

  final String message;
  final String code;

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      message: json['message'] as String? ?? 'Unknown error',
      code: json['code']?.toString() ?? 'unknown_error',
    );
  }

  @override
  String toString() => 'ApiError($code): $message';
}

class ApiException implements Exception {
  const ApiException({
    required this.message,
    required this.code,
    this.statusCode,
    this.meta,
  });

  final String message;
  final String code;
  final int? statusCode;
  final Map<String, dynamic>? meta;

  factory ApiException.fromApiError(ApiError error, {int? statusCode}) {
    return ApiException(
      message: error.message,
      code: error.code,
      statusCode: statusCode,
    );
  }

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}
