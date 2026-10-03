// Control-level tests for sign-up (dating and friend-only accounts). Each
// test fills the real form, asserts the exact requests the fake BFF received
// and what the member sees. Each test name carries its catalog case ids.
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verified_dating_app/core/auth/auth_session_store.dart';
import 'package:verified_dating_app/core/widgets/glass_widgets.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/auth/screens/auth_screen.dart';
import 'package:verified_dating_app/features/auth/screens/signup_screen.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_quality.dart';

final _en = qaL10n(const Locale('en'));

Override get _signedOut => authNotifierProvider.overrideWith(AuthNotifier.new);

QaReply _slow(QaReply reply) => QaReply(
  reply.status,
  reply.body,
  offline: reply.offline,
  delay: const Duration(milliseconds: 400),
);

Map<String, dynamic> _session(String userId, {String? kind}) => {
  'success': true,
  'user_id': userId,
  'access_token': 'access-$userId',
  'refresh_token': 'refresh-$userId',
  'account_kind': ?kind,
};

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Navigator).first));

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _type(WidgetTester tester, String key, String text) async {
  await tester.ensureVisible(_key(key));
  await tester.enterText(_key(key), text);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.pump();
  await tester.tap(_key(key));
  await qaSettle(tester);
}

bool _obscured(WidgetTester tester, String fieldKey) => tester
    .widget<EditableText>(
      find.descendant(of: _key(fieldKey), matching: find.byType(EditableText)),
    )
    .obscureText;

bool _focused(WidgetTester tester, String fieldKey) =>
    tester.widget<TextField>(_key(fieldKey)).focusNode!.hasFocus;

/// Snack bars stay four seconds and sit over the bottom of the form; clear
/// the current one before the next check.
Future<void> _clearSnackBars(WidgetTester tester) async {
  ScaffoldMessenger.of(
    tester.element(find.byType(SignupScreen)),
  ).clearSnackBars();
  await qaSettle(tester);
}

/// The date picker opens on 1 January, 25 years ago; OK keeps it.
DateTime get _pickedDob => DateTime(DateTime.now().year - 25);

String get _pickedDobWire =>
    '${_pickedDob.year.toString().padLeft(4, '0')}-01-01';

Future<void> _pickDateOfBirth(WidgetTester tester) async {
  await _tap(tester, 'qa.signup.dob_field');
  final dialog = find.byType(DatePickerDialog);
  expect(dialog, findsOneWidget);
  await tester.tap(
    find.text(MaterialLocalizations.of(tester.element(dialog)).okButtonLabel),
  );
  await qaSettle(tester);
}

Future<void> _fillCredentials(
  WidgetTester tester, {
  String username = 'New.Member',
  String password = 'Passw0rd1',
  String? confirmation,
}) async {
  await _type(tester, 'qa.signup.username_field', username);
  await _type(tester, 'qa.signup.password_field', password);
  await _type(
    tester,
    'qa.signup.confirm_password_field',
    confirmation ?? password,
  );
}

Future<void> _fillAll(
  WidgetTester tester, {
  String password = 'Passw0rd1',
  bool gender = true,
}) async {
  await _fillCredentials(tester, password: password);
  await _type(tester, 'qa.signup.name_field', '  Zoë Ångström ');
  await _pickDateOfBirth(tester);
  if (gender) {
    await _tap(tester, 'qa.signup.gender.F');
  }
}

QaApi _signupApi() => QaApi()
  ..on('POST /auth/signup', (_) => qaOk(_session('new-1')))
  ..on('POST /auth/signup/bootstrap', (_) => qaOk({'success': true}));

Future<List<Object?>> _open(
  WidgetTester tester,
  QaApi api, {
  bool introducer = false,
}) => pumpQa(
  tester,
  api,
  SignupScreen(introducer: introducer),
  launcher: true,
  extra: [_signedOut],
);

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: '');
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    AuthSessionStore.instance.clear();
  });
  tearDown(AuthSessionStore.instance.clear);

  testWidgets(
    'Create account signs up, saves the profile basics and closes sign-up '
    '[case:auth.signup.signup_create_account_button.action] '
    '[case:auth.signup.signup_gender_x.action] '
    '[case:auth.signup.signup_dob_field.action] '
    '[case:auth.signup.select_date_of_birth.action]',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final api = _signupApi();
      final results = await _open(tester, api);
      await _fillCredentials(tester);
      await _type(tester, 'qa.signup.name_field', '  Zoë Ångström ');

      // Date of birth: the picker opens with the localized help text and
      // the chosen date shows in the field.
      expect(find.text(_en.signupDobPlaceholder), findsOneWidget);
      await _tap(tester, 'qa.signup.dob_field');
      final dialog = find.byType(DatePickerDialog);
      expect(
        tester.widget<DatePickerDialog>(dialog).helpText,
        _en.signupDobPickerHelp,
      );
      await tester.tap(
        find.text(
          MaterialLocalizations.of(tester.element(dialog)).okButtonLabel,
        ),
      );
      await qaSettle(tester);
      expect(find.byType(DatePickerDialog), findsNothing);
      // The member's own short date (en-US: M/d/y).
      expect(
        find.text(DateFormat.yMd('en').format(_pickedDob)),
        findsOneWidget,
      );
      expect(find.text(_en.signupDobPlaceholder), findsNothing);

      // Gender: one choice selected at a time.
      await _tap(tester, 'qa.signup.gender.M');
      await _tap(tester, 'qa.signup.gender.F');
      expect(
        tester.getSemantics(_key('qa.signup.gender.F')),
        isSemantics(isSelected: true, isButton: true),
      );
      expect(
        tester.getSemantics(_key('qa.signup.gender.M')),
        isNot(isSemantics(isSelected: true)),
      );

      await _tap(tester, 'qa.signup.create_account_button');

      expect(api.writeLines, [
        'POST /auth/signup',
        'POST /auth/signup/bootstrap',
      ]);
      expect(api.sent('POST', '/auth/signup').single.body, {
        'username': 'new.member',
        'password': 'Passw0rd1',
      });
      expect(api.sent('POST', '/auth/signup/bootstrap').single.body, {
        'user_id': 'new-1',
        'username': 'new.member',
        'name': 'Zoë Ångström',
        'date_of_birth': _pickedDobWire,
        'gender': 'F',
      });
      expect(results, [null], reason: 'sign-up closed back to the app gate');
      expect(find.byType(SignupScreen), findsNothing);
      final auth = _container(tester).read(authNotifierProvider);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.isNewAccount, isTrue);
      expect(auth.userId, 'new-1');
      expect(AuthSessionStore.instance.accessToken, 'access-new-1');
      semantics.dispose();
    },
  );

  testWidgets('A friend-only account signs up without a dating profile '
      '[case:auth.signup.signup_create_account_button.action]', (tester) async {
    final api = QaApi()
      ..on(
        'POST /auth/signup',
        (_) => qaOk(_session('friend-1', kind: 'introducer')),
      );
    await _open(tester, api, introducer: true);
    await _fillCredentials(tester, username: 'kind.friend');
    await _type(tester, 'qa.signup.name_field', 'Kai');
    await _pickDateOfBirth(tester);
    expect(_key('qa.signup.gender.F'), findsNothing);
    expect(
      tester.widget<GlassButton>(_key('qa.signup.create_account_button')).label,
      _en.signupCreateFriendAccount,
    );
    await _tap(tester, 'qa.signup.create_account_button');

    expect(api.writeLines, ['POST /auth/signup']);
    expect(api.writes.single.body, {
      'username': 'kind.friend',
      'password': 'Passw0rd1',
      'account_kind': 'introducer',
      'name': 'Kai',
      'date_of_birth': _pickedDobWire,
    });
    final auth = _container(tester).read(authNotifierProvider);
    expect(auth.isAuthenticated, isTrue);
    expect(auth.isIntroducer, isTrue);
    expect(find.byType(SignupScreen), findsNothing);
  });

  testWidgets('Back leaves sign-up [case:auth.signup.signup_back.action]', (
    tester,
  ) async {
    final api = _signupApi();
    final results = await _open(tester, api);
    await _type(tester, 'qa.signup.username_field', 'half.done');
    await _tap(tester, 'qa.signup.back');

    expect(results, [null]);
    expect(find.byType(SignupScreen), findsNothing);
    expect(api.calls, isEmpty);
  });

  testWidgets(
    'Sign in swaps sign-up for sign-in [case:auth.signup.signup_sign_in_link.action]',
    (tester) async {
      final api = _signupApi();
      await _open(tester, api);
      await _tap(tester, 'qa.signup.sign_in_link');

      expect(find.byType(SignupScreen), findsNothing);
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.text(_en.authHeadline), findsOneWidget);
      // Replaced, not stacked: back from sign-in returns to the launcher.
      await _tap(tester, 'qa.signin.back');
      expect(find.byKey(const ValueKey('qa.test.launcher')), findsOneWidget);
      expect(api.calls, isEmpty);
    },
  );

  testWidgets('Next walks through username, password, confirmation and name '
      '[case:auth.signup.your_username_onsubmitted.action] '
      '[case:auth.signup.at_least_8_characters_onsubmitted.action] '
      '[case:auth.signup.confirm_password_onsubmitted.action]', (
    tester,
  ) async {
    final api = _signupApi();
    await _open(tester, api);
    expect(_focused(tester, 'qa.signup.username_field'), isTrue);

    await _type(tester, 'qa.signup.username_field', 'new.member');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(_focused(tester, 'qa.signup.password_field'), isTrue);

    await _type(tester, 'qa.signup.password_field', 'Passw0rd1');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(_focused(tester, 'qa.signup.confirm_password_field'), isTrue);

    await _type(tester, 'qa.signup.confirm_password_field', 'Passw0rd1');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(_focused(tester, 'qa.signup.name_field'), isTrue);
    expect(api.calls, isEmpty);
  });

  testWidgets('Sign-up username must be 3–30 letters, numbers, _ or . '
      '[case:auth.signup.your_username_onsubmitted.validation]', (
    tester,
  ) async {
    final api = _signupApi();
    await _open(tester, api);
    for (final bad in ['a', 'zoë', '_lead', 'trail.', 'has space']) {
      await _fillCredentials(tester, username: bad);
      await _tap(tester, 'qa.signup.create_account_button');
      expect(qaSnackText(tester), _en.authErrorUsernameFormat, reason: bad);
      expect(_focused(tester, 'qa.signup.username_field'), isTrue);
      await _clearSnackBars(tester);
    }
    // A valid username passes this check; the next missing field is named.
    await _fillCredentials(tester, username: 'Zoe_99');
    await _tap(tester, 'qa.signup.create_account_button');
    expect(qaSnackText(tester), _en.signupErrorFullName);
    expect(api.calls, isEmpty);
  });

  testWidgets(
    'Sign-up password must be 8–72 bytes with a letter and a number; any '
    'script is kept '
    '[case:auth.signup.at_least_8_characters_onsubmitted.validation]',
    (tester) async {
      final api = _signupApi();
      await _open(tester, api);
      await _type(tester, 'qa.signup.name_field', 'Zoë Ångström');
      await _pickDateOfBirth(tester);
      await _tap(tester, 'qa.signup.gender.F');
      for (final weak in [
        'short1',
        'lettersonly',
        '12345678',
        '${'é' * 36}1',
      ]) {
        await _fillCredentials(tester, password: weak);
        await _tap(tester, 'qa.signup.create_account_button');
        expect(qaSnackText(tester), _en.authErrorPasswordFormat, reason: weak);
        expect(_focused(tester, 'qa.signup.password_field'), isTrue);
        await _clearSnackBars(tester);
      }
      expect(api.calls, isEmpty);

      const strong = 'Pässwörd 1';
      await _fillCredentials(tester, password: strong);
      await _tap(tester, 'qa.signup.create_account_button');
      expect(api.sent('POST', '/auth/signup').single.body['password'], strong);
    },
  );

  testWidgets('The confirmation must match the password '
      '[case:auth.signup.confirm_password_onsubmitted.validation]', (
    tester,
  ) async {
    final api = _signupApi();
    await _open(tester, api);
    await _fillCredentials(
      tester,
      password: 'Passw0rd1',
      confirmation: 'Passw0rd2',
    );
    await _tap(tester, 'qa.signup.create_account_button');

    expect(qaSnackText(tester), _en.signupErrorPasswordMismatch);
    expect(_focused(tester, 'qa.signup.confirm_password_field'), isTrue);
    expect(api.calls, isEmpty);
  });

  testWidgets('Password and confirmation each have their own show/hide '
      '[case:auth.signup.signup_password_visibility.action] '
      '[case:auth.signup.signup_confirm_password_visibility.action]', (
    tester,
  ) async {
    await _open(tester, _signupApi());
    await _fillCredentials(tester);
    expect(_obscured(tester, 'qa.signup.password_field'), isTrue);
    expect(_obscured(tester, 'qa.signup.confirm_password_field'), isTrue);

    await _tap(tester, 'qa.signup.password_visibility');
    expect(_obscured(tester, 'qa.signup.password_field'), isFalse);
    expect(_obscured(tester, 'qa.signup.confirm_password_field'), isTrue);
    expect(
      tester
          .widget<IconButton>(
            find.descendant(
              of: _key('qa.signup.password_visibility'),
              matching: find.byType(IconButton),
            ),
          )
          .tooltip,
      _en.authHidePassword,
    );

    await _tap(tester, 'qa.signup.confirm_password_visibility');
    expect(_obscured(tester, 'qa.signup.confirm_password_field'), isFalse);

    await _tap(tester, 'qa.signup.password_visibility');
    expect(_obscured(tester, 'qa.signup.password_field'), isTrue);
  });

  testWidgets('Name, date of birth and gender are required before sign-up '
      '[case:auth.signup.signup_create_account_button.validation]', (
    tester,
  ) async {
    final api = _signupApi();
    await _open(tester, api);
    await _fillCredentials(tester);

    await _type(tester, 'qa.signup.name_field', ' Z ');
    await _tap(tester, 'qa.signup.create_account_button');
    expect(qaSnackText(tester), _en.signupErrorFullName);
    expect(_focused(tester, 'qa.signup.name_field'), isTrue);
    await _clearSnackBars(tester);

    await _type(tester, 'qa.signup.name_field', 'Zoë');
    await _tap(tester, 'qa.signup.create_account_button');
    expect(qaSnackText(tester), _en.signupErrorDobMissing);
    await _clearSnackBars(tester);

    await _pickDateOfBirth(tester);
    await _tap(tester, 'qa.signup.create_account_button');
    expect(qaSnackText(tester), _en.signupErrorGenderMissing);
    expect(api.calls, isEmpty);
  });

  testWidgets('A refused sign-up shows the reason, re-enables and sends once '
      '[case:auth.signup.signup_create_account_button.api_failure]', (
    tester,
  ) async {
    final api = QaApi()
      ..on(
        'POST /auth/signup',
        (_) => _slow(
          qaError(409, message: 'username already exists', code: 'CONFLICT'),
        ),
      );
    final results = await _open(tester, api);
    await _fillAll(tester);
    final button = _key('qa.signup.create_account_button');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.widget<GlassButton>(button).isLoading, isTrue);
    expect(
      tester.widget<TextField>(_key('qa.signup.username_field')).enabled,
      isFalse,
    );
    await tester.tap(button, warnIfMissed: false); // impatient second tap
    await qaSettle(tester);

    expect(api.writeLines, ['POST /auth/signup']);
    // The server's reason maps to the member's message, never raw.
    expect(find.text(_en.authErrorUsernameTaken), findsOneWidget);
    expect(find.text('username already exists'), findsNothing);
    expect(tester.widget<GlassButton>(button).onPressed, isNotNull);
    expect(
      tester.widget<TextField>(_key('qa.signup.username_field')).enabled,
      isTrue,
    );
    expect(find.byType(SignupScreen), findsOneWidget);
    expect(results, isEmpty);
    expect(
      _container(tester).read(authNotifierProvider).isAuthenticated,
      isFalse,
    );

    api.offline('POST /auth/signup');
    await _tap(tester, 'qa.signup.create_account_button');
    // Offline says so (and replaces the earlier reason).
    expect(find.text(_en.authErrorNetwork), findsOneWidget);
    expect(find.text(_en.authErrorUsernameTaken), findsNothing);
    expect(api.writeLines, ['POST /auth/signup', 'POST /auth/signup']);
    expect(AuthSessionStore.instance.accessToken, isNull);
  });

  testWidgets(
    'A failed profile bootstrap after sign-up leaves the member signed out '
    'with the reason '
    '[case:auth.signup.signup_create_account_button.api_failure]',
    (tester) async {
      final api = _signupApi()..fail('POST /auth/signup/bootstrap');
      await _open(tester, api);
      await _fillAll(tester);
      await _tap(tester, 'qa.signup.create_account_button');

      expect(api.writeLines, [
        'POST /auth/signup',
        'POST /auth/signup/bootstrap',
      ]);
      expect(find.text(_en.authErrorCreateAccountFailed), findsOneWidget);
      expect(find.text('Something broke on our side.'), findsNothing);
      expect(find.byType(SignupScreen), findsOneWidget);
      expect(
        _container(tester).read(authNotifierProvider).isAuthenticated,
        isFalse,
      );
      expect(AuthSessionStore.instance.accessToken, isNull);
      expect(
        tester
            .widget<GlassButton>(_key('qa.signup.create_account_button'))
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('Sign-up renders in every language [case:auth.signup.l10n]', (
    tester,
  ) async {
    for (final locale in qaLocales) {
      final l10n = qaL10n(locale);
      await tester.pumpWidget(const SizedBox()); // fresh tree
      await pumpQa(
        tester,
        QaApi(),
        const SignupScreen(),
        locale: locale,
        extra: [_signedOut],
      );
      expect(find.text(l10n.signupTitle), findsOneWidget);
      expect(find.text(l10n.signupUsernameLabel), findsOneWidget);
      expect(find.text(l10n.signupDobPlaceholder), findsOneWidget);
      expect(
        tester
            .widget<GlassButton>(_key('qa.signup.create_account_button'))
            .label,
        l10n.welcomeCreateAccount,
      );
      expect(tester.takeException(), isNull, reason: '$locale');
    }
  });

  group('screen quality', () {
    testWidgets('Sign-up lays out on phone and tablet in both themes '
        '[case:auth.signup.layout_matrix]', (tester) async {
      await qaExpectLaysOutOnPhoneAndTablet(
        tester,
        api: QaApi.new,
        build: SignupScreen.new,
        extra: () => [_signedOut],
        loaded: () => _key('qa.signup.create_account_button'),
      );
      // The friend-only variant has a different form.
      await qaExpectLaysOutOnPhoneAndTablet(
        tester,
        api: QaApi.new,
        build: () => const SignupScreen(introducer: true),
        extra: () => [_signedOut],
        loaded: () => find.text(_en.signupCreateFriendAccount),
      );
    });

    testWidgets('Sign-up meets tap-target, label and contrast guidelines '
        '[case:auth.signup.a11y_guidelines]', (tester) async {
      await qaExpectMeetsA11yGuidelines(
        tester,
        api: QaApi.new,
        build: SignupScreen.new,
        extra: () => [_signedOut],
        loaded: () => _key('qa.signup.create_account_button'),
      );
    });

    testWidgets('Back on sign-up returns to the opener '
        '[case:auth.signup.back_affordance]', (tester) async {
      await qaExpectBackReturnsToOpener(
        tester,
        api: QaApi(),
        build: SignupScreen.new,
        extra: [_signedOut],
        screen: find.byType(SignupScreen),
        loaded: _key('qa.signup.create_account_button'),
      );
    });
  });
}
