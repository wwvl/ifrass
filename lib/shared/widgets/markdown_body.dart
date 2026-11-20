import 'package:cached_network_image/cached_network_image.dart';
import 'package:cna/core/router/content_link_parser.dart';
import 'package:cna/core/theme/app_tokens.dart';
import 'package:cna/shared/widgets/code_block.dart';
import 'package:cna/shared/widgets/skeleton_repo_card.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart' as markdown;
import 'package:markdown/markdown.dart' as md;
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// Resolves an image against an approved repository or image source.
/// Returning null keeps the image offline and displays its placeholder.
typedef MarkdownImageUriResolver = Uri? Function(Uri source);

/// Shared, non-scrolling Markdown renderer for Flutter 3.47 content views.
///
/// The flutter_markdown_plus 1.0.12 body caches its parsed children between
/// ordinary rebuilds. Theme or source changes rebuild that cache; parsing is
/// never performed by this widget's build method.
class MarkdownBody extends StatelessWidget {
  /// Creates a body; links are reported as intent and never executed here.
  const new({
    required this.data,
    super.key,
    this.onLink,
    this.imageUriResolver,
  });

  /// Markdown source, including GitHub Flavored Markdown extensions.
  final String data;

  /// Business callback for an explicitly tapped, parsed link target.
  final ValueChanged<ContentLinkTarget>? onLink;

  /// Optional repository-aware policy for approving an image source.
  /// Resolved images still require HTTPS without credentials or explicit ports.
  final MarkdownImageUriResolver? imageUriResolver;

  @override
  Widget build(BuildContext context) {
    return markdown.MarkdownBody(
      key: ObjectKey(imageUriResolver),
      data: data,
      selectable: true,
      fitContent: false,
      styleSheet: _styleSheet(context),
      builders: {'pre': _CodeBlockBuilder()},
      onTapLink: (text, href, title) => onLink?.call(parseContentLink(href)),
      imageBuilder: (uri, title, alt) {
        final source = _resolveImage(uri);
        if (source == null) {
          return _ImagePlaceholder(label: '图片暂不可用', description: alt);
        }
        return CachedNetworkImage(
          imageUrl: source.toString(),
          fadeInDuration: AppDurations.normal,
          fadeOutDuration: AppDurations.fast,
          fit: BoxFit.contain,
          placeholder: (context, url) => _ImagePlaceholder(
            label: '图片加载中',
            description: alt,
            loading: true,
          ),
          errorWidget: (context, url, error) =>
              _ImagePlaceholder(label: '图片加载失败', description: alt),
        );
      },
    );
  }

  Uri? _resolveImage(Uri source) {
    final resolver = imageUriResolver;
    final resolved = resolver == null
        ? switch (source.host) {
            'cnb.cool' || 'api.cnb.cool' => source,
            _ => null,
          }
        : resolver(source);
    // TODO(M5-1): resolve relative paths using the repository and revision
    // context. Until then, unapproved or unresolved paths stay placeholders.
    if (resolved == null ||
        resolved.scheme != 'https' ||
        resolved.host.isEmpty ||
        resolved.userInfo.isNotEmpty ||
        resolved.hasPort) {
      return null;
    }
    return resolved;
  }

  markdown.MarkdownStyleSheet _styleSheet(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final tokens = context.tTheme;
    return markdown.MarkdownStyleSheet.fromTheme(theme).copyWith(
      a: text.bodyMedium?.copyWith(color: tokens.brandColor),
      h1: text.headlineLarge?.copyWith(color: tokens.textColorPrimary),
      h2: text.headlineMedium?.copyWith(color: tokens.textColorPrimary),
      h3: text.headlineSmall?.copyWith(color: tokens.textColorPrimary),
      h4: text.titleLarge?.copyWith(color: tokens.textColorPrimary),
      h5: text.titleMedium?.copyWith(color: tokens.textColorPrimary),
      h6: text.titleSmall?.copyWith(color: tokens.textColorPrimary),
      p: text.bodyMedium?.copyWith(color: tokens.textColorPrimary),
      code: text.bodyMedium?.copyWith(
        fontFamily: AppTypography.code.fontFamily,
        fontFamilyFallback: AppTypography.code.fontFamilyFallback,
        fontWeight: AppTypography.code.fontWeight,
        color: tokens.textColorPrimary,
        backgroundColor: tokens.bgColorSecondaryContainer,
      ),
      blockquote: text.bodyMedium?.copyWith(color: tokens.textColorSecondary),
      blockSpacing: AppSpacing.sm,
      listIndent: AppSpacing.lg,
      listBullet: text.bodyMedium?.copyWith(color: tokens.textColorPrimary),
      listBulletPadding: const EdgeInsets.only(right: AppSpacing.xs),
      tableHead: text.titleSmall?.copyWith(color: tokens.textColorPrimary),
      tableBody: text.bodyMedium?.copyWith(color: tokens.textColorPrimary),
      tablePadding: const EdgeInsets.only(bottom: AppSpacing.sm),
      tableCellsPadding: const EdgeInsets.all(AppSpacing.sm),
      tableBorder: TableBorder.all(color: tokens.componentBorder),
      tableCellsDecoration: BoxDecoration(color: tokens.bgColorContainer),
      blockquotePadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      blockquoteDecoration: BoxDecoration(
        color: tokens.bgColorSecondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border(left: BorderSide(color: tokens.brandColor)),
      ),
      codeblockPadding: EdgeInsets.zero,
      // flutter_markdown_plus 1.0.12 also wraps custom pre builders in a
      // decorated container. CodeBlock owns the only visible code frame.
      codeblockDecoration: const BoxDecoration(),
    );
  }
}

class _CodeBlockBuilder extends markdown.MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    md.Element? code;
    for (final child in element.children ?? const <md.Node>[]) {
      if (child is md.Element && child.tag == 'code') {
        code = child;
        break;
      }
    }
    final languageClass = code?.attributes['class'];
    const prefix = 'language-';
    final language = languageClass?.startsWith(prefix) ?? false
        ? languageClass!.substring(prefix.length)
        : null;
    final source = code?.textContent ?? element.textContent;
    return CodeBlock(
      code: source.endsWith('\n')
          ? source.substring(0, source.length - 1)
          : source,
      language: language,
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const new({required this.label, this.description, this.loading = false});

  final String label;
  final String? description;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.xxl),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.tTheme.bgColorSecondaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading) ...[
              const SkeletonBlock(height: AppSpacing.sm),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: context.tTheme.textColorSecondary),
            ),
            if (description != null && description!.isNotEmpty)
              Text(
                description!,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: context.tTheme.textColorPlaceholder),
              ),
          ],
        ),
      ),
    );
  }
}
