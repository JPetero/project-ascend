import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Thin, reusable video playback wrapper — Build Session 8 Part 3. Used
/// for reviewing a freshly-recorded clip before upload and for playing
/// back a published Reel (Part 4). No autoplay audio unless [autoplay]
/// and [startMuted] are explicitly overridden by the caller.
class AscendVideoPlayer extends StatefulWidget {
  const AscendVideoPlayer({
    super.key,
    required this.url,
    this.autoplay = false,
    this.startMuted = true,
    this.looping = true,
  });

  final String url;
  final bool autoplay;
  final bool startMuted;
  final bool looping;

  @override
  State<AscendVideoPlayer> createState() => _AscendVideoPlayerState();
}

class _AscendVideoPlayerState extends State<AscendVideoPlayer> {
  late final VideoPlayerController _controller;
  bool _isMuted = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _isMuted = widget.startMuted;
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..setLooping(widget.looping)
      ..setVolume(_isMuted ? 0 : 1)
      ..initialize()
          .then((_) {
            if (!mounted) return;
            setState(() {});
            if (widget.autoplay) _controller.play();
          })
          .catchError((_) {
            if (!mounted) return;
            setState(() => _hasError = true);
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _controller.setVolume(_isMuted ? 0 : 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const AspectRatio(
        aspectRatio: 9 / 16,
        child: ColoredBox(
          color: Colors.black12,
          child: Center(child: Icon(Icons.error_outline)),
        ),
      );
    }
    if (!_controller.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 9 / 16,
        child: ColoredBox(
          color: Colors.black12,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlay,
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            VideoPlayer(_controller),
            if (!_controller.value.isPlaying)
              const Center(
                child: Icon(Icons.play_arrow, size: 56, color: Colors.white70),
              ),
            IconButton(
              icon: Icon(
                _isMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
              ),
              onPressed: _toggleMute,
            ),
          ],
        ),
      ),
    );
  }
}
