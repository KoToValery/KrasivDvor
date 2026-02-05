import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';

import '../services/qr_code_service.dart';
import '../../../models/models.dart';
import '../../../core/services/service_locator.dart';
import '../../garden_management/services/garden_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  
  QRCodeService? qrCodeService;
  GardenService? gardenService;
  bool isProcessing = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    qrCodeService = ServiceLocator.instance.get<QRCodeService>();
    gardenService = ServiceLocator.instance.get<GardenService>();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.isInitialized) {
      return;
    }
    
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        // Restart camera if needed
        controller.start();
        break;
      case AppLifecycleState.inactive:
        // Stop camera to save battery
        controller.stop();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Скенер'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, state, child) {
              return IconButton(
                icon: Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                ),
                onPressed: () => controller.toggleTorch(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: _onDetect,
                  errorBuilder: (context, error, child) {
                    return Center(
                      child: Text(
                        'Грешка при камерата: ${error.errorCode}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  },
                ),
                // Overlay
                Container(
                  decoration: ShapeDecoration(
                    shape: _ScannerOverlayShape(
                      borderColor: Theme.of(context).primaryColor,
                      borderRadius: 10,
                      borderLength: 30,
                      borderWidth: 10,
                      cutOutSize: 300,
                    ),
                  ),
                ),
                if (isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Обработване на QR код...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                errorMessage = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  const Text(
                    'Насочете камерата към QR код на растение',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'QR кодът ще бъде сканиран автоматично',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _processQRCode(barcode.rawValue!);
        break; // Process only the first valid code
      }
    }
  }

  Future<void> _processQRCode(String qrData) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
      errorMessage = null;
    });

    try {
      // Pause camera while processing
      await controller.stop();

      // Process the QR code
      final plant = await qrCodeService!.processScannedQR(qrData);

      if (plant != null) {
        // Show success and navigate to plant detail
        if (mounted) {
          _showPlantFoundDialog(plant);
        }
      } else {
        setState(() {
          errorMessage = 'Растението не е намерено в каталога';
        });
        await controller.start();
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Невалиден QR код: ${e.toString()}';
      });
      await controller.start();
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  void _showPlantFoundDialog(Plant plant) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600),
              const SizedBox(width: 8),
              const Text('Растение намерено!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (plant.imageUrls.isNotEmpty)
                Container(
                  height: 120,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(plant.imageUrls.first),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Text(
                plant.bulgarianName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                plant.latinName,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Категория: ${_getCategoryDisplayName(plant.category)}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.start();
              },
              child: const Text('Продължи сканирането'),
            ),
            TextButton(
              onPressed: () => _addToMyGarden(plant),
              child: const Text('Добави в градината'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.pushNamed('plant-detail', pathParameters: {
                  'plantId': plant.id,
                });
              },
              child: const Text('Виж детайли'),
            ),
          ],
        );
      },
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

  Future<void> _addToMyGarden(Plant plant) async {
    try {
      // For now, we'll use a placeholder client ID
      // In a real implementation, this would come from user authentication
      const String clientId = 'current_user';
      
      // Create a plant instance for the garden
      final plantInstance = PlantInstance(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        plantId: plant.id,
        plantedDate: DateTime.now(),
        plantedSize: PlantSize.small, // Default size
        status: PlantStatus.planted,
        progressPhotos: [],
        careHistory: [],
        notes: 'Added via QR scanner',
      );

      await gardenService?.addPlantToGarden(clientId, plantInstance);

      if (mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${plant.bulgarianName} е добавено в градината ви!',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Виж градината',
              textColor: Colors.white,
              onPressed: () {
                context.go('/garden');
              },
            ),
          ),
        );
        
        // Resume camera for more scanning
        controller.start();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Грешка при добавяне в градината: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        
        controller.start();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }
}

// Custom painter to mimic QrScannerOverlayShape
class _ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;
  final double? cutOutBottomOffset;

  const _ScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 10.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
    this.cutOutBottomOffset,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final cutOutWidth = cutOutSize;
    final cutOutHeight = cutOutSize;
    final bottomOffset = cutOutBottomOffset ?? 0;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - cutOutWidth / 2 + borderOffset,
      rect.top + height / 2 - cutOutHeight / 2 + borderOffset - bottomOffset,
      cutOutWidth - borderWidth,
      cutOutHeight - borderWidth,
    );

    canvas
      ..saveLayer(
        rect,
        backgroundPaint,
      )
      ..drawRect(
        rect,
        backgroundPaint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          cutOutRect,
          Radius.circular(borderRadius),
        ),
        Paint()..blendMode = BlendMode.clear,
      )
      ..restore();

    final borderPath = _getBorderPath(cutOutRect, borderRadius);
    canvas.drawPath(borderPath, borderPaint);
  }

  Path _getBorderPath(Rect rect, double radius) {
    final path = Path();
    
    // Top left
    path.moveTo(rect.left, rect.top + borderLength);
    path.lineTo(rect.left, rect.top + radius);
    path.arcToPoint(
      Offset(rect.left + radius, rect.top),
      radius: Radius.circular(radius),
    );
    path.lineTo(rect.left + borderLength, rect.top);

    // Top right
    path.moveTo(rect.right - borderLength, rect.top);
    path.lineTo(rect.right - radius, rect.top);
    path.arcToPoint(
      Offset(rect.right, rect.top + radius),
      radius: Radius.circular(radius),
    );
    path.lineTo(rect.right, rect.top + borderLength);

    // Bottom right
    path.moveTo(rect.right, rect.bottom - borderLength);
    path.lineTo(rect.right, rect.bottom - radius);
    path.arcToPoint(
      Offset(rect.right - radius, rect.bottom),
      radius: Radius.circular(radius),
    );
    path.lineTo(rect.right - borderLength, rect.bottom);

    // Bottom left
    path.moveTo(rect.left + borderLength, rect.bottom);
    path.lineTo(rect.left + radius, rect.bottom);
    path.arcToPoint(
      Offset(rect.left, rect.bottom - radius),
      radius: Radius.circular(radius),
    );
    path.lineTo(rect.left, rect.bottom - borderLength);

    return path;
  }

  @override
  ShapeBorder scale(double t) {
    return _ScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
      borderRadius: borderRadius * t,
      borderLength: borderLength * t,
      cutOutSize: cutOutSize * t,
      cutOutBottomOffset: cutOutBottomOffset != null ? cutOutBottomOffset! * t : null,
    );
  }
}
