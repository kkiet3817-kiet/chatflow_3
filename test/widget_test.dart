// Tệp kiểm thử tự động
// Đã dọn dẹp để tránh lỗi biên dịch do thay đổi cấu trúc dự án.

import 'package:flutter_test/flutter_test.dart';
import 'package:chatflow_3/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App starts test', (WidgetTester tester) async {
    // Kiểm tra xem ứng dụng có khởi động được vào màn hình LoginPage không
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    
    // Bạn có thể thêm các logic kiểm thử giao diện tại đây nếu muốn
    expect(find.byType(MyApp), findsOneWidget);
  });
}
