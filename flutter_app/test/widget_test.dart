import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_app/app.dart';

void main() {
  testWidgets('App launches with pet character', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PetApp()));

    // 验证首页显示
    expect(find.text('我的 小暖'), findsOneWidget);
  });
}
