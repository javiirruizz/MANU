class PlanB {
  const PlanB({required this.id, required this.descripcion});

  final String id;
  final String descripcion;

  factory PlanB.fromMap(String id, Map<String, dynamic> m) =>
      PlanB(id: id, descripcion: m['descripcion'] ?? '');

  Map<String, dynamic> toMap() => {'descripcion': descripcion};
}
