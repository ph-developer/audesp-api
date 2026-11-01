import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audesp_api/core/database/database_service.dart';
import 'package:audesp_api/core/database/db_pool.dart';
import 'package:mysql_client/mysql_client.dart';

/// Servidor local que fala só o necessário do protocolo MySQL, para exercitar
/// o driver real e contar o que chega pelo socket, como o `SHOW GLOBAL STATUS`.
///
/// Marcadores no SQL: `/*sleep:300*/` atrasa a resposta, `/*dup*/` responde o
/// erro 1062 e `/*drop*/` fecha o socket sem responder.
class FakeMySqlServer {
  late ServerSocket _server;
  final _connections = <_FakeConnection>[];

  int comStmtPrepare = 0;
  int comStmtExecute = 0;
  int comStmtClose = 0;
  int comQuery = 0;

  /// Maior número de conexões abertas ao mesmo tempo.
  int peakConnections = 0;

  int get port => _server.port;

  int get threadsConnected => _connections.where((c) => c.alive).length;

  int get preparedStmtCount => _connections
      .where((c) => c.alive)
      .fold(0, (total, c) => total + c.statements.length);

  static Future<FakeMySqlServer> start() async {
    final server = FakeMySqlServer();
    server._server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    server._server.listen(server._accept);
    return server;
  }

  /// Derruba as conexões, como o `wait_timeout` ou um restart do servidor.
  void dropConnections() {
    for (final connection in _connections) {
      connection.close();
    }
  }

  Future<void> stop() async {
    dropConnections();
    await _server.close();
  }

  /// [DbPool] apontando para este servidor, sem TLS.
  DbPool pool({
    int maxConnections = 5,
    Duration commandTimeout = const Duration(seconds: 5),
  }) => DbPool(
    maxConnections: maxConnections,
    commandTimeout: commandTimeout,
    connect: () async {
      final conn = await MySQLConnection.createConnection(
        host: '127.0.0.1',
        port: port,
        userName: 'teste',
        password: 'teste',
        databaseName: 'teste',
        secure: false,
      );
      await conn.connect();
      return conn;
    },
  );

  DatabaseService database({int maxConnections = 5}) =>
      DatabaseService(pool(maxConnections: maxConnections));

  void _accept(Socket socket) {
    socket.setOption(SocketOption.tcpNoDelay, true);
    final connection = _FakeConnection(socket);
    _connections.add(connection);
    if (threadsConnected > peakConnections) {
      peakConnections = threadsConnected;
    }
    socket.listen(
      (data) {
        connection.buffer.addAll(data);
        _readPackets(connection);
      },
      onDone: () => connection.close(),
      onError: (_) => connection.close(),
    );
    connection.send(0, _handshake(_connections.length));
  }

  void _readPackets(_FakeConnection connection) {
    final buffer = connection.buffer;
    while (buffer.length >= 4) {
      final length = buffer[0] | (buffer[1] << 8) | (buffer[2] << 16);
      if (buffer.length < 4 + length) return;
      final payload = Uint8List.fromList(buffer.sublist(4, 4 + length));
      buffer.removeRange(0, 4 + length);
      connection.queue = connection.queue.then(
        (_) => _handle(connection, payload),
      );
    }
  }

  Future<void> _handle(_FakeConnection connection, Uint8List payload) async {
    if (!connection.authenticated) {
      connection.authenticated = true;
      connection.send(2, _ok);
      return;
    }
    switch (payload[0]) {
      case 0x01:
        connection.close();
      case 0x03:
        comQuery++;
        await _respond(connection, utf8.decode(payload.sublist(1)));
      case 0x16:
        comStmtPrepare++;
        _prepare(connection, utf8.decode(payload.sublist(1)));
      case 0x17:
        comStmtExecute++;
        final id = ByteData.sublistView(payload).getUint32(1, Endian.little);
        await _respond(connection, connection.statements[id]!);
      case 0x19:
        comStmtClose++;
        final id = ByteData.sublistView(payload).getUint32(1, Endian.little);
        connection.statements.remove(id);
    }
  }

  void _prepare(_FakeConnection connection, String sql) {
    final id = ++connection.lastStatementId;
    connection.statements[id] = sql;
    final params = '?'.allMatches(sql).length;
    final ok = ByteData(12)
      ..setUint32(1, id, Endian.little)
      ..setUint16(7, params, Endian.little);
    var sequence = 1;
    connection.send(sequence++, ok.buffer.asUint8List());
    if (params == 0) return;
    for (var i = 0; i < params; i++) {
      connection.send(sequence++, ascii.encode('\x03def'));
    }
    connection.send(sequence, const [0xfe, 0, 0, 2, 0]);
  }

  Future<void> _respond(_FakeConnection connection, String sql) async {
    final sleep = RegExp(r'/\*sleep:(\d+)\*/').firstMatch(sql);
    if (sleep != null) {
      await Future.delayed(Duration(milliseconds: int.parse(sleep[1]!)));
    }
    if (sql.contains('/*drop*/')) {
      connection.close();
    } else if (sql.contains('/*dup*/')) {
      connection.send(1, [
        0xff,
        0x26,
        0x04,
        0x23,
        ...ascii.encode('23000Duplicate entry'),
      ]);
    } else {
      connection.send(1, _ok);
    }
  }

  static const _ok = [0, 0, 0, 2, 0, 0, 0];

  static List<int> _handshake(int id) {
    const capabilities = 0x00000001 | 0x00000200 | 0x00002000 | 0x00008000;
    const pluginAuth = 0x00080000;
    return [
      0x0a,
      ...ascii.encode('8.0-teste'),
      0,
      id,
      0,
      0,
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      0,
      capabilities & 0xff,
      (capabilities >> 8) & 0xff,
      45,
      2,
      0,
      (pluginAuth >> 16) & 0xff,
      0,
      21,
      ...List.filled(10, 0),
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      0,
      ...ascii.encode('mysql_native_password'),
      0,
    ];
  }
}

class _FakeConnection {
  final Socket socket;
  final List<int> buffer = [];
  final Map<int, String> statements = {};
  int lastStatementId = 0;
  bool alive = true;
  bool authenticated = false;
  Future<void> queue = Future.value();

  _FakeConnection(this.socket);

  void send(int sequence, List<int> payload) {
    if (!alive) return;
    final length = payload.length;
    socket.add([
      length & 0xff,
      (length >> 8) & 0xff,
      (length >> 16) & 0xff,
      sequence,
      ...payload,
    ]);
  }

  void close() {
    alive = false;
    socket.destroy();
  }
}
