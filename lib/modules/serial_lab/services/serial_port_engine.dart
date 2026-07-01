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
      _errorController.add(_friendlySerialError(error));
      return const [];
    }
  }

  Future<void> open({required String name, required int baudRate, required int dataBits, required int stopBits, required int parity}) async {
    await close();
    try {
      final available = availablePorts();
      if (!available.contains(name)) {
        throw StateError('Serial port not found: $name.');
      }
      final port = SerialPort(name);
      final config =
          SerialPortConfig()
            ..baudRate = baudRate
            ..bits = dataBits
            ..stopBits = stopBits
            ..parity = parity;
      try {
        port.config = config;
      } finally {
        config.dispose();
      }
      if (!port.openReadWrite()) {
        final error = SerialPort.lastError;
        port.dispose();
        throw error ?? StateError('Could not open serial port $name.');
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
      _errorController.add(_friendlySerialError(error));
      _setState(SerialEngineState.error);
      rethrow;
    }
  }

  void sendBytes(List<int> bytes) {
    final port = _port;
    if (port == null || !port.isOpen) {
      throw StateError('Serial port is not open.');
    }
    final written = port.write(Uint8List.fromList(bytes));
    if (written != bytes.length) {
      final error = StateError('Serial write incomplete: wrote $written/${bytes.length} bytes.');
      _errorController.add(error);
      throw error;
    }
    _outgoingController.add(bytes);
  }

  void sendText(String text) => sendBytes(utf8.encode(text));

  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    _reader = null;
    try {
      _port?.close();
    } finally {
      _port?.dispose();
    }
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

  String _friendlySerialError(Object error) {
    final text = error.toString();
    final lower = text.toLowerCase();
    if (lower.contains('permission') || lower.contains('access is denied')) {
      return 'Permission denied while opening serial port. Close other apps or run with suitable permissions. ($text)';
    }
    if (lower.contains('busy') || lower.contains('already') || lower.contains('in use')) {
      return 'Serial port is busy or already open. Close the other connection and retry. ($text)';
    }
    if (lower.contains('not found') || lower.contains('no such')) {
      return 'Serial port not found. Refresh the port list and check the cable. ($text)';
    }
    if (lower.contains('unsupported') || lower.contains('failed to load') || lower.contains('library')) {
      return 'Serial library is unavailable or unsupported on this platform. ($text)';
    }
    return text;
  }
}
