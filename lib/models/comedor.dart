class Comedor {
  const Comedor({required this.id});

  final String id;

  factory Comedor.fromMap(String id, Map<String, dynamic> m) => Comedor(id: id);

  Map<String, dynamic> toMap() => {};
}
