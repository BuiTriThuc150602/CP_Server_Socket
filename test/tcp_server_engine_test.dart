import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:socket_server/core/socket/tcp_server_engine.dart';

void main() {
  test(
    'starts, accepts loopback client, sends newline data, and stops',
    () async {
    final engine = TcpServerEngine();
    developer.log('before free port');
    final port = await _freePort();
    developer.log('before start');
    final incomingCompleter = Completer<String>();

    await engine.start(host: '127.0.0.1', port: port);
    developer.log('before connect');
    final client = await Socket.connect('127.0.0.1', port);
    developer.log('before listen');
    final clientSubscription = client.listen((bytes) {
      incomingCompleter.complete(utf8.decode(bytes));
    });

    await Future<void>.delayed(const Duration(milliseconds: 50));
    developer.log('before clients expect ${engine.clients.length}');
    expect(engine.clients.length, 1);

    developer.log('before send');
    await engine.sendToAll('{"ok":true}', appendNewline: true);
    developer.log('before receive');
    expect(
      await incomingCompleter.future.timeout(const Duration(seconds: 2)),
      '{"ok":true}\n',
    );

    developer.log('before cleanup');
    await clientSubscription.cancel();
    client.destroy();
    await engine.stop();
      expect(engine.state, TcpServerState.stopped);
      expect(engine.clients, isEmpty);
      await engine.dispose();
    },
  );
}

Future<int> _freePort() async {
  final socket = await ServerSocket.bind('127.0.0.1', 0);
  final port = socket.port;
  await socket.close();
  return port;
}
