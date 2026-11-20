import 'package:cna/core/router/content_link_actions.dart';
import 'package:cna/core/router/content_link_parser.dart';
import 'package:cna/core/router/guards.dart';
import 'package:cna/core/router/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final path in [
    AppRoutes.home,
    AppRoutes.repos,
    AppRoutes.settings,
    AppRoutes.offline,
    AppRoutes.sessionExpired,
    AppRoutes.repo(owner: 'CNB', name: 'App'),
    '${AppRoutes.repos}?search=dart#recent',
  ]) {
    test('resolves registered internal path $path', () {
      final target = parseContentLink(path) as InternalContentLink;
      expect(target.location, path);
      expect(safeFromTarget(target.location), path);
    });
  }

  for (final value in [
    null,
    '',
    '#123',
    '@user',
    '/Repos',
    '/repo/owner/name/issue/123',
    '/search',
    'repo/owner/name',
    '//evil.com/repos',
    r'/\evil.com/repos',
    '/repo/owner/name%2Fother',
    '/repo/owner/name%5Cother',
    '/repo/%FF/name',
    '/repo/%C0%AF/name',
    '/repo/%E0%A4/name',
    'http://example.com',
    'javascript:alert(1)',
    'data:text/html,hello',
    'file:///repos',
    'https:/example.com',
    'https://user:password@example.com',
    ' https://example.com',
    'https://example.com/\nrepos',
  ]) {
    test('leaves unsupported or unsafe target unresolved: $value', () {
      expect(parseContentLink(value), isA<UnresolvedContentLink>());
    });
  }

  test('accepts HTTPS without treating it as an internal route', () {
    for (final value in ['https://cnb.cool/a', 'HTTPS://example.com/Repos']) {
      expect(safeFromTarget(value), isNull);
      final target = parseContentLink(value) as ExternalContentLink;
      expect(target.uri.scheme, 'https');
    }
  });

  test('recognition does not execute navigation', () async {
    final navigated = <String>[];
    final opened = <Uri>[];
    final internal = parseContentLink(AppRoutes.repos);
    final external = parseContentLink('https://cnb.cool');
    expect(navigated, isEmpty);
    expect(opened, isEmpty);
    expect(await followContentLink(internal, navigate: navigated.add), isTrue);
    expect(navigated, [AppRoutes.repos]);
    expect(
      await followContentLink(
        external,
        navigate: navigated.add,
        openExternal: (uri) async {
          opened.add(uri);
          return true;
        },
      ),
      isTrue,
    );
    expect(opened.single, Uri.parse('https://cnb.cool'));
  });

  test('execution revalidates a manually constructed destination', () async {
    void noNavigation(String location) => fail('unsafe navigation: $location');
    for (final target in [
      const InternalContentLink('//evil.com'),
      ExternalContentLink(Uri.parse('javascript:alert(1)')),
      const UnresolvedContentLink('#123'),
    ]) {
      expect(
        await followContentLink(
          target,
          navigate: noNavigation,
          openExternal: (_) async => fail('unsafe external link'),
        ),
        isFalse,
      );
    }
  });
}
