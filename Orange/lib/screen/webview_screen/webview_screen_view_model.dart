import 'package:ketua_ui/utils/const_res.dart';
import 'package:stacked/stacked.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';

class WebViewScreenViewModel extends BaseViewModel {
  WebViewControllerPlus controller = WebViewControllerPlus();

  // Allowed domains for WebView - only these can be loaded
  static const List<String> _allowedDomains = [
    'ketua.sanaa.co',
  ];

  void init(String url) {
    final uri = Uri.parse(ConstRes.base + url);

    // Validate the URL is from an allowed domain
    if (!_isAllowedDomain(uri.host)) {
      throw Exception('Domain not allowed: ${uri.host}');
    }

    controller = WebViewControllerPlus()
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (Uri.tryParse(request.url)?.scheme != 'https' || !_isAllowedDomain(Uri.tryParse(request.url)?.host ?? '')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (url) async {},
        ),
      )
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..loadRequest(uri);
  }

  bool _isAllowedDomain(String host) {
    return _allowedDomains.any((domain) =>
        host == domain);
  }
}
