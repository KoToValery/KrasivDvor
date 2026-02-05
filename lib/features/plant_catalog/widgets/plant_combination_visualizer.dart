import 'package:flutter/material.dart';
import '../../../models/models.dart';
import '../services/compatibility_engine.dart';
import '../../../core/services/service_locator.dart';
import 'plant_image_gallery.dart';

/// Widget for visualizing plant combinations and their compatibility
class PlantCombinationVisualizer extends StatefulWidget {
  final List<Plant> selectedPlants;
  final Function(List<Plant>)? onPlantsChanged;

  const PlantCombinationVisualizer({
    super.key,
    required this.selectedPlants,
    this.onPlantsChanged,
  });

  @override
  State<PlantCombinationVisualizer> createState() => _PlantCombinationVisualizerState();
}

class _PlantCombinationVisualizerState extends State<PlantCombinationVisualizer> {
  PlantCombinationAnalysis? _analysis;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedPlants.isNotEmpty) {
      _analyzeCombination();
    }
  }

  @override
  void didUpdateWidget(PlantCombinationVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPlants != oldWidget.selectedPlants) {
      _analyzeCombination();
    }
  }

  Future<void> _analyzeCombination() async {
    if (widget.selectedPlants.isEmpty) {
      setState(() {
        _analysis = null;
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final compatibilityEngine = ServiceLocator.compatibilityEngine;
      final analysis = compatibilityEngine.analyzePlantCombination(widget.selectedPlants);
      
      setState(() {
        _analysis = analysis;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (widget.selectedPlants.isEmpty)
              _buildEmptyState()
            else ...[
              _buildPlantGrid(),
              const SizedBox(height: 16),
              if (_isAnalyzing)
                const Center(child: CircularProgressIndicator())
              else if (_analysis != null) ...[
                _buildAnalysisResults(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.palette,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        const Text(
          'Визуализация на комбинацията',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (widget.selectedPlants.isNotEmpty)
          TextButton.icon(
            onPressed: _clearSelection,
            icon: const Icon(Icons.clear),
            label: const Text('Изчисти'),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Изберете растения за визуализация',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Добавете растения, за да видите как се комбинират',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantGrid() {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.selectedPlants.length + 1,
        itemBuilder: (context, index) {
          if (index == widget.selectedPlants.length) {
            return _buildAddPlantCard();
          }
          
          final plant = widget.selectedPlants[index];
          return _buildPlantCard(plant, index);
        },
      ),
    );
  }

  Widget _buildPlantCard(Plant plant, int index) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Card(
        child: InkWell(
          onTap: () => _showPlantOptions(plant, index),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // Plant image
                Container(
                  width: 60,
                  height: 60,
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
                            height: 60,
                            showThumbnails: false,
                            enableZoom: false,
                          ),
                        )
                      : const Icon(Icons.local_florist, size: 30),
                ),
                const SizedBox(height: 4),
                // Plant name
                Text(
                  plant.bulgarianName,
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddPlantCard() {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Card(
        child: InkWell(
          onTap: _showPlantSelector,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                style: BorderStyle.solid,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Добави растение',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisResults() {
    if (_analysis == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall harmony score
        _buildHarmonyScore(),
        const SizedBox(height: 16),
        // Strengths and weaknesses
        if (_analysis!.strengths.isNotEmpty) ...[
          _buildAnalysisSection(
            'Силни страни',
            Icons.check_circle,
            Colors.green,
            _analysis!.strengths,
          ),
          const SizedBox(height: 12),
        ],
        if (_analysis!.weaknesses.isNotEmpty) ...[
          _buildAnalysisSection(
            'Слаби страни',
            Icons.warning,
            Colors.orange,
            _analysis!.weaknesses,
          ),
          const SizedBox(height: 12),
        ],
        if (_analysis!.suggestions.isNotEmpty) ...[
          _buildAnalysisSection(
            'Предложения',
            Icons.lightbulb_outline,
            Colors.blue,
            _analysis!.suggestions,
          ),
        ],
      ],
    );
  }

  Widget _buildHarmonyScore() {
    final score = _analysis!.overallHarmony;
    final percentage = (score * 100).toInt();
    final color = _getHarmonyColor(score);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Обща хармония',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getHarmonyDescription(score),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.grey[300],
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: score,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(
    String title,
    IconData icon,
    Color color,
    List<String> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 28, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: TextStyle(color: color)),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  void _showPlantOptions(Plant plant, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Детайли за растението'),
              onTap: () {
                Navigator.pop(context);
                _showPlantDetails(plant);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Премахни от комбинацията'),
              onTap: () {
                Navigator.pop(context);
                _removePlant(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPlantSelector() {
    // This would typically open a plant selection dialog
    // For now, we'll show a simple message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Функционалността за избор на растения ще бъде добавена скоро'),
      ),
    );
  }

  void _showPlantDetails(Plant plant) {
    Navigator.of(context).pushNamed('/plant-detail', arguments: plant.id);
  }

  void _removePlant(int index) {
    final updatedPlants = List<Plant>.from(widget.selectedPlants);
    updatedPlants.removeAt(index);
    widget.onPlantsChanged?.call(updatedPlants);
  }

  void _clearSelection() {
    widget.onPlantsChanged?.call([]);
  }

  Color _getHarmonyColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getHarmonyDescription(double score) {
    if (score >= 0.8) return 'Отлична хармония - растенията се допълват перфектно';
    if (score >= 0.6) return 'Добра хармония - растенията работят добре заедно';
    if (score >= 0.4) return 'Задоволителна хармония - има място за подобрение';
    return 'Слаба хармония - препоръчва се преразглеждане на избора';
  }
}