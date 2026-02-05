import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/models.dart';
import '../providers/plant_catalog_provider.dart';
import '../services/plant_catalog_service.dart';

class PlantCatalogScreen extends StatefulWidget {
  const PlantCatalogScreen({super.key});

  @override
  State<PlantCatalogScreen> createState() => _PlantCatalogScreenState();
}

class _PlantCatalogScreenState extends State<PlantCatalogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  
  // Filter state
  LightRequirement? _selectedLight;
  WaterRequirement? _selectedWater;
  GrowthRate? _selectedGrowthRate;
  PriceCategory? _selectedPrice;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: PlantCategory.values.length + 1, vsync: this);
    
    // Load plants when screen initializes
    print('DEBUG: Calling loadAllPlants from initState');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('DEBUG: Calling loadAllPlants from addPostFrameCallback');
      context.read<PlantCatalogProvider>().loadAllPlants();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог на растения'),
        actions: [
          // Small admin button in top right
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, size: 20),
            onPressed: () => context.push('/admin/login'),
            tooltip: 'Админ панел',
          ),
          IconButton(
            icon: const Icon(Icons.palette),
            onPressed: () => context.pushNamed('plant-combinations'),
            tooltip: 'Комбиниране на растения',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list : Icons.filter_list_off),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            const Tab(text: 'Всички'),
            ...PlantCategory.values.map((category) => Tab(
              text: _getCategoryDisplayName(category),
            )),
          ],
          onTap: (index) {
            if (index == 0) {
              context.read<PlantCatalogProvider>().loadAllPlants();
            } else {
              final category = PlantCategory.values[index - 1];
              context.read<PlantCatalogProvider>().loadPlantsByCategory(category);
            }
          },
        ),
      ),
      body: Column(
        children: [
          if (_showFilters) _buildFiltersSection(),
          Expanded(
            child: Consumer<PlantCatalogProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Грешка при зареждане: ${provider.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.loadAllPlants(),
                          child: const Text('Опитай отново'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.plants.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_florist, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Няма намерени растения',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/admin/login'),
                          icon: const Icon(Icons.admin_panel_settings),
                          label: const Text('Вход за администратори'),
                        ),
                      ],
                    ),
                  );
                }

                return _buildPlantGrid(provider.plants);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Филтри:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Изчисти всички'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterDropdown<LightRequirement>(
                'Светлина',
                _selectedLight,
                LightRequirement.values,
                (value) => setState(() => _selectedLight = value),
                _getLightDisplayName,
              ),
              _buildFilterDropdown<WaterRequirement>(
                'Вода',
                _selectedWater,
                WaterRequirement.values,
                (value) => setState(() => _selectedWater = value),
                _getWaterDisplayName,
              ),
              _buildFilterDropdown<GrowthRate>(
                'Растеж',
                _selectedGrowthRate,
                GrowthRate.values,
                (value) => setState(() => _selectedGrowthRate = value),
                _getGrowthRateDisplayName,
              ),
              _buildFilterDropdown<PriceCategory>(
                'Цена',
                _selectedPrice,
                PriceCategory.values,
                (value) => setState(() => _selectedPrice = value),
                _getPriceCategoryDisplayName,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _applyFilters,
            child: const Text('Приложи филтри'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>(
    String label,
    T? selectedValue,
    List<T> values,
    ValueChanged<T?> onChanged,
    String Function(T) getDisplayName,
  ) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<T>(
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        initialValue: selectedValue,
        items: [
          DropdownMenuItem<T>(
            value: null,
            child: Text(
              'Всички',
              style: TextStyle(color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...values.map((value) => DropdownMenuItem<T>(
            value: value,
            child: Text(
              getDisplayName(value),
              overflow: TextOverflow.ellipsis,
            ),
          )),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildPlantGrid(List<Plant> plants) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: plants.length,
      itemBuilder: (context, index) {
        final plant = plants[index];
        return _buildPlantCard(plant);
      },
    );
  }

  Widget _buildPlantCard(Plant plant) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/plant/${plant.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                ),
                child: plant.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: plant.imageUrls.first,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.local_florist, size: 48),
                        // Optimize for card thumbnails
                        memCacheWidth: 400,
                        memCacheHeight: 300,
                      )
                    : const Icon(Icons.local_florist, size: 48),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.bulgarianName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      plant.latinName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _getCategoryIcon(plant.category),
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _getCategoryDisplayName(plant.category),
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          _getLightIcon(plant.characteristics.lightRequirement),
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          _getWaterIcon(plant.characteristics.waterRequirement),
                          size: 14,
                          color: Colors.blue,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPriceCategoryColor(plant.priceCategory),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getPriceCategoryDisplayName(plant.priceCategory),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Търсене на растения'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Въведете име на растение...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) {
            Navigator.of(context).pop();
            _performSearch(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отказ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performSearch(_searchController.text);
            },
            child: const Text('Търси'),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      context.read<PlantCatalogProvider>().loadAllPlants();
    } else {
      context.read<PlantCatalogProvider>().searchPlants(query);
    }
  }

  void _applyFilters() {
    final criteria = SearchCriteria(
      lightRequirement: _selectedLight,
      waterRequirement: _selectedWater,
      growthRate: _selectedGrowthRate,
      priceCategory: _selectedPrice,
    );
    
    context.read<PlantCatalogProvider>().searchPlantsWithCriteria(criteria);
  }

  void _clearFilters() {
    setState(() {
      _selectedLight = null;
      _selectedWater = null;
      _selectedGrowthRate = null;
      _selectedPrice = null;
    });
    context.read<PlantCatalogProvider>().loadAllPlants();
  }

  // Helper methods for display names and icons
  String _getCategoryDisplayName(PlantCategory category) {
    switch (category) {
      case PlantCategory.trees:
        return 'Дървета';
      case PlantCategory.shrubs:
        return 'Храсти';
      case PlantCategory.flowers:
        return 'Цветя';
      case PlantCategory.grasses:
        return 'Треви';
      case PlantCategory.climbers:
        return 'Катерливи';
      case PlantCategory.aquatic:
        return 'Водни';
    }
  }

  IconData _getCategoryIcon(PlantCategory category) {
    switch (category) {
      case PlantCategory.trees:
        return Icons.park;
      case PlantCategory.shrubs:
        return Icons.nature;
      case PlantCategory.flowers:
        return Icons.local_florist;
      case PlantCategory.grasses:
        return Icons.grass;
      case PlantCategory.climbers:
        return Icons.trending_up;
      case PlantCategory.aquatic:
        return Icons.water;
    }
  }

  String _getLightDisplayName(LightRequirement light) {
    switch (light) {
      case LightRequirement.fullSun:
        return 'Пълно слънце';
      case LightRequirement.partialSun:
        return 'Частично слънце';
      case LightRequirement.partialShade:
        return 'Частична сянка';
      case LightRequirement.fullShade:
        return 'Пълна сянка';
    }
  }

  IconData _getLightIcon(LightRequirement light) {
    switch (light) {
      case LightRequirement.fullSun:
        return Icons.wb_sunny;
      case LightRequirement.partialSun:
        return Icons.wb_cloudy;
      case LightRequirement.partialShade:
        return Icons.cloud;
      case LightRequirement.fullShade:
        return Icons.nights_stay;
    }
  }

  String _getWaterDisplayName(WaterRequirement water) {
    switch (water) {
      case WaterRequirement.low:
        return 'Малко';
      case WaterRequirement.moderate:
        return 'Умерено';
      case WaterRequirement.high:
        return 'Много';
    }
  }

  IconData _getWaterIcon(WaterRequirement water) {
    switch (water) {
      case WaterRequirement.low:
        return Icons.water_drop_outlined;
      case WaterRequirement.moderate:
        return Icons.water_drop;
      case WaterRequirement.high:
        return Icons.waves;
    }
  }

  String _getGrowthRateDisplayName(GrowthRate rate) {
    switch (rate) {
      case GrowthRate.slow:
        return 'Бавен';
      case GrowthRate.moderate:
        return 'Умерен';
      case GrowthRate.fast:
        return 'Бърз';
    }
  }

  String _getPriceCategoryDisplayName(PriceCategory price) {
    switch (price) {
      case PriceCategory.budget:
        return 'Бюджет';
      case PriceCategory.standard:
        return 'Стандарт';
      case PriceCategory.premium:
        return 'Премиум';
    }
  }

  Color _getPriceCategoryColor(PriceCategory price) {
    switch (price) {
      case PriceCategory.budget:
        return Colors.green;
      case PriceCategory.standard:
        return Colors.orange;
      case PriceCategory.premium:
        return Colors.red;
    }
  }
}