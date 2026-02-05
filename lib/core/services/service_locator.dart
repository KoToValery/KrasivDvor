import '../../features/plant_catalog/services/plant_catalog_service.dart';
import '../../features/plant_catalog/services/compatibility_engine.dart';
import '../../features/garden_management/services/garden_service.dart';
import '../../features/care_reminders/services/care_reminder_service.dart';
import '../../features/care_reminders/services/notification_service.dart';
import '../../features/qr_scanner/services/qr_code_service.dart';
import '../../features/admin/services/admin_service.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'client_auth_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  static ServiceLocator get instance => _instance;
  
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};

  static Future<void> init() async {
    // Initialize core services
    final apiService = ApiService();
    final storageService = StorageService();
    await storageService.init();

    // Register core services
    _instance._services[ApiService] = apiService;
    _instance._services[StorageService] = storageService;

    // Initialize compatibility engine
    final compatibilityEngine = CompatibilityEngine();
    _instance._services[CompatibilityEngine] = compatibilityEngine;

    // Initialize and register feature services
    final plantCatalogService = PlantCatalogService(apiService, storageService, compatibilityEngine);
    final gardenService = GardenService(apiService, storageService);
    final careReminderService = CareReminderService(apiService, storageService.remindersBox);
    final notificationService = NotificationService();
    try {
      await notificationService.initialize();
    } catch (e) {
      print('NotificationService initialization failed: $e');
      // Continue even if notifications fail
    }
    final qrCodeService = QRCodeService(plantCatalogService);
    final adminService = AdminService(apiService, storageService);
    final clientAuthService = ClientAuthService(apiService);

    _instance._services[PlantCatalogService] = plantCatalogService;
    _instance._services[GardenService] = gardenService;
    _instance._services[CareReminderService] = careReminderService;
    _instance._services[NotificationService] = notificationService;
    _instance._services[QRCodeService] = qrCodeService;
    _instance._services[AdminService] = adminService;
    _instance._services[ClientAuthService] = clientAuthService;
  }

  // Generic getter for services
  T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service of type $T is not registered');
    }
    return service as T;
  }

  // Convenience getters for backward compatibility
  static ApiService get apiService => _instance.get<ApiService>();
  static StorageService get storageService => _instance.get<StorageService>();
  static CompatibilityEngine get compatibilityEngine => _instance.get<CompatibilityEngine>();
  static PlantCatalogService get plantCatalogService => _instance.get<PlantCatalogService>();
  static GardenService get gardenService => _instance.get<GardenService>();
  static CareReminderService get careReminderService => _instance.get<CareReminderService>();
  static NotificationService get notificationService => _instance.get<NotificationService>();
  static QRCodeService get qrCodeService => _instance.get<QRCodeService>();
  static AdminService get adminService => _instance.get<AdminService>();
  static ClientAuthService get clientAuthService => _instance.get<ClientAuthService>();
}