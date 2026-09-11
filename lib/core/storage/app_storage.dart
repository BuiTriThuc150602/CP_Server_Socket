import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract class AppStorage {
  Future<Map<String, dynamic>?> readJsonDocument(String key);

  Future<void> writeJsonDocument(String key, Map<String, dynamic> value);

  Future<void> deleteJsonDocument(String key);

  Future<List<String>> listJsonDocuments(String prefix);
}

class JsonFileAppStorage implements AppStorage {
  JsonFileAppStorage({Directory? rootDirectory})
    : _rootDirectory = rootDirectory;

  Directory? _rootDirectory;

  Future<Directory> get rootDirectory async {
    final existing = _rootDirectory;
    if (existing != null) {
      await existing.create(recursive: true);
      return existing;
    }
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    _rootDirectory = directory;
    return directory;
  }

  @override
  Future<Map<String, dynamic>?> readJsonDocument(String key) async {
    final target = await _fileForKey(key);
    if (!await target.exists()) {
      return null;
    }
    final text = await target.readAsString();
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

  @override
  Future<void> writeJsonDocument(String key, Map<String, dynamic> value) async {
    final target = await _fileForKey(key);
    await target.parent.create(recursive: true);
    await target.writeAsString(
      const JsonEncoder.withIndent('  ').convert(value),
      flush: true,
    );
  }

  @override
  Future<void> deleteJsonDocument(String key) async {
    final target = await _fileForKey(key);
    if (await target.exists()) {
      await target.delete();
    }
  }

  @override
  Future<List<String>> listJsonDocuments(String prefix) async {
    final root = await rootDirectory;
    if (!await root.exists()) {
      return const [];
    }
    final files =
        await root
            .list(recursive: true)
            .where(
              (entity) => entity is File && p.extension(entity.path) == '.json',
            )
            .cast<File>()
            .toList();
    return files
        .map(
          (file) =>
              p.relative(file.path, from: root.path).replaceAll(r'\', '/'),
        )
        .where((key) => key.startsWith(prefix))
        .toList()
      ..sort();
  }

  Future<File> _fileForKey(String key) async {
    final root = await rootDirectory;
    final safeKey = key.endsWith('.json') ? key : '$key.json';
    final normalized = p.normalize(safeKey).replaceAll(r'\', '/');
    if (normalized.startsWith('../') || p.isAbsolute(normalized)) {
      throw ArgumentError('Invalid storage key: $key');
    }
    return File(p.join(root.path, normalized));
  }
}
