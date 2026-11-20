import 'package:cna/core/theme/app_tokens.dart';
import 'package:cna/core/theme/theme.dart';
import 'package:cna/shared/widgets/code_block.dart';
import 'package:cna/shared/widgets/commit_tile.dart';
import 'package:cna/shared/widgets/status_badge.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

Widget _shell({
  required Widget child,
  Brightness brightness = Brightness.light,
  FontWeight? inheritedWeight,
}) => MaterialApp(
  theme: brightness == Brightness.light
      ? buildLightAppTheme()
      : buildDarkAppTheme(),
  home: Scaffold(
    body: DefaultTextStyle.merge(
      style: TextStyle(fontWeight: inheritedWeight),
      child: child,
    ),
  ),
);

void main() {
  group('CodeBlock', () {
    testWidgets('长行在代码块内横向滚动，外层文档保持纵向滚动', (tester) async {
      final code = 'final value = "${'long-code-' * 30}";';
      await tester.pumpWidget(
        _shell(
          child: SizedBox(
            width: 200,
            child: SingleChildScrollView(
              child: CodeBlock(code: code, language: 'dart'),
            ),
          ),
        ),
      );

      final horizontal = find.descendant(
        of: find.byType(CodeBlock),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.right,
        ),
      );
      expect(horizontal, findsOneWidget);
      final position = tester.state<ScrollableState>(horizontal).position;
      expect(position.maxScrollExtent, greaterThan(0));
      await tester.drag(horizontal, const Offset(-120, 0));
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
      expect(tester.takeException(), isNull);
      expect(
        tester.widget<HighlightView>(find.byType(HighlightView)).source,
        code,
      );
    });

    testWidgets('未识别的代码语言回退纯文本', (tester) async {
      await tester.pumpWidget(
        _shell(
          child: const CodeBlock(
            code: 'not syntax: <unsafe-looking> & text',
            language: 'unknown-cnb-language',
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.text('not syntax: <unsafe-looking> & text', findRichText: true),
        findsOneWidget,
      );
    });

    for (final language in <String?>[null, '', '   ']) {
      testWidgets('缺失或空白语言 $language 显式使用 plaintext', (tester) async {
        await tester.pumpWidget(
          _shell(
            child: CodeBlock(code: 'plain code content', language: language),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(
          tester.widget<HighlightView>(find.byType(HighlightView)).language,
          'plaintext',
        );
        expect(
          find.text('plain code content', findRichText: true),
          findsOneWidget,
        );
      });
    }

    for (final brightness in Brightness.values) {
      testWidgets('$brightness 代码使用语义色与固定等宽字排', (tester) async {
        await tester.pumpWidget(
          _shell(
            brightness: brightness,
            inheritedWeight: FontWeight.w900,
            child: const CodeBlock(code: 'final count = 42;', language: 'dart'),
          ),
        );

        final context = tester.element(find.byType(CodeBlock));
        final token = context.tTheme;
        final highlight = tester.widget<HighlightView>(
          find.byType(HighlightView),
        );
        expect(highlight.textStyle!.fontFamily, AppTypography.code.fontFamily);
        expect(highlight.textStyle!.fontWeight, AppTypography.code.fontWeight);
        expect(highlight.theme['root']!.color, token.textColorPrimary);
        expect(
          highlight.theme['root']!.backgroundColor,
          token.bgColorSecondaryContainer,
        );
        expect(highlight.theme['keyword']!.color, token.brandColor);
        expect(highlight.theme['string']!.color, token.successColor);
        expect(highlight.theme['number']!.color, token.warningColor);
        final richText = tester.widget<RichText>(
          find.descendant(
            of: find.byType(HighlightView),
            matching: find.byType(RichText),
          ),
        );
        expect(richText.text.style!.fontFamily, AppTypography.code.fontFamily);
        expect(richText.text.style!.fontWeight, AppTypography.code.fontWeight);
      });
    }
  });

  group('StatusBadge', () {
    for (final brightness in Brightness.values) {
      testWidgets('$brightness 四种状态带文案且只使用语义配色', (tester) async {
        await tester.pumpWidget(
          _shell(
            brightness: brightness,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final tone in StatusTone.values)
                  StatusBadge(label: tone.name, tone: tone),
              ],
            ),
          ),
        );

        final token = tester.element(find.byType(StatusBadge).first).tTheme;
        for (final (tone, preset, color) in [
          (StatusTone.success, TTagColorPreset.success, token.successColor),
          (StatusTone.warning, TTagColorPreset.warning, token.warningColor),
          (StatusTone.error, TTagColorPreset.danger, token.errorColor),
          (StatusTone.info, TTagColorPreset.primary, token.brandColor),
        ]) {
          final tagFinder = find.ancestor(
            of: find.text(tone.name),
            matching: find.byType(TTag),
          );
          expect(tagFinder, findsOneWidget);
          final tag = tester.widget<TTag>(tagFinder);
          expect(tag.colorPreset, preset);
          expect(tag.variant, TTagVariant.light);
          final rendered = tester.widget<RichText>(
            find.descendant(of: tagFinder, matching: find.byType(RichText)),
          );
          expect(rendered.text.style!.color, color);
        }
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('CommitTile', () {
    testWidgets('字段完整呈现，点击由调用方处理', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _shell(
          child: CommitTile(
            hash: '4d34e10',
            message: 'feat(repos): 使用真实数据',
            author: 'CNB contributor',
            timeLabel: '2026-11-20 21:30',
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('4d34e10'), findsOneWidget);
      expect(find.text('feat(repos): 使用真实数据'), findsOneWidget);
      expect(find.text('CNB contributor'), findsOneWidget);
      expect(find.text('2026-11-20 21:30'), findsOneWidget);
      await tester.tap(find.text('feat(repos): 使用真实数据'));
      expect(tapped, isTrue);
    });

    testWidgets('长字段与大字体不溢出，hash 不继承全局粗体', (tester) async {
      final hash = '0123456789abcdef' * 4;
      await tester.pumpWidget(
        _shell(
          inheritedWeight: FontWeight.w900,
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: SizedBox(
              width: 160,
              child: CommitTile(
                hash: hash,
                message: 'very long commit message ' * 10,
                author: 'long author ' * 10,
                timeLabel: 'long localized time label ' * 5,
              ),
            ),
          ),
        ),
      );

      final hashWidget = tester.widget<Text>(find.text(hash));
      expect(hashWidget.style!.fontFamily, AppTypography.code.fontFamily);
      expect(hashWidget.style!.fontWeight, AppTypography.code.fontWeight);
      expect(hashWidget.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });
  });
}
