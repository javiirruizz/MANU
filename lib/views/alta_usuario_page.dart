import 'package:flutter/material.dart';
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
  final _nombreCtrl = TextEditingController();
  final _usuarioCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  RolUsuario _rol = RolUsuario.alumno;
  DateTime? _fechaNacimiento;
  String? _errorLocal;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _usuarioCtrl.dispose();
    _dniCtrl.dispose();
    _telefonoCtrl.dispose();
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
    setState(() => _errorLocal = null);

    final vm = context.read<UsuarioViewModel>();
    final creado = await vm.crearUsuario(
      nombre: _nombreCtrl.text,
      nombreUsuario: _usuarioCtrl.text,
      rol: _rol,
      dni: _dniCtrl.text,
      telefonoContacto: _telefonoCtrl.text,
      fechaNacimiento: _fechaNacimiento,
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
    setState(() {
      _rol = RolUsuario.alumno;
      _fechaNacimiento = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UsuarioViewModel>();

    // Prueba 3: un rol sin permiso queda bloqueado
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

    final error = _errorLocal ?? vm.mensajeError;

    return Scaffold(
      appBar: AppBar(title: const Text('Alta de nuevas cuentas')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
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
                              DropdownMenuItem(
                                value: r,
                                child: Text(_nombreRol(r)),
                              ),
                          ],
                          onChanged: (r) => setState(() => _rol = r ?? _rol),
                        ),
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Crear cuenta'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Usuarios registrados',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                for (final u in vm.usuarios)
                  ListTile(
                    dense: true,
                    title: Text(u.nombre),
                    subtitle: Text('${u.nombreUsuario} · ${_nombreRol(u.rol)}'),
                  ),
              ],
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
