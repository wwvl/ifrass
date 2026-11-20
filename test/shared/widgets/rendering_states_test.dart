import 'package:cna/core/error/failure.dart';
import 'package:cna/core/theme/app_tokens.dart';
import 'package:cna/core/theme/theme.dart';
import 'package:cna/shared/widgets/async_state_view.dart';
import 'package:cna/shared/widgets/code_block.dart';
import 'package:cna/shared/widgets/commit_tile.dart';
import 'package:cna/shared/widgets/log_terminal.dart';
import 'package:cna/shared/widgets/markdown_body.dart';
import 'package:cna/shared/widgets/skeleton_repo_card.dart';
import 'package:cna/shared/widgets/status_badge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

void main() {
  final fixtures = <Widget>[
    const MarkdownBody(data: 'content'),
    const CodeBlock(code: 'content'),
    const StatusBadge(label: 'content', tone: StatusTone.info),
    const CommitTile(
      hash: 'a1b2c3',
      message: 'content',
      author: 'author',
      timeLabel: 'now',
    ),
    const LogTerminal(lines: ['content']),
  ];
  for (final fixture in fixtures) {
    testWidgets('${fixture.runtimeType} composes with existing states', (
      tester,
    ) async {
      Future<void> show(AsyncValue<String> value) => tester.pumpWidget(
        MaterialApp(
          theme: buildLightAppTheme(),
          home: Scaffold(
            body: AsyncStateHost<String>(
              async: value,
              isEmpty: (text) => text.isEmpty,
              loadingView: const SkeletonBlock(height: AppSpacing.xxl),
              contentBuilder: (_, _) => fixture,
              onRetry: () {},
            ),
          ),
        ),
      );
      await show(const AsyncLoading());
      expect(find.byType(SkeletonBlock), findsOneWidget);
      await show(const AsyncError(FailureHttp(403), StackTrace.empty));
      expect(find.text('令牌授权范围不足'), findsOneWidget);
      await show(const AsyncError(FailureNetwork(), StackTrace.empty));
      expect(find.text('网络不可用'), findsOneWidget);
      await show(const AsyncData(''));
      expect(find.text('这里还没有内容'), findsOneWidget);
      await show(const AsyncData('content'));
      expect(find.byType(fixture.runtimeType), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
