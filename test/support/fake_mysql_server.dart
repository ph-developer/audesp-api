import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audesp_api/core/database/database_service.dart';
import 'package:audesp_api/core/database/db_pool.dart';
import 'package:mysql_client/mysql_client.dart';

/// Resposta opcional para exercitar leituras e linhas afetadas pelo driver real.
class FakeMySqlResult {
  final List<Map<String, Object?>> rows;
  final int affectedRows;

  const FakeMySqlResult({this.rows = const [], this.affectedRows = 0});
}

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

  final consultas = <({String sql, List<String?> params})>[];
  FutureOr<FakeMySqlResult?> Function(String sql, List<String?> params)?
  responder;

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
        final sql = connection.statements[id]!;
        await _respond(
          connection,
          sql,
          params: _params(payload, '?'.allMatches(sql).length),
        );
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

  Future<void> _respond(
    _FakeConnection connection,
    String sql, {
    List<String?>? params,
  }) async {
    consultas.add((sql: sql, params: params ?? const []));
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
      final resultado = await responder?.call(sql, params ?? const []);
      if (resultado == null) {
        connection.send(1, _ok);
      } else if (resultado.rows.isEmpty) {
        connection.send(1, [
          0,
          ..._tamanho(resultado.affectedRows),
          0,
          2,
          0,
          0,
          0,
        ]);
      } else {
        _rows(connection, resultado.rows, binario: params != null);
      }
    }
  }

  // O mysql_client envia parâmetros como strings com tamanho codificado.
  static List<String?> _params(Uint8List payload, int quantidade) {
    final bitmap = payload.sublist(10, 10 + (quantidade + 7) ~/ 8);
    var offset = 10 + bitmap.length + 1 + quantidade * 2;
    return List.generate(quantidade, (i) {
      if (bitmap[i ~/ 8] & (1 << (i % 8)) != 0) return null;
      var tamanho = payload[offset++];
      if (tamanho == 0xfc) {
        tamanho = ByteData.sublistView(
          payload,
        ).getUint16(offset, Endian.little);
        offset += 2;
      } else if (tamanho == 0xfd) {
        tamanho =
            payload[offset] |
            payload[offset + 1] << 8 |
            payload[offset + 2] << 16;
        offset += 3;
      } else if (tamanho == 0xfe) {
        tamanho = ByteData.sublistView(
          payload,
        ).getUint64(offset, Endian.little);
        offset += 8;
      }
      final valor = utf8.decode(payload.sublist(offset, offset + tamanho));
      offset += tamanho;
      return valor;
    });
  }

  static List<int> _tamanho(int valor) {
    if (valor < 251) return [valor];
    if (valor <= 0xffff) return [0xfc, valor & 0xff, valor >> 8];
    return [0xfd, valor & 0xff, (valor >> 8) & 0xff, valor >> 16];
  }

  static List<int> _texto(String valor) {
    final bytes = utf8.encode(valor);
    return [..._tamanho(bytes.length), ...bytes];
  }

  static void _rows(
    _FakeConnection connection,
    List<Map<String, Object?>> rows, {
    required bool binario,
  }) {
    final colunas = rows.first.keys.toList();
    final inteiros = [
      for (final coluna in colunas) rows.any((r) => r[coluna] is int),
    ];
    var sequencia = 1;
    connection.send(sequencia++, _tamanho(colunas.length));
    for (final (i, coluna) in colunas.indexed) {
      connection.send(sequencia++, [
        ..._texto('def'),
        ..._texto('teste'),
        ..._texto(''),
        ..._texto(''),
        ..._texto(coluna),
        ..._texto(''),
        0x0c,
        45,
        0,
        0xff,
        0xff,
        0,
        0,
        inteiros[i] ? 0x08 : 0xfd,
        0,
        0,
        0,
        0,
        0,
      ]);
    }
    const eof = [0xfe, 0, 0, 2, 0];
    connection.send(sequencia++, eof);
    for (final row in rows) {
      final valores = <int>[];
      final bitmap = List.filled((colunas.length + 9) ~/ 8, 0);
      for (final (i, coluna) in colunas.indexed) {
        final valor = row[coluna];
        if (valor == null) {
          if (binario) {
            bitmap[(i + 2) ~/ 8] |= 1 << ((i + 2) % 8);
          } else {
            valores.add(0xfb);
          }
        } else if (binario && inteiros[i]) {
          valores.addAll(
            (ByteData(
              8,
            )..setInt64(0, valor as int, Endian.little)).buffer.asUint8List(),
          );
        } else {
          valores.addAll(_texto(valor.toString()));
        }
      }
      connection.send(sequencia++, [
        if (binario) ...[0, ...bitmap],
        ...valores,
      ]);
    }
    connection.send(sequencia, eof);
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
