import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../viewmodels/auth_view_model.dart';

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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final error = _errorLocal ?? auth.error;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              color: AppColors.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Crea tu contraseña',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Es tu primer acceso. Cambia la contraseña temporal por una tuya.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSoft),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nuevaCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Nueva contraseña',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _repetirCtrl,
                      obscureText: true,
                      onSubmitted: (_) => _guardar(),
                      decoration: const InputDecoration(
                        labelText: 'Repite la contraseña',
                        border: OutlineInputBorder(),
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
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: auth.cargando ? null : _guardar,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Guardar contraseña'),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.read<AuthViewModel>().cerrarSesion(),
                      child: const Text('Cerrar sesión'),
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
