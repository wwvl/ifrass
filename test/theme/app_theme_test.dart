import 'package:cna/core/theme/tdesign_theme.dart';
import 'package:cna/core/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

void main() {
  group('AppThemeTokens', () {
    test('defaultData 自带深色 Token（不得只做浅色）', () {
      expect(AppThemeTokens.root.dark, isNotNull);
      expect(identical(AppThemeTokens.dark, AppThemeTokens.root.dark), isTrue);
    });
  });

  group('buildLightAppTheme / buildDarkAppTheme', () {
    test('浅色：亮度正确且携带 Token 扩展', () {
      final theme = buildLightAppTheme();
      expect(theme.brightness, Brightness.light);
      expect(theme.extension<TThemeData>(), isNotNull);
    });

    test('深色：亮度为 dark 且扩展即深色 Token', () {
      final theme = buildDarkAppTheme();
      expect(theme.brightness, Brightness.dark);
      final token = theme.extension<TThemeData>();
      expect(token, isNotNull);
      expect(identical(token, AppThemeTokens.root.dark), isTrue);
    });

    test('浅深两套 Token 的页面底色不同（两套完整配置）', () {
      final light = buildLightAppTheme().extension<TThemeData>()!;
      final dark = buildDarkAppTheme().extension<TThemeData>()!;
      expect(dark.bgColorPage, isNot(light.bgColorPage));
    });

    test('品牌色进入 Material ColorScheme.primary', () {
      expect(
        buildLightAppTheme().colorScheme.primary,
        AppThemeTokens.root.brandColor,
      );
    });
  });
}
