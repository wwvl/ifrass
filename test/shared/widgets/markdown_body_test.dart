import 'package:cached_network_image/cached_network_image.dart';
import 'package:cna/core/router/content_link_parser.dart';
import 'package:cna/core/theme/app_tokens.dart';
import 'package:cna/core/theme/theme.dart';
import 'package:cna/shared/widgets/code_block.dart';
import 'package:cna/shared/widgets/markdown_body.dart';
import 'package:cna/shared/widgets/skeleton_repo_card.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart' as markdown;
import 'package:flutter_test/flutter_test.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

Widget _shell(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: brightness == Brightness.light
        ? buildLightAppTheme()
        : buildDarkAppTheme(),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  testWidgets('GFM headings, lists, quotes, table and strikethrough render', (
    tester,
  ) async {
    await tester.pumpWidget(
      _shell(
        const MarkdownBody(
          data: '''
# 标题

- 列表项目

> 引用文字

| 名称 | 状态 |
| --- | --- |
| cna | 完成 |

~~已删除~~
''',
        ),
      ),
    );

    for (final text in ['标题', '列表项目', '引用文字', '名称', '完成', '已删除']) {
      expect(find.text(text, findRichText: true), findsOneWidget);
    }
    expect(find.byType(Table), findsOneWidget);
    final deleted = tester
        .widgetList<SelectableText>(find.byType(SelectableText))
        .singleWhere((text) => text.textSpan?.toPlainText() == '已删除');
    var hasStrike = false;
    deleted.textSpan!.visitChildren((span) {
      if (span.style?.decoration == TextDecoration.lineThrough) {
        hasStrike = true;
      }
      return true;
    });
    expect(hasStrike, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fenced code uses one CodeBlock with the declared language', (
    tester,
  ) async {
    await tester.pumpWidget(
      _shell(const MarkdownBody(data: '```dart\nfinal value = 1;\n```')),
    );

    final block = tester.widget<CodeBlock>(find.byType(CodeBlock));
    expect(block.code, 'final value = 1;');
    expect(block.language, 'dart');
    final rendered = tester.widget<markdown.MarkdownBody>(
      find.byType(markdown.MarkdownBody),
    );
    expect(rendered.builders.keys, contains('pre'));
    expect(rendered.styleSheet!.codeblockDecoration, const BoxDecoration());
    expect(rendered.selectable, isTrue);
  });

  testWidgets('body shares the outer vertical scroll view without a viewport', (
    tester,
  ) async {
    await tester.pumpWidget(
      _shell(MarkdownBody(data: List.filled(60, '段落内容\n').join('\n'))),
    );

    // SelectableText uses its own EditableText scrollable for selection. The
    // rendered body must not add a document ListView or a second scroll view.
    expect(find.byType(ListView), findsNothing);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    expect(tester.takeException(), isNull);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -400),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets('styles use theme roles and semantic tokens: $brightness', (
      tester,
    ) async {
      await tester.pumpWidget(
        _shell(
          const MarkdownBody(data: '# 标题\n\n正文 `code`'),
          brightness: brightness,
        ),
      );

      final context = tester.element(find.byType(MarkdownBody));
      final text = Theme.of(context).textTheme;
      final tokens = context.tTheme;
      final style = tester
          .widget<markdown.MarkdownBody>(find.byType(markdown.MarkdownBody))
          .styleSheet!;
      expect(
        style.p,
        text.bodyMedium?.copyWith(color: tokens.textColorPrimary),
      );
      expect(
        style.h1,
        text.headlineLarge?.copyWith(color: tokens.textColorPrimary),
      );
      expect(style.a!.color, tokens.brandColor);
      expect(style.blockquote!.color, tokens.textColorSecondary);
      expect(style.code!.fontFamily, AppTypography.code.fontFamily);
      expect(style.code!.fontWeight, AppTypography.code.fontWeight);
      expect(style.code!.fontSize, text.bodyMedium!.fontSize);
      expect(style.tableBorder!.top.color, tokens.componentBorder);
      expect(style.tableCellsPadding, const EdgeInsets.all(AppSpacing.sm));
    });
  }

  testWidgets('parsing links does not execute them or notify during build', (
    tester,
  ) async {
    final targets = <ContentLinkTarget>[];
    await tester.pumpWidget(
      _shell(
        MarkdownBody(
          data: '[内部](/repos)\n\n[外部](https://dart.dev)',
          onLink: targets.add,
        ),
      ),
    );
    expect(targets, isEmpty);

    await tester.tap(find.text('内部', findRichText: true));
    expect(targets, hasLength(1));
    expect(
      targets.single,
      isA<InternalContentLink>().having(
        (target) => target.location,
        'location',
        '/repos',
      ),
    );

    await tester.tap(find.text('外部', findRichText: true));
    expect(targets, hasLength(2));
    expect(
      targets.last,
      isA<ExternalContentLink>().having(
        (target) => target.uri.toString(),
        'uri',
        'https://dart.dev',
      ),
    );
  });

  testWidgets('missing callback leaves links inert', (tester) async {
    await tester.pumpWidget(_shell(const MarkdownBody(data: '[内部](/repos)')));
    await tester.tap(find.text('内部', findRichText: true));
    expect(tester.takeException(), isNull);
  });

  testWidgets('unapproved and relative images stay offline with alt text', (
    tester,
  ) async {
    const sources = [
      '/images/logo.png',
      'logo.png',
      '//evil.example/logo.png',
      'http://cnb.cool/logo.png',
      'https://evil.example/logo.png',
      'https://cnb.cool.evil.example/logo.png',
      'https://secret@cnb.cool/logo.png',
      'https://cnb.cool:8443/logo.png',
      'data:image/png;base64,dGVzdA==',
      'file:///tmp/logo.png',
    ];
    for (final source in sources) {
      await tester.pumpWidget(_shell(MarkdownBody(data: '![项目图标]($source)')));
      expect(find.byType(CachedNetworkImage), findsNothing, reason: source);
      expect(find.text('图片暂不可用'), findsOneWidget, reason: source);
      expect(find.text('项目图标'), findsOneWidget, reason: source);
    }
  });

  testWidgets('approved images provide loading and failure placeholders', (
    tester,
  ) async {
    await tester.pumpWidget(_shell(const MarkdownBody(data: '正文')));
    final context = tester.element(find.byType(MarkdownBody));
    final imageBuilder = tester
        .widget<markdown.MarkdownBody>(find.byType(markdown.MarkdownBody))
        .imageBuilder!;
    final image = imageBuilder(
      Uri.parse('https://cnb.cool/assets/logo.png'),
      null,
      '项目图标',
    ) as CachedNetworkImage;
    expect(image.imageUrl, 'https://cnb.cool/assets/logo.png');

    final loading = image.placeholder!(context, image.imageUrl);
    await tester.pumpWidget(_shell(loading));
    expect(find.text('图片加载中'), findsOneWidget);
    expect(find.text('项目图标'), findsOneWidget);
    expect(find.byType(SkeletonBlock), findsOneWidget);

    final failed = image.errorWidget!(
      context,
      image.imageUrl,
      StateError('stub image download failed'),
    );
    await tester.pumpWidget(_shell(failed));
    expect(find.text('图片加载失败'), findsOneWidget);
    expect(find.byType(SkeletonBlock), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('explicit source policy cannot bypass HTTPS and credentials', (
    tester,
  ) async {
    final sources = [
      Uri.parse('http://approved.example/image.png'),
      Uri.parse('https://secret@approved.example/image.png'),
      Uri.parse('https://approved.example:444/image.png'),
      Uri.parse('/image.png'),
    ];
    for (final source in sources) {
      await tester.pumpWidget(
        _shell(
          MarkdownBody(
            data: '![图标](images/logo.png)',
            imageUriResolver: (_) => source,
          ),
        ),
      );
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.text('图片暂不可用'), findsOneWidget);
    }
  });

  testWidgets('explicit source policy may approve a repository image host', (
    tester,
  ) async {
    await tester.pumpWidget(
      _shell(
        MarkdownBody(
          data: '正文',
          imageUriResolver: (uri) => Uri.https('images.example.test', uri.path),
        ),
      ),
    );
    final imageBuilder = tester
        .widget<markdown.MarkdownBody>(find.byType(markdown.MarkdownBody))
        .imageBuilder!;
    final image =
        imageBuilder(Uri.parse('logo.png'), null, null) as CachedNetworkImage;
    expect(image.imageUrl, 'https://images.example.test/logo.png');
  });

  testWidgets('ordinary parent rebuild reuses parsed body children', (
    tester,
  ) async {
    var resolutions = 0;
    Uri? resolve(Uri source) {
      resolutions++;
      return null;
    }

    late StateSetter rebuild;
    await tester.pumpWidget(
      _shell(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return MarkdownBody(
              data: '![图标](logo.png)',
              imageUriResolver: resolve,
            );
          },
        ),
      ),
    );
    expect(resolutions, 1);

    for (var index = 0; index < 3; index++) {
      rebuild(() {});
      await tester.pump();
    }
    expect(
      resolutions,
      1,
      reason: 'unchanged content must retain parsed output',
    );
    expect(find.text('图片暂不可用'), findsOneWidget);
  });

  testWidgets('changing image policy rebuilds the cached body safely', (
    tester,
  ) async {
    var firstResolutions = 0;
    var secondResolutions = 0;
    Uri? first(Uri source) {
      firstResolutions++;
      return null;
    }

    Uri? second(Uri source) {
      secondResolutions++;
      return null;
    }

    var resolver = first;
    late StateSetter rebuild;
    await tester.pumpWidget(
      _shell(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return MarkdownBody(
              data: '![图标](logo.png)',
              imageUriResolver: resolver,
            );
          },
        ),
      ),
    );
    expect(firstResolutions, 1);
    expect(secondResolutions, 0);

    rebuild(() => resolver = second);
    await tester.pump();
    expect(firstResolutions, 1);
    expect(secondResolutions, 1);
    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
