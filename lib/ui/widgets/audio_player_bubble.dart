import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerBubble extends StatefulWidget {
  final String audioPath;
  final Color baseColor;

  const AudioPlayerBubble({
    super.key,
    required this.audioPath,
    required this.baseColor,
  });

  @override
  State<AudioPlayerBubble> createState() => _AudioPlayerBubbleState();
}

class _AudioPlayerBubbleState extends State<AudioPlayerBubble> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    // Listen to player state
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    // Listen to duration
    _audioPlayer.onDurationChanged.listen((newDuration) {
       if (mounted) {
        setState(() {
          _duration = newDuration;
        });
       }
    });

    // Listen to position
    _audioPlayer.onPositionChanged.listen((newPosition) {
       if (mounted) {
        setState(() {
          _position = newPosition;
        });
       }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(DeviceFileSource(widget.audioPath));
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    final twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.baseColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.baseColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, 
                color: widget.baseColor, size: 32),
            onPressed: _playPause,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                  Text(
                    _isPlaying ? "Playing Audio..." : "Play Recording",
                    style: TextStyle(
                        color: widget.baseColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                      children: [
                          Text(
                            _formatDuration(_position),
                            style: TextStyle(color: widget.baseColor.withOpacity(0.7), fontSize: 10),
                          ),
                          Text(
                            " / ${_formatDuration(_duration)}",
                            style: TextStyle(color: widget.baseColor.withOpacity(0.7), fontSize: 10),
                          ),
                      ],
                  )
              ],
          ),
          const SizedBox(width: 12),
          // Simple visualizer placeholder
          SizedBox(
              width: 40,
              height: 20,
              child: CustomPaint(
                  painter: _WaveformPainter(color: widget.baseColor, animating: _isPlaying),
              ),
          )
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
    final Color color;
    final bool animating;
    
    _WaveformPainter({required this.color, required this.animating});

    @override
    void paint(Canvas canvas, Size size) {
        final paint = Paint()
            ..color = color
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round;
            
        final gap = size.width / 5;
        for (int i = 0; i < 5; i++) {
            final height = animating ? (size.height * (0.3 + (i % 3) * 0.2)) : 2.0; 
            // Simple static logic for now, could be random if animating
            final x = i * gap + gap/2;
            final y = size.height / 2;
            canvas.drawLine(Offset(x, y - height/2), Offset(x, y + height/2), paint);
        }
    }
    
    @override
    bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
