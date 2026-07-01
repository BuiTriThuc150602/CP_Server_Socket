import 'dart:io';

class SocketService {
  ServerSocket? _serverSocket;
  final List<Socket> _clients = [];

  Future<ServerSocket> start(int port, void Function(Socket) onClient) async {
    _serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
    _serverSocket!.listen(onClient);
    return _serverSocket!;
  }

  void sendToClients(String data) {
    for (final c in _clients) {
      c.write('$data\n');
    }
  }

  void addClient(Socket client) => _clients.add(client);

  void removeClient(Socket client) {
    client.destroy();
    _clients.remove(client);
  }

  List<Socket> get clients => _clients;

  Future<void> stop() async {
    await _serverSocket?.close();
    for (var c in _clients) {
      await c.close();
    }
    _clients.clear();
  }
}
