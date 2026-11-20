import 'package:cna/core/router/content_link_parser.dart';
import 'package:url_launcher/url_launcher.dart';

/// Executes a previously recognized link after an explicit user action.
///
/// [navigate] belongs to the host page. External links use url_launcher 6.x;
/// [openExternal] allows tests to verify intent without opening a browser.
Future<bool> followContentLink(
  ContentLinkTarget target, {
  required void Function(String location) navigate,
  Future<bool> Function(Uri uri)? openExternal,
}) async {
  switch (target) {
    case InternalContentLink(:final location):
      if (parseContentLink(location) case InternalContentLink()) {
        navigate(location);
        return true;
      }
      return false;
    case ExternalContentLink(:final uri):
      if (parseContentLink(uri.toString()) case ExternalContentLink()) {
        return await (openExternal ?? _launchExternal)(uri);
      }
      return false;
    case UnresolvedContentLink():
      return false;
  }
}

Future<bool> _launchExternal(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);
