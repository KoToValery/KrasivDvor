import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/plant_instance.dart';
import '../providers/garden_provider.dart';
import '../../plant_catalog/providers/plant_catalog_provider.dart';

/// Screen displaying planting history timeline
class PlantingHistoryScreen extends StatefulWidget {
  final String clientId;

  const PlantingHistoryScreen({
    Key? key,
    required this.clientId,
  }) : super(key: key);

  @override
  State<PlantingHistoryScreen> createState() => _PlantingHistoryScreenState();
}

class _PlantingHistoryScreenState extends State<PlantingHistoryScreen> {
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final gardenProvider = context.read<GardenProvider>();
    await gardenProvider.loadPlantingHistory(widget.clientId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История на засаждане'),
        elevation: 0,
      ),
      body: Consumer<GardenProvider>(
        builder: (context, gardenProvider, child) {
          if (gardenProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (gardenProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Грешка: ${gardenProvider.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadHistory,
                    child: const Text('Опитай отново'),
                  ),
                ],
              ),
            );
          }

          final history = gardenProvider.plantingHistory;

          if (history.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Няма история на засаждане',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadHistory,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final plantInstance = history[index];
                return _PlantingHistoryItem(
                  plantInstance: plantInstance,
                  clientId: widget.clientId,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PlantingHistoryItem extends StatelessWidget {
  final PlantInstance plantInstance;
  final String clientId;

  const _PlantingHistoryItem({
    required this.plantInstance,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context) {
    final catalogProvider = context.watch<PlantCatalogProvider>();

    return FutureBuilder(
      future: catalogProvider.getPlantById(plantInstance.plantId),
      builder: (context, snapshot) {
        final plant = snapshot.data;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/plant-instance-detail',
                arguments: {
                  'plantInstanceId': plantInstance.id,
                  'clientId': clientId,
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline indicator
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getStatusColor(plantInstance.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 60,
                        color: Colors.grey[300],
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Plant info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plant?.bulgarianName ?? 'Неизвестно растение',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plant?.latinName ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd.MM.yyyy').format(plantInstance.plantedDate),
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 16),
                            _StatusChip(status: plantInstance.status),
                          ],
                        ),
                        if (plantInstance.progressPhotos.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.photo_library, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${plantInstance.progressPhotos.length} снимки',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Thumbnail
                  if (plant != null && plant.imageUrls.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        plant.imageUrls.first,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(PlantStatus status) {
    switch (status) {
      case PlantStatus.healthy:
        return Colors.green;
      case PlantStatus.establishing:
        return Colors.blue;
      case PlantStatus.stressed:
        return Colors.orange;
      case PlantStatus.diseased:
        return Colors.red;
      case PlantStatus.dead:
      case PlantStatus.removed:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final PlantStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor(status)),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          fontSize: 12,
          color: _getStatusColor(status),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(PlantStatus status) {
    switch (status) {
      case PlantStatus.healthy:
        return Colors.green;
      case PlantStatus.establishing:
        return Colors.blue;
      case PlantStatus.stressed:
        return Colors.orange;
      case PlantStatus.diseased:
        return Colors.red;
      case PlantStatus.dead:
      case PlantStatus.removed:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(PlantStatus status) {
    switch (status) {
      case PlantStatus.planted:
        return 'Засадено';
      case PlantStatus.establishing:
        return 'Установява се';
      case PlantStatus.healthy:
        return 'Здраво';
      case PlantStatus.stressed:
        return 'Стресирано';
      case PlantStatus.diseased:
        return 'Болно';
      case PlantStatus.dead:
        return 'Мъртво';
      case PlantStatus.removed:
        return 'Премахнато';
    }
  }
}
