import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'core/app.dart';
import 'core/services/service_locator.dart';
import 'core/services/pwa_service.dart';
import 'core/services/offline_sync_service.dart';
import 'models/care_reminder.dart';
import 'models/plant_instance.dart';
import 'models/plant.dart';
import 'models/client.dart' as client_models;
import 'models/client_garden.dart';
import 'core/models/notification.dart';
import 'core/models/contact.dart' as core_models;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Register care reminder adapters
  if (!Hive.isAdapterRegistered(17)) {
    Hive.registerAdapter(CareReminderAdapter());
  }
  if (!Hive.isAdapterRegistered(18)) {
    Hive.registerAdapter(ReminderFrequencyAdapter());
  }
  if (!Hive.isAdapterRegistered(19)) {
    Hive.registerAdapter(WeatherDependencyAdapter());
  }
  if (!Hive.isAdapterRegistered(32)) {
    Hive.registerAdapter(FrequencyTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(33)) {
    Hive.registerAdapter(WeatherConditionAdapter());
  }
  if (!Hive.isAdapterRegistered(31)) {
    Hive.registerAdapter(CareTypeAdapter());
  }

  // Register plant adapters
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(PlantAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(PlantCharacteristicsAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(CareRequirementsAdapter());
  }
  if (!Hive.isAdapterRegistered(48)) {
    Hive.registerAdapter(PlantSpecificationsAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(ToxicityInfoAdapter());
  }
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(WateringScheduleAdapter());
  }
  if (!Hive.isAdapterRegistered(45)) {
    Hive.registerAdapter(FertilizingScheduleAdapter());
  }
  if (!Hive.isAdapterRegistered(7)) {
    Hive.registerAdapter(PruningScheduleAdapter());
  }
  if (!Hive.isAdapterRegistered(8)) {
    Hive.registerAdapter(SeasonalCareAdapter());
  }
  if (!Hive.isAdapterRegistered(47)) {
    Hive.registerAdapter(WinterizingScheduleAdapter());
  }
  if (!Hive.isAdapterRegistered(20)) {
    Hive.registerAdapter(PlantCategoryAdapter());
  }
  if (!Hive.isAdapterRegistered(21)) {
    Hive.registerAdapter(LightRequirementAdapter());
  }
  if (!Hive.isAdapterRegistered(22)) {
    Hive.registerAdapter(WaterRequirementAdapter());
  }
  if (!Hive.isAdapterRegistered(23)) {
    Hive.registerAdapter(SoilTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(24)) {
    Hive.registerAdapter(SeasonAdapter());
  }
  if (!Hive.isAdapterRegistered(25)) {
    Hive.registerAdapter(GrowthRateAdapter());
  }
  if (!Hive.isAdapterRegistered(26)) {
    Hive.registerAdapter(ToxicityLevelAdapter());
  }
  if (!Hive.isAdapterRegistered(27)) {
    Hive.registerAdapter(PriceCategoryAdapter());
  }
  
  // Register plant instance adapters
  if (!Hive.isAdapterRegistered(15)) {
    Hive.registerAdapter(PlantInstanceAdapter());
  }
  if (!Hive.isAdapterRegistered(16)) {
    Hive.registerAdapter(CareRecordAdapter());
  }
  if (!Hive.isAdapterRegistered(29)) {
    Hive.registerAdapter(PlantSizeAdapter());
  }
  if (!Hive.isAdapterRegistered(30)) {
    Hive.registerAdapter(PlantStatusAdapter());
  }
  
  // Register client garden adapters
  if (!Hive.isAdapterRegistered(9)) {
    Hive.registerAdapter(ClientGardenAdapter());
  }
  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(ClientProfileAdapter());
  }
  if (!Hive.isAdapterRegistered(11)) {
    Hive.registerAdapter(GardenMasterPlanAdapter());
  }
  if (!Hive.isAdapterRegistered(12)) {
    Hive.registerAdapter(GardenZoneAdapter());
  }
  if (!Hive.isAdapterRegistered(13)) {
    Hive.registerAdapter(GardenNoteAdapter());
  }
  if (!Hive.isAdapterRegistered(14)) {
    Hive.registerAdapter(GardenDocumentAdapter());
  }
  if (!Hive.isAdapterRegistered(28)) {
    Hive.registerAdapter(DocumentTypeAdapter());
  }
  
  // Register client adapters
  if (!Hive.isAdapterRegistered(40)) {
    Hive.registerAdapter(client_models.ClientAdapter());
  }
  if (!Hive.isAdapterRegistered(41)) {
    Hive.registerAdapter(client_models.ZoneAdapter());
  }
  if (!Hive.isAdapterRegistered(42)) {
    Hive.registerAdapter(client_models.ZonePlantAdapter());
  }
  if (!Hive.isAdapterRegistered(43)) {
    // Contact from models/client.dart
    Hive.registerAdapter(client_models.ContactAdapter());
  }
  if (!Hive.isAdapterRegistered(44)) {
    Hive.registerAdapter(client_models.ContactTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(46)) {
    // CoreContact from core/models/contact.dart
    Hive.registerAdapter(core_models.CoreContactAdapter());
  }
  
  // Register notification adapter
  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(AppNotificationAdapter());
  }

  // Open all necessary boxes at startup
  try {
    await Hive.openBox<Plant>('catalog_plants');
    await Hive.openBox<client_models.Client>('clients');
    await Hive.openBox<client_models.Zone>('zones');
    await Hive.openBox<client_models.Contact>('contacts');
    await Hive.openBox<ClientGarden>('gardens');
    await Hive.openBox<PlantInstance>('plant_instances');
    await Hive.openBox<CareReminder>('care_reminders');
    await Hive.openBox<AppNotification>('notifications');
    debugPrint('All Hive boxes opened successfully');
  } catch (e) {
    debugPrint('Error opening Hive boxes: $e');
  }

  // Initialize Firebase for push notifications
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }
  }

  // Initialize service locator
  await ServiceLocator.init();

  // Initialize PWA service for web
  if (kIsWeb) {
    await PWAService().init();
    await OfflineSyncService().init();
  }

  runApp(const LandscapePlantCatalogApp());
}
