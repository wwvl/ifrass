import 'package:cna/core/theme/app_tokens.dart';
import 'package:cna/core/theme/theme.dart';
import 'package:cna/shared/widgets/code_block.dart';
import 'package:cna/shared/widgets/commit_tile.dart';
import 'package:cna/shared/widgets/log_terminal.dart';
import 'package:cna/shared/widgets/markdown_body.dart';
import 'package:cna/shared/widgets/status_badge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

const _markdown = '''
# Build notes

Token styles, **strong text**, ~~obsolete~~ and `inline code`.

- First item
- Second item

> Keep the client small and predictable.

| Status | Result |
| --- | --- |
| Tests | Passed |

```dart
final result = await client.getRepos();
print(result);
```

![Repository image](assets/preview.png)
''';

void main() {
  final fixtures = <String, Widget Function()>{
    'markdown_body': () =>
        const SingleChildScrollView(child: MarkdownBody(data: _markdown)),
    'code_block': () => const Align(
      alignment: Alignment.topLeft,
      child: CodeBlock(
        code:
            'final repositories = await client.getRepos();\n'
            '// Long lines stay inside their own horizontal scroll view.\n'
            'print(repositories.map((repo) => repo.path).join(", "));',
        language: 'dart',
      ),
    ),
    'status_badge': () => const Align(
      alignment: Alignment.topLeft,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          StatusBadge(label: '已完成', tone: StatusTone.success),
          StatusBadge(label: '等待中', tone: StatusTone.warning),
          StatusBadge(label: '失败', tone: StatusTone.error),
          StatusBadge(label: '进行中', tone: StatusTone.info),
        ],
      ),
    ),
    'commit_tile': () => const Align(
      alignment: Alignment.topLeft,
      child: CommitTile(
        hash: '4d34e1021aed',
        message: 'feat(repos): connect remote repository data',
        author: 'CNB developer',
        timeLabel: '2026-11-20 21:00',
      ),
    ),
    'log_terminal': () => const Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        height: 320,
        child: LogTerminal(
          lines: [
            r'$ flutter test',
            'Resolving dependencies...',
            'Running repository tests...',
            'All tests passed!',
          ],
        ),
      ),
    ),
  };

  for (final brightness in Brightness.values) {
    for (final fixture in fixtures.entries) {
      testWidgets('${fixture.key} ${brightness.name} golden', (tester) async {
        tester.view
          ..physicalSize = const Size(420, 720)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: brightness == Brightness.light
                ? buildLightAppTheme()
                : buildDarkAppTheme(),
            home: Scaffold(
              body: Builder(
                builder: (context) => RepaintBoundary(
                  key: const ValueKey('rendering-golden'),
                  child: ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: SizedBox.expand(child: fixture.value()),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const ValueKey('rendering-golden')),
          matchesGoldenFile('goldens/${fixture.key}_${brightness.name}.png'),
        );
      });
    }
  }
}
