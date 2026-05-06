import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:raunaq/reset_password_screen.dart';
import 'package:raunaq/splash_screen.dart';

/// Picks initial screen: password-reset deep link on web, otherwise splash.
class AuthEntry extends StatelessWidget {
  const AuthEntry({super.key});

  static String? _queryParam(String key) {
    final fromQuery = Uri.base.queryParameters[key];
    if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;
    if (Uri.base.fragment.isNotEmpty) {
      final frag = Uri.splitQueryString(Uri.base.fragment);
      final v = frag[key];
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      final mode = _queryParam('mode');
      final oobCode = _queryParam('oobCode');
      if (mode == 'resetPassword' &&
          oobCode != null &&
          oobCode.isNotEmpty) {
        return ResetPasswordScreen(oobCode: oobCode);
      }
    }
    return const SplashScreen();
  }
}
