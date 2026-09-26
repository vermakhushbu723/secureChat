import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/core.dart';
import '../../groups/data/group_models.dart';
import '../../groups/data/group_repository.dart';
import '../../groups/state/group_sender.dart';

class VoiceMessageScreen extends StatelessWidget {
  const VoiceMessageScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return LoginGate(
      title: 'Voice Message',
      child: Scaffold(
        appBar: AppBar(title: const Text('Voice Message')),
        body: AsyncView<GroupDetail>(load: () => GroupRepository.detail(groupId), builder: (_, d, _) => _Voice(detail: d)),
      ),
    );
  }
}

class _Voice extends StatefulWidget {
  const _Voice({required this.detail});

  final GroupDetail detail;

  @override
  State<_Voice> createState() => _VoiceState();
}

class _VoiceState extends State<_Voice> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  StreamSubscription<Amplitude>? _ampSub;
  Timer? _timer;
  int _seconds = 0;
  bool _recording = false;
  String? _path;
  String _ext = 'm4a';
  bool _sending = false;
  bool _playing = false;
  final List<double> _levels = List.filled(36, 0.05);
  late MessageVisibility _visibility = Session.defaultVisibility.value;

  MessageVisibility get _effective => switch (widget.detail.settings.messageMode) {
    'public' => MessageVisibility.public,
    'private' => MessageVisibility.private,
    _ => _visibility,
  };

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) => mounted ? setState(() => _playing = false) : null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ampSub?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_recording) return _stop();
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) context.showSnack('Microphone permission is required');
        return;
      }
      var encoder = kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc;
      if (!await _recorder.isEncoderSupported(encoder)) encoder = AudioEncoder.wav;
      _ext = switch (encoder) {
        AudioEncoder.opus => 'webm',
        AudioEncoder.wav => 'wav',
        _ => 'm4a',
      };
      var path = '';
      if (!kIsWeb) path = '${(await getTemporaryDirectory()).path}/voice_${DateTime.now().millisecondsSinceEpoch}.$_ext';
      await _recorder.start(RecordConfig(encoder: encoder, numChannels: 1, bitRate: 64000), path: path);
      _ampSub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 150)).listen((a) {
        final level = ((a.current + 50) / 50).clamp(0.05, 1.0);
        setState(() => _levels
          ..removeAt(0)
          ..add(level));
      });
      GroupRepository.typing(widget.detail.id, isTyping: true, kind: 'recording');
      setState(() {
        _recording = true;
        _path = null;
        _seconds = 0;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _seconds++));
    } catch (e) {
      if (mounted) context.showSnack('Cannot record audio: $e');
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    await _ampSub?.cancel();
    GroupRepository.typing(widget.detail.id, isTyping: false, kind: 'recording');
    final path = await _recorder.stop();
    setState(() {
      _recording = false;
      _path = path;
    });
  }

  Future<void> _discard() async {
    if (_recording) await _stop();
    await _player.stop();
    setState(() {
      _path = null;
      _seconds = 0;
      _playing = false;
    });
  }

  Future<void> _preview() async {
    final path = _path;
    if (path == null) return;
    if (_playing) {
      await _player.pause();
      return setState(() => _playing = false);
    }
    await _player.play(kIsWeb ? UrlSource(path) : DeviceFileSource(path));
    setState(() => _playing = true);
  }

  Future<void> _send() async {
    final path = _path;
    if (path == null) return;
    if (_seconds < 1) return context.showSnack('Voice message too short');
    setState(() => _sending = true);
    final bytes = await XFile(path).readAsBytes();
    final blocked = await GroupSender.file(
      widget.detail.id,
      bytes,
      'voice_${DateTime.now().millisecondsSinceEpoch}.$_ext',
      'voice',
      _effective,
      duration: _seconds.toDouble(),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (await GroupSender.handle(context, blocked, sent: '${_effective.label} voice message sent') && mounted) context.pop();
  }

  String get _time => '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final done = _path != null && !_recording;
    final fixed = widget.detail.settings.messageMode != 'user_select';
    if (!widget.detail.me.canSendMedia) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: EmptyState(icon: Icons.mic_off_outlined, title: 'Voice disabled', message: widget.detail.me.sendBlockedMessage ?? 'Members cannot send media in this group.'),
      );
    }
    return SafeArea(
      child: ResponsiveBody(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Text(_time, style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w300, fontFeatures: [FontFeature.tabularFigures()])),
              const SizedBox(height: 8),
              Text(
                _recording ? 'Recording...' : done ? 'Recording ready' : 'Tap the mic to start recording',
                style: TextStyle(color: context.palette.textSecondary),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 64,
                child: Row(
                  children: [
                    for (final l in _levels)
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          height: 6 + l * 54,
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(alpha: _recording ? 0.9 : 0.35),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.outlined(iconSize: 28, icon: const Icon(Icons.delete_outline), tooltip: 'Discard', onPressed: _sending ? null : _discard),
                  GestureDetector(
                    onTap: _sending ? null : _toggle,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: _recording ? context.palette.danger : context.colors.primary),
                      child: Icon(_recording ? Icons.stop_rounded : Icons.mic, size: 42, color: context.colors.onPrimary),
                    ),
                  ),
                  IconButton.filled(
                    color: Colors.white,
                    iconSize: 28,
                    tooltip: 'Send',
                    icon: _sending ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
                    onPressed: done && !_sending ? _send : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (done) TextButton.icon(onPressed: _preview, icon: Icon(_playing ? Icons.pause : Icons.play_arrow), label: Text(_playing ? 'Pause' : 'Preview')),
              const SizedBox(height: 8),
              if (fixed)
                Text('Group admin set message mode to ${messageModeLabel(widget.detail.settings.messageMode)}', style: TextStyle(color: context.palette.textSecondary))
              else
                SegmentedButton<MessageVisibility>(
                  showSelectedIcon: false,
                  segments: [for (final v in MessageVisibility.values) ButtonSegment(value: v, icon: Icon(v.icon), tooltip: v.label)],
                  selected: {_visibility},
                  onSelectionChanged: (s) => setState(() => _visibility = s.first),
                ),
              const SizedBox(height: 4),
              Text('Send as ${_effective.label}', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 14, color: context.palette.textSecondary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _effective.isProtected ? 'Encrypted - opens only in the secure viewer' : 'Voice messages are sent over an encrypted connection',
                      style: TextStyle(color: context.palette.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
