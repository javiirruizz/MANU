import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageRepository {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> seleccionarYSubirImagen() async {
    // 1. Abrir la galería/explorador de archivos
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    // 2. Crear una referencia en Firebase Storage
    final String fileName = 'tareas/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
    final Reference ref = _storage.ref().child(fileName);

    // 3. Subir el archivo
    // Nota: En Flutter Web se usa putData, en móvil putFile. Aquí usamos putData para que sea multiplataforma.
    final uploadTask = await ref.putData(await image.readAsBytes());

    // 4. Obtener la URL pública para guardarla en la Tarea
    final String downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }
}