import 'package:testdeck/app/app_settings.dart';
import 'package:testdeck/core/storage/json_storage_repository.dart';

class AppSettingsRepository {
  AppSettingsRepository({JsonStorageRepository? storage})
    : _storage = storage ?? JsonStorageRepository();

  static const _filename = 'app_settings.json';

  final JsonStorageRepository _storage;

  Future<AppSettings> load() async {
    final json = await _storage.readMap(_filename);
    if (json == null) {
      return AppSettings.defaults();
    }
    return AppSettings.fromJson(json);
  }

  Future<void> save(AppSettings settings) {
    return _storage.writeMap(_filename, settings.toJson());
  }
}
