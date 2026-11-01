import 'dart:async';
import 'dart:collection';

import 'package:mysql_client/exception.dart';
import 'package:mysql_client/mysql_client.dart';

/// Pool de conexões usado no lugar do `MySQLConnectionPool` do driver, que
/// ultrapassa o limite em rajadas, congela o isolate quando fica sem conexão
/// ociosa e não devolve a conexão quando o callback lança exceção.
class DbPool {
  final int maxConnections;
  final Duration commandTimeout;
  final Future<MySQLConnection> Function() _connect;

  final _idle = <MySQLConnection>[];
  final _waiters = Queue<Completer<void>>();
  // Conta também as conexões ainda em handshake.
  int _open = 0;

  DbPool({
    required this.maxConnections,
    required Future<MySQLConnection> Function() connect,
    this.commandTimeout = const Duration(seconds: 60),
  }) : _connect = connect;

  int get openConnections => _open;
  int get idleConnections => _idle.length;

  /// Dá a [action] uso exclusivo de uma conexão e a devolve mesmo com erro.
  ///
  /// O driver não conclui um comando se o socket fechar no meio, por isso o
  /// timeout. A conexão só volta ao pool se continuar em estado confiável.
  Future<T> use<T>(Future<T> Function(MySQLConnection conn) action) async {
    final conn = await _acquire();
    var reusable = false;
    try {
      final result = await action(conn).timeout(commandTimeout);
      reusable = true;
      return result;
    } on MySQLServerException {
      reusable = true;
      rethrow;
    } finally {
      _release(conn, reusable: reusable && conn.connected);
    }
  }

  Future<MySQLConnection> _acquire() async {
    while (true) {
      while (_idle.isNotEmpty) {
        final conn = _idle.removeLast();
        if (conn.connected) return conn;
        _open--;
      }
      if (_open < maxConnections) {
        _open++;
        try {
          return await _connect();
        } catch (_) {
          _open--;
          _wakeOne();
          rethrow;
        }
      }
      final waiter = Completer<void>();
      _waiters.add(waiter);
      await waiter.future;
    }
  }

  void _release(MySQLConnection conn, {required bool reusable}) {
    if (reusable) {
      _idle.add(conn);
    } else {
      _open--;
      if (conn.connected) unawaited(_closeQuietly(conn));
    }
    _wakeOne();
  }

  void _wakeOne() {
    if (_waiters.isNotEmpty) _waiters.removeFirst().complete();
  }

  Future<void> _closeQuietly(MySQLConnection conn) async {
    try {
      await conn.close();
    } catch (_) {}
  }

  Future<void> close() async {
    final conns = [..._idle];
    _idle.clear();
    _open -= conns.length;
    await Future.wait(conns.map(_closeQuietly));
  }
}
