import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

class ReproductorVideoWidget extends StatefulWidget {
  final String url;

  const ReproductorVideoWidget({super.key, required this.url});

  @override
  State<ReproductorVideoWidget> createState() => _ReproductorVideoWidgetState();
}

class _ReproductorVideoWidgetState extends State<ReproductorVideoWidget> {
  late final VideoPlayerController _controller;
  bool _inicializado = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _inicializado = true);
        }
      })
      ..addListener(() {
        if (mounted) setState(() {});
      });
  }

  void _alternarReproduccion() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_inicializado) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final bool reproduciendo = _controller.value.isPlaying;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_controller),
                GestureDetector(
                  onTap: _alternarReproduccion,
                  child: Container(
                    color: Colors.black26,
                    child: Center(
                      child: Icon(
                        reproduciendo ? Icons.pause_circle : Icons.play_circle,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          ),
        ],
      ),
    );
  }
}
