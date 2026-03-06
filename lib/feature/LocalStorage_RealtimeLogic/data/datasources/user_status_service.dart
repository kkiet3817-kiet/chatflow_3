import 'dart:async';

class UserStatusService {
  static Stream<bool> statusStream() {
    return Stream.periodic(const Duration(seconds: 5), (i) => i % 2 == 0);
  }
}
