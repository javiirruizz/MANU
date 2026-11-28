import 'package:material_ui/material_ui.dart';

import '../../data/chat_repository.dart';

class InsigniaMensajes extends StatefulWidget {
  const InsigniaMensajes({super.key, required this.uid, required this.child});

  final String uid;
  final Widget child;

  @override
  State<InsigniaMensajes> createState() => _InsigniaMensajesState();
}

class _InsigniaMensajesState extends State<InsigniaMensajes> {
  late final Stream<int> _stream = ChatRepository().streamNoLeidos(widget.uid);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _stream,
      builder: (context, snap) {
        final n = snap.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            if (n > 0)
              Positioned(
                top: -8,
                right: -8,
                child: Semantics(
                  label: n == 1 ? '1 mensaje sin leer' : '$n mensajes sin leer',
                  excludeSemantics: true,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      '$n',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
