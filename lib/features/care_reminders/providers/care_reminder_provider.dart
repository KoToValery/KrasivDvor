import 'package:flutter/foundation.dart';
import '../../../models/care_reminder.dart';
import '../../../models/plant_instance.dart';
import '../../../models/plant.dart';
import '../services/care_reminder_service.dart';
import '../services/notification_service.dart';

class CareReminderProvider extends ChangeNotifier {
  final CareReminderService _careReminderService;
  final NotificationService _notificationService;

  CareReminderProvider(this._careReminderService, this._notificationService);

  List<CareReminder> _reminders = [];
  bool _isLoading = false;
  String? _error;

  List<CareReminder> get reminders => _reminders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load active reminders for a client
  Future<void> loadReminders(String clientId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reminders = await _careReminderService.getActiveReminders(clientId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark a reminder as completed
  Future<void> completeReminder(String reminderId) async {
    try {
      await _careReminderService.markReminderComplete(reminderId);
      await _notificationService.cancelReminderNotification(reminderId);
      
      // Update local list
      _reminders = _reminders.where((r) => r.id != reminderId).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Postpone a reminder
  Future<void> postponeReminder(String reminderId, Duration delay) async {
    try {
      await _careReminderService.postponeReminder(reminderId, delay);
      
      // Update local list
      final index = _reminders.indexWhere((r) => r.id == reminderId);
      if (index != -1) {
        final reminder = _reminders[index];
        final updated = CareReminder(
          id: reminder.id,
          clientId: reminder.clientId,
          plantInstanceId: reminder.plantInstanceId,
          careType: reminder.careType,
          scheduledDate: reminder.scheduledDate.add(delay),
          frequency: reminder.frequency,
          instructions: reminder.instructions,
          isCompleted: reminder.isCompleted,
          weatherDependency: reminder.weatherDependency,
          completedAt: reminder.completedAt,
          createdAt: reminder.createdAt,
        );
        _reminders[index] = updated;
        
        // Reschedule notification
        await _notificationService.cancelReminderNotification(reminderId);
        await _notificationService.scheduleReminderNotification(updated);
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Generate reminders for a plant instance
  Future<void> generateRemindersForPlant(
    String clientId,
    PlantInstance plantInstance,
    Plant plant,
  ) async {
    try {
      final newReminders = await _careReminderService.generateRemindersForPlant(
        clientId,
        plantInstance,
        plant,
      );
      
      // Schedule notifications for new reminders
      for (final reminder in newReminders) {
        await _notificationService.scheduleReminderNotification(reminder);
      }
      
      // Add to local list
      _reminders.addAll(newReminders);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update reminders based on weather
  Future<void> updateForWeather(String clientId, double latitude, double longitude) async {
    try {
      await _careReminderService.updateRemindersForWeather(clientId, latitude, longitude);
      await loadReminders(clientId); // Reload to get updated reminders
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}