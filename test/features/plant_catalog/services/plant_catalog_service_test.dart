import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:landscape_plant_catalog/core/services/api_service.dart';
import 'package:landscape_plant_catalog/core/services/storage_service.dart';
import 'package:landscape_plant_catalog/features/plant_catalog/services/plant_catalog_service.dart';
import 'package:landscape_plant_catalog/features/plant_catalog/services/compatibility_engine.dart';
import 'package:landscape_plant_catalog/models/models.dart';
import 'plant_catalog_service_test.mocks.dart';

@GenerateMocks([ApiService, StorageService, CompatibilityEngine])
void main() {
  group('PlantCatalogService API Integration Tests', () {
    late PlantCatalogService service;
    late MockApiService mockApiService;
    late MockStorageService mockStorageService;
    late MockCompatibilityEngine mockCompatibilityEngine;

    setUp(() {
      mockApiService = MockApiService();
      mockStorageService = MockStorageService();
      mockCompatibilityEngine = MockCompatibilityEngine();
      service = PlantCatalogService(mockApiService, mockStorageService, mockCompatibilityEngine);
    });

    group('Enhanced Search Functionality', () {
      test('should build comprehensive search query with all criteria', () {
        // Create comprehensive search criteria
        final criteria = SearchCriteria(
          name: 'Rose',
          category: PlantCategory.flowers,
          lightRequirement: LightRequirement.fullSun,
          waterRequirement: WaterRequirement.moderate,
          maxHeight: 200,
          minHeight: 50,
          maxWidth: 150,
          minWidth: 30,
          hardinessZone: 5,
          bloomSeason: [Season.spring, Season.summer],
          growthRate: GrowthRate.moderate,
          soilType: SoilType.loam,
          maxToxicityLevel: ToxicityLevel.mild,
          priceCategory: PriceCategory.standard,
        );

        // Test that hasFilters works correctly
        expect(criteria.hasFilters, isTrue);

        // Test copyWith functionality
        final updatedCriteria = criteria.copyWith(name: 'Tulip');
        expect(updatedCriteria.name, equals('Tulip'));
        expect(updatedCriteria.category, equals(PlantCategory.flowers));
      });

      test('should handle empty search criteria', () {
        final criteria = SearchCriteria();
        expect(criteria.hasFilters, isFalse);
      });

      test('should search plants with API call and fallback to cache', () async {
        // Mock API response
        when(mockApiService.get(any)).thenAnswer((_) async => {
          'data': [
            {
              'id': '1',
              'latinName': 'Rosa damascena',
              'bulgarianName': 'Дамасцена роза',
              'category': 'flowers',
              'imageUrls': ['image1.jpg'],
              'characteristics': {
                'description': 'Beautiful rose',
                'lightRequirement': 'fullSun',
                'waterRequirement': 'moderate',
                'preferredSoil': 'loam',
                'hardinessZone': 5,
              },
              'careRequirements': {
                'watering': {
                  'frequencyDays': 3,
                  'instructions': 'Water regularly',
                  'weatherDependent': true,
                },
                'fertilizing': {
                  'frequencyDays': 30,
                  'instructions': 'Monthly fertilizing',
                  'seasons': ['spring', 'summer'],
                },
                'pruning': {
                  'seasons': ['winter'],
                  'instructions': 'Prune in winter',
                },
                'seasonalCare': [],
              },
              'specifications': {
                'maxHeightCm': 150,
                'maxWidthCm': 100,
                'bloomSeason': ['spring', 'summer'],
                'growthRate': 'moderate',
              },
              'compatiblePlantIds': [],
              'toxicity': {
                'level': 'none',
                'warning': null,
              },
              'priceCategory': 'standard',
              'qrCode': 'QR123',
            }
          ]
        });

        final criteria = SearchCriteria(name: 'Rose');
        final results = await service.searchPlants(criteria);

        expect(results, isNotEmpty);
        expect(results.first.bulgarianName, contains('роза'));
        verify(mockApiService.get(any)).called(1);
      });

      test('should get plants by multiple categories', () async {
        // Mock API response
        when(mockApiService.get(any)).thenAnswer((_) async => {
          'data': []
        });

        final categories = [PlantCategory.flowers, PlantCategory.shrubs];
        await service.getPlantsByCategories(categories);

        verify(mockApiService.get(argThat(contains('categories=')))).called(1);
      });

      test('should get plants for specific conditions', () async {
        // Mock API response
        when(mockApiService.get(any)).thenAnswer((_) async => {
          'data': []
        });

        await service.getPlantsForConditions(
          lightCondition: LightRequirement.partialShade,
          waterCondition: WaterRequirement.low,
          soilCondition: SoilType.sand,
          hardinessZone: 6,
        );

        verify(mockApiService.get(argThat(contains('search')))).called(1);
      });

      test('should get plants by size range', () async {
        // Mock API response
        when(mockApiService.get(any)).thenAnswer((_) async => {
          'data': []
        });

        await service.getPlantsBySize(
          minHeight: 50,
          maxHeight: 200,
          minWidth: 30,
          maxWidth: 150,
        );

        verify(mockApiService.get(argThat(contains('search')))).called(1);
      });

      test('should get plants by bloom season', () async {
        // Mock API response
        when(mockApiService.get(any)).thenAnswer((_) async => {
          'data': []
        });

        await service.getPlantsByBloomSeason([Season.spring, Season.summer]);

        verify(mockApiService.get(argThat(contains('search')))).called(1);
      });

      test('should get safe plants with low toxicity', () async {
        // Mock API response
        when(mockApiService.get(any)).thenAnswer((_) async => {
          'data': []
        });

        await service.getSafePlants();

        verify(mockApiService.get(argThat(contains('search')))).called(1);
      });
    });

    group('API Error Handling', () {
      test('should fallback to cache when API fails', () async {
        // Mock API failure
        when(mockApiService.get(any)).thenThrow(Exception('Network error'));
        
        // Mock cached data
        when(mockStorageService.getAllPlants()).thenReturn({});

        final criteria = SearchCriteria(name: 'Rose');
        final results = await service.searchPlants(criteria);

        expect(results, isEmpty); // Should return empty list from cache
        verify(mockApiService.get(any)).called(1);
        verify(mockStorageService.getAllPlants()).called(1);
      });
    });
  });
}