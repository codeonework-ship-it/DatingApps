/// Removes personal data from crash and error text before it is stored on the
/// device or sent to the self-hosted error endpoint.
///
/// The server scrubs again; this is the first line of defence so that nothing
/// personal ever leaves the phone or sits in the on-disk retry queue.
class PiiScrubber {
  const PiiScrubber._();

  static const int maxMessageLength = 1000;
  static const int maxStackLines = 50;
  static const int maxStackLength = 8000;
  static const int maxRouteLength = 120;

  /// Upper bound on text scanned by the regular expressions. The result is
  /// truncated much shorter afterwards, so anything cut here is discarded.
  static const int _maxScanLength = 20000;

  static final RegExp _url = RegExp(
    r'''\b[a-zA-Z][a-zA-Z0-9+.-]*://[^\s"'<>()\[\]{}]+''',
  );
  // A bare path followed by a query string: `/v1/search?q=...`.
  static final RegExp _pathQuery = RegExp(r'''(/[\w\-.~%/<>]*)[?#][^\s"']*''');
  static final RegExp _homeDir = RegExp(r'(/Users|/home)/[^/\s]+/');
  static final RegExp _bearer = RegExp(
    r'\bBearer\s+[A-Za-z0-9\-._~+/]+=*',
    caseSensitive: false,
  );
  static final RegExp _jwt = RegExp(
    r'\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]*',
  );
  static final RegExp _email = RegExp(
    r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}',
  );
  static final RegExp _uuid = RegExp(
    r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{12}\b',
  );
  static final RegExp _hexToken = RegExp(
    r'(?<![A-Za-z0-9_+\-])[0-9a-fA-F]{24,}(?![A-Za-z0-9_+\-])',
  );
  // Long opaque base64/url-safe runs. '/' and '.' are excluded so package
  // paths and file names in stack traces are not mistaken for tokens.
  static final RegExp _opaqueToken = RegExp(
    r'(?<![A-Za-z0-9_+\-])[A-Za-z0-9_+\-]{24,}={0,2}(?![A-Za-z0-9_+\-])',
  );
  static final RegExp _ipv4 = RegExp(
    r'(?<![\d.])(?:\d{1,3}\.){3}\d{1,3}(?![\d.])',
  );
  static final RegExp _card = RegExp(r'(?<!\d)(?:\d[ -]?){12,18}\d(?!\d)');
  static final RegExp _phone = RegExp(
    r'(?<![\w<])\+?\d[\d \-()]{5,}\d(?![\w>])',
  );
  static final RegExp _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}');
  static final RegExp _digit = RegExp(r'\d');
  static final RegExp _letter = RegExp(r'[A-Za-z]');

  static final RegExp _digitRun = RegExp(r'\d{4,}');
  static final RegExp _numericSegment = RegExp(r'^\d+$');
  static final RegExp _uuidSegment = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{12}$',
  );
  static final RegExp _hexSegment = RegExp(r'^[0-9a-fA-F]{12,}$');
  static final RegExp _opaqueSegment = RegExp(r'^[A-Za-z0-9_\-]{16,}$');

  /// Replaces personal data in free text with placeholders.
  static String scrub(String input) {
    var out = input.length > _maxScanLength
        ? input.substring(0, _maxScanLength)
        : input;
    out = out
        .replaceAllMapped(_url, (m) => scrubUrl(m[0]!))
        .replaceAllMapped(_pathQuery, (m) => m[1]!)
        .replaceAllMapped(_homeDir, (m) => '${m[1]}/<user>/')
        .replaceAll(_bearer, 'Bearer <token>')
        .replaceAll(_jwt, '<token>')
        .replaceAll(_email, '<email>')
        .replaceAll(_uuid, '<id>')
        .replaceAll(_hexToken, '<token>')
        .replaceAllMapped(_opaqueToken, (m) {
          final value = m[0]!;
          final digits = _digit.allMatches(value).length;
          return digits >= 2 && _letter.hasMatch(value) ? '<token>' : value;
        })
        .replaceAll(_ipv4, '<ip>')
        .replaceAll(_card, '<number>')
        .replaceAllMapped(_phone, (m) {
          final value = m[0]!;
          if (_isoDate.hasMatch(value)) {
            return value;
          }
          final digits = _digit.allMatches(value).length;
          return digits >= 7 ? '<phone>' : value;
        });
    return out;
  }

  /// Keeps scheme, host and a templated path; drops credentials, the query
  /// string and the fragment.
  static String scrubUrl(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) {
      return routeTemplate(raw);
    }
    final authority = uri.host.isEmpty
        ? ''
        : uri.hasPort
        ? '${uri.host}:${uri.port}'
        : uri.host;
    final path = uri.path.split('/').map(_templateSegment).join('/');
    return '${uri.scheme}://$authority$path';
  }

  /// A route or API path with the query string and fragment removed and every
  /// id-like segment replaced by `<id>`, e.g. `/profile/42?tab=x` becomes
  /// `/profile/<id>`.
  static String routeTemplate(String path) {
    var value = path.trim();
    final cut = value.indexOf(RegExp('[?#]'));
    if (cut >= 0) {
      value = value.substring(0, cut);
    }
    final template = value.split('/').map(_templateSegment).join('/');
    return template.length > maxRouteLength
        ? template.substring(0, maxRouteLength)
        : template;
  }

  static String _templateSegment(String segment) {
    if (segment.isEmpty || segment == '<id>') {
      return segment;
    }
    final lower = segment.toLowerCase();
    if (segment.contains('@') ||
        lower.contains('%40') ||
        _numericSegment.hasMatch(segment) ||
        _digitRun.hasMatch(segment) ||
        _uuidSegment.hasMatch(segment) ||
        _hexSegment.hasMatch(segment) ||
        (_opaqueSegment.hasMatch(segment) && _digit.hasMatch(segment))) {
      return '<id>';
    }
    return segment;
  }

  /// Scrubbed error message, at most [maxMessageLength] characters.
  static String message(String raw) =>
      _truncate(scrub(raw.trim()), maxMessageLength);

  /// Scrubbed stack trace: at most [maxStackLines] non-empty lines and
  /// [maxStackLength] characters.
  static String stack(String raw) {
    final lines = raw
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => line.trim().isNotEmpty)
        .take(maxStackLines)
        .join('\n');
    return _truncate(scrub(lines), maxStackLength);
  }

  static String _truncate(String value, int max) =>
      value.length > max ? value.substring(0, max) : value;
}
