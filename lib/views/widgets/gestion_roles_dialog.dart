import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/usuario_repository.dart';
import '../../models/usuario.dart';
import '../../viewmodels/usuario_view_model.dart';

class GestionRolesDialog extends StatefulWidget {
  const GestionRolesDialog({
    super.key,
    required this.repository,
    this.solicitanteInicial,
  });

  final UsuarioRepository repository;
  final Usuario? solicitanteInicial;

  @override
  State<GestionRolesDialog> createState() => _GestionRolesDialogState();
}

class _GestionRolesDialogState extends State<GestionRolesDialog> {
  late final UsuarioViewModel _vm;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = UsuarioViewModel(
      widget.repository,
      solicitanteInicial: widget.solicitanteInicial,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _vm.dispose();
    super.dispose();
  }

  Color _colorRol(RolUsuario rol) {
    switch (rol) {
      case RolUsuario.administrador:
        return const Color(0xFF8E24AA);
      case RolUsuario.profesor:
        return AppColors.primary;
      case RolUsuario.familiar:
        return AppColors.green;
      case RolUsuario.alumno:
        return AppColors.orange;
    }
  }

  IconData _iconoRol(RolUsuario rol) {
    switch (rol) {
      case RolUsuario.administrador:
        return Icons.admin_panel_settings;
      case RolUsuario.profesor:
        return Icons.school;
      case RolUsuario.familiar:
        return Icons.family_restroom;
      case RolUsuario.alumno:
        return Icons.face;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _vm,
      builder: (context, _) {
        final uSel = _vm.usuarioSeleccionado;

        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cardBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.security,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Control de Accesos: Roles y Permisos (HU 03)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Gestión de perfiles de usuario y privacidad de la información',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSoft,
                      ),
                    ),
                  ],
                ),
              ),
              // Conmutador del solicitante activo (para probar permisos)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tabTrack,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Sesión activa: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSoft,
                      ),
                    ),
                    DropdownButton<String>(
                      value: _vm.solicitante.id,
                      underline: const SizedBox.shrink(),
                      isDense: true,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'admin_1',
                          child: Text('Usuario Administrador'),
                        ),
                        DropdownMenuItem(
                          value: 'profe_1',
                          child: Text('Usuario Profesor'),
                        ),
                        DropdownMenuItem(
                          value: 'alum_1',
                          child: Text('Usuario Alumno 1'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val == null) return;
                        if (val == 'admin_1') {
                          _vm.cambiarSolicitante(
                            Usuario(
                              id: 'admin_1',
                              nombre: 'Usuario Administrador',
                              dni: '00000001A',
                              telefonoContacto: '600000001',
                              fechaNacimiento: DateTime(1985, 1, 1),
                              rol: RolUsuario.administrador,
                            ),
                          );
                        } else if (val == 'profe_1') {
                          _vm.cambiarSolicitante(
                            Usuario(
                              id: 'profe_1',
                              nombre: 'Usuario Profesor',
                              dni: '00000002B',
                              telefonoContacto: '600000002',
                              fechaNacimiento: DateTime(1990, 1, 1),
                              rol: RolUsuario.profesor,
                            ),
                          );
                        } else if (val == 'alum_1') {
                          _vm.cambiarSolicitante(
                            Usuario(
                              id: 'alum_1',
                              nombre: 'Usuario Alumno 1',
                              dni: '00000004D',
                              telefonoContacto: '600000004',
                              fechaNacimiento: DateTime(2012, 1, 1),
                              rol: RolUsuario.alumno,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 860,
            height: 520,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Panel izquierdo: Listado de usuarios y filtros
                SizedBox(
                  width: 320,
                  child: Column(
                    children: [
                      // Buscador
                      TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre o DNI...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          filled: true,
                          fillColor: AppColors.tabTrack,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        onChanged: _vm.filtrarPorTexto,
                      ),
                      const SizedBox(height: 8),

                      // Filtro por rol
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Todos', style: TextStyle(fontSize: 11)),
                              selected: _vm.filtroRol == null,
                              onSelected: (_) => _vm.filtrarPorRol(null),
                            ),
                            const SizedBox(width: 4),
                            ChoiceChip(
                              label: const Text('Admin', style: TextStyle(fontSize: 11)),
                              selected: _vm.filtroRol == RolUsuario.administrador,
                              onSelected: (_) => _vm.filtrarPorRol(RolUsuario.administrador),
                            ),
                            const SizedBox(width: 4),
                            ChoiceChip(
                              label: const Text('Profesores', style: TextStyle(fontSize: 11)),
                              selected: _vm.filtroRol == RolUsuario.profesor,
                              onSelected: (_) => _vm.filtrarPorRol(RolUsuario.profesor),
                            ),
                            const SizedBox(width: 4),
                            ChoiceChip(
                              label: const Text('Familiares', style: TextStyle(fontSize: 11)),
                              selected: _vm.filtroRol == RolUsuario.familiar,
                              onSelected: (_) => _vm.filtrarPorRol(RolUsuario.familiar),
                            ),
                            const SizedBox(width: 4),
                            ChoiceChip(
                              label: const Text('Alumnos', style: TextStyle(fontSize: 11)),
                              selected: _vm.filtroRol == RolUsuario.alumno,
                              onSelected: (_) => _vm.filtrarPorRol(RolUsuario.alumno),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Lista de usuarios
                      Expanded(
                        child: _vm.cargando
                            ? const Center(child: CircularProgressIndicator())
                            : _vm.usuarios.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No se encontraron usuarios.',
                                      style: TextStyle(color: AppColors.textSoft),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: _vm.usuarios.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 6),
                                    itemBuilder: (context, index) {
                                      final u = _vm.usuarios[index];
                                      final isSelected = u.id == uSel?.id;
                                      final rolColor = _colorRol(u.rol);

                                      return InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () => _vm.seleccionarUsuario(u),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.cardBlue
                                                : AppColors.surface,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.divider,
                                              width: isSelected ? 1.5 : 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 18,
                                                backgroundColor:
                                                    rolColor.withValues(alpha: 0.15),
                                                child: Icon(
                                                  _iconoRol(u.rol),
                                                  color: rolColor,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      u.nombre,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                        color: AppColors.textDark,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      'DNI: ${u.dni}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: AppColors.textSoft,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      rolColor.withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  u.rol.name.toUpperCase(),
                                                  style: TextStyle(
                                                    color: rolColor,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),

                const VerticalDivider(width: 24, thickness: 1),

                // Panel derecho: Detalle de rol y permisos granulares
                Expanded(
                  child: uSel == null
                      ? const Center(
                          child: Text(
                            'Selecciona un usuario para gestionar sus accesos.',
                            style: TextStyle(color: AppColors.textSoft),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Mensajes de error o éxito
                            if (_vm.mensajeError != null)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _vm.mensajeError!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red.shade900,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_vm.mensajeExito != null)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.greenSoft,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.green),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      color: AppColors.greenDark,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _vm.mensajeExito!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.greenDark,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Tarjeta de información del usuario y selector de rol
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.cardBlue.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: _colorRol(uSel.rol),
                                    child: Icon(
                                      _iconoRol(uSel.rol),
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          uSel.nombre,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        Text(
                                          'DNI: ${uSel.dni} | Teléfono: ${uSel.telefonoContacto}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSoft,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Selector de Rol
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Rol de Usuario:',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textSoft,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        child: DropdownButton<RolUsuario>(
                                          value: uSel.rol,
                                          underline: const SizedBox.shrink(),
                                          isDense: true,
                                          items: RolUsuario.values
                                              .map(
                                                (r) => DropdownMenuItem(
                                                  value: r,
                                                  child: Text(
                                                    r.name.toUpperCase(),
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                      color: _colorRol(r),
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (nuevoRol) {
                                            if (nuevoRol != null &&
                                                nuevoRol != uSel.rol) {
                                              _vm.cambiarRol(uSel.id, nuevoRol);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Cabecera de permisos granulares
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Permisos y control de acciones:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () =>
                                      _vm.restablecerPermisosPorDefecto(uSel.id),
                                  icon: const Icon(Icons.restore, size: 16),
                                  label: const Text(
                                    'Restablecer por defecto',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Lista de permisos con Switch
                            Expanded(
                              child: ListView.separated(
                                itemCount: PermisoUsuario.values.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final permiso = PermisoUsuario.values[index];
                                  final tiene = uSel.permisos.contains(permiso);

                                  return SwitchListTile(
                                    dense: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 0,
                                    ),
                                    title: Text(
                                      permiso.nombre,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    subtitle: Text(
                                      permiso.descripcion,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSoft,
                                      ),
                                    ),
                                    value: tiene,
                                    activeThumbColor: AppColors.primary,
                                    onChanged: (val) {
                                      _vm.togglePermiso(uSel.id, permiso, val);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}
