// Chapter connections in German: server codes and the server's English
// sentinel title never reach the member as raw text.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/blog/blog_connections.dart';

import '../../support/qa_api.dart';

final de = qaL10n(const Locale('de'));

void main() {
  testWidgets('a shared link whose source changed reads in German and offers '
      'no approval [case:l10n.blog_connections.publication_unavailable]', (
    t,
  ) async {
    final api = QaApi()
      ..json('GET /blog/publications', {
        'publications': [
          {
            'id': 'pub1',
            'title': 'Sharing unavailable',
            'excerpt':
                'The source changed or access was withdrawn. Revoke this link.',
            'published': false,
            'joint': true,
            'my_approval': false,
            'moderation_state': 'active',
            'version': 2,
          },
        ],
        'next_cursor': '',
      });
    await pumpQa(
      t,
      api,
      const BlogConnectionsScreen(section: 'publications'),
      locale: const Locale('de'),
    );
    expect(find.text(de.blogPublicationUnavailableTitle), findsOneWidget);
    expect(find.text(de.blogPublicationUnavailableExcerpt), findsOneWidget);
    expect(find.text('Sharing unavailable'), findsNothing);
    expect(
      find.byKey(const ValueKey('qa.blog.connections.approve_copy.pub1')),
      findsNothing,
    );
  });

  testWidgets('a review notice names its kind and outcome in German '
      '[case:l10n.blog_connections.notice_labels]', (t) async {
    final api = QaApi()
      ..json('GET /blog/notices', {
        'notices': [
          {
            'id': 'case1',
            'content_type': 'theme_entry',
            'content_id': 'e1',
            'status': 'removed',
            'decision_note': 'Removed after review.',
            'appeal': '',
            'version': 1,
            'can_appeal': false,
          },
          {
            'id': 'case2',
            'content_type': 'brand_new_kind',
            'content_id': 'e2',
            'status': 'needs_more_info',
            'decision_note': 'Looking into it.',
            'appeal': '',
            'version': 1,
            'can_appeal': false,
          },
        ],
        'next_cursor': '',
      });
    await pumpQa(
      t,
      api,
      const BlogConnectionsScreen(section: 'notices'),
      locale: const Locale('de'),
    );
    expect(find.text('Themenfoto · Entfernt'), findsOneWidget);
    expect(find.text('Inhalt · Needs more info'), findsOneWidget);
    expect(find.textContaining('theme_entry'), findsNothing);
    expect(find.textContaining('needs_more_info'), findsNothing);
  });
}
