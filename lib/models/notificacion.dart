class Notificacion {
  String idNotificacion;
  String idTarea; 
  List<String> idAlumnos; // Vector de alumnos a los que va dirigido la notificación
  DateTime fecha;
  DateTime hora;
  String? periodicidad; // Relacionado con la periodicidad, puede ser null ya que hay notificaciones que son
  int? numeroPeriodicidad; // periódicas como un "Buenos días" y otras que no como "La tarea acaba en 15 minutos"

  Notificacion({
    required this.idNotificacion,
    required this.idTarea,
    required this.idAlumnos,
    required this.fecha,
    required this.hora, // no es required
    this.periodicidad, // no es required
    this.numeroPeriodicidad,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      idNotificacion: json['idNotificacion'] ?? '',
      idTarea: json['idTarea'] ?? '',
      // Convertimos el array de Firebase (List<dynamic>) a List<String> de Dart
      idAlumnos: List<String>.from(json['idAlumnos'] ?? []), 
      fecha: DateTime.parse(json['fecha']),
      hora: DateTime.parse(json['hora']),
      periodicidad: json['periodicidad'],
      numeroPeriodicidad: json['numeroPeriodicidad'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idNotificacion': idNotificacion,
      'idTarea': idTarea,
      'idAlumnos': idAlumnos, // Se sube directamente como un array a Firebase
      'fecha': fecha.toIso8601String(),
      'hora': hora.toIso8601String(),
      'periodicidad': periodicidad,
      'numeroPeriodicidad': numeroPeriodicidad,
    };
  }
}