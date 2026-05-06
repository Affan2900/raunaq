import 'package:flutter/foundation.dart';

/// App-wide flag: when true, signed-in users see CRUD UI for category items they own.
class AdminModeNotifier extends ChangeNotifier {
  bool _isAdminView = false;

  bool get isAdminView => _isAdminView;

  void setAdminView(bool value) {
    if (_isAdminView == value) return;
    _isAdminView = value;
    notifyListeners();
  }

  void toggle() {
    _isAdminView = !_isAdminView;
    notifyListeners();
  }
}
