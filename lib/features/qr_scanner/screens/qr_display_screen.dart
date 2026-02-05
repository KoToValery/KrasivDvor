import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/qr_code_service.dart';
import '../../../models/models.dart';
import '../../../core/services/service_locator.dart';

class QRDisplayScreen extends StatefulWidget {
  final Plant plant;

  const QRDisplayScreen({
    super.key,
    required this.plant,
  });

  @override
  State<QRDisplayScreen> createState() => _QRDisplayScreenState();
}

class _QRDisplayScreenState extends State<QRDisplayScreen> {
  QRCodeService? qrCodeService;
  bool isSharing = false;

  @override
  void initState() {
    super.initState();
    qrCodeService = ServiceLocator.instance.get<QRCodeService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Код'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: isSharing ? null : _shareQRCode,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Plant information header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (widget.plant.imageUrls.isNotEmpty)
                      Container(
                        height: 120,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(widget.plant.imageUrls.first),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    Text(
                      widget.plant.bulgarianName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.plant.latinName,
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Категория: ${_getCategoryDisplayName(widget.plant.category)}',
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // QR Code display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'QR Код за растението',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // QR Code widget
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: FutureBuilder<Widget>(
                        future: qrCodeService?.generateQRWidget(widget.plant.id, size: 250),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              width: 250,
                              height: 250,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.red),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error, color: Colors.red, size: 48),
                                    SizedBox(height: 8),
                                    Text(
                                      'Грешка при генериране на QR код',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            return snapshot.data ?? const SizedBox();
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 16),
                    
                    const Text(
                      'Сканирайте този код за бърз достъп до информацията за растението',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isSharing ? null : _shareQRCode,
                    icon: isSharing 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.share),
                    label: Text(isSharing ? 'Споделяне...' : 'Сподели'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyPlantInfo,
                    icon: const Icon(Icons.copy),
                    label: const Text('Копирай инфо'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Instructions
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Как да използвате QR кода',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Споделете QR кода с клиенти за лесен достъп до информацията\n'
                      '• Отпечатайте кода и го поставете до растението в градината\n'
                      '• Използвайте го в презентации и каталози\n'
                      '• Сканирайте с всяко QR четец приложение',
                      style: TextStyle(fontSize: 14),
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

  Future<void> _shareQRCode() async {
    setState(() {
      isSharing = true;
    });

    try {
      await qrCodeService?.shareQRCode(widget.plant.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR кодът е споделен успешно'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Грешка при споделяне: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isSharing = false;
      });
    }
  }

  void _copyPlantInfo() {
    final plantInfo = '''
🌱 ${widget.plant.bulgarianName} (${widget.plant.latinName})

Категория: ${_getCategoryDisplayName(widget.plant.category)}
Светлина: ${_getLightRequirementDisplayName(widget.plant.characteristics.lightRequirement)}
Вода: ${_getWaterRequirementDisplayName(widget.plant.characteristics.waterRequirement)}
Почва: ${_getSoilTypeDisplayName(widget.plant.characteristics.preferredSoil)}
Зона на издръжливост: ${widget.plant.characteristics.hardinessZone}

Описание: ${widget.plant.characteristics.description}
''';

    Clipboard.setData(ClipboardData(text: plantInfo));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Информацията е копирана в клипборда'),
        backgroundColor: Colors.green,
      ),
    );
  }

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

  String _getLightRequirementDisplayName(LightRequirement requirement) {
    switch (requirement) {
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

  String _getWaterRequirementDisplayName(WaterRequirement requirement) {
    switch (requirement) {
      case WaterRequirement.low:
        return 'Малко';
      case WaterRequirement.moderate:
        return 'Умерено';
      case WaterRequirement.high:
        return 'Много';
    }
  }

  String _getSoilTypeDisplayName(SoilType soilType) {
    switch (soilType) {
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
}