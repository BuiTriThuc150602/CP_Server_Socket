import 'package:fluxlab/core/storage/app_storage.dart';

class ModuleConfigRepository {
  ModuleConfigRepository({AppStorage? storage})
    : _storage = storage ?? JsonFileAppStorage();

  final AppStorage _storage;

  Future<Map<String, dynamic>?> read(String moduleKey) {
    return _storage.readJsonDocument('module_configs/$moduleKey.json');
  }

  Future<void> write(String moduleKey, Map<String, dynamic> value) {
    return _storage.writeJsonDocument('module_configs/$moduleKey.json', {
      ...value,
      'moduleKey': moduleKey,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
