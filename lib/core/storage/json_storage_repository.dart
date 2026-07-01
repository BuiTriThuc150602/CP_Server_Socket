import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class JsonStorageRepository {
  JsonStorageRepository({Directory? rootDirectory, Directory? legacyDirectory})
    : _rootDirectory = rootDirectory,
      _legacyDirectory = legacyDirectory;

  Directory? _rootDirectory;
  Directory? _legacyDirectory;

  Future<Directory> get rootDirectory async {
    final existing = _rootDirectory;
    if (existing != null) {
      await existing.create(recursive: true);
      return existing;
    }
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    _rootDirectory = dir;
    return dir;
  }

  Future<Directory> get legacyDirectory async {
    final existing = _legacyDirectory;
    if (existing != null) {
      await existing.create(recursive: true);
      return existing;
    }
    final dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    _legacyDirectory = dir;
    return dir;
  }

  Future<File> file(String filename) async {
    final dir = await rootDirectory;
    return File('${dir.path}${Platform.pathSeparator}$filename');
  }

  Future<File> legacyFile(String filename) async {
    final dir = await legacyDirectory;
    return File('${dir.path}${Platform.pathSeparator}$filename');
  }

  Future<Map<String, dynamic>?> readMap(String filename) async {
    final target = await file(filename);
    if (!await target.exists()) {
      return null;
    }
    return _readMapFile(target);
  }

  Future<Map<String, dynamic>?> readLegacyMap(String filename) async {
    final target = await legacyFile(filename);
    if (!await target.exists()) {
      return null;
    }
    return _readMapFile(target);
  }

  Future<void> writeMap(String filename, Map<String, dynamic> value) async {
    final target = await file(filename);
    await target.writeAsString(
      const JsonEncoder.withIndent('  ').convert(value),
      flush: true,
    );
  }

  Future<Map<String, dynamic>?> _readMapFile(File file) async {
    final text = await file.readAsString();
    if (text.trim().isEmpty) {
      return null;
    }
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return null;
  }
}
