import 'package:flutter/foundation.dart';

/// Network egress allowlist for the KETUA client.
///
/// K17: the app is permitted to talk ONLY to the destinations it genuinely
/// needs — its own backend plus the Google/Firebase/Pesapal/Agora services
/// the product depends on. Any other host (e.g. a third-party IP-geolocation
/// service, an ad network, an analytics beacon) is blocked at the call site
/// so a compromised or careless code path cannot silently exfiltrate user data.
///
/// Enforcement point: ApiProvider.callPost() validates every outbound URL
/// through [isAllowed] before dispatching. Firebase/Maps/Ads SDKs reach their
/// own endpoints through the platform SDKs and are governed by their own
/// config, not this guard — this guard covers app-authored HTTP.
class NetworkGuard {
  NetworkGuard._();

  /// Exact hosts the app is allowed to contact over app-authored HTTP.
  ///
  /// - ketua.sanaa.co   : the KETUA Laravel API + self-hosted assets
  /// - api.agora.io     : Agora RTC token/recording REST (livestream engine)
  /// - pay/cybqa pesapal: mobile-money checkout (billing)
  static const Set<String> _allowedExact = {
    'ketua.sanaa.co',
    'www.ketua.sanaa.co',
    'api.agora.io',
    'pay.pesapal.com',
    'cybqa.pesapal.com',
  };

  /// Host suffixes the app is allowed to contact (covers subdomains).
  static const Set<String> _allowedSuffixes = {
    '.pesapal.com', // e.g. checkout subdomains
  };

  /// Returns true only when [url] targets an allowlisted host over https.
  ///
  /// Rules:
  /// - Must be https (no cleartext, no ws://).
  /// - Host must be in the exact set or match an allowed suffix.
  /// - Anything else is denied and logged (debug builds only) so a rejected
  ///   egress attempt is visible during development.
  static bool isAllowed(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    // Only https is permitted for app-authored calls.
    if (uri.scheme != 'https') {
      _log('blocked non-https scheme', url);
      return false;
    }

    final host = uri.host.toLowerCase();
    if (host.isEmpty) return false;

    if (_allowedExact.contains(host)) return true;

    for (final suffix in _allowedSuffixes) {
      if (host.endsWith(suffix)) return true;
    }

    _log('blocked non-allowlisted host', url);
    return false;
  }

  static void _log(String reason, String url) {
    if (kDebugMode) {
      debugPrint('[NetworkGuard] $reason: $url');
    }
  }
}
