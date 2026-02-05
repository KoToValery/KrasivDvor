import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/care_reminder.dart';
import '../../models/plant.dart';
import '../../models/client.dart';
import '../../../core/models/notification.dart';

class StorageService {
  late SharedPreferences _prefs;
  late Box _plantsBox;
  late Box _gardensBox;
  late Box _remindersBox;

  Future<void> init() async {
    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();

    // Initialize Hive boxes
    _plantsBox = await Hive.openBox('plants');
    _gardensBox = await Hive.openBox('gardens');
    _remindersBox = await Hive.openBox<CareReminder>('reminders');

    // Initialize new feature boxes
    await Hive.openBox<Plant>('catalog_plants');
    await Hive.openBox<Client>('clients');
    await Hive.openBox<Zone>('zones');
    await Hive.openBox<Contact>('contacts');
    await Hive.openBox<AppNotification>('notifications');
  }

  // Getters for boxes
  Box get plantsBox => _plantsBox;
  Box get gardensBox => _gardensBox;
  Box<CareReminder> get remindersBox => _remindersBox as Box<CareReminder>;

  // SharedPreferences methods
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  // Hive methods for complex data
  Future<void> storePlant(String id, Map<String, dynamic> plantData) async {
    await _plantsBox.put(id, plantData);
  }

  Map<String, dynamic>? getPlant(String id) {
    final data = _plantsBox.get(id);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  Future<void> storePlants(Map<String, Map<String, dynamic>> plants) async {
    await _plantsBox.putAll(plants);
  }

  Map<String, Map<String, dynamic>> getAllPlants() {
    final Map<String, Map<String, dynamic>> plants = {};
    for (final key in _plantsBox.keys) {
      final data = _plantsBox.get(key);
      if (data != null) {
        plants[key.toString()] = Map<String, dynamic>.from(data);
      }
    }
    return plants;
  }

  Future<void> storeGarden(String id, Map<String, dynamic> gardenData) async {
    await _gardensBox.put(id, gardenData);
  }

  Map<String, dynamic>? getGarden(String id) {
    final data = _gardensBox.get(id);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  Future<void> storeReminder(
      String id, Map<String, dynamic> reminderData) async {
    await _remindersBox.put(id, reminderData);
  }

  Map<String, dynamic>? getReminder(String id) {
    final data = _remindersBox.get(id);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  List<Map<String, dynamic>> getAllReminders() {
    final List<Map<String, dynamic>> reminders = [];
    for (final key in _remindersBox.keys) {
      final data = _remindersBox.get(key);
      if (data != null) {
        reminders.add(Map<String, dynamic>.from(data));
      }
    }
    return reminders;
  }

  Future<void> clearAllData() async {
    await _plantsBox.clear();
    await _gardensBox.clear();
    await _remindersBox.clear();
    await _prefs.clear();
  }

  // Cache management
  Future<void> setCacheTimestamp(String key) async {
    await setInt('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  bool isCacheValid(String key, Duration maxAge) {
    final timestamp = getInt('${key}_timestamp');
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cacheTime) < maxAge;
  }

  // File upload functionality
  /// Upload file to storage and return URL
  /// In a real implementation, this would upload to cloud storage (S3, CloudFlare R2, etc.)
  /// For now, this is a placeholder that simulates the upload
  Future<String> uploadFile(String filePath, String folder) async {
    try {
      // In a real implementation, this would:
      // 1. Read the file from filePath
      // 2. Upload to cloud storage (AWS S3, CloudFlare R2, etc.)
      // 3. Return the public URL

      // For now, simulate upload and return a mock URL
      final fileName = filePath.split('/').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final mockUrl =
          'https://storage.example.com/$folder/$timestamp-$fileName';

      // Store file path locally for offline access
      await setString('file_$timestamp', filePath);

      return mockUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }
}
