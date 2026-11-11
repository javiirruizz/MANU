import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../viewmodels/auth_view_model.dart';
import 'widgets/pictograma_imagen.dart';

/// Se muestra en el primer acceso, cuando la contraseña es temporal.
class CambiarPasswordPage extends StatefulWidget {
  const CambiarPasswordPage({super.key});

  @override
  State<CambiarPasswordPage> createState() => _CambiarPasswordPageState();
}

class _CambiarPasswordPageState extends State<CambiarPasswordPage> {
  final _nuevaCtrl = TextEditingController();
  final _repetirCtrl = TextEditingController();
  String? _errorLocal;

  @override
  void dispose() {
    _nuevaCtrl.dispose();
    _repetirCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nueva = _nuevaCtrl.text;
    if (nueva.length < 6) {
      setState(() => _errorLocal = 'Mínimo 6 caracteres.');
      return;
    }
    if (nueva != _repetirCtrl.text) {
      setState(() => _errorLocal = 'Las contraseñas no coinciden.');
      return;
    }
    setState(() => _errorLocal = null);
    // Si va bien, AuthGate cambia de pantalla solo.
    await context.read<AuthViewModel>().cambiarPassword(nueva);
  }

  InputDecoration _decoracion(String etiqueta) => InputDecoration(
    labelText: etiqueta,
    labelStyle: const TextStyle(fontSize: 22),
    prefixIcon: const Icon(Icons.lock_outline, size: 32),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
  );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final error = _errorLocal ?? auth.error;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Card(
              color: AppColors.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: PictogramaImagen(
                        consulta: 'contraseña',
                        size: 110,
                        iconoReserva: Icons.lock_outline,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Crea tu contraseña',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Es tu primer acceso. Cambia la contraseña temporal por una tuya.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, color: AppColors.textSoft),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _nuevaCtrl,
                      obscureText: true,
                      style: const TextStyle(fontSize: 26),
                      decoration: _decoracion('Nueva contraseña'),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _repetirCtrl,
                      obscureText: true,
                      onSubmitted: (_) => _guardar(),
                      style: const TextStyle(fontSize: 26),
                      decoration: _decoracion('Repite la contraseña'),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        error,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: auth.cargando ? null : _guardar,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(76),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'GUARDAR CONTRASEÑA',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          context.read<AuthViewModel>().cerrarSesion(),
                      child: const Text(
                        'Cerrar sesión',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
