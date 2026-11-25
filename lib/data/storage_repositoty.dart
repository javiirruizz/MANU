import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class StorageRepository {
  final ImagePicker _picker = ImagePicker();

  static const String _cloudName = 'k4v88xwh';
  static const String _uploadPreset = 'k4v88xwh';

  Future<String?> _subirACloudinary({
    required Uint8List bytes,
    required String fileName,
    required String folder,
  }) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/auto/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = folder
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName,
          ),
        );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['secure_url'] as String?;
      } else {
        debugPrint('Error Cloudinary (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Excepción al subir a Cloudinary: $e');
      return null;
    }
  }

  Future<String?> seleccionarYSubirImagen() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    final bytes = await image.readAsBytes();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';

    return _subirACloudinary(
      bytes: bytes,
      fileName: fileName,
      folder: 'tareas/imagenes',
    );
  }

  Future<String?> seleccionarYSubirVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return null;

    final bytes = await video.readAsBytes();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${video.name}';

    return _subirACloudinary(
      bytes: bytes,
      fileName: fileName,
      folder: 'tareas/videos',
    );
  }

  Future<String?> seleccionarYSubirAudio() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: true, // Crucial para Web: carga los bytes del archivo
    );

    if (result == null || result.files.isEmpty) return null;

    final fileBytes = result.files.first.bytes;
    if (fileBytes == null) return null;

    final String originalName = result.files.first.name;
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}_$originalName';

    return _subirACloudinary(
      bytes: fileBytes,
      fileName: fileName,
      folder: 'tareas/audios',
    );
  }
}