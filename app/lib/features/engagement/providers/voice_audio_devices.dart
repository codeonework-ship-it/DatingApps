// The microphone and the audio player behind Voice Icebreakers, as small
// interfaces with one provider each, so the screen and the notifier talk to
// a device they are handed (the plugins in the app, a fake in tests).

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

/// Records one voice clip at a time to a file.
abstract class VoiceRecorder {
  Future<bool> hasPermission();

  /// Starts recording to [path] (mono, 48 kHz; AAC on devices, Opus on web).
  Future<void> start(String path);

  /// Stops and returns the clip's path, or null when nothing was saved.
  Future<String?> stop();

  Future<void> dispose();
}

/// Plays a voice clip from a URL.
abstract class VoicePlayer {
  Future<void> setUrl(String url);

  /// Plays the loaded clip; completes when it ends or [stop] is called.
  Future<void> play();

  Future<void> stop();

  Future<void> dispose();
}

class _PluginVoiceRecorder implements VoiceRecorder {
  final AudioRecorder _recorder = AudioRecorder();

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start(String path) => _recorder.start(
    RecordConfig(
      encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
      numChannels: 1,
      sampleRate: 48000,
      bitRate: 96000,
    ),
    path: path,
  );

  @override
  Future<String?> stop() => _recorder.stop();

  @override
  Future<void> dispose() => _recorder.dispose();
}

class _JustAudioVoicePlayer implements VoicePlayer {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> setUrl(String url) => _player.setUrl(url);

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

/// Makes the recorder a Voice Icebreakers screen uses (one per screen).
final voiceRecorderFactoryProvider = Provider<VoiceRecorder Function()>(
  (ref) => _PluginVoiceRecorder.new,
);

/// Makes the player used to listen to voice introductions.
final voicePlayerFactoryProvider = Provider<VoicePlayer Function()>(
  (ref) => _JustAudioVoicePlayer.new,
);
