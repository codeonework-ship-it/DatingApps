import 'dart:async';

import 'package:flutter/material.dart' hide Title;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../../l10n/app_localizations.dart';
import 'club_widgets.dart';
import 'clubs_data.dart';

/// Finds a book or film in the shared catalogue, or adds a new one.
///
/// Adding a title that already exists returns the catalogue's copy, which may
/// carry a different ID from the one the client generated.
///
/// [heading] defaults to "Choose a title".
Future<Title?> pickTitle(
  BuildContext context, {
  required String kind,
  String? heading,
}) => showClubSheet<Title>(context, _TitlePicker(kind: kind, heading: heading));

class _TitlePicker extends ConsumerStatefulWidget {
  const _TitlePicker({required this.kind, this.heading});
  final String kind;
  final String? heading;

  @override
  ConsumerState<_TitlePicker> createState() => _TitlePickerState();
}

class _TitlePickerState extends ConsumerState<_TitlePicker> {
  final search = TextEditingController();
  final name = TextEditingController();
  final creator = TextEditingController();
  final year = TextEditingController();
  late final String newId = const Uuid().v4();
  Timer? debounce;
  String query = '';
  bool adding = false, busy = false;
  String? error;

  @override
  void dispose() {
    debounce?.cancel();
    search.dispose();
    name.dispose();
    creator.dispose();
    year.dispose();
    super.dispose();
  }

  void onSearch(String value) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() => query = value.trim());
      }
    });
  }

  Future<void> add() async {
    final title = name.text.trim();
    final released = int.tryParse(year.text.trim());
    final l10n = AppLocalizations.of(context);
    if (title.isEmpty) {
      setState(() => error = l10n.clubsEnterTitle);
      return;
    }
    if (year.text.trim().isNotEmpty &&
        (released == null || released < 1450 || released > 2100)) {
      setState(() => error = l10n.clubsYearRange);
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final response = await ref
          .read(apiClientProvider)
          .put<dynamic>(
            '/clubs/titles/$newId',
            data: {
              'kind': widget.kind,
              'title': title,
              'creator': creator.text.trim(),
              'release_year': released,
            },
          );
      final saved = Title.fromJson((response.data as Map)['title'] as Map);
      if (mounted) {
        Navigator.of(context).pop(saved);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(
          () => error = apiErrorMessage(e, fallback: l10n.clubsTitleAddFailed),
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final film = widget.kind == 'film';
    final l10n = AppLocalizations.of(context);
    final addNew = film ? l10n.clubsAddNewFilm : l10n.clubsAddNewBook;
    return SheetFrame(
      title: widget.heading ?? l10n.clubsChooseTitle,
      children: [
        TextField(
          controller: search,
          autofocus: true,
          onChanged: onSearch,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: film ? l10n.clubsSearchFilms : l10n.clubsSearchBooks,
            helperText: l10n.clubsTypeTwoLetters,
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 8),
        if (query.length >= 2)
          ref
              .watch(titleSearchProvider((kind: widget.kind, q: query)))
              .when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    apiErrorMessage(e, fallback: l10n.clubsSearchUnavailable),
                  ),
                ),
                data: (titles) => Column(
                  children: [
                    if (titles.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          film
                              ? l10n.clubsNoFilmsMatch
                              : l10n.clubsNoBooksMatch,
                        ),
                      ),
                    for (final title in titles)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: KindDisc(kind: title.kind, size: 40),
                        title: Text(title.title),
                        subtitle: title.byline.isEmpty
                            ? null
                            : Text(title.byline),
                        onTap: () => Navigator.of(context).pop(title),
                      ),
                  ],
                ),
              ),
        const SizedBox(height: 8),
        if (!adding)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() {
                adding = true;
                name.text = search.text.trim();
              }),
              icon: const Icon(Icons.add),
              label: Text(addNew),
            ),
          )
        else ...[
          Text(addNew, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: name,
            maxLength: 200,
            decoration: InputDecoration(labelText: l10n.clubsTitleFieldLabel),
          ),
          TextField(
            controller: creator,
            maxLength: 120,
            decoration: InputDecoration(
              labelText: film ? l10n.clubsDirector : l10n.clubsAuthor,
            ),
          ),
          TextField(
            controller: year,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: InputDecoration(labelText: l10n.clubsYearOptional),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          FilledButton(
            onPressed: busy ? null : add,
            child: Text(busy ? l10n.clubsAdding : l10n.clubsAddAndChoose),
          ),
        ],
      ],
    );
  }
}
