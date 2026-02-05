import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../widgets/plant_combination_visualizer.dart';
import '../widgets/plant_image_gallery.dart';
import '../../../core/services/service_locator.dart';

/// Screen for creating and visualizing plant combinations
class PlantCombinationScreen extends StatefulWidget {
  final List<Plant>? initialPlants;

  const PlantCombinationScreen({
    super.key,
    this.initialPlants,
  });

  @override
  State<PlantCombinationScreen> createState() => _PlantCombinationScreenState();
}

class _PlantCombinationScreenState extends State<PlantCombinationScreen> {
  List<Plant> _selectedPlants = [];
  List<Plant> _availablePlants = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedPlants = widget.initialPlants ?? [];
    _loadAvailablePlants();
  }

  Future<void> _loadAvailablePlants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final plantCatalogService = ServiceLocator.plantCatalogService;
      final plants = await plantCatalogService.getAllPlants();
      
      setState(() {
        _availablePlants = plants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Комбиниране на растения'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    // Plant combination visualizer
                    PlantCombinationVisualizer(
                      selectedPlants: _selectedPlants,
                      onPlantsChanged: (plants) {
                        setState(() {
                          _selectedPlants = plants;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Plant selector
                    Expanded(
                      child: _buildPlantSelector(),
                    ),
                  ],
                ),
      floatingActionButton: _selectedPlants.length >= 2
          ? FloatingActionButton.extended(
              onPressed: _saveCombination,
              icon: const Icon(Icons.save),
              label: const Text('Запази комбинацията'),
            )
          : null,
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Грешка: $_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAvailablePlants,
            child: const Text('Опитай отново'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantSelector() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header with search
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Добави растения',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Търси растения...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ],
            ),
          ),
          // Plant grid
          Expanded(
            child: _buildPlantGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantGrid() {
    final filteredPlants = _availablePlants.where((plant) {
      if (_searchQuery.isEmpty) return true;
      
      return plant.bulgarianName.toLowerCase().contains(_searchQuery) ||
             plant.latinName.toLowerCase().contains(_searchQuery);
    }).where((plant) {
      // Don't show already selected plants
      return !_selectedPlants.any((selected) => selected.id == plant.id);
    }).toList();

    if (filteredPlants.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Няма намерени растения',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredPlants.length,
      itemBuilder: (context, index) {
        final plant = filteredPlants[index];
        return _buildPlantCard(plant);
      },
    );
  }

  Widget _buildPlantCard(Plant plant) {
    return Card(
      child: InkWell(
        onTap: () => _addPlantToCombination(plant),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plant image
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.grey[200],
                  ),
                  child: plant.imageUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: PlantImageGallery(
                            imageUrls: [plant.imageUrls.first],
                            plantName: plant.bulgarianName,
                            height: double.infinity,
                            showThumbnails: false,
                            enableZoom: false,
                          ),
                        )
                      : const Icon(Icons.local_florist, size: 40),
                ),
              ),
              const SizedBox(height: 8),
              // Plant info
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.bulgarianName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plant.latinName,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
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
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _getCategoryDisplayName(plant.category),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addPlantToCombination(Plant plant) {
    if (_selectedPlants.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Максимум 6 растения в комбинация'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _selectedPlants.add(plant);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${plant.bulgarianName} е добавено в комбинацията'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _saveCombination() {
    // This would typically save the combination to user's favorites or garden plan
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Запази комбинацията'),
        content: const Text('Искате ли да запазите тази комбинация от растения?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отказ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Комбинацията е запазена успешно!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Запази'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Как да използвам комбинатора'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Добавяне на растения',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Изберете растения от списъка долу, за да ги добавите в комбинацията.'),
              SizedBox(height: 12),
              Text(
                '2. Анализ на съвместимостта',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Системата автоматично анализира съвместимостта между растенията.'),
              SizedBox(height: 12),
              Text(
                '3. Преглед на резултатите',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Вижте силните и слабите страни на комбинацията, както и предложения за подобрение.'),
              SizedBox(height: 12),
              Text(
                '4. Запазване',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Запазете успешните комбинации за бъдеща употреба.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Разбрах'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getCategoryDisplayName(PlantCategory category) {
    switch (category) {
      case PlantCategory.trees: return 'Дървета';
      case PlantCategory.shrubs: return 'Храсти';
      case PlantCategory.flowers: return 'Цветя';
      case PlantCategory.grasses: return 'Треви';
      case PlantCategory.climbers: return 'Катерливи';
      case PlantCategory.aquatic: return 'Водни';
    }
  }

  IconData _getCategoryIcon(PlantCategory category) {
    switch (category) {
      case PlantCategory.trees: return Icons.park;
      case PlantCategory.shrubs: return Icons.nature;
      case PlantCategory.flowers: return Icons.local_florist;
      case PlantCategory.grasses: return Icons.grass;
      case PlantCategory.climbers: return Icons.trending_up;
      case PlantCategory.aquatic: return Icons.water;
    }
  }
}