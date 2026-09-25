import 'package:web/web.dart' as web;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void initializePlatform() {
  setUrlStrategy(PathUrlStrategy());
}

void updatePageLanguage(String code) {
  final english = code == 'en';
  web.document.documentElement?.setAttribute('lang', english ? 'en' : 'zh-CN');
  try {
    web.window.localStorage.setItem('vokusz-language', english ? 'en' : 'zh');
  } catch (_) {
    // Browsers may disable storage; language switching must still work.
  }
}
