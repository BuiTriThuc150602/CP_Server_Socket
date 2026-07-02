import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class LoggerService {
  LoggerService._();

  static final LoggerService instance = LoggerService._();

  Directory? _logDir;
  File? _logFile;
  final Queue<String> _queue = Queue<String>();
  bool _isWriting = false;

  String? get logDirectoryPath => _logDir?.path;

  Future<void> init({Directory? directory}) async {
    try {
      final baseDir = directory ?? await getApplicationSupportDirectory();
      _logDir = Directory('${baseDir.path}${Platform.pathSeparator}logs');
      if (!await _logDir!.exists()) {
        await _logDir!.create(recursive: true);
      }
      await _createTodayLogFile();
    } catch (error, stackTrace) {
      developer.log(
        'Logger initialization failed',
        name: 'FluxLab.Logger',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> info(String message) => _write('INFO', message);

  Future<void> error(String message, [Object? error, StackTrace? stackTrace]) {
    final suffix = error == null ? '' : ' | $error';
    if (error != null) {
      developer.log(
        message,
        name: 'FluxLab.Logger',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return _write('ERROR', '$message$suffix');
  }

  Future<void> socket(String message) => _write('SOCKET', message);

  Future<List<FileSystemEntity>> listLogs() async {
    final dir = _logDir;
    if (dir == null || !await dir.exists()) {
      return const [];
    }
    return dir.list().toList();
  }

  Future<String> readLog(String filename) async {
    final dir = _logDir;
    if (dir == null) {
      return 'Logger is not initialized';
    }
    try {
      final file = File('${dir.path}${Platform.pathSeparator}$filename');
      final bytes = await file.readAsBytes();
      return utf8.decode(bytes, allowMalformed: true);
    } catch (error, stackTrace) {
      await this.error('Error reading log file', error, stackTrace);
      return 'Error reading log file: $error';
    }
  }

  Future<void> _createTodayLogFile() async {
    final dir = _logDir;
    if (dir == null) {
      throw StateError('Logger directory is not initialized');
    }
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _logFile = File('${dir.path}${Platform.pathSeparator}$date.log');
    if (!await _logFile!.exists()) {
      await _logFile!.create(recursive: true);
    }
  }

  Future<void> _write(String level, String message) async {
    final timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());
    _queue.add('[$timestamp] [$level] $message\n');
    if (!_isWriting) {
      unawaited(_processQueue());
    }
  }

  Future<void> _processQueue() async {
    if (_isWriting || _queue.isEmpty) {
      return;
    }

    _isWriting = true;
    try {
      await _createTodayLogFile();
      final batch = StringBuffer();
      while (_queue.isNotEmpty) {
        batch.write(_queue.removeFirst());
      }
      await _logFile!.writeAsString(
        batch.toString(),
        mode: FileMode.append,
        flush: true,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Logger write failed',
        name: 'FluxLab.Logger',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _isWriting = false;
      if (_queue.isNotEmpty) {
        unawaited(_processQueue());
      }
    }
  }
}
