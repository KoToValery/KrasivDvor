import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../plant_catalog/services/plant_catalog_service.dart';
import '../../../models/models.dart';

class QRCodeService {
  final PlantCatalogService _plantCatalogService;

  QRCodeService(this._plantCatalogService);

  /// Scan QR code and return plant information
  Future<Plant?> scanPlantQR() async {
    try {
      // This method will be called from the QR scanner screen
      // The actual scanning is handled by the QRView widget
      // This method processes the scanned result
      return null; // Will be set by the scanner screen
    } catch (e) {
      throw Exception('Failed to scan QR code: $e');
    }
  }

  /// Process scanned QR code data and return plant information
  Future<Plant?> processScannedQR(String qrData) async {
    try {
      // Parse QR data - expecting JSON format with plant ID
      final Map<String, dynamic> qrContent = jsonDecode(qrData);
      
      if (qrContent.containsKey('plantId')) {
        final String plantId = qrContent['plantId'];
        final plant = await _plantCatalogService.getPlantById(plantId);
        return plant;
      } else if (qrContent.containsKey('type') && qrContent['type'] == 'plant') {
        // Alternative format: {"type": "plant", "id": "plant_id"}
        final String plantId = qrContent['id'];
        final plant = await _plantCatalogService.getPlantById(plantId);
        return plant;
      } else {
        throw Exception('Invalid QR code format');
      }
    } catch (e) {
      // Try to parse as simple plant ID string
      try {
        final plant = await _plantCatalogService.getPlantById(qrData);
        return plant;
      } catch (e2) {
        throw Exception('Invalid QR code: $e');
      }
    }
  }

  /// Generate QR code data for a plant
  Future<String> generatePlantQR(String plantId) async {
    try {
      // Verify plant exists
      final plant = await _plantCatalogService.getPlantById(plantId);
      if (plant == null) {
        throw Exception('Plant not found');
      }

      // Create QR data with plant information
      final qrData = {
        'type': 'plant',
        'id': plantId,
        'name': plant.bulgarianName,
        'latinName': plant.latinName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      return jsonEncode(qrData);
    } catch (e) {
      throw Exception('Failed to generate QR code: $e');
    }
  }

  /// Generate QR code widget for display
  Future<Widget> generateQRWidget(String plantId, {double size = 200.0}) async {
    try {
      final qrData = await generatePlantQR(plantId);
      
      return QrImageView(
        data: qrData,
        version: QrVersions.auto,
        size: size,
        backgroundColor: Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        padding: const EdgeInsets.all(8.0),
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      );
    } catch (e) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.error, color: Colors.red),
        ),
      );
    }
  }

  /// Generate QR code as image bytes for sharing
  Future<Uint8List> generateQRImageBytes(String plantId, {double size = 300.0}) async {
    try {
      final qrData = await generatePlantQR(plantId);
      
      final qrValidationResult = QrValidator.validate(
        data: qrData,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );

      if (qrValidationResult.status != QrValidationStatus.valid) {
        throw Exception('Invalid QR data');
      }

      final qrCode = qrValidationResult.qrCode!;
      final painter = QrPainter.withQr(
        qr: qrCode,
        gapless: false,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      );

      final picData = await painter.toImageData(size);
      return picData!.buffer.asUint8List();
    } catch (e) {
      throw Exception('Failed to generate QR image: $e');
    }
  }

  /// Share QR code with plant information
  Future<void> shareQRCode(String plantId) async {
    try {
      final plant = await _plantCatalogService.getPlantById(plantId);
      if (plant == null) {
        throw Exception('Plant not found');
      }

      // Generate QR code image
      final qrImageBytes = await generateQRImageBytes(plantId);
      
      // Create XFile from data
      final xFile = XFile.fromData(
        qrImageBytes,
        mimeType: 'image/png',
        name: 'plant_qr_$plantId.png',
      );

      // Share with plant information
      final shareText = '''
🌱 ${plant.bulgarianName} (${plant.latinName})

Сканирайте QR кода за пълна информация за растението.

Категория: ${_getCategoryDisplayName(plant.category)}
Светлина: ${_getLightRequirementDisplayName(plant.characteristics.lightRequirement)}
Вода: ${_getWaterRequirementDisplayName(plant.characteristics.waterRequirement)}
''';

      await Share.shareXFiles(
        [xFile],
        text: shareText,
        subject: 'Информация за растение: ${plant.bulgarianName}',
      );
    } catch (e) {
      throw Exception('Failed to share QR code: $e');
    }
  }

  /// Validate QR code format
  bool isValidPlantQR(String qrData) {
    try {
      final Map<String, dynamic> qrContent = jsonDecode(qrData);
      return qrContent.containsKey('type') && 
             qrContent['type'] == 'plant' && 
             qrContent.containsKey('id');
    } catch (e) {
      // Try as simple plant ID
      return qrData.isNotEmpty && qrData.length > 5; // Basic validation
    }
  }

  /// Get plant ID from QR data
  String? getPlantIdFromQR(String qrData) {
    try {
      final Map<String, dynamic> qrContent = jsonDecode(qrData);
      if (qrContent.containsKey('id')) {
        return qrContent['id'];
      } else if (qrContent.containsKey('plantId')) {
        return qrContent['plantId'];
      }
      return null;
    } catch (e) {
      // Try as simple plant ID
      return qrData.isNotEmpty ? qrData : null;
    }
  }

  // Helper methods for display names
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
}