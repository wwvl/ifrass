import 'package:cna/core/theme/app_tokens.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 代码块：等宽字排与语义高亮，长行在块内横向滚动。
class CodeBlock extends StatelessWidget {
  /// 创建代码块；缺少语言时显式使用 highlight 0.7 的 plaintext 模式。
  const new({required this.code, super.key, this.language});

  /// 已提取的代码正文。
  final String code;

  /// fenced code 声明的语言；无需调用方预解析。
  final String? language;

  @override
  Widget build(BuildContext context) {
    final token = context.tTheme;
    final declaredLanguage = language?.trim();
    final effectiveLanguage =
        declaredLanguage == null || declaredLanguage.isEmpty
        ? 'plaintext'
        : declaredLanguage;
    final style = AppTypography.code.copyWith(color: token.textColorPrimary);
    final brand = style.copyWith(color: token.brandColor);
    final success = style.copyWith(color: token.successColor);
    final warning = style.copyWith(color: token.warningColor);
    final secondary = style.copyWith(color: token.textColorSecondary);
    final syntaxTheme = <String, TextStyle>{
      'root': style.copyWith(backgroundColor: token.bgColorSecondaryContainer),
      'keyword': brand,
      'selector-tag': brand,
      'built_in': brand,
      'type': brand,
      'title': brand,
      'name': brand,
      'attribute': brand,
      'string': success,
      'symbol': success,
      'regexp': success,
      'number': warning,
      'literal': warning,
      'comment': secondary,
      'quote': secondary,
      'meta': secondary,
      'deletion': style.copyWith(color: token.errorColor),
      'addition': success,
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: ColoredBox(
        color: token.bgColorSecondaryContainer,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              primary: false,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.hasBoundedWidth
                      ? constraints.maxWidth
                      : 0,
                ),
                child: HighlightView(
                  code,
                  language: effectiveLanguage,
                  theme: syntaxTheme,
                  textStyle: style,
                  padding: const EdgeInsets.all(AppSpacing.md),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
