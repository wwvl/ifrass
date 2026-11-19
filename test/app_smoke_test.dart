import 'package:cna/core/theme/tdesign_theme.dart';
import 'package:cna/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

void main() {
  testWidgets('浅色：占位页渲染且主题携带浅色 Token 扩展', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const CnaApp());

    expect(find.text('CNB'), findsOneWidget);
    final context = tester.element(find.text('CNB'));
    expect(Theme.of(context).brightness, Brightness.light);
    expect(
      identical(Theme.of(context).extension<TThemeData>(), AppThemeTokens.root),
      isTrue,
    );
  });

  testWidgets('深色：主题随系统切深且扩展为深色 Token', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(const CnaApp());

    expect(find.text('CNB'), findsOneWidget);
    final context = tester.element(find.text('CNB'));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(
      identical(
        Theme.of(context).extension<TThemeData>(),
        AppThemeTokens.root.dark,
      ),
      isTrue,
    );
  });
}
