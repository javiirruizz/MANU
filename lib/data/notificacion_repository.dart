import '../models/notificacion.dart';

class NotificacionService {
  
  // Método para guardar la notificación en Firebase cuando el profesor la crea
  Future<void> guardarNotificacionEnBD(Notificacion notificacion) async {
    // Lógica para hacer el insert en Firebase Firestore
  }

  // Método para que el alumno descargue sus notificaciones al abrir la app
  Future<List<Notificacion>> cargarNotificacionesAlumno(String idAlumno) async {
    // Lógica para hacer el select en Firebase Firestore
    return [];
  }

  // Método que habla con el sistema del móvil (Android/iOS) para que suene
  Future<void> programarAlertaLocal(Notificacion notificacion) async {
    // Lógica usando flutter_local_notifications para que el móvil 
    // pite 5 minutos antes de "notificacion.hora"
  }
}