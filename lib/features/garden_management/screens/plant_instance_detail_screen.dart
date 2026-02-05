import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/plant_instance.dart';
import '../../../models/plant.dart';
import '../../../core/services/service_locator.dart';
import '../../../features/plant_catalog/services/plant_catalog_service.dart';
import '../providers/garden_provider.dart';

class PlantInstanceDetailScreen extends StatefulWidget {
  final String plantInstanceId;

  const PlantInstanceDetailScreen({
    super.key,
    required this.plantInstanceId,
  });

  @override
  State<PlantInstanceDetailScreen> createState() => _PlantInstanceDetailScreenState();
}

class _PlantInstanceDetailScreenState extends State<PlantInstanceDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GardenProvider>().loadPlantInstance(widget.plantInstanceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детайли за растението'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit screen
            },
          ),
        ],
      ),
      body: Consumer<GardenProvider>(
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
                    'Грешка: ${provider.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.loadPlantInstance(widget.plantInstanceId);
                    },
                    child: const Text('Опитай отново'),
                  ),
                ],
              ),
            );
          }

          final plantInstance = provider.selectedPlantInstance;
          if (plantInstance == null) {
            return const Center(
              child: Text('Растението не е намерено'),
            );
          }

          return FutureBuilder<Plant?>(
            future: ServiceLocator.instance.get<PlantCatalogService>().getPlantById(plantInstance.plantId),
            builder: (context, snapshot) {
              final plant = snapshot.data;
              
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plant images
                    _buildImageGallery(plantInstance, plant),
                    
                    // Basic info
                    _buildBasicInfo(plantInstance, plant),
                    
                    // Status section
                    _buildStatusSection(plantInstance),
                    
                    // Care history
                    _buildCareHistory(plantInstance),
                    
                    // Progress photos
                    _buildProgressPhotos(plantInstance),
                    
                    // Notes
                    if (plantInstance.notes != null)
                      _buildNotesSection(plantInstance),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildImageGallery(PlantInstance plantInstance, Plant? plant) {
    final images = plant?.imageUrls ?? [];
    
    if (images.isEmpty) {
      return Container(
        height: 250,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.local_florist, size: 64, color: Colors.grey),
        ),
      );
    }
    
    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Image.network(
            images[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.broken_image, size: 64),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBasicInfo(PlantInstance plantInstance, Plant? plant) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plant?.bulgarianName ?? 'Зареждане...',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              plant?.latinName ?? '',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.calendar_today, 'Засадено', _formatDate(plantInstance.plantedDate)),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.straighten, 'Размер при засаждане', _getPlantSizeLabel(plantInstance.plantedSize)),
            if (plantInstance.zoneId != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.location_on, 'Зона', plantInstance.zoneId!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatusSection(PlantInstance plantInstance) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.health_and_safety, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Състояние',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusChip(plantInstance.status),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showStatusUpdateDialog(plantInstance),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Промени'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(PlantStatus status) {
    Color color;
    String label;
    IconData icon;
    
    switch (status) {
      case PlantStatus.planted:
        color = Colors.blue;
        label = 'Засадено';
        icon = Icons.eco;
        break;
      case PlantStatus.establishing:
        color = Colors.orange;
        label = 'Установява се';
        icon = Icons.trending_up;
        break;
      case PlantStatus.healthy:
        color = Colors.green;
        label = 'Здраво';
        icon = Icons.check_circle;
        break;
      case PlantStatus.stressed:
        color = Colors.amber;
        label = 'Стресирано';
        icon = Icons.warning;
        break;
      case PlantStatus.diseased:
        color = Colors.red;
        label = 'Болно';
        icon = Icons.local_hospital;
        break;
      case PlantStatus.dead:
        color = Colors.grey;
        label = 'Мъртво';
        icon = Icons.cancel;
        break;
      case PlantStatus.removed:
        color = Colors.black54;
        label = 'Премахнато';
        icon = Icons.remove_circle;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareHistory(PlantInstance plantInstance) {
    if (plantInstance.careHistory.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.history, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              const Text('Няма записи за грижи'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Add care record
                },
                icon: const Icon(Icons.add),
                label: const Text('Добави запис'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'История на грижите',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    // Add care record
                  },
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: plantInstance.careHistory.length,
            itemBuilder: (context, index) {
              final record = plantInstance.careHistory[index];
              return ListTile(
                leading: Icon(_getCareTypeIcon(record.careType)),
                title: Text(_getCareTypeLabel(record.careType)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatDate(record.performedAt)),
                    if (record.notes != null)
                      Text(
                        record.notes!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                trailing: record.photoUrls.isNotEmpty
                    ? const Icon(Icons.photo_camera)
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPhotos(PlantInstance plantInstance) {
    if (plantInstance.progressPhotos.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.photo_library, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              const Text('Няма снимки на прогреса'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Add progress photo
                },
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Добави снимка'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.photo_library, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text(
                      'Снимки на прогреса',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_a_photo),
                  onPressed: () {
                    // Add progress photo
                  },
                ),
              ],
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: plantInstance.progressPhotos.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _showFullScreenImage(context, plantInstance.progressPhotos[index]);
                  },
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 8, bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(plantInstance.progressPhotos[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(PlantInstance plantInstance) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Бележки',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(plantInstance.notes!),
          ],
        ),
      ),
    );
  }

  void _showStatusUpdateDialog(PlantInstance plantInstance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Промени състоянието'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: PlantStatus.values.map((status) {
            return ListTile(
              title: Text(_getPlantStatusLabel(status)),
              leading: Radio<PlantStatus>(
                value: status,
                groupValue: plantInstance.status,
                onChanged: (value) {
                  if (value != null) {
                    context.read<GardenProvider>().updatePlantStatus(
                      plantInstance.id,
                      value,
                    );
                    Navigator.pop(context);
                  }
                },
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отказ'),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _getPlantSizeLabel(PlantSize size) {
    switch (size) {
      case PlantSize.seedling:
        return 'Разсад';
      case PlantSize.small:
        return 'Малък';
      case PlantSize.medium:
        return 'Среден';
      case PlantSize.large:
        return 'Голям';
      case PlantSize.mature:
        return 'Зрял';
    }
  }

  String _getPlantStatusLabel(PlantStatus status) {
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

  IconData _getCareTypeIcon(CareType type) {
    switch (type) {
      case CareType.watering:
        return Icons.water_drop;
      case CareType.fertilizing:
        return Icons.grass;
      case CareType.pruning:
        return Icons.content_cut;
      case CareType.weeding:
        return Icons.cleaning_services;
      case CareType.mulching:
        return Icons.layers;
      case CareType.pestControl:
        return Icons.bug_report;
      case CareType.diseaseControl:
        return Icons.medical_services;
      case CareType.other:
        return Icons.more_horiz;
    }
  }

  String _getCareTypeLabel(CareType type) {
    switch (type) {
      case CareType.watering:
        return 'Поливане';
      case CareType.fertilizing:
        return 'Торене';
      case CareType.pruning:
        return 'Подрязване';
      case CareType.weeding:
        return 'Плевене';
      case CareType.mulching:
        return 'Мулчиране';
      case CareType.pestControl:
        return 'Контрол на вредители';
      case CareType.diseaseControl:
        return 'Контрол на болести';
      case CareType.other:
        return 'Друго';
    }
  }
}