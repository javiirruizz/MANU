import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../models/usuario.dart';
import '../viewmodels/usuario_view_model.dart';

class AltaUsuarioPage extends StatefulWidget {
  const AltaUsuarioPage({super.key});

  @override
  State<AltaUsuarioPage> createState() => _AltaUsuarioPageState();
}

class _AltaUsuarioPageState extends State<AltaUsuarioPage> {
  final _busquedaCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _usuarioCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  RolUsuario _rol = RolUsuario.alumno;
  DateTime? _fechaNacimiento;
  final Set<String> _alumnosSeleccionadosIds = {};
  String? _errorLocal;

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    _nombreCtrl.dispose();
    _usuarioCtrl.dispose();
    _dniCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final ahora = DateTime.now();
    final f = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(ahora.year - 12),
      firstDate: DateTime(1920),
      lastDate: ahora,
    );
    if (f != null) setState(() => _fechaNacimiento = f);
  }

  Future<void> _crear() async {
    if (_nombreCtrl.text.trim().isEmpty || _usuarioCtrl.text.trim().isEmpty) {
      setState(
        () => _errorLocal = 'Nombre y nombre de usuario son obligatorios.',
      );
      return;
    }

    final vm = context.read<UsuarioViewModel>();
    if (_rol == RolUsuario.familiar &&
        vm.alumnos.isNotEmpty &&
        _alumnosSeleccionadosIds.isEmpty) {
      setState(
        () => _errorLocal =
            'Selecciona al menos un alumno para vincular al familiar.',
      );
      return;
    }

    setState(() => _errorLocal = null);

    final creado = await vm.crearUsuario(
      nombre: _nombreCtrl.text,
      nombreUsuario: _usuarioCtrl.text,
      rol: _rol,
      dni: _dniCtrl.text,
      telefonoContacto: _telefonoCtrl.text,
      email: _emailCtrl.text,
      fechaNacimiento: _fechaNacimiento,
      alumnoIds: _alumnosSeleccionadosIds.toList(),
    );

    if (creado == null || !mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Cuenta creada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Entrega estos datos a la persona o a su familia.'),
            const SizedBox(height: 12),
            const Text('Nombre de usuario:'),
            SelectableText(
              creado.usuario.nombreUsuario,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text('Contraseña temporal:'),
            SelectableText(
              creado.passwordTemporal,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              'Solo se muestra una vez. En su primer acceso tendrá que cambiarla.',
              style: TextStyle(color: AppColors.textSoft),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Clipboard.setData(
              ClipboardData(
                text:
                    'Usuario: ${creado.usuario.nombreUsuario}\n'
                    'Contraseña: ${creado.passwordTemporal}',
              ),
            ),
            child: const Text('Copiar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hecho'),
          ),
        ],
      ),
    );

    _nombreCtrl.clear();
    _usuarioCtrl.clear();
    _dniCtrl.clear();
    _telefonoCtrl.clear();
    _emailCtrl.clear();
    setState(() {
      _rol = RolUsuario.alumno;
      _fechaNacimiento = null;
      _alumnosSeleccionadosIds.clear();
    });
  }

  Future<void> _editarUsuario(Usuario u) async {
    final nombreCtrl = TextEditingController(text: u.nombre);
    final dniCtrl = TextEditingController(text: u.dni ?? '');
    final telefonoCtrl = TextEditingController(text: u.telefonoContacto ?? '');
    String? errorDialogo;

    final guardado = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Editar usuario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(text: u.nombreUsuario),
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de usuario (no editable)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dniCtrl,
                  decoration: const InputDecoration(
                    labelText: 'DNI (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono de contacto (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (errorDialogo != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorDialogo!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final vm = context.read<UsuarioViewModel>();
                final ok = await vm.modificarUsuario(
                  usuarioId: u.id,
                  nombre: nombreCtrl.text,
                  nombreUsuario: u.nombreUsuario,
                  dni: dniCtrl.text,
                  telefonoContacto: telefonoCtrl.text,
                );
                if (!dialogCtx.mounted) return;
                if (ok) {
                  Navigator.of(dialogCtx).pop(true);
                } else {
                  setStateDialog(() => errorDialogo = vm.mensajeError);
                }
              },
              child: const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );

    nombreCtrl.dispose();
    dniCtrl.dispose();
    telefonoCtrl.dispose();

    if (guardado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos del usuario actualizados.')),
      );
    }
  }

  Future<void> _restablecerPassword(Usuario u) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Restablecer contraseña'),
        content: Text(
          'Se enviará un correo a ${u.email} con un enlace de un solo uso '
          'para que ${u.nombre} elija una contraseña nueva.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Enviar correo'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    final vm = context.read<UsuarioViewModel>();
    final correo = await vm.restablecerPassword(u.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          correo != null
              ? 'Correo enviado a $correo. Revisa también la carpeta de spam.'
              : (vm.mensajeError ?? 'Error al restablecer contraseña.'),
        ),
      ),
    );
  }

  Future<void> _cambiarEstado(Usuario u, EstadoCuenta nuevo) async {
    final (titulo, texto, boton) = switch (nuevo) {
      EstadoCuenta.suspendida => (
        'Suspender cuenta',
        '${u.nombre} no podrá iniciar sesión hasta que reactives su cuenta. '
            'Sus datos se conservan.',
        'Suspender',
      ),
      EstadoCuenta.baja => (
        'Dar de baja',
        '${u.nombre} perderá el acceso definitivamente. Su historial quedará '
            'archivado y no se eliminará de los registros del colegio.',
        'Dar de baja',
      ),
      EstadoCuenta.activa => (
        'Reactivar cuenta',
        '${u.nombre} podrá volver a iniciar sesión.',
        'Reactivar',
      ),
    };

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: nuevo == EstadoCuenta.baja
                ? FilledButton.styleFrom(backgroundColor: Colors.red)
                : null,
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(boton),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    final vm = context.read<UsuarioViewModel>();
    final ok = await vm.cambiarEstado(u.id, nuevo);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (vm.mensajeExito ?? 'Estado actualizado.')
              : (vm.mensajeError ?? 'No se pudo cambiar el estado.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UsuarioViewModel>();

    if (!vm.solicitante.tienePermiso(PermisoUsuario.gestionarUsuarios)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gestión de usuarios')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Acceso denegado: no tienes permiso para gestionar usuarios.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de usuarios'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.people_outline),
                text: 'Usuarios registrados',
              ),
              Tab(icon: Icon(Icons.person_add_outlined), text: 'Dar de alta'),
            ],
          ),
        ),
        body: TabBarView(children: [_buildTabUsuarios(vm), _buildTabAlta(vm)]),
      ),
    );
  }

  Widget _buildTabUsuarios(UsuarioViewModel vm) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Buscador
              TextField(
                controller: _busquedaCtrl,
                onChanged: vm.filtrarPorTexto,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, usuario o DNI...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: vm.filtroTexto.isNotEmpty
                      ? IconButton(
                          tooltip: 'Limpiar búsqueda',
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _busquedaCtrl.clear();
                            vm.filtrarPorTexto('');
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              // Filtro por rol
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Todos'),
                      selected: vm.filtroRol == null,
                      onSelected: (_) => vm.filtrarPorRol(null),
                    ),
                    const SizedBox(width: 8),
                    for (final r in RolUsuario.values) ...[
                      ChoiceChip(
                        label: Text(_nombreRol(r)),
                        selected: vm.filtroRol == r,
                        onSelected: (_) =>
                            vm.filtrarPorRol(vm.filtroRol == r ? null : r),
                      ),
                      const SizedBox(width: 8),
                    ],
                    FilterChip(
                      avatar: const Icon(Icons.archive_outlined, size: 18),
                      label: const Text('Bajas'),
                      selected: vm.verBajas,
                      onSelected: (_) => vm.alternarBajas(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Lista de usuarios filtrados
              Expanded(
                child: vm.cargando && vm.usuarios.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : vm.usuarios.isEmpty
                    ? const Center(
                        child: Text(
                          'No se encontraron usuarios con ese criterio.',
                          style: TextStyle(color: AppColors.textSoft),
                        ),
                      )
                    : ListView.separated(
                        itemCount: vm.usuarios.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, index) {
                          final u = vm.usuarios[index];
                          return ListTile(
                            title: Text(
                              u.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${u.nombreUsuario} · ${_nombreRol(u.rol)}'
                              '${u.dni != null ? ' · DNI: ${u.dni}' : ''}'
                              '${u.estado == EstadoCuenta.suspendida ? ' · SUSPENDIDA' : ''}'
                              '${u.estado == EstadoCuenta.baja ? ' · BAJA' : ''}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Editar usuario',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: vm.cargando
                                      ? null
                                      : () => _editarUsuario(u),
                                ),
                                IconButton(
                                  tooltip: (u.email == null || u.email!.isEmpty)
                                      ? 'Sin correo de recuperación'
                                      : 'Restablecer contraseña por correo',
                                  icon: const Icon(Icons.lock_reset),
                                  onPressed:
                                      (vm.cargando ||
                                          u.email == null ||
                                          u.email!.isEmpty)
                                      ? null
                                      : () => _restablecerPassword(u),
                                ),
                                if (u.estado != EstadoCuenta.baja)
                                  PopupMenuButton<EstadoCuenta>(
                                    tooltip: 'Estado de la cuenta',
                                    icon: const Icon(
                                      Icons.manage_accounts_outlined,
                                    ),
                                    enabled: !vm.cargando,
                                    onSelected: (e) => _cambiarEstado(u, e),
                                    itemBuilder: (_) => [
                                      if (u.estado == EstadoCuenta.activa)
                                        const PopupMenuItem(
                                          value: EstadoCuenta.suspendida,
                                          child: Text('Suspender'),
                                        )
                                      else
                                        const PopupMenuItem(
                                          value: EstadoCuenta.activa,
                                          child: Text('Reactivar'),
                                        ),
                                      const PopupMenuItem(
                                        value: EstadoCuenta.baja,
                                        child: Text('Dar de baja'),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabAlta(UsuarioViewModel vm) {
    final error = _errorLocal ?? vm.mensajeError;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            color: AppColors.surface,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _usuarioCtrl,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de usuario * (ej. lucas.gomez)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<RolUsuario>(
                    initialValue: _rol,
                    decoration: const InputDecoration(
                      labelText: 'Perfil *',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final r in RolUsuario.values)
                        DropdownMenuItem(value: r, child: Text(_nombreRol(r))),
                    ],
                    onChanged: (r) => setState(() {
                      _rol = r ?? _rol;
                      if (_rol != RolUsuario.familiar) {
                        _alumnosSeleccionadosIds.clear();
                      }
                    }),
                  ),
                  if (_rol == RolUsuario.familiar) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBlue,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(60),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Alumno(s) vinculados a este familiar *',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (vm.alumnos.isEmpty)
                            const Text(
                              'No hay alumnos registrados todavía. Crea primero la cuenta del alumno.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSoft,
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: vm.alumnos.map((alumno) {
                                final seleccionado = _alumnosSeleccionadosIds
                                    .contains(alumno.id);
                                return FilterChip(
                                  label: Text(alumno.nombre),
                                  selected: seleccionado,
                                  onSelected: (val) {
                                    setState(() {
                                      if (val) {
                                        _alumnosSeleccionadosIds.add(alumno.id);
                                      } else {
                                        _alumnosSeleccionadosIds.remove(
                                          alumno.id,
                                        );
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _dniCtrl,
                    decoration: const InputDecoration(
                      labelText: 'DNI (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _telefonoCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono de contacto (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Correo de recuperación (opcional)',
                      helperText:
                          'Necesario para poder restablecer la contraseña por correo.',
                      helperMaxLines: 2,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _elegirFecha,
                    icon: const Icon(Icons.cake_outlined),
                    label: Text(
                      _fechaNacimiento == null
                          ? 'Fecha de nacimiento (opcional)'
                          : '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}',
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: vm.cargando ? null : _crear,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: vm.cargando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Crear cuenta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _nombreRol(RolUsuario r) => switch (r) {
    RolUsuario.administrador => 'Administrador',
    RolUsuario.profesor => 'Profesor',
    RolUsuario.familiar => 'Familiar',
    RolUsuario.alumno => 'Alumno',
  };
}
