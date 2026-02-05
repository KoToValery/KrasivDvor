import 'package:image_picker/image_picker.dart';
import '../../../models/client_garden.dart';
import 'garden_service.dart';

/// Service for handling garden documentation including photos and files
class DocumentationService {
  final GardenService _gardenService;
  final ImagePicker _imagePicker;

  DocumentationService(this._gardenService) : _imagePicker = ImagePicker();

  /// Pick image from camera for progress tracking
  Future<String?> captureProgressPhoto(String plantInstanceId) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo == null) return null;

      // Upload photo
      final photoUrl = await _gardenService.uploadProgressPhoto(
        plantInstanceId,
        photo.path,
      );

      return photoUrl;
    } catch (e) {
      throw Exception('Failed to capture progress photo: $e');
    }
  }

  /// Pick image from gallery for progress tracking
  Future<String?> pickProgressPhoto(String plantInstanceId) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo == null) return null;

      // Upload photo
      final photoUrl = await _gardenService.uploadProgressPhoto(
        plantInstanceId,
        photo.path,
      );

      return photoUrl;
    } catch (e) {
      throw Exception('Failed to pick progress photo: $e');
    }
  }

  /// Pick multiple images for garden note
  Future<List<String>> pickNotePhotos() async {
    try {
      final List<XFile> photos = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photos.isEmpty) return [];

      // Return file paths for upload
      return photos.map((photo) => photo.path).toList();
    } catch (e) {
      throw Exception('Failed to pick note photos: $e');
    }
  }

  /// Create garden note with photos
  Future<GardenNote> createNoteWithPhotos(
    String clientId,
    String content, {
    bool includePhotos = false,
  }) async {
    try {
      List<String>? photoFilePaths;

      if (includePhotos) {
        photoFilePaths = await pickNotePhotos();
      }

      return await _gardenService.createGardenNote(
        clientId,
        content,
        photoFilePaths,
      );
    } catch (e) {
      throw Exception('Failed to create note with photos: $e');
    }
  }

  /// Upload document file (PDF, image, etc.)
  Future<GardenDocument?> uploadDocument(
    String clientId,
    DocumentType type,
  ) async {
    try {
      // For PWA, we would use file_picker package or HTML input
      // For now, we'll use image picker as a placeholder
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (file == null) return null;

      final fileName = file.name;
      final document = await _gardenService.uploadGardenDocument(
        clientId,
        file.path,
        fileName,
        type,
      );

      return document;
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  /// Get all documentation for a garden
  Future<GardenDocumentation> getGardenDocumentation(String clientId) async {
    try {
      final notes = await _gardenService.getGardenNotes(clientId);
      final documents = await _gardenService.getGardenDocuments(clientId);
      final plantingHistory = await _gardenService.getPlantingHistory(clientId);

      return GardenDocumentation(
        notes: notes,
        documents: documents,
        plantingHistory: plantingHistory,
      );
    } catch (e) {
      throw Exception('Failed to get garden documentation: $e');
    }
  }
}

/// Container for all garden documentation
class GardenDocumentation {
  final List<GardenNote> notes;
  final List<GardenDocument> documents;
  final List<dynamic> plantingHistory;

  GardenDocumentation({
    required this.notes,
    required this.documents,
    required this.plantingHistory,
  });
}
