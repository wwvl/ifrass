import 'package:cna/core/theme/app_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSpacing（DESIGN.md §3.3 固定值）', () {
    test('8pt 网格数值', () {
      expect(AppSpacing.xs, 4);
      expect(AppSpacing.sm, 8);
      expect(AppSpacing.md, 16);
      expect(AppSpacing.lg, 24);
      expect(AppSpacing.xl, 32);
      expect(AppSpacing.xxl, 48);
    });
  });

  group('AppRadius（对齐 TDesign TRadius 刻度）', () {
    test('数值', () {
      expect(AppRadius.sm, 6);
      expect(AppRadius.md, 9);
      expect(AppRadius.lg, 12);
      expect(AppRadius.pill, 999);
    });
  });

  group('AppDurations（DESIGN.md §3.4）', () {
    test('时长', () {
      expect(AppDurations.fast, const Duration(milliseconds: 150));
      expect(AppDurations.normal, const Duration(milliseconds: 250));
      expect(AppDurations.slow, const Duration(milliseconds: 400));
    });
  });

  group('AppTypography（DESIGN.md §3.2 角色层次）', () {
    test('字号逐级递减 headline > title > body > label', () {
      expect(
        AppTypography.headline.fontSize! > AppTypography.title.fontSize!,
        isTrue,
      );
      expect(
        AppTypography.title.fontSize! > AppTypography.body.fontSize!,
        isTrue,
      );
      expect(
        AppTypography.body.fontSize! > AppTypography.label.fontSize!,
        isTrue,
      );
    });

    test('code 为等宽字族且只在此定义一次', () {
      expect(AppTypography.code.fontFamily, 'monospace');
      expect(AppTypography.code.fontFamilyFallback, isNotEmpty);
    });

    test('角色样式不携带颜色（颜色由 context.tTheme.text* 提供）', () {
      expect(AppTypography.headline.color, isNull);
      expect(AppTypography.body.color, isNull);
    });
  });
}
