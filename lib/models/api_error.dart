class ApiError implements Exception {
  final String type;
  final String code;
  final String userMessage;
  final String? devMessage;
  final String nextAction;
  final bool retryable;

  ApiError({
    required this.type,
    required this.code,
    required this.userMessage,
    this.devMessage,
    required this.nextAction,
    required this.retryable,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      type: json['type'] as String? ?? 'UNKNOWN',
      code: json['code'] as String? ?? 'ERR_UNKNOWN',
      userMessage: json['user_message'] as String? ?? 'An unexpected error occurred.',
      devMessage: json['dev_message'] as String?,
      nextAction: json['next_action'] as String? ?? 'NONE',
      retryable: json['retryable'] == true,
    );
  }

  /// Parses the response body if it's an error payload, otherwise returns a generic error.
  static ApiError fromResponseBody(Map<String, dynamic> body) {
    if (body['error'] is Map<String, dynamic>) {
      return ApiError.fromJson(body['error'] as Map<String, dynamic>);
    } else if (body['error'] is String) {
      // Fallback for legacy string errors
      return ApiError(
        type: 'SERVER',
        code: 'ERR_LEGACY',
        userMessage: body['error'] as String,
        nextAction: 'NONE',
        retryable: false,
      );
    }
    return ApiError(
      type: 'SERVER',
      code: 'ERR_UNKNOWN',
      userMessage: 'An unexpected error occurred.',
      nextAction: 'NONE',
      retryable: false,
    );
  }

  @override
  String toString() => 'ApiError[$code]: $userMessage';
}
