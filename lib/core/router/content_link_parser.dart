import 'package:cna/core/router/guards.dart' show safeFromTarget;
import 'package:cna/core/router/routes.dart';

/// A recognized destination; parsing never performs navigation or network IO.
sealed class ContentLinkTarget {
  /// Creates a destination.
  const new();
}

/// A supported application route, with its original query and fragment.
final class InternalContentLink extends ContentLinkTarget {
  /// Creates an internal destination.
  const new(this.location);

  /// Application location built from [AppRoutes].
  final String location;
}

/// An HTTPS destination that may be opened after an explicit user action.
final class ExternalContentLink extends ContentLinkTarget {
  /// Creates an external destination.
  const new(this.uri);

  /// Destination URI, without embedded credentials.
  final Uri uri;
}

/// An unsafe destination or a reference with no registered application route.
final class UnresolvedContentLink extends ContentLinkTarget {
  /// Retains the original reference for a future feature resolver.
  const new(this.source);

  /// Original link, including unresolved issue references and user mentions.
  final String? source;
}

/// Recognizes supported routes and HTTPS links without executing them.
///
/// Internal path validation uses the same [safeFromTarget] function as login
/// redirects. Issue and user references remain unresolved until those routes
/// are registered in a later milestone.
ContentLinkTarget parseContentLink(String? href) {
  if (href == null || href.isEmpty || href != href.trim()) {
    return UnresolvedContentLink(href);
  }
  final uri = Uri.tryParse(href);
  if (uri == null) return UnresolvedContentLink(href);

  if (safeFromTarget(href) != null) {
    final String? location;
    try {
      // Uri.tryParse validates syntax, but segment UTF-8 decoding is lazy.
      location = _supportedPath(uri);
    } on FormatException {
      return UnresolvedContentLink(href);
    }
    if (location == null) return UnresolvedContentLink(href);
    return InternalContentLink(
      Uri.parse(location)
          .replace(
            query: uri.hasQuery ? uri.query : null,
            fragment: uri.hasFragment ? uri.fragment : null,
          )
          .toString(),
    );
  }
  if (uri.scheme == 'https' &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty &&
      !href.contains(r'\') &&
      !RegExp(r'[\x00-\x20\x7f]').hasMatch(href)) {
    return ExternalContentLink(uri);
  }
  return UnresolvedContentLink(href);
}

String? _supportedPath(Uri uri) {
  const locations = {
    AppRoutes.home,
    AppRoutes.repos,
    AppRoutes.settings,
    AppRoutes.login,
    AppRoutes.splash,
    AppRoutes.offline,
    AppRoutes.sessionExpired,
  };
  if (locations.contains(uri.path)) return uri.path;

  final segments = uri.pathSegments;
  final repoPrefix = Uri.parse(AppRoutes.repo(owner: '_', name: '_'))
      .pathSegments
      .first;
  if (segments.length != 3 || segments.first != repoPrefix) return null;
  final owner = segments[1];
  final name = segments[2];
  if ([owner, name].any(
    (part) =>
        part.isEmpty ||
        part == '.' ||
        part == '..' ||
        part.contains('/') ||
        part.contains(r'\') ||
        RegExp(r'[\x00-\x20\x7f]').hasMatch(part),
  )) {
    return null;
  }
  return AppRoutes.repo(
    owner: Uri.encodeComponent(owner),
    name: Uri.encodeComponent(name),
  );
}
