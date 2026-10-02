import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Route local media through the browser's same-origin gateway. Production CDN
/// URLs and unrelated links are intentionally preserved.
///
/// Binary payloads (`ResponseType.bytes`, e.g. an authenticated photo) are
/// returned untouched: walking them as a JSON list would turn a `Uint8List`
/// into a `List<dynamic>`, which Dio then fails to cast to `List<int>`.
dynamic browserMediaUrls(dynamic value, Uri apiBase) {
  if (value is TypedData || value is List<int>) return value;
  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), browserMediaUrls(item, apiBase)),
    );
  }
  if (value is List)
    return value.map((item) => browserMediaUrls(item, apiBase)).toList();
  if (value is String &&
      (value.startsWith('http://') || value.startsWith('https://'))) {
    final uri = Uri.tryParse(value);
    if (uri != null &&
        uri.path.startsWith('${apiBase.path}/media/') &&
        (['localhost', '127.0.0.1', '10.0.2.2', '::1'].contains(uri.host) ||
            uri.host == apiBase.host)) {
      return apiBase
          .replace(path: uri.path, query: uri.hasQuery ? uri.query : null)
          .toString();
    }
  }
  return value;
}

/// Rewrites media links in a decoded JSON [response] in place. Byte, stream
/// and plain-text responses are left exactly as received.
void rewriteBrowserMediaResponse(Response<dynamic> response, Uri apiBase) {
  if (response.requestOptions.responseType != ResponseType.json) return;
  response.data = browserMediaUrls(response.data, apiBase);
}
