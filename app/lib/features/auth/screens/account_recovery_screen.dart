import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_client_provider.dart';
import '../../../l10n/app_localizations.dart';

/// "Can't sign in?" (PEN-06 / AUTH-009).
///
/// Two journeys, neither of which can revive a revoked session:
///  * With a recovery code: set a new password. The server consumes the code
///    and signs out every device, so the member signs in fresh.
///  * Without one: ask the safety team for help. The answer is identical
///    whether or not the username exists; an operator verifies identity and
///    issues a single-use code, which the member then uses in the first path.
class AccountRecoveryScreen extends ConsumerStatefulWidget {
  const AccountRecoveryScreen({super.key, this.initialUsername = ''});

  final String initialUsername;

  @override
  ConsumerState<AccountRecoveryScreen> createState() =>
      _AccountRecoveryScreenState();
}

enum _RecoveryPath { haveCode, lostCode }

class _AccountRecoveryScreenState extends ConsumerState<AccountRecoveryScreen> {
  late final TextEditingController _username = TextEditingController(
    text: widget.initialUsername,
  );
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _message = TextEditingController();
  _RecoveryPath _path = _RecoveryPath.haveCode;
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  String? _done;

  @override
  void dispose() {
    _username.dispose();
    _code.dispose();
    _password.dispose();
    _message.dispose();
    super.dispose();
  }

  static bool _strongPassword(String value) {
    final bytes = utf8.encode(value).length;
    return bytes >= 8 &&
        bytes <= 72 &&
        RegExp('[A-Za-z]').hasMatch(value) &&
        RegExp('[0-9]').hasMatch(value);
  }

  Future<void> _submit() async {
    final username = _username.text.trim().toLowerCase();
    final l10n = AppLocalizations.of(context);
    if (username.isEmpty) {
      setState(() => _error = l10n.authRecoveryEnterUsername);
      return;
    }
    if (_path == _RecoveryPath.haveCode) {
      if (_code.text.trim().isEmpty) {
        setState(() => _error = l10n.authRecoveryEnterCode);
        return;
      }
      if (!_strongPassword(_password.text)) {
        setState(() => _error = l10n.authRecoveryPasswordRule);
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final dio = ref.read(apiClientProvider);
    try {
      if (_path == _RecoveryPath.haveCode) {
        await dio.post<Map<String, dynamic>>(
          '/auth/password/recover',
          data: {
            'username': username,
            'recovery_code': _code.text.trim(),
            'new_password': _password.text,
          },
        );
        _done = l10n.authRecoveryResetDone;
      } else {
        final response = await dio.post<Map<String, dynamic>>(
          '/auth/recovery/assistance',
          data: {'username': username, 'message': _message.text.trim()},
        );
        _done =
            response.data?['message']?.toString() ??
            l10n.authRecoveryAssistanceDone;
      }
    } on DioException catch (error) {
      final data = error.response?.data;
      _error = _path == _RecoveryPath.haveCode
          ? (data is Map && data['error'] != null
                ? l10n.authRecoveryInvalidCode
                : l10n.authRecoveryOffline)
          : l10n.authRecoverySendFailed;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authCantSignIn)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (_done != null) ...[
                  Icon(
                    Icons.mark_email_read_outlined,
                    size: 40,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    label: 'qa.recovery.done',
                    child: Text(_done!, style: theme.textTheme.bodyLarge),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(l10n.authRecoveryBackToSignIn),
                  ),
                ] else ...[
                  SegmentedButton<_RecoveryPath>(
                    segments: [
                      ButtonSegment(
                        value: _RecoveryPath.haveCode,
                        label: Text(l10n.authRecoveryHaveCode),
                      ),
                      ButtonSegment(
                        value: _RecoveryPath.lostCode,
                        label: Text(l10n.authRecoveryLostCode),
                      ),
                    ],
                    selected: {_path},
                    showSelectedIcon: false,
                    onSelectionChanged: (value) => setState(() {
                      _path = value.first;
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _path == _RecoveryPath.haveCode
                        ? l10n.authRecoveryHaveCodeIntro
                        : l10n.authRecoveryLostCodeIntro,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    key: const ValueKey('qa.recovery.username'),
                    controller: _username,
                    autofillHints: const [AutofillHints.username],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.authRecoveryUsernameLabel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_path == _RecoveryPath.haveCode) ...[
                    TextField(
                      key: const ValueKey('qa.recovery.code'),
                      controller: _code,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.authRecoveryCodeLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('qa.recovery.new_password'),
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: l10n.authRecoveryNewPasswordLabel,
                        suffixIcon: IconButton(
                          tooltip: _obscure
                              ? l10n.authShowPassword
                              : l10n.authHidePassword,
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                  ] else
                    TextField(
                      key: const ValueKey('qa.recovery.message'),
                      controller: _message,
                      maxLength: 500,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: l10n.authRecoveryMessageLabel,
                        hintText: l10n.authRecoveryMessageHint,
                      ),
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const ValueKey('qa.recovery.submit'),
                    onPressed: _busy ? null : _submit,
                    child: Text(
                      _busy
                          ? l10n.authRecoverySending
                          : _path == _RecoveryPath.haveCode
                          ? l10n.authRecoveryResetPassword
                          : l10n.authRecoveryAskForHelp,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
