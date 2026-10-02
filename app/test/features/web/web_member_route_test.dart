import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/web/web_member_workspace.dart';

/// A member who already has a session and opens a signed-out entry link (the
/// website's "Sign in" button is `/app/#/signin`) lands on Discover, not on a
/// "This page could not be found" workspace. Both the first route and later
/// browser route changes go through [webMemberRoute].
void main() {
  test('signed-out entry pages send a signed-in member to Discover', () {
    for (final path in [
      '/',
      '/signin',
      '/signup',
      '/welcome',
      '/introducer/signup',
    ]) {
      expect(webMemberRoute(path), '/discover', reason: path);
    }
  });

  test('member pages and unknown pages are left alone', () {
    for (final path in ['/discover', '/matches', '/features', '/nope']) {
      expect(webMemberRoute(path), path, reason: path);
    }
  });

  group('WebPageTrail (phone Back, WEB-09)', () {
    test('a page opened directly has no previous page', () {
      final trail = WebPageTrail()..visit('/groups');
      expect(trail.previous, isNull);
    });

    test('remembers the page the member came from', () {
      final trail = WebPageTrail()
        ..visit('/discover')
        ..visit('/features')
        ..visit('/groups');
      expect(trail.previous, '/features');
      // Re-reporting the current page (a route echo) changes nothing.
      trail.visit('/groups');
      expect(trail.previous, '/features');
    });

    test('going back pops, so repeated Back walks the whole trail', () {
      final trail = WebPageTrail()
        ..visit('/discover')
        ..visit('/features')
        ..visit('/groups')
        ..visit('/features');
      expect(trail.previous, '/discover');
      trail.visit('/discover');
      expect(trail.previous, isNull);
    });

    test('keeps a bounded history', () {
      final trail = WebPageTrail();
      for (var i = 0; i < 200; i++) {
        trail.visit('/page-$i');
      }
      expect(trail.previous, '/page-198');
    });
  });
}
