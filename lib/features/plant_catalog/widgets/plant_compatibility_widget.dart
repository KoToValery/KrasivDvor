import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../services/compatibility_engine.dart';
import '../../../core/services/service_locator.dart';
import 'plant_image_gallery.dart';

/// Widget for displaying plant compatibility information and suggestions
class PlantCompatibilityWidget extends StatefulWidget {
  final Plant plant;

  const PlantCompatibilityWidget({
    super.key,
    required this.plant,
  });

  @override
  State<PlantCompatibilityWidget> createState() => _PlantCompatibilityWidgetState();
}

class _PlantCompatibilityWidgetState extends State<PlantCompatibilityWidget> {
  List<Plant> _compatiblePlants = [];
  List<CompatibilityResult> _compatibilityResults = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCompatiblePlants();
  }

  Future<void> _loadCompatiblePlants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final plantCatalogService = ServiceLocator.plantCatalogService;
      final compatibilityEngine = ServiceLocator.compatibilityEngine;
      
      // Get all plants for compatibility analysis
      final allPlants = await plantCatalogService.getAllPlants();
      
      // Find compatible plants using the compatibility engine
      final compatibilityResults = compatibilityEngine.findCompatiblePlants(
        widget.plant,
        allPlants,
        minCompatibilityScore: 0.5,
        maxResults: 20,
      );
      
      // Get the actual plant objects
      final compatiblePlants = <Plant>[];
      for (final result in compatibilityResults) {
        final plant = allPlants.firstWhere(
          (p) => p.id == result.plant2Id || p.id == result.plant1Id,
          orElse: () => allPlants.first,
        );
        if (plant.id != widget.plant.id) {
          compatiblePlants.add(plant);
        }
      }
      
      setState(() {
        _compatiblePlants = compatiblePlants;
        _compatibilityResults = compatibilityResults;
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
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
              onPressed: _loadCompatiblePlants,
              child: const Text('Опитай отново'),
            ),
          ],
        ),
      );
    }

    if (_compatiblePlants.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_work, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Няма намерени съвместими растения',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompatibilityOverview(),
          const SizedBox(height: 24),
          _buildCompatiblePlantsList(),
          const SizedBox(height: 24),
          _buildPlantCombinationTips(),
        ],
      ),
    );
  }

  Widget _buildCompatibilityOverview() {
    if (_compatibilityResults.isEmpty) return const SizedBox.shrink();

    final averageScore = _compatibilityResults
        .map((r) => r.overallScore)
        .reduce((a, b) => a + b) / _compatibilityResults.length;

    final excellentCount = _compatibilityResults
        .where((r) => r.compatibilityLevel == CompatibilityLevel.excellent)
        .length;
    final goodCount = _compatibilityResults
        .where((r) => r.compatibilityLevel == CompatibilityLevel.good)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Анализ на съвместимостта',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildScoreCard(
                    'Средна съвместимост',
                    '${(averageScore * 100).toInt()}%',
                    _getScoreColor(averageScore),
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildScoreCard(
                    'Отлични съвпадения',
                    '$excellentCount',
                    Colors.green,
                    Icons.star,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildScoreCard(
                    'Добри съвпадения',
                    '$goodCount',
                    Colors.orange,
                    Icons.thumb_up,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatiblePlantsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.group_work,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text(
              'Съвместими растения',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _compatiblePlants.length,
          itemBuilder: (context, index) {
            final plant = _compatiblePlants[index];
            final compatibilityResult = _compatibilityResults.firstWhere(
              (r) => r.plant1Id == plant.id || r.plant2Id == plant.id,
              orElse: () => _compatibilityResults.first,
            );
            
            return _buildCompatiblePlantCard(plant, compatibilityResult);
          },
        ),
      ],
    );
  }

  Widget _buildCompatiblePlantCard(Plant plant, CompatibilityResult compatibility) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showPlantDetails(plant),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  // Plant image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: plant.imageUrls.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: PlantImageGallery(
                              imageUrls: [plant.imageUrls.first],
                              plantName: plant.bulgarianName,
                              height: 60,
                              showThumbnails: false,
                              enableZoom: false,
                            ),
                          )
                        : const Icon(Icons.local_florist, size: 30),
                  ),
                  const SizedBox(width: 12),
                  // Plant info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plant.bulgarianName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          plant.latinName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
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
                            Text(
                              _getCategoryDisplayName(plant.category),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Compatibility score
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getCompatibilityColor(compatibility.compatibilityLevel),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(compatibility.overallScore * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getCompatibilityLevelDisplayName(compatibility.compatibilityLevel),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (compatibility.reasons.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Причини за съвместимост:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...compatibility.reasons.take(2).map((reason) => 
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontSize: 12)),
                              Expanded(
                                child: Text(
                                  reason,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlantCombinationTips() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Съвети за комбиниране',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTipItem(
              Icons.wb_sunny,
              'Светлинни изисквания',
              _getLightTip(widget.plant.characteristics.lightRequirement),
            ),
            const SizedBox(height: 12),
            _buildTipItem(
              Icons.water_drop,
              'Водни изисквания',
              _getWaterTip(widget.plant.characteristics.waterRequirement),
            ),
            const SizedBox(height: 12),
            _buildTipItem(
              Icons.straighten,
              'Височина и структура',
              _getHeightTip(widget.plant.specifications.maxHeightCm),
            ),
            const SizedBox(height: 12),
            _buildTipItem(
              Icons.local_florist,
              'Сезонен интерес',
              _getSeasonalTip(widget.plant.specifications.bloomSeason),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String title, String tip) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                tip,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPlantDetails(Plant plant) {
    Navigator.of(context).pushNamed('/plant-detail', arguments: plant.id);
  }

  // Helper methods
  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getCompatibilityColor(CompatibilityLevel level) {
    switch (level) {
      case CompatibilityLevel.excellent:
        return Colors.green;
      case CompatibilityLevel.good:
        return Colors.orange;
      case CompatibilityLevel.fair:
        return Colors.deepOrange;
      case CompatibilityLevel.poor:
        return Colors.red;
    }
  }

  String _getCompatibilityLevelDisplayName(CompatibilityLevel level) {
    switch (level) {
      case CompatibilityLevel.excellent:
        return 'Отлично';
      case CompatibilityLevel.good:
        return 'Добро';
      case CompatibilityLevel.fair:
        return 'Задоволително';
      case CompatibilityLevel.poor:
        return 'Слабо';
    }
  }

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

  String _getLightTip(LightRequirement light) {
    switch (light) {
      case LightRequirement.fullSun:
        return 'Комбинирайте с други растения, които обичат пълно слънце. Избягвайте сенколюбиви видове.';
      case LightRequirement.partialSun:
        return 'Подходящо за комбиниране с повечето растения. Може да се съчетае с видове за пълно слънце или частична сянка.';
      case LightRequirement.partialShade:
        return 'Отлично за комбиниране с други сенколюбиви растения. Избягвайте видове за пълно слънце.';
      case LightRequirement.fullShade:
        return 'Комбинирайте само с други сенколюбиви растения. Идеално за подлесни композиции.';
    }
  }

  String _getWaterTip(WaterRequirement water) {
    switch (water) {
      case WaterRequirement.low:
        return 'Комбинирайте с други засухоустойчиви растения. Избягвайте влаголюбиви видове.';
      case WaterRequirement.moderate:
        return 'Универсално за комбиниране. Може да се съчетае с повечето растения.';
      case WaterRequirement.high:
        return 'Комбинирайте с други влаголюбиви растения. Подходящо за влажни зони.';
    }
  }

  String _getHeightTip(int height) {
    if (height > 300) {
      return 'Високо растение - използвайте като фон или акцент. Комбинирайте с по-ниски видове отпред.';
    } else if (height > 100) {
      return 'Средна височина - отлично за средния план. Комбинирайте с високи и ниски растения.';
    } else {
      return 'Ниско растение - идеално за преден план или като покривка. Комбинирайте с по-високи видове.';
    }
  }

  String _getSeasonalTip(List<Season> seasons) {
    if (seasons.isEmpty) {
      return 'Не цъфти - комбинирайте с цъфтящи растения за цветен акцент.';
    } else if (seasons.length >= 3) {
      return 'Дълъг период на цъфтеж - отличен избор за основа на композицията.';
    } else {
      return 'Комбинирайте с растения, които цъфтят в други сезони за продължителен интерес.';
    }
  }
}