import 'package:flutter/foundation.dart';

class AppConfig {
  static String get baseUrl {
    // Mode Produksi (Release APK): Mengarah ke server Railway
    if (kReleaseMode) {
      return 'https://keuanganrtrw.up.railway.app';
    }

    // Mode Pengembangan (Debug/Local)
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://localhost:5000';
  }
}
