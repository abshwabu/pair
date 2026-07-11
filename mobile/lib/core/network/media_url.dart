import 'package:pair/core/network/realtime_config.dart';

/// Rewrites backend media URLs so they load on the current device.
///
/// The API may return absolute URLs built from server-side [APP_URL] (e.g.
/// `http://localhost/storage/...`). On mobile/emulator that host is unreachable
/// or missing the API port. Relative paths and localhost URLs are mapped to the
/// same origin as [ReverbConfig.appBaseUrl].
String? resolveMediaUrl(String? url) {
  if (url == null || url.isEmpty) return null;

  final base = Uri.parse(ReverbConfig.appBaseUrl);

  if (url.startsWith('/')) {
    return _mergeBaseAndPath(base, url);
  }

  final parsed = Uri.tryParse(url);
  if (parsed == null || !parsed.hasScheme) {
    final path = url.startsWith('/') ? url : '/$url';
    return _mergeBaseAndPath(base, path);
  }

  if (parsed.host == 'localhost' || parsed.host == '127.0.0.1') {
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: parsed.path,
      query: parsed.hasQuery ? parsed.query : null,
    ).toString();
  }

  return url;
}

String _mergeBaseAndPath(Uri base, String path) {
  return Uri(
    scheme: base.scheme,
    host: base.host,
    port: base.hasPort ? base.port : null,
    path: path,
  ).toString();
}
