import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../models/models.dart';
import '../providers/plant_catalog_provider.dart';
import '../widgets/plant_image_gallery.dart';
import '../widgets/plant_compatibility_widget.dart';
import '../../../core/services/service_locator.dart';
import '../../qr_scanner/services/qr_code_service.dart';

class PlantDetailScreen extends StatefulWidget {
  final String plantId;

  const PlantDetailScreen({
    super.key,
    required this.plantId,
  });

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Plant? _plant;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPlantDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlantDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = context.read<PlantCatalogProvider>();
      final plant = await provider.getPlantById(widget.plantId);

      if (plant != null) {
        setState(() {
          _plant = plant;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Растението не е намерено';
          _isLoading = false;
        });
      }
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
        title: Text(_plant?.bulgarianName ?? 'Детайли за растението'),
        actions: [
          if (_plant != null) ...[
            IconButton(
              icon: const Icon(Icons.qr_code),
              onPressed: () => _showQRCode(),
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _sharePlant(),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _plant != null
                  ? _buildPlantDetails()
                  : const Center(child: Text('Растението не е намерено')),
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
            onPressed: _loadPlantDetails,
            child: const Text('Опитай отново'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantDetails() {
    return Column(
      children: [
        // Plant image gallery
        Container(
          padding: const EdgeInsets.all(16),
          child: PlantImageGallery(
            imageUrls: _plant!.imageUrls,
            plantName: _plant!.bulgarianName,
            height: 250,
            showThumbnails: true,
            enableZoom: true,
          ),
        ),
        // Plant basic info header
        _buildPlantHeader(),
        // Tab bar
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Общо', icon: Icon(Icons.info_outline)),
            Tab(text: 'Грижи', icon: Icon(Icons.eco)),
            Tab(text: 'Спецификации', icon: Icon(Icons.straighten)),
            Tab(text: 'Съвместими', icon: Icon(Icons.group_work)),
          ],
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGeneralTab(),
              _buildCareTab(),
              _buildSpecificationsTab(),
              _buildCompatiblePlantsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlantHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _plant!.bulgarianName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _plant!.latinName,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                _getCategoryIcon(_plant!.category),
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                _getCategoryDisplayName(_plant!.category),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getPriceCategoryColor(_plant!.priceCategory),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _getPriceCategoryDisplayName(_plant!.priceCategory),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _getLightIcon(_plant!.characteristics.lightRequirement),
                size: 20,
                color: Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(_getLightDisplayName(
                  _plant!.characteristics.lightRequirement)),
              const SizedBox(width: 16),
              Icon(
                _getWaterIcon(_plant!.characteristics.waterRequirement),
                size: 20,
                color: Colors.blue,
              ),
              const SizedBox(width: 4),
              Text(_getWaterDisplayName(
                  _plant!.characteristics.waterRequirement)),
              const Spacer(),
              if (_plant!.toxicity.level != ToxicityLevel.none)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getToxicityColor(_plant!.toxicity.level),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        _getToxicityDisplayName(_plant!.toxicity.level),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            'Описание',
            Icons.description,
            [
              Text(
                _plant!.characteristics.description,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Основни характеристики',
            Icons.eco,
            [
              _buildCharacteristicRow(
                  'Светлинни изисквания',
                  _getLightDisplayName(
                      _plant!.characteristics.lightRequirement),
                  _getLightIcon(_plant!.characteristics.lightRequirement)),
              _buildCharacteristicRow(
                  'Водни изисквания',
                  _getWaterDisplayName(
                      _plant!.characteristics.waterRequirement),
                  _getWaterIcon(_plant!.characteristics.waterRequirement)),
              _buildCharacteristicRow(
                  'Предпочитана почва',
                  _getSoilDisplayName(_plant!.characteristics.preferredSoil),
                  Icons.terrain),
              _buildCharacteristicRow(
                  'Зона на издръжливост',
                  'Зона ${_plant!.characteristics.hardinessZone}',
                  Icons.thermostat),
            ],
          ),
          if (_plant!.toxicity.level != ToxicityLevel.none) ...[
            const SizedBox(height: 16),
            _buildSectionCard(
              'Предупреждение за токсичност',
              Icons.warning,
              [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getToxicityColor(_plant!.toxicity.level)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _getToxicityColor(_plant!.toxicity.level)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning,
                              color: _getToxicityColor(_plant!.toxicity.level)),
                          const SizedBox(width: 8),
                          Text(
                            'Ниво на токсичност: ${_getToxicityDisplayName(_plant!.toxicity.level)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getToxicityColor(_plant!.toxicity.level),
                            ),
                          ),
                        ],
                      ),
                      if (_plant!.toxicity.warning != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _plant!.toxicity.warning!,
                          style: TextStyle(
                              color: _getToxicityColor(_plant!.toxicity.level)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCareTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            'Поливане',
            Icons.water_drop,
            [
              _buildCareItem('Честота',
                  '${_plant!.careRequirements.watering.frequencyDays} дни'),
              _buildCareItem(
                  'Инструкции', _plant!.careRequirements.watering.instructions),
              _buildCareItem(
                  'Зависи от времето',
                  _plant!.careRequirements.watering.weatherDependent
                      ? 'Да'
                      : 'Не'),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Торене',
            Icons.grass,
            [
              _buildCareItem('Честота',
                  '${_plant!.careRequirements.fertilizing.frequencyDays} дни'),
              if ((_plant!.careRequirements.fertilizing.fertilizerType ?? '')
                  .isNotEmpty)
                _buildCareItem('Вид тор',
                    _plant!.careRequirements.fertilizing.fertilizerType!),
              _buildCareItem('Инструкции',
                  _plant!.careRequirements.fertilizing.instructions),
              _buildCareItem(
                  'Сезони',
                  _plant!.careRequirements.fertilizing.seasons
                      .map(_getSeasonDisplayName)
                      .join(', ')),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Подрязване',
            Icons.content_cut,
            [
              if (_plant!.careRequirements.pruning.frequencyDays != null)
                _buildCareItem('Честота',
                    '${_plant!.careRequirements.pruning.frequencyDays} дни'),
              _buildCareItem(
                  'Сезони',
                  _plant!.careRequirements.pruning.seasons
                      .map(_getSeasonDisplayName)
                      .join(', ')),
              _buildCareItem(
                  'Инструкции', _plant!.careRequirements.pruning.instructions),
            ],
          ),
          if (_plant!.careRequirements.winterizing != null &&
              _plant!.careRequirements.winterizing!.needed) ...[
            const SizedBox(height: 16),
            _buildSectionCard(
              'Зазимяване',
              Icons.ac_unit,
              [
                _buildCareItem(
                  'Начало',
                  _getMonthName(
                      _plant!.careRequirements.winterizing!.startMonth),
                ),
                _buildCareItem(
                  'Инструкции',
                  _plant!.careRequirements.winterizing!.instructions.isNotEmpty
                      ? _plant!.careRequirements.winterizing!.instructions
                      : 'Зазимяване според нуждите на растението.',
                ),
              ],
            ),
          ],
          if (_plant!.careRequirements.seasonalCare.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionCard(
              'Сезонни грижи',
              Icons.calendar_today,
              _plant!.careRequirements.seasonalCare
                  .map((care) => _buildCareItem(
                      _getSeasonDisplayName(care.season), care.instructions))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecificationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            'Размери',
            Icons.straighten,
            [
              _buildSpecRow('Максимална височина',
                  '${_plant!.specifications.maxHeightCm} см'),
              _buildSpecRow('Максимална ширина',
                  '${_plant!.specifications.maxWidthCm} см'),
              _buildSpecRow('Скорост на растеж',
                  _getGrowthRateDisplayName(_plant!.specifications.growthRate)),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            'Цъфтеж',
            Icons.local_florist,
            [
              _buildSpecRow(
                  'Сезон на цъфтеж',
                  _plant!.specifications.bloomSeason.isEmpty
                      ? 'Не цъфти'
                      : _plant!.specifications.bloomSeason
                          .map(_getSeasonDisplayName)
                          .join(', ')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompatiblePlantsTab() {
    return PlantCompatibilityWidget(plant: _plant!);
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildCharacteristicRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildCareItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  void _showQRCode() {
    if (_plant != null) {
      context.pushNamed('plant-qr', extra: _plant);
    }
  }

  void _sharePlant() async {
    if (_plant != null) {
      try {
        final qrCodeService = ServiceLocator.instance.get<QRCodeService>();
        await qrCodeService.shareQRCode(_plant!.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Грешка при споделяне: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Helper methods for display names and icons (same as in catalog screen)
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

  String _getSoilDisplayName(SoilType soil) {
    switch (soil) {
      case SoilType.clay:
        return 'Глинеста';
      case SoilType.loam:
        return 'Пръстна';
      case SoilType.sand:
        return 'Пясъчна';
      case SoilType.chalk:
        return 'Варовикова';
      case SoilType.peat:
        return 'Торфена';
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

  String _getSeasonDisplayName(Season season) {
    switch (season) {
      case Season.spring:
        return 'Пролет';
      case Season.summer:
        return 'Лято';
      case Season.autumn:
        return 'Есен';
      case Season.winter:
        return 'Зима';
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

  String _getToxicityDisplayName(ToxicityLevel level) {
    switch (level) {
      case ToxicityLevel.none:
        return 'Безопасно';
      case ToxicityLevel.mild:
        return 'Леко токсично';
      case ToxicityLevel.moderate:
        return 'Умерено токсично';
      case ToxicityLevel.severe:
        return 'Силно токсично';
    }
  }

  Color _getToxicityColor(ToxicityLevel level) {
    switch (level) {
      case ToxicityLevel.none:
        return Colors.green;
      case ToxicityLevel.mild:
        return Colors.orange;
      case ToxicityLevel.moderate:
        return Colors.deepOrange;
      case ToxicityLevel.severe:
        return Colors.red;
    }
  }
}
