import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_libserialport/flutter_libserialport.dart';

enum SerialEngineState { closed, open, error }

class SerialPortEngine {
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription<Uint8List>? _subscription;
  SerialEngineState _state = SerialEngineState.closed;

  final _stateController = StreamController<SerialEngineState>.broadcast();
  final _incomingController = StreamController<List<int>>.broadcast();
  final _outgoingController = StreamController<List<int>>.broadcast();
  final _errorController = StreamController<Object>.broadcast();

  SerialEngineState get state => _state;
  Stream<SerialEngineState> get states => _stateController.stream;
  Stream<List<int>> get incoming => _incomingController.stream;
  Stream<List<int>> get outgoing => _outgoingController.stream;
  Stream<Object> get errors => _errorController.stream;

  List<String> availablePorts() {
    try {
      return SerialPort.availablePorts;
    } catch (error) {
      _errorController.add(error);
      return const [];
    }
  }

  Future<void> open({
    required String name,
    required int baudRate,
    required int dataBits,
    required int stopBits,
    required int parity,
  }) async {
    await close();
    try {
      final port = SerialPort(name);
      final config =
          SerialPortConfig()
            ..baudRate = baudRate
            ..bits = dataBits
            ..stopBits = stopBits
            ..parity = parity;
      port.config = config;
      if (!port.openReadWrite()) {
        throw SerialPort.lastError ?? StateError('Could not open serial port.');
      }
      _port = port;
      _reader = SerialPortReader(port);
      _subscription = _reader!.stream.listen(
        (bytes) => _incomingController.add(bytes),
        onError: (Object error) {
          _errorController.add(error);
          _setState(SerialEngineState.error);
        },
      );
      _setState(SerialEngineState.open);
    } catch (error) {
      _errorController.add(error);
      _setState(SerialEngineState.error);
      rethrow;
    }
  }

  void sendBytes(List<int> bytes) {
    final port = _port;
    if (port == null || !port.isOpen) {
      throw StateError('Serial port is not open.');
    }
    port.write(Uint8List.fromList(bytes));
    _outgoingController.add(bytes);
  }

  void sendText(String text) => sendBytes(utf8.encode(text));

  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    _reader = null;
    _port?.close();
    _port?.dispose();
    _port = null;
    _setState(SerialEngineState.closed);
  }

  Future<void> dispose() async {
    await close();
    await _stateController.close();
    await _incomingController.close();
    await _outgoingController.close();
    await _errorController.close();
  }

  void _setState(SerialEngineState state) {
    _state = state;
    if (!_stateController.isClosed) {
      _stateController.add(state);
    }
  }
}
