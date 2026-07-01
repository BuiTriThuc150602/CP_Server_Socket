import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  late Directory _logDir;
  late File _logFile;
  final Queue<String> _logQueue = Queue<String>();
  bool _isWriting = false;

  factory LoggerService() => _instance;

  LoggerService._internal();

  Future<void> init() async {
    final currentAppDir = p.dirname(Platform.resolvedExecutable);
    _logDir = Directory(p.join(currentAppDir, 'logs'));
    if (!await _logDir.exists()) {
      await _logDir.create(recursive: true);
    }
    await _createTodayLogFile();
  }

  Future<void> _createTodayLogFile() async {
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _logFile = File('${_logDir.path}/$date.log');
    if (!await _logFile.exists()) {
      await _logFile.create();
    }
  }

  Future<void> log(String message, {bool isError = false}) async {
    final timestamp = DateFormat('HH:mm:ss.SSS').format(DateTime.now());
    final logMessage = '[$timestamp] ${isError ? '[ERROR]' : '[INFO]'} $message\n';
    _logQueue.add(logMessage);
    if (!_isWriting) {
      _processQueue();
    }
  }

  Future<void> logError(String message) async {
    await log(message, isError: true);
  }

  Future<void> _processQueue() async {
    if (_isWriting || _logQueue.isEmpty) return;

    _isWriting = true;

    try {
      // Create/Update file reference before writing
      await _createTodayLogFile();

      // Get batch of logs to write
      final batch = StringBuffer();
      while (_logQueue.isNotEmpty) {
        batch.write(_logQueue.removeFirst());
      }

      await _logFile.writeAsString(batch.toString(), mode: FileMode.append, flush: true);
    } catch (e) {
    } finally {
      _isWriting = false;
      // Check if new logs arrived while writing
      if (_logQueue.isNotEmpty) {
        _processQueue();
      }
    }
  }

  Future<List<FileSystemEntity>> listLogs() async {
    return _logDir.list().toList();
  }

  Future<String> readLog(String filename) async {
    final file = File('${_logDir.path}/$filename');
    // return await file.readAsString();
    try {
      final bytes = await file.readAsBytes();
      return utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      await log('Error reading log file: $e');
      return 'Error reading log file: $e';
    }
  }
}
