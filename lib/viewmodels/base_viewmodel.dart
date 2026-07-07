import 'package:flutter/foundation.dart';

class BaseViewModel extends ChangeNotifier {
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true; // 뷰모델이 파괴될 때 깃발을 꽂는다.
    super.dispose();
  }

  @override
  void notifyListeners() {
    // 뷰모델이 살아있을 때만 호출되도록 가드
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
