// Guided Voice Icebreakers (release-excluded flag `voice_icebreakers_enabled`;
// the hub tests cover the gated state). The microphone and the audio player
// are handed to the screen through voiceRecorderFactoryProvider and
// voicePlayerFactoryProvider: here they are fakes that behave like a device
// that granted (or refused) the microphone, wrote the clip to the temp folder
// (path_provider answers with a real temp directory) and played a URL, so
// every screen path around them runs for real: the requests built from the
// clip, the labels, the errors. Real capture and audible playback stay manual.

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/engagement/providers/voice_audio_devices.dart';
import 'package:verified_dating_app/features/engagement/screens/voice_icebreakers_screen.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_checks.dart';
import 'engagement_qa.dart';

const _record = ValueKey('qa.voice.recording_button');
const _transcript = ValueKey('qa.voice.transcript');
const _share = ValueKey('qa.voice.share');
const _discard = ValueKey('qa.voice.discard');
const _prompt = ValueKey('qa.voice.prompt');
const _listen = ValueKey('qa.voice.listen.v-1');
const _audioUrl = 'https://media.test/voice/v-1.m4a';

/// The microphone, the player and the temp folder of a test device.
class _Device {
  _Device(this.dir);
  final Directory dir;
  bool micAllowed = true;
  bool startFails = false;
  bool stopLosesClip = false;
  String? clipPath;

  /// Every recorder call, in order.
  final recorder = <String>[];

  /// Every player call, in order (`setUrl <url>`, `play`, `stop`, ...).
  final player = <String>[];
  Completer<void>? _playing;

  bool get isPlaying => _playing != null && !_playing!.isCompleted;

  void finishPlayback() {
    if (isPlaying) _playing!.complete();
  }

  List<Override> get overrides => [
    voiceRecorderFactoryProvider.overrideWithValue(() => _FakeRecorder(this)),
    voicePlayerFactoryProvider.overrideWithValue(() => _FakePlayer(this)),
  ];

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => dir.path,
        );
  }
}

class _FakeRecorder implements VoiceRecorder {
  _FakeRecorder(this.d);
  final _Device d;

  @override
  Future<bool> hasPermission() async {
    d.recorder.add('hasPermission');
    return d.micAllowed;
  }

  @override
  Future<void> start(String path) async {
    d.recorder.add('start');
    if (d.startFails) {
      throw PlatformException(code: 'record', message: 'busy');
    }
    d.clipPath = path;
  }

  @override
  Future<String?> stop() async {
    d.recorder.add('stop');
    if (d.stopLosesClip) return null;
    File(d.clipPath!).writeAsBytesSync(List<int>.generate(64, (i) => i));
    return d.clipPath;
  }

  @override
  Future<void> dispose() async => d.recorder.add('dispose');
}

class _FakePlayer implements VoicePlayer {
  _FakePlayer(this.d);
  final _Device d;

  @override
  Future<void> setUrl(String url) async => d.player.add('setUrl $url');

  @override
  Future<void> play() async {
    d.player.add('play');
    d._playing = Completer<void>();
    await d._playing!.future;
  }

  @override
  Future<void> stop() async {
    d.player.add('stop');
    d.finishPlayback();
  }

  @override
  Future<void> dispose() async {
    d.player.add('dispose');
    d.finishPlayback();
  }
}

Map<String, dynamic> _intro({
  String id = 'v-1',
  String sender = 'maya',
  String transcript = 'I like a book and a quiet coffee.',
}) => {
  'id': id,
  'match_id': 'match-1',
  'sender_user_id': sender,
  'receiver_user_id': sender == 'me' ? 'maya' : 'me',
  'prompt_id': 'p-1',
  'prompt_text': 'A Sunday you love',
  'transcript': transcript,
  'duration_seconds': 24,
  'status': 'sent',
  'moderation_status': 'approved',
  'play_count': 0,
};

QaApi _api({List<Map<String, dynamic>>? intros}) => QaApi()
  ..json('GET /matches/me', {
    'matches': [
      {'id': 'match-1', 'user_id': 'maya', 'user_name': 'Maya'},
      {'id': 'match-2', 'user_id': 'theo', 'user_name': 'Theo'},
    ],
  })
  ..json('GET /engagement/voice-icebreakers/prompts', {
    'prompts': [
      {'id': 'p-1', 'prompt_text': 'A Sunday you love'},
      {'id': 'p-2', 'prompt_text': 'A small ritual you never skip'},
    ],
  })
  ..json('GET /matches/*/voice-introductions', {
    'introductions': intros ?? [_intro()],
  });

const _direct = VoiceIcebreakersScreen(
  matchId: 'match-1',
  receiverUserId: 'maya',
  partnerName: 'Maya',
);

late _Device _device;

Future<void> _open(
  WidgetTester tester,
  QaApi api, {
  Widget screen = _direct,
  Locale? locale,
}) => pumpQa(
  tester,
  api,
  screen,
  locale: locale,
  flags: const {'voice_icebreakers_enabled': true},
  extra: _device.overrides,
);

String _recordLabel(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(of: find.byKey(_record), matching: find.byType(Text)),
    )
    .data!;

Future<void> _tap(WidgetTester tester, Key key) async {
  await qaScrollTo(tester, find.byKey(key));
  await tester.tap(find.byKey(key));
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }
}

/// Records a clip of [seconds] (the screen's one-second ticker).
Future<void> _recordClip(WidgetTester tester, int seconds) async {
  await _tap(tester, _record);
  expect(_recordLabel(tester), en.engagementVoiceStop(0));
  for (var i = 0; i < seconds; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  if (seconds < 45) await _tap(tester, _record);
}

/// Lets the real file read of the clip and the requests finish: waits (in
/// real time, for the file read) until Share no longer says Sending.
Future<void> _settleUpload(WidgetTester tester) async {
  for (var i = 0; i < 100; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await qaSettle(tester, frames: 2);
    if (find.text(en.engagementVoiceSending).evaluate().isEmpty) break;
  }
  expect(find.text(en.engagementVoiceSending), findsNothing);
  await qaSettle(tester, frames: 3);
}

Future<void> _type(WidgetTester tester, String text) async {
  await qaScrollTo(tester, find.byKey(_transcript));
  await tester.enterText(find.byKey(_transcript), text);
  await tester.pump();
}

/// Wraps a widget test body so it always unmounts the screen and lets the
/// recorder and player finish disposing: the record plugin serialises every
/// call behind one global lock, so a dispose left pending would stall the
/// next test.
WidgetTesterCallback _voice(WidgetTesterCallback body) => (tester) async {
  await body(tester);
  await qaUnmount(tester);
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('voice_qa');
    _device = _Device(dir)..install();
  });
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  group('recording', () {
    testWidgets(
      'Record starts the microphone, counts seconds, and Stop keeps a clip ready to share [case:engagement.voice_icebreakers.voice_recording_button.action]',
      _voice((tester) async {
        final api = _api();
        await _open(tester, api);
        expect(_recordLabel(tester), en.engagementVoiceRecord);

        await _tap(tester, _record);
        expect(
          _device.recorder,
          containsAllInOrder(['hasPermission', 'start']),
        );
        expect(_device.clipPath, startsWith(dir.path));
        expect(_device.clipPath, endsWith('.m4a'));
        expect(_recordLabel(tester), en.engagementVoiceStop(0));
        for (var i = 0; i < 25; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
        expect(_recordLabel(tester), en.engagementVoiceStop(25));
        expect(
          tester.widget<TextField>(find.byKey(_transcript)).enabled,
          isFalse,
          reason: 'the transcript is locked while recording',
        );

        await _tap(tester, _record);
        expect(_device.recorder, contains('stop'));
        expect(_recordLabel(tester), en.engagementVoiceRecordAgain(25));
        expect(find.text(en.engagementVoiceRecordingReady), findsOneWidget);
        expect(
          qaEnabled(tester, find.byKey(_share)),
          isFalse,
          reason: 'no transcript yet',
        );
        expect(api.writes, isEmpty);
      }),
    );

    testWidgets(
      'recording stops by itself at 45 seconds [case:engagement.voice_icebreakers.voice_recording_button.action]',
      _voice((tester) async {
        await _open(tester, _api());
        await _recordClip(tester, 45);
        await tester.pump();
        expect(_device.recorder.where((m) => m == 'stop'), hasLength(1));
        expect(_recordLabel(tester), en.engagementVoiceRecordAgain(45));
        await tester.pump(const Duration(seconds: 5));
        expect(_recordLabel(tester), en.engagementVoiceRecordAgain(45));
      }),
    );

    testWidgets(
      'a clip under 20 seconds asks for a longer one and cannot be shared [case:engagement.voice_icebreakers.voice_recording_button.action]',
      _voice((tester) async {
        await _open(tester, _api());
        await _type(tester, 'Hello there');
        await _recordClip(tester, 8);
        expect(find.text(en.engagementVoiceRecordingShort), findsOneWidget);
        expect(qaEnabled(tester, find.byKey(_share)), isFalse);
      }),
    );

    testWidgets(
      'Record again drops the kept clip, records a new one and the new one is what is shared [case:engagement.voice_icebreakers.voice_recording_button.action]',
      _voice((tester) async {
        final api = _api()
          ..json('POST /engagement/voice-icebreakers/start', {
            'voice_icebreaker': {'id': 'vi-9'},
          })
          ..json('POST /engagement/voice-icebreakers/vi-9/send', {
            'voice_icebreaker': _intro(id: 'vi-9', sender: 'me'),
          });
        await _open(tester, api);
        await _type(tester, 'Hello there');
        await _recordClip(tester, 25);
        expect(_recordLabel(tester), en.engagementVoiceRecordAgain(25));
        expect(find.byKey(_discard), findsOneWidget);
        expect(qaEnabled(tester, find.byKey(_share)), isTrue);
        expect(_device.recorder.where((m) => m == 'start'), hasLength(1));

        // Record again: the 25 s clip is gone and the microphone runs again.
        await _tap(tester, _record);
        expect(_device.recorder.where((m) => m == 'start'), hasLength(2));
        expect(_recordLabel(tester), en.engagementVoiceStop(0));
        expect(find.byKey(_discard), findsNothing);
        expect(find.text(en.engagementVoiceRecordingReady), findsNothing);
        expect(qaEnabled(tester, find.byKey(_share)), isFalse);
        expect(qaFieldText(tester, find.byKey(_transcript)), 'Hello there');

        for (var i = 0; i < 31; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
        await _tap(tester, _record);
        expect(_device.recorder.where((m) => m == 'stop'), hasLength(2));
        expect(_recordLabel(tester), en.engagementVoiceRecordAgain(31));
        expect(api.writes, isEmpty);

        await _tap(tester, _share);
        await _settleUpload(tester);
        final form =
            api
                    .sent('POST', '/engagement/voice-icebreakers/vi-9/send')
                    .single
                    .data!
                as FormData;
        expect(Map.fromEntries(form.fields)['duration_seconds'], '31');
      }),
    );

    for (final (label, setUpDevice, message) in [
      (
        'microphone permission refused',
        (_Device d) => d.micAllowed = false,
        'Allow microphone access to record. You can still read transcripts without it.',
      ),
      (
        'the recorder cannot start',
        (_Device d) => d.startFails = true,
        'Unable to start recording. Check microphone access and try again.',
      ),
    ]) {
      testWidgets(
        'Record with $label explains it and nothing is recorded',
        _voice((tester) async {
          setUpDevice(_device);
          await _open(tester, _api());
          await _tap(tester, _record);
          expect(find.text(message), findsOneWidget);
          expect(_recordLabel(tester), en.engagementVoiceRecord);
          expect(find.byKey(_discard), findsNothing);
          expect(qaEnabled(tester, find.byKey(_share)), isFalse);
          expect(_device.recorder, isNot(contains('stop')));
        }),
      );
    }

    testWidgets(
      'a recorder that loses the clip on Stop says so and leaves nothing to share',
      _voice((tester) async {
        _device.stopLosesClip = true;
        await _open(tester, _api());
        await _type(tester, 'Hello there');
        await _recordClip(tester, 25);
        expect(find.text(en.engagementVoiceSaveFailed), findsOneWidget);
        expect(_recordLabel(tester), en.engagementVoiceRecord);
        expect(qaEnabled(tester, find.byKey(_share)), isFalse);
      }),
    );

    testWidgets(
      'Discard recording drops the clip so a new one can be recorded [case:engagement.voice_icebreakers.voice_discard.action]',
      _voice((tester) async {
        final api = _api();
        await _open(tester, api);
        await _type(tester, 'Hello there');
        await _recordClip(tester, 25);
        expect(qaEnabled(tester, find.byKey(_share)), isTrue);

        await _tap(tester, _discard);

        expect(find.byKey(_discard), findsNothing);
        expect(find.text(en.engagementVoiceRecordingReady), findsNothing);
        expect(_recordLabel(tester), en.engagementVoiceRecord);
        expect(qaEnabled(tester, find.byKey(_share)), isFalse);
        expect(qaFieldText(tester, find.byKey(_transcript)), 'Hello there');
        expect(api.writes, isEmpty);
      }),
    );
  });

  group('Share your hello', () {
    testWidgets(
      'Share your hello starts a session, uploads the clip with the transcript, confirms and resets [case:engagement.voice_icebreakers.voice_share.action]',
      _voice((tester) async {
        final api = _api()
          ..json('POST /engagement/voice-icebreakers/start', {
            'voice_icebreaker': {'id': 'vi-9', 'status': 'started'},
          })
          ..json('POST /engagement/voice-icebreakers/vi-9/send', {
            'voice_icebreaker': _intro(id: 'vi-9', sender: 'me'),
          });
        await _open(tester, api);
        final intros0 = api.sent('GET', '/matches/match-1/voice-introductions');
        await _type(tester, '  Hi Maya, Sundays are for long walks.  ');
        await _recordClip(tester, 25);
        expect(qaEnabled(tester, find.byKey(_share)), isTrue);

        await _tap(tester, _share);
        await _settleUpload(tester);

        final start = api.sent('POST', '/engagement/voice-icebreakers/start');
        expect(start, hasLength(1));
        expect(start.single.body, {
          'match_id': 'match-1',
          'sender_user_id': 'me',
          'receiver_user_id': 'maya',
          'prompt_id': 'p-1',
        });
        final send = api.sent(
          'POST',
          '/engagement/voice-icebreakers/vi-9/send',
        );
        expect(send, hasLength(1));
        final form = send.single.data! as FormData;
        expect(Map.fromEntries(form.fields), {
          'sender_user_id': 'me',
          'duration_seconds': '25',
          'transcript': 'Hi Maya, Sundays are for long walks.',
        });
        expect(form.files.single.key, 'audio');
        expect(form.files.single.value.length, 64);
        expect(
          form.files.single.value.filename,
          matches(RegExp(r'^connect-voice-\d+\.m4a$')),
        );
        expect(qaSnackText(tester), en.engagementVoiceSubmitted);
        expect(qaFieldText(tester, find.byKey(_transcript)), isEmpty);
        expect(_recordLabel(tester), en.engagementVoiceRecord);
        expect(qaEnabled(tester, find.byKey(_share)), isFalse);
        expect(
          api.sent('GET', '/matches/match-1/voice-introductions'),
          hasLength(intros0.length + 1),
        );
      }),
    );

    for (final (label, route, failure, message) in [
      (
        'the daily limit refuses the session',
        'POST /engagement/voice-icebreakers/start',
        qaError(429, message: 'One voice hello per match each day.'),
        'One voice hello per match each day.',
      ),
      (
        'the upload fails',
        'POST /engagement/voice-icebreakers/vi-9/send',
        qaError(500, message: 'Upload store unavailable.'),
        'Upload store unavailable.',
      ),
      (
        'the device is offline',
        'POST /engagement/voice-icebreakers/start',
        qaOffline,
        en.networkOfflineTryAgain,
      ),
      (
        'the session reply has no id',
        'POST /engagement/voice-icebreakers/start',
        qaOk({'voice_icebreaker': <String, dynamic>{}}),
        'Unable to create voice icebreaker session.',
      ),
    ]) {
      testWidgets(
        'when $label the hello is kept (clip and transcript), the reason shows and Share works again [case:engagement.voice_icebreakers.voice_share.api_failure]',
        _voice((tester) async {
          final api = _api()
            ..json('POST /engagement/voice-icebreakers/start', {
              'voice_icebreaker': {'id': 'vi-9'},
            })
            ..json('POST /engagement/voice-icebreakers/vi-9/send', {
              'voice_icebreaker': _intro(id: 'vi-9', sender: 'me'),
            })
            ..on(route, (_) => failure);
          await _open(tester, api);
          await _type(tester, 'Hi Maya');
          await _recordClip(tester, 25);
          await _tap(tester, _share);
          await _settleUpload(tester);

          expect(find.text(message), findsOneWidget);
          expect(qaSnackText(tester), isNull);
          expect(qaFieldText(tester, find.byKey(_transcript)), 'Hi Maya');
          expect(_recordLabel(tester), en.engagementVoiceRecordAgain(25));
          expect(qaEnabled(tester, find.byKey(_share)), isTrue);
          expect(
            api.sent('POST', '/engagement/voice-icebreakers/start'),
            hasLength(1),
          );

          api
            ..json('POST /engagement/voice-icebreakers/start', {
              'voice_icebreaker': {'id': 'vi-9'},
            })
            ..json('POST /engagement/voice-icebreakers/vi-9/send', {
              'voice_icebreaker': _intro(id: 'vi-9', sender: 'me'),
            });
          await _tap(tester, _share);
          await _settleUpload(tester);
          expect(find.text(message), findsNothing);
          expect(qaSnackText(tester), en.engagementVoiceSubmitted);
          expect(
            api
                .sent('POST', '/engagement/voice-icebreakers/vi-9/send')
                .last
                .data,
            isA<FormData>(),
          );
        }),
      );
    }
  });

  group('transcript', () {
    testWidgets(
      'typing the transcript is what enables Share once a clip is ready [case:engagement.voice_icebreakers.voice_transcript.action]',
      _voice((tester) async {
        final api = _api();
        await _open(tester, api);
        expect(find.text(en.engagementVoiceTranscriptLabel), findsOneWidget);
        await _recordClip(tester, 25);
        expect(qaEnabled(tester, find.byKey(_share)), isFalse);

        await _type(tester, 'Hello from the park');
        expect(
          qaFieldText(tester, find.byKey(_transcript)),
          'Hello from the park',
        );
        expect(find.text('19/2000'), findsOneWidget);
        expect(qaEnabled(tester, find.byKey(_share)), isTrue);
        expect(api.writes, isEmpty);
      }),
    );

    testWidgets(
      'whitespace-only keeps Share off, 2001 characters are capped at 2000, emoji/RTL is uploaded byte-for-byte [case:engagement.voice_icebreakers.voice_transcript.validation]',
      _voice((tester) async {
        const unicode = 'مرحبا مايا 👋🏾 שלום';
        final api = _api()
          ..json('POST /engagement/voice-icebreakers/start', {
            'voice_icebreaker': {'id': 'vi-9'},
          })
          ..json('POST /engagement/voice-icebreakers/vi-9/send', {
            'voice_icebreaker': _intro(id: 'vi-9', sender: 'me'),
          });
        await _open(tester, api);
        await _recordClip(tester, 25);

        await _type(tester, '   \n  ');
        expect(qaEnabled(tester, find.byKey(_share)), isFalse);
        await tester.tap(find.byKey(_share), warnIfMissed: false);
        await tester.pump();
        expect(api.writes, isEmpty);

        await _type(tester, 'y' * 2001);
        expect(qaFieldText(tester, find.byKey(_transcript)), 'y' * 2000);

        await _type(tester, ' $unicode ');
        await _tap(tester, _share);
        await _settleUpload(tester);
        final form =
            api
                    .sent('POST', '/engagement/voice-icebreakers/vi-9/send')
                    .single
                    .data!
                as FormData;
        final sent = Map.fromEntries(form.fields)['transcript']!;
        expect(sent.codeUnits, unicode.codeUnits);
      }),
    );
  });

  group('choosing who and what', () {
    testWidgets(
      'picking a conversation opens its card, loads its introductions and sends to that match [case:engagement.voice_icebreakers.voice_conversation.action]',
      _voice((tester) async {
        final api = _api()
          ..json('POST /engagement/voice-icebreakers/start', {
            'voice_icebreaker': {'id': 'vi-9'},
          })
          ..json('POST /engagement/voice-icebreakers/vi-9/send', {
            'voice_icebreaker': _intro(id: 'vi-9', sender: 'me'),
          });
        await _open(tester, api, screen: const VoiceIcebreakersScreen());
        expect(find.text(en.engagementVoicePickConversation), findsOneWidget);
        expect(find.byKey(_record), findsNothing);

        await tester.tap(find.byKey(const ValueKey('qa.voice.conversation')));
        await qaSettle(tester);
        await tester.tap(find.text('Theo').last);
        await qaSettle(tester);

        expect(find.byKey(_record), findsOneWidget);
        expect(
          api.sent('GET', '/matches/match-2/voice-introductions'),
          hasLength(1),
        );
        await _type(tester, 'Hi Theo');
        await _recordClip(tester, 22);
        await _tap(tester, _share);
        await _settleUpload(tester);
        expect(
          api.sent('POST', '/engagement/voice-icebreakers/start').single.body,
          {
            'match_id': 'match-2',
            'sender_user_id': 'me',
            'receiver_user_id': 'theo',
            'prompt_id': 'p-1',
          },
        );
      }),
    );

    testWidgets(
      'Choose a prompt changes the prompt the hello is sent with [case:engagement.voice_icebreakers.voice_prompt.action]',
      _voice((tester) async {
        final api = _api()
          ..json('POST /engagement/voice-icebreakers/start', {
            'voice_icebreaker': {'id': 'vi-9'},
          })
          ..json('POST /engagement/voice-icebreakers/vi-9/send', {
            'voice_icebreaker': _intro(id: 'vi-9', sender: 'me'),
          });
        await _open(tester, api);
        expect(find.text(en.engagementVoiceChoosePrompt), findsOneWidget);
        await tester.tap(find.byKey(_prompt));
        await qaSettle(tester);
        await tester.tap(find.text('A small ritual you never skip').last);
        await qaSettle(tester);
        expect(
          find.descendant(
            of: find.byKey(_prompt),
            matching: find.text('A small ritual you never skip'),
          ),
          findsOneWidget,
        );

        await _type(tester, 'Coffee at seven');
        await _recordClip(tester, 30);
        await _tap(tester, _share);
        await _settleUpload(tester);
        expect(
          api
              .sent('POST', '/engagement/voice-icebreakers/start')
              .single
              .body['prompt_id'],
          'p-2',
        );
      }),
    );

    testWidgets(
      'Try again after the conversations failed to load reloads them and shows the picker [case:engagement.voice_icebreakers.voice_retry_conversations.action]',
      _voice((tester) async {
        final api = _api()
          ..fail('GET /matches/me', message: 'Matches are down.');
        await _open(tester, api, screen: const VoiceIcebreakersScreen());
        expect(
          find.text(en.engagementVoiceConversationsLoadFailed),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('qa.voice.conversation')),
          findsNothing,
        );

        api.json('GET /matches/me', {
          'matches': [
            {'id': 'match-1', 'user_id': 'maya', 'user_name': 'Maya'},
          ],
        });
        await _tap(tester, const ValueKey('qa.voice.retry_conversations'));
        await qaSettle(tester);

        expect(api.sent('GET', '/matches/me'), hasLength(2));
        expect(
          find.text(en.engagementVoiceConversationsLoadFailed),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('qa.voice.conversation')),
          findsOneWidget,
        );
      }),
    );
  });

  group('introductions', () {
    testWidgets(
      'Try again after the introductions failed to load fetches them again and shows them [case:engagement.voice_icebreakers.voice_retry_intros.action]',
      _voice((tester) async {
        final api = _api()
          ..fail('GET /matches/*/voice-introductions', status: 403);
        await _open(tester, api);
        await qaScrollTo(tester, find.text(en.engagementVoiceIntrosLoadFailed));
        expect(find.text(en.engagementVoiceIntrosLoadFailed), findsOneWidget);

        api.json('GET /matches/*/voice-introductions', {
          'introductions': [_intro()],
        });
        await _tap(tester, const ValueKey('qa.voice.retry_intros'));
        await qaSettle(tester);

        expect(
          api.sent('GET', '/matches/match-1/voice-introductions'),
          hasLength(2),
        );
        expect(find.text(en.engagementVoiceIntrosLoadFailed), findsNothing);
        await qaScrollTo(
          tester,
          find.text('I like a book and a quiet coffee.'),
        );
        expect(
          find.text(en.engagementVoiceHelloFromName('Maya')),
          findsOneWidget,
        );
      }),
    );

    testWidgets(
      'a received transcript is shown as selectable text that can be copied, never edited [case:engagement.voice_icebreakers.selectabletext_input_input.action]',
      _voice((tester) async {
        final api = _api();
        await _open(tester, api);
        final transcript = find.widgetWithText(
          SelectableText,
          'I like a book and a quiet coffee.',
        );
        await qaScrollTo(tester, transcript);
        expect(transcript, findsOneWidget);
        expect(
          find.ancestor(of: transcript, matching: find.byType(TextField)),
          findsNothing,
        );

        await tester.longPress(transcript);
        await qaSettle(tester);
        expect(find.text('Copy'), findsOneWidget);
        expect(api.writes, isEmpty);
      }),
    );

    testWidgets(
      'emoji and right-to-left transcripts are shown exactly as sent [case:engagement.voice_icebreakers.selectabletext_input_input.validation]',
      _voice((tester) async {
        const unicode = 'שלום! 🌻 أحب القهوة\nsecond line';
        await _open(tester, _api(intros: [_intro(transcript: unicode)]));
        final transcript = find.byType(SelectableText);
        await qaScrollTo(tester, transcript);
        expect(
          tester.widget<SelectableText>(transcript).data!.codeUnits,
          unicode.codeUnits,
        );
        expect(tester.takeException(), isNull);
      }),
    );

    testWidgets(
      'Listen marks the play, loads the signed URL into the player and offers Stop playback until it ends [case:engagement.voice_icebreakers.voice_listen_x.action]',
      _voice((tester) async {
        final api = _api()
          ..json('POST /engagement/voice-icebreakers/v-1/play', {
            'voice_icebreaker': {
              ..._intro(),
              'play_count': 1,
              'audio_url': _audioUrl,
            },
          });
        await _open(tester, api);
        await qaScrollTo(tester, find.byKey(_listen));
        expect(find.text(en.engagementVoiceListen(24)), findsOneWidget);

        await _tap(tester, _listen);
        await qaSettle(tester);

        expect(
          api
              .sent('POST', '/engagement/voice-icebreakers/v-1/play')
              .single
              .body,
          {'user_id': 'me'},
        );
        expect(_device.player, ['setUrl $_audioUrl', 'play']);
        expect(_device.isPlaying, isTrue);
        expect(find.text(en.engagementVoiceStopPlayback), findsOneWidget);
        expect(
          qaEnabled(tester, find.byKey(_record)),
          isFalse,
          reason: 'no recording while listening',
        );

        await _tap(tester, _listen);
        await qaSettle(tester);
        expect(_device.isPlaying, isFalse);
        expect(find.text(en.engagementVoiceListen(24)), findsOneWidget);
        expect(qaEnabled(tester, find.byKey(_listen)), isTrue);
        await qaUnmount(tester);
      }),
    );

    for (final (label, failure, message) in [
      (
        'the server refuses the play',
        qaError(403, message: 'Recording is not available.'),
        'Recording is not available.',
      ),
      (
        'the reply has no playback URL',
        qaOk({'voice_icebreaker': _intro()}),
        'Unable to play this recording right now.',
      ),
      ('offline', qaOffline, en.networkOfflineTryAgain),
    ]) {
      testWidgets(
        'Listen when $label explains it, plays nothing and can be tried again [case:engagement.voice_icebreakers.voice_listen_x.api_failure]',
        _voice((tester) async {
          final api = _api()
            ..on('POST /engagement/voice-icebreakers/v-1/play', (_) => failure);
          await _open(tester, api);
          await _tap(tester, _listen);
          await qaSettle(tester);

          expect(find.text(message), findsOneWidget);
          expect(_device.player, isEmpty);
          expect(find.text(en.engagementVoiceListen(24)), findsOneWidget);
          expect(qaEnabled(tester, find.byKey(_listen)), isTrue);
          expect(
            api.sent('POST', '/engagement/voice-icebreakers/v-1/play'),
            hasLength(1),
          );
          await _tap(tester, _listen);
          await qaSettle(tester);
          expect(
            api.sent('POST', '/engagement/voice-icebreakers/v-1/play'),
            hasLength(2),
          );
          await qaUnmount(tester);
        }),
      );
    }
  });

  group('prompts', () {
    testWidgets(
      'Reload prompts after a failed load fetches them and fills the prompt picker [case:engagement.voice_icebreakers.voice_reload_prompts.action]',
      _voice((tester) async {
        final api = _api()
          ..offline('GET /engagement/voice-icebreakers/prompts');
        await _open(tester, api);
        await qaScrollTo(
          tester,
          find.byKey(const ValueKey('qa.voice.reload_prompts')),
        );
        // Offline reads as the shared can't-connect message.
        expect(find.text(en.networkOfflineTryAgain), findsOneWidget);

        api.json('GET /engagement/voice-icebreakers/prompts', {
          'prompts': [
            {'id': 'p-1', 'prompt_text': 'A Sunday you love'},
          ],
        });
        await _tap(tester, const ValueKey('qa.voice.reload_prompts'));
        await qaSettle(tester);

        expect(
          api.sent('GET', '/engagement/voice-icebreakers/prompts'),
          hasLength(2),
        );
        expect(find.text(en.networkOfflineTryAgain), findsNothing);
        expect(
          find.byKey(const ValueKey('qa.voice.reload_prompts')),
          findsNothing,
        );
        await qaScrollTo(tester, find.byKey(_prompt));
        expect(
          find.descendant(
            of: find.byKey(_prompt),
            matching: find.text('A Sunday you love'),
          ),
          findsOneWidget,
        );
      }),
    );

    testWidgets(
      'a Reload that fails again keeps the reason and the button [case:engagement.voice_icebreakers.voice_reload_prompts.api_failure]',
      _voice((tester) async {
        final api = _api()
          ..offline('GET /engagement/voice-icebreakers/prompts');
        await _open(tester, api);
        api.fail(
          'GET /engagement/voice-icebreakers/prompts',
          message: 'Prompts are being refreshed.',
        );
        await _tap(tester, const ValueKey('qa.voice.reload_prompts'));
        await qaSettle(tester);
        // The reason and Reload sit at the end of the list, below the
        // introductions, so bring them into view first.
        await qaScrollTo(tester, find.text('Prompts are being refreshed.'));

        expect(find.text('Prompts are being refreshed.'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('qa.voice.reload_prompts')),
          findsOneWidget,
        );
        expect(
          api.sent('GET', '/engagement/voice-icebreakers/prompts'),
          hasLength(2),
        );
        expect(qaEnabled(tester, find.byKey(_share)), isFalse);
        expect(tester.takeException(), isNull);
      }),
    );
  });

  group('screen checks', () {
    final prompt = find.descendant(
      of: find.byKey(_prompt),
      matching: find.text('A Sunday you love'),
    );
    final intro = find.text('I like a book and a quiet coffee.');
    final picker = find.byKey(const ValueKey('qa.voice.conversation'));
    VoiceIcebreakersScreen pickerScreen() => const VoiceIcebreakersScreen();
    VoiceIcebreakersScreen directScreen() => _direct;

    testWidgets(
      'VoiceIcebreakersScreen lays out on every device size in both themes, '
      'opened on a match and with the conversation picker '
      '[case:engagement.voice_icebreakers.layout_matrix]',
      _voice((tester) async {
        await qaExpectLaysOutEverywhere(
          tester,
          _api(),
          directScreen,
          loaded: intro,
          extra: _device.overrides,
        );
        await qaExpectLaysOutEverywhere(
          tester,
          _api(),
          pickerScreen,
          loaded: picker,
          extra: _device.overrides,
        );
      }),
    );

    testWidgets(
      'VoiceIcebreakersScreen meets the tap-target, label and contrast '
      'guidelines, including the introduction card and the picker '
      '[case:engagement.voice_icebreakers.a11y_guidelines]',
      _voice((tester) async {
        await qaExpectMeetsA11yGuidelines(
          tester,
          _api(),
          directScreen,
          loaded: prompt,
          extra: _device.overrides,
        );
        // A tall phone so the introduction card (transcript, Listen) is on
        // screen and judged too.
        await qaExpectMeetsA11yGuidelines(
          tester,
          _api(),
          directScreen,
          loaded: find.byKey(_listen),
          extra: _device.overrides,
          size: const Size(360, 1800),
        );
        await qaExpectMeetsA11yGuidelines(
          tester,
          _api(),
          pickerScreen,
          loaded: picker,
          extra: _device.overrides,
        );
      }),
    );

    testWidgets(
      'VoiceIcebreakersScreen pushed from another screen shows Back, which '
      'closes it [case:engagement.voice_icebreakers.back_affordance]',
      _voice((tester) async {
        await qaExpectBackReturns(
          tester,
          _api(),
          directScreen,
          screen: VoiceIcebreakersScreen,
          extra: _device.overrides,
        );
      }),
    );

    // Fixture data from the fake server (member names, prompt and transcript
    // text, the server's own error message) is the same in every locale.
    const fixture = {
      'Maya',
      'Theo',
      'A Sunday you love',
      'A small ritual you never skip',
      'I like a book and a quiet coffee.',
      'Prompts are down.',
    };

    testWidgets(
      'VoiceIcebreakersScreen renders translated in all 10 locales with no '
      'English left: a kept clip, the picker and the load failures '
      '[case:engagement.voice_icebreakers.l10n]',
      _voice((tester) async {
        // Opened on a match, with a 25 s clip recorded and kept.
        await qaExpectRendersInAllLocales(
          tester,
          _api(),
          directScreen,
          extra: _device.overrides,
          size: const Size(430, 2200),
          prepare: (tester, l) async {
            await _tap(tester, _record);
            expect(_recordLabel(tester), l.engagementVoiceStop(0));
            for (var i = 0; i < 25; i++) {
              await tester.pump(const Duration(seconds: 1));
            }
            await _tap(tester, _record);
          },
          allow: fixture,
          expected: [
            (l) => l.engagementVoiceAppBarTitle,
            (l) => l.engagementVoiceHeadline,
            (l) => l.engagementVoiceIntro,
            (l) => l.engagementVoiceYouAndName('Maya'),
            (l) => l.engagementVoicePrivate,
            (l) => l.engagementVoiceStartingPoint,
            (l) => l.engagementVoiceChoosePrompt,
            (l) => l.engagementVoiceTranscriptLabel,
            (l) => l.engagementVoiceTranscriptHelper,
            (l) => l.engagementVoiceRecordAgain(25),
            (l) => l.engagementVoiceRecordingReady,
            (l) => l.engagementVoiceDiscard,
            (l) => l.engagementVoiceShare,
            (l) => l.engagementVoiceCheckedNote,
            (l) => l.engagementVoiceYourIntros,
            (l) => l.engagementVoiceLatestNote,
            (l) => l.engagementVoiceTranscriptHeading,
            (l) => l.engagementVoiceHelloFromName('Maya'),
            (l) => l.engagementVoiceListen(24),
          ],
        );
        // No match yet: the conversation picker.
        await qaExpectRendersInAllLocales(
          tester,
          _api(),
          pickerScreen,
          extra: _device.overrides,
          allow: fixture,
          expected: [
            (l) => l.engagementVoiceHeadline,
            (l) => l.engagementVoicePickConversation,
          ],
        );
        // The conversations failed to load.
        await qaExpectRendersInAllLocales(
          tester,
          _api()..fail('GET /matches/me', message: 'Matches are down.'),
          pickerScreen,
          extra: _device.overrides,
          allow: fixture,
          expected: [
            (l) => l.engagementVoiceConversationsLoadFailed,
            (l) => l.chatTryAgain,
          ],
        );
        // The prompts and the introductions failed to load.
        await qaExpectRendersInAllLocales(
          tester,
          _api()
            ..fail(
              'GET /engagement/voice-icebreakers/prompts',
              message: 'Prompts are down.',
            )
            ..fail('GET /matches/*/voice-introductions', status: 403),
          directScreen,
          extra: _device.overrides,
          size: const Size(430, 2200),
          allow: fixture,
          expected: [
            (l) => l.engagementVoiceIntrosLoadFailed,
            (l) => l.chatTryAgain,
            (l) => l.engagementVoiceReloadPrompts,
            (l) => l.engagementVoiceRecord,
          ],
        );
      }),
    );
  });
}
