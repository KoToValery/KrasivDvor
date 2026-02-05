import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/admin_provider_new.dart';
import '../../../models/models.dart';

class PlantManagementScreen extends StatefulWidget {
  const PlantManagementScreen({super.key});

  @override
  State<PlantManagementScreen> createState() => _PlantManagementScreenState();
}

class _PlantManagementScreenState extends State<PlantManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadPlants();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление на растения'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Импорт от JSON',
            onPressed: _handleBulkImport,
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (adminProvider.plants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_florist,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Няма добавени растения',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Добавете растение или импортирайте от файл',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddPlantDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Добави растение'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: adminProvider.plants.length,
            itemBuilder: (context, index) {
              final plant = adminProvider.plants[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.local_florist),
                  ),
                  title: Text(plant.bulgarianName),
                  subtitle: Text(plant.latinName),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditPlantDialog(context, plant),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDelete(context, plant),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPlantDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _handleBulkImport() async {
    final adminProvider = context.read<AdminProvider>();
    await adminProvider.importPlantsFromJson();

    if (!mounted) return;

    if (adminProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Грешка при импорт: ${adminProvider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Растенията са импортирани успешно'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showAddPlantDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddPlantDialog(),
    ).then((result) {
      if (result == true) {
        context.read<AdminProvider>().loadPlants();
      }
    });
  }

  void _showEditPlantDialog(BuildContext context, Plant plant) {
    showDialog(
      context: context,
      builder: (context) => AddPlantDialog(plant: plant),
    ).then((result) {
      if (result == true) {
        context.read<AdminProvider>().loadPlants();
      }
    });
  }

  void _confirmDelete(BuildContext context, Plant plant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изтриване на растение'),
        content: Text(
          'Сигурни ли сте, че искате да изтриете "${plant.bulgarianName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отказ'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deletePlant(plant);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Изтрий'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePlant(Plant plant) async {
    try {
      await context.read<AdminProvider>().deletePlantFromCatalog(plant.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Растението е изтрито')),
      );
      await context.read<AdminProvider>().loadPlants();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Грешка при изтриване: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class AddPlantDialog extends StatefulWidget {
  final Plant? plant;

  const AddPlantDialog({super.key, this.plant});

  @override
  State<AddPlantDialog> createState() => _AddPlantDialogState();
}

class _AddPlantDialogState extends State<AddPlantDialog> {
  final _formKey = GlobalKey<FormState>();
  final _latinNameController = TextEditingController();
  final _bulgarianNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxHeightController = TextEditingController();
  final _maxWidthController = TextEditingController();
  final _hardinessZoneController = TextEditingController();
  final _wateringFrequencyController = TextEditingController();
  final _wateringInstructionsController = TextEditingController();
  final _fertilizingFrequencyController = TextEditingController();
  final _fertilizingInstructionsController = TextEditingController();
  final _fertilizerTypeController = TextEditingController();
  final _pruningFrequencyController = TextEditingController();
  final _pruningInstructionsController = TextEditingController();

  PlantCategory _selectedCategory = PlantCategory.flowers;
  LightRequirement _selectedLight = LightRequirement.fullSun;
  WaterRequirement _selectedWater = WaterRequirement.moderate;
  SoilType _selectedSoil = SoilType.loam;
  GrowthRate _selectedGrowthRate = GrowthRate.moderate;
  ToxicityLevel _selectedToxicity = ToxicityLevel.none;
  PriceCategory _selectedPrice = PriceCategory.standard;
  bool _winterizingNeeded = false;
  int _winterizingStartMonth = 10;

  @override
  void initState() {
    super.initState();
    if (widget.plant != null) {
      final plant = widget.plant!;
      _latinNameController.text = plant.latinName;
      _bulgarianNameController.text = plant.bulgarianName;
      _descriptionController.text = plant.characteristics.description;
      _maxHeightController.text = plant.specifications.maxHeightCm.toString();
      _maxWidthController.text = plant.specifications.maxWidthCm.toString();
      _hardinessZoneController.text =
          plant.characteristics.hardinessZone.toString();
      _wateringFrequencyController.text =
          plant.careRequirements.watering.frequencyDays.toString();
      _wateringInstructionsController.text =
          plant.careRequirements.watering.instructions;
      _fertilizingFrequencyController.text =
          plant.careRequirements.fertilizing.frequencyDays.toString();
      _fertilizingInstructionsController.text =
          plant.careRequirements.fertilizing.instructions;
      _fertilizerTypeController.text =
          plant.careRequirements.fertilizing.fertilizerType ?? '';
      _pruningFrequencyController.text =
          plant.careRequirements.pruning.frequencyDays?.toString() ?? '';
      _pruningInstructionsController.text =
          plant.careRequirements.pruning.instructions;
      _selectedCategory = plant.category;
      _selectedLight = plant.characteristics.lightRequirement;
      _selectedWater = plant.characteristics.waterRequirement;
      _selectedSoil = plant.characteristics.preferredSoil;
      _selectedGrowthRate = plant.specifications.growthRate;
      _selectedToxicity = plant.toxicity.level;
      _selectedPrice = plant.priceCategory;
      if (plant.careRequirements.winterizing != null) {
        _winterizingNeeded = plant.careRequirements.winterizing!.needed;
        _winterizingStartMonth = plant.careRequirements.winterizing!.startMonth;
      }
    }
  }

  @override
  void dispose() {
    _latinNameController.dispose();
    _bulgarianNameController.dispose();
    _descriptionController.dispose();
    _maxHeightController.dispose();
    _maxWidthController.dispose();
    _hardinessZoneController.dispose();
    _wateringFrequencyController.dispose();
    _wateringInstructionsController.dispose();
    _fertilizingFrequencyController.dispose();
    _fertilizingInstructionsController.dispose();
    _fertilizerTypeController.dispose();
    _pruningFrequencyController.dispose();
    _pruningInstructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            AppBar(
              title: Text(widget.plant == null
                  ? 'Добави растение'
                  : 'Редактирай растение'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _latinNameController,
                        decoration: const InputDecoration(
                          labelText: 'Латинско име *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Моля въведете латинско име';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _bulgarianNameController,
                        decoration: const InputDecoration(
                          labelText: 'Българско име *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Моля въведете българско име';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<PlantCategory>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Категория',
                          border: OutlineInputBorder(),
                        ),
                        items: PlantCategory.values.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(_getCategoryName(category)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Описание',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<LightRequirement>(
                              value: _selectedLight,
                              decoration: const InputDecoration(
                                labelText: 'Светлина',
                                border: OutlineInputBorder(),
                              ),
                              items: LightRequirement.values.map((light) {
                                return DropdownMenuItem(
                                  value: light,
                                  child: Text(_getLightName(light)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedLight = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<WaterRequirement>(
                              value: _selectedWater,
                              decoration: const InputDecoration(
                                labelText: 'Вода',
                                border: OutlineInputBorder(),
                              ),
                              items: WaterRequirement.values.map((water) {
                                return DropdownMenuItem(
                                  value: water,
                                  child: Text(_getWaterName(water)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedWater = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Грижи',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _wateringFrequencyController,
                        decoration: const InputDecoration(
                          labelText: 'Поливане - на колко дни *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final parsed = int.tryParse(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Моля въведете валидни дни за поливане';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _wateringInstructionsController,
                        decoration: const InputDecoration(
                          labelText: 'Поливане - инструкции',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _fertilizingFrequencyController,
                        decoration: const InputDecoration(
                          labelText: 'Торене - на колко дни *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final parsed = int.tryParse(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Моля въведете валидни дни за торене';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _fertilizerTypeController,
                        decoration: const InputDecoration(
                          labelText: 'Торене - вид тор *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Моля въведете вид тор';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _fertilizingInstructionsController,
                        decoration: const InputDecoration(
                          labelText: 'Торене - инструкции',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pruningFrequencyController,
                        decoration: const InputDecoration(
                          labelText: 'Подрязване - на колко дни *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final parsed = int.tryParse(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Моля въведете валидни дни за подрязване';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pruningInstructionsController,
                        decoration: const InputDecoration(
                          labelText: 'Подрязване - инструкции',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        value: _winterizingNeeded,
                        onChanged: (value) {
                          setState(() {
                            _winterizingNeeded = value;
                          });
                        },
                        title: const Text('Зазимяване - нужно ли е'),
                      ),
                      if (_winterizingNeeded) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _winterizingStartMonth,
                          decoration: const InputDecoration(
                            labelText: 'Зазимяване - начало (месец) *',
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(12, (index) => index + 1)
                              .map((month) => DropdownMenuItem(
                                    value: month,
                                    child: Text(_getMonthName(month)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _winterizingStartMonth = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Моля изберете месец';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Отказ'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _handleSave,
                              child: const Text('Запази'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final maxHeight = int.tryParse(_maxHeightController.text) ?? 0;
    final maxWidth = int.tryParse(_maxWidthController.text) ?? 0;
    final hardinessZone = int.tryParse(_hardinessZoneController.text) ?? 6;
    final wateringFrequency = int.parse(_wateringFrequencyController.text);
    final fertilizingFrequency =
        int.parse(_fertilizingFrequencyController.text);
    final pruningFrequency = int.parse(_pruningFrequencyController.text);
    final plantId =
        widget.plant?.id ?? 'plant_${DateTime.now().millisecondsSinceEpoch}';

    final plant = Plant(
      id: plantId,
      latinName: _latinNameController.text.trim(),
      bulgarianName: _bulgarianNameController.text.trim(),
      category: _selectedCategory,
      imageUrls: widget.plant?.imageUrls ?? [],
      characteristics: PlantCharacteristics(
        description: _descriptionController.text.trim(),
        lightRequirement: _selectedLight,
        waterRequirement: _selectedWater,
        preferredSoil: _selectedSoil,
        hardinessZone: hardinessZone,
      ),
      careRequirements: CareRequirements(
        watering: WateringSchedule(
          frequencyDays: wateringFrequency,
          instructions: _wateringInstructionsController.text.trim(),
          weatherDependent: false,
        ),
        fertilizing: FertilizingSchedule(
          frequencyDays: fertilizingFrequency,
          instructions: _fertilizingInstructionsController.text.trim(),
          seasons: const [],
          fertilizerType: _fertilizerTypeController.text.trim(),
        ),
        pruning: PruningSchedule(
          seasons: const [],
          instructions: _pruningInstructionsController.text.trim(),
          frequencyDays: pruningFrequency,
        ),
        seasonalCare: const [],
        winterizing: WinterizingSchedule(
          needed: _winterizingNeeded,
          startMonth: _winterizingStartMonth,
          instructions: '',
        ),
      ),
      specifications: PlantSpecifications(
        maxHeightCm: maxHeight,
        maxWidthCm: maxWidth,
        bloomSeason: const [],
        growthRate: _selectedGrowthRate,
      ),
      compatiblePlantIds: const [],
      toxicity: ToxicityInfo(level: _selectedToxicity),
      priceCategory: _selectedPrice,
      qrCode: widget.plant?.qrCode ?? '',
    );
    final plantData = plant.toJson();
    if (widget.plant == null) {
      plantData.remove('id');
    }

    try {
      final adminProvider = context.read<AdminProvider>();
      if (widget.plant == null) {
        await adminProvider.addPlantToCatalog(plantData);
      } else {
        await adminProvider.updatePlantInCatalog(plantId, plantData);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.plant == null
              ? 'Растението е добавено успешно'
              : 'Растението е обновено успешно'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Грешка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getCategoryName(PlantCategory category) {
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

  String _getLightName(LightRequirement light) {
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

  String _getWaterName(WaterRequirement water) {
    switch (water) {
      case WaterRequirement.low:
        return 'Ниска';
      case WaterRequirement.moderate:
        return 'Умерена';
      case WaterRequirement.high:
        return 'Висока';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Януари',
      'Февруари',
      'Март',
      'Април',
      'Май',
      'Юни',
      'Юли',
      'Август',
      'Септември',
      'Октомври',
      'Ноември',
      'Декември'
    ];
    if (month < 1 || month > 12) return 'Неизвестен';
    return months[month - 1];
  }
}
