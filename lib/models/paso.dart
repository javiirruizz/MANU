class Paso {
  const Paso({
    required this.id,
    required this.descripcion,
    required this.orden,
    this.estado = 'pendiente',
    this.pictogramaId,
  });

  final String id;
  final String descripcion;
  final int orden;
  final String estado;
  final String? pictogramaId;

  Paso copyWith({
    String? id,
    String? descripcion,
    int? orden,
    String? estado,
    String? pictogramaId,
  }) {
    return Paso(
      id: id ?? this.id,
      descripcion: descripcion ?? this.descripcion,
      orden: orden ?? this.orden,
      estado: estado ?? this.estado,
      pictogramaId: pictogramaId ?? this.pictogramaId,
    );
  }

  factory Paso.fromMap(String id, Map<String, dynamic> m) => Paso(
    id: id,
    descripcion: m['descripcion'] ?? '',
    orden: m['orden'] ?? 0,
    estado: m['estado'] ?? 'pendiente',
    pictogramaId: m['pictogramaId'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'descripcion': descripcion,
    'orden': orden,
    'estado': estado,
    'pictogramaId': pictogramaId,
  };
}
