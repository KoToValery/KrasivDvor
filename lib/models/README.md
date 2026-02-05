# Data Models

This directory contains the core data models for the Landscape Plant Catalog application.

## Models Created

1. **Plant** (`plant.dart`) - Core plant data with characteristics, care requirements, and specifications
2. **ClientGarden** (`client_garden.dart`) - Client garden profiles with zones, notes, and documents
3. **PlantInstance** (`plant_instance.dart`) - Individual plant instances in client gardens
4. **CareReminder** (`care_reminder.dart`) - Care reminders with scheduling and weather dependencies

## Code Generation Required

The models use `json_serializable` and `hive_generator` for JSON serialization and Hive storage. 

**To generate the required .g.dart files, run:**

```bash
flutter packages pub run build_runner build
```

Or for continuous generation during development:

```bash
flutter packages pub run build_runner watch
```

## Features Implemented

- ✅ JSON serialization/deserialization for all models
- ✅ Hive offline storage support with type adapters
- ✅ Complete plant catalog data structure
- ✅ Client garden management with zones and documentation
- ✅ Plant instance tracking with care history
- ✅ Smart care reminders with weather dependencies
- ✅ Comprehensive enums for all plant characteristics

## Requirements Satisfied

- **Requirements 1.1, 1.2**: Plant catalog with categories and complete plant data
- **Requirements 4.2**: Client garden profiles with pre-populated plants
- **Requirements 5.1**: Care reminder system with plant-specific scheduling

## Next Steps

1. Run code generation to create .g.dart files
2. Initialize Hive type adapters in main.dart
3. Test model serialization/deserialization
4. Integrate with PlantCatalogService for full functionality