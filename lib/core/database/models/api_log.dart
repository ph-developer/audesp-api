class ApiLog {
  final int id;
  final String endpoint;
  final String request;
  final String? response;
  final int? statusCode;
  final int? userId;
  final DateTime timestamp;

  const ApiLog({
    required this.id,
    required this.endpoint,
    required this.request,
    this.response,
    this.statusCode,
    this.userId,
    required this.timestamp,
  });

  factory ApiLog.fromMap(Map<String, dynamic> row) => ApiLog(
        id: row['id'] as int,
        endpoint: row['endpoint'] as String,
        request: row['request'] as String,
        response: row['response'] as String?,
        statusCode: row['status_code'] as int?,
        userId: row['user_id'] as int?,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          (row['timestamp'] as int) * 1000,
        ),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'endpoint': endpoint,
        'request': request,
        'response': response,
        'status_code': statusCode,
        'user_id': userId,
        'timestamp': timestamp.millisecondsSinceEpoch ~/ 1000,
      };
}
