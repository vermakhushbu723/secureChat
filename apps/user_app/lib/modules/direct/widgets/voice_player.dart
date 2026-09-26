import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../../../core/core.dart';
import '../data/direct_models.dart';

/// Inline player for voice notes and audio files.
class VoicePlayer extends StatefulWidget {
  const VoicePlayer({super.key, required this.url, this.duration, required this.color, this.isVoice = true});

  final String url;
  final double? duration;
  final Color color;
  final bool isVoice;

  @override
  State<VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<VoicePlayer> {
  AudioPlayer? _player;
  final List<StreamSubscription<dynamic>> _subs = [];
  PlayerState _state = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration? _total;

  AudioPlayer _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;
    final p = AudioPlayer();
    _subs.addAll([
      p.onPlayerStateChanged.listen((s) => mounted ? setState(() => _state = s) : null),
      p.onPositionChanged.listen((d) => mounted ? setState(() => _position = d) : null),
      p.onDurationChanged.listen((d) => mounted ? setState(() => _total = d) : null),
      p.onPlayerComplete.listen((_) => mounted ? setState(() => _position = Duration.zero) : null),
    ]);
    return _player = p;
  }

  Future<void> _toggle() async {
    final p = _ensurePlayer();
    try {
      if (_state == PlayerState.playing) {
        await p.pause();
      } else if (_state == PlayerState.paused) {
        await p.resume();
      } else {
        await p.play(UrlSource(widget.url));
      }
    } catch (_) {
      if (mounted) context.showSnack('Could not play audio');
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalMs = (_total?.inMilliseconds ?? ((widget.duration ?? 0) * 1000)).toDouble();
    final pos = _position.inMilliseconds.toDouble().clamp(0, totalMs <= 0 ? 1 : totalMs).toDouble();
    final playing = _state == PlayerState.playing;
    return SizedBox(
      width: 240,
      child: Row(
        children: [
          Icon(widget.isVoice ? Icons.mic : Icons.audiotrack, color: widget.color.withValues(alpha: 0.7), size: 20),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: widget.color, size: 32),
            onPressed: _toggle,
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: SliderComponentShape.noOverlay,
                activeTrackColor: widget.color,
                inactiveTrackColor: widget.color.withValues(alpha: 0.25),
                thumbColor: widget.color,
              ),
              child: Slider(
                value: pos,
                max: totalMs <= 0 ? 1 : totalMs,
                onChanged: totalMs <= 0 ? null : (v) => _player?.seek(Duration(milliseconds: v.round())),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            formatDuration(playing || _position > Duration.zero ? _position.inSeconds : (totalMs / 1000)),
            style: TextStyle(color: widget.color.withValues(alpha: 0.7), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
