class Aula {
  const Aula({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.capacidad,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final int capacidad;

  factory Aula.fromMap(String id, Map<String, dynamic> m) => Aula(
    id: id,
    nombre: m['nombre'] ?? '',
    descripcion: m['descripcion'] ?? '',
    capacidad: m['capacidad'] ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'descripcion': descripcion,
    'capacidad': capacidad,
  };
}
