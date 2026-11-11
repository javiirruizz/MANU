import '../models/paso.dart';
import '../models/tarea.dart';
import 'arasaac_service.dart';
import 'tarea_repository.dart';

class _Franja {
  const _Franja(
    this.nombre,
    this.descripcion,
    this.pictograma,
    this.hi,
    this.mi,
    this.hf,
    this.mf,
  );

  final String nombre;
  final String descripcion;
  final String pictograma; // palabra que se busca en ARASAAC
  final int hi, mi, hf, mf;
}

/// Horario de ejemplo: de lunes a viernes, de 8:30 a 13:30.
const _franjas = [
  _Franja(
    'Llegada y saludo',
    'Dejo la mochila y saludo',
    'saludar',
    8,
    30,
    9,
    0,
  ),
  _Franja(
    'Asamblea',
    'Calendario, tiempo y buenos días',
    'asamblea',
    9,
    0,
    9,
    45,
  ),
  _Franja(
    'Lectoescritura',
    'Leo y escribo con mi ficha',
    'escribir',
    9,
    45,
    10,
    30,
  ),
  _Franja('Almuerzo', 'Tomo mi bocadillo', 'bocadillo', 10, 30, 11, 0),
  _Franja('Recreo', 'Juego en el patio', 'patio', 11, 0, 11, 30),
  _Franja('Matemáticas', 'Números y cuentas', 'matemáticas', 11, 30, 12, 15),
  _Franja('Taller de plástica', 'Pinto y creo', 'pintar', 12, 15, 13, 0),
  _Franja(
    'Recoger y despedida',
    'Recojo mi mochila y digo adiós',
    'adiós',
    13,
    0,
    13,
    30,
  ),
];

/// Crea el horario de la semana actual (lunes a viernes; si hoy es fin de
/// semana, el de la semana siguiente) para los alumnos indicados.
/// Es seguro repetirlo: reemplaza el horario de ejemplo anterior.
/// Devuelve cuántas tareas ha creado.
Future<int> cargarHorarioEjemplo({
  required List<String> alumnoIds,
  TareaRepository? repositorio,
}) async {
  final repo = repositorio ?? TareaRepository();

  // Un pictograma por franja (se buscan en ARASAAC y se guardan en el paso).
  final ids = await Future.wait(
    _franjas.map((f) => ArasaacService.instance.buscarId(f.pictograma)),
  );

  final hoy = DateTime.now();
  var lunes = DateTime(
    hoy.year,
    hoy.month,
    hoy.day,
  ).subtract(Duration(days: hoy.weekday - 1));
  if (hoy.weekday >= DateTime.saturday) {
    lunes = lunes.add(const Duration(days: 7));
  }

  String dos(int n) => n.toString().padLeft(2, '0');
  final tareas = <Tarea>[];
  for (var d = 0; d < 5; d++) {
    final dia = lunes.add(Duration(days: d));
    for (var n = 0; n < _franjas.length; n++) {
      final f = _franjas[n];
      final pid = ids[n];
      tareas.add(
        Tarea(
          id: 'ejemplo_${dia.year}${dos(dia.month)}${dos(dia.day)}_$n',
          nombre: f.nombre,
          descripcion: f.descripcion,
          fecha: dia,
          horario: 'mañana',
          horaInicio: DateTime(dia.year, dia.month, dia.day, f.hi, f.mi),
          horaFinal: DateTime(dia.year, dia.month, dia.day, f.hf, f.mf),
          aulaId: 'Aula',
          creadaPor: 'ejemplo',
          alumnoIds: alumnoIds,
          pasos: pid == null
              ? const []
              : [
                  Paso(
                    id: '1',
                    descripcion: f.nombre,
                    orden: 1,
                    pictogramaId: pid.toString(),
                  ),
                ],
        ),
      );
    }
  }

  await repo.reemplazarHorarioEjemplo(
    tareas: tareas,
    desde: lunes,
    hasta: lunes.add(const Duration(days: 5)),
  );
  return tareas.length;
}
