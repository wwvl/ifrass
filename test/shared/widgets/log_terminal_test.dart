import 'dart:async';

import 'package:cna/core/error/failure.dart';
import 'package:cna/core/theme/app_tokens.dart';
import 'package:cna/core/theme/theme.dart';
import 'package:cna/shared/widgets/log_terminal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

Widget _shell(Widget child) => MaterialApp(
  theme: buildLightAppTheme(),
  home: Scaffold(body: SizedBox(height: 240, child: child)),
);

void main() {
  testWidgets('snapshot uses monospace and wraps a long log line', (
    tester,
  ) async {
    await tester.pumpWidget(_shell(LogTerminal(lines: ['a' * 300])));
    final text = tester.widget<Text>(find.text('a' * 300));
    expect(text.style!.fontFamily, AppTypography.code.fontFamily);
    expect(text.style!.fontWeight, AppTypography.code.fontWeight);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pause, resume, then stop cancels once', (tester) async {
    var releases = 0;
    final controller = StreamController<String>();
    addTearDown(controller.close);
    await tester.pumpWidget(
      _shell(
        LogTerminal(stream: controller.stream, onCancel: () => releases++),
      ),
    );
    controller.add('first line');
    await tester.pump();
    await tester.pump();
    expect(find.text('first line'), findsOneWidget);
    await tester.tap(find.text('暂停'));
    await tester.pump();
    controller.add('buffered line');
    await tester.pump();
    expect(find.text('buffered line'), findsNothing);
    await tester.tap(find.text('继续'));
    await tester.pump();
    await tester.pump();
    expect(find.text('buffered line'), findsOneWidget);
    await tester.tap(find.text('停止'));
    await tester.pump();
    expect(controller.hasListener, isFalse);
    expect(releases, 1);
    await tester.pumpWidget(_shell(const SizedBox()));
    await tester.pump();
    expect(releases, 1);
  });

  testWidgets('dispose cancels and retains at most maxLines', (tester) async {
    var releases = 0;
    final controller = StreamController<String>();
    addTearDown(controller.close);
    await tester.pumpWidget(
      _shell(
        LogTerminal(
          lines: const ['oldest', 'middle'],
          maxLines: 2,
          stream: controller.stream,
          onCancel: () => releases++,
        ),
      ),
    );
    controller.add('newest');
    await tester.pump();
    expect(find.text('oldest'), findsNothing);
    expect(find.text('newest'), findsOneWidget);
    await tester.pumpWidget(_shell(const SizedBox()));
    await tester.pump();
    expect(controller.hasListener, isFalse);
    expect(releases, 1);
  });

  testWidgets('stream failure uses the existing error component', (
    tester,
  ) async {
    final controller = StreamController<String>();
    addTearDown(controller.close);
    await tester.pumpWidget(_shell(LogTerminal(stream: controller.stream)));
    controller.addError(const FailureHttp(403));
    await tester.pump();
    expect(find.text('令牌授权范围不足'), findsOneWidget);
    await tester.pumpWidget(_shell(const SizedBox()));
  });

  testWidgets('new lines follow the end; replacing a stream releases it', (
    tester,
  ) async {
    var releases = 0;
    final first = StreamController<String>();
    final second = StreamController<String>();
    addTearDown(first.close);
    addTearDown(second.close);
    await tester.pumpWidget(
      _shell(
        LogTerminal(
          lines: List.generate(80, (index) => 'line $index'),
          stream: first.stream,
          onCancel: () => releases++,
        ),
      ),
    );
    await tester.pump();
    first.add('last line');
    await tester.pump();
    await tester.pump();
    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.controller!.offset, list.controller!.position.minScrollExtent);

    await tester.pumpWidget(
      _shell(LogTerminal(stream: second.stream, onCancel: () => releases++)),
    );
    await tester.pump();
    expect(first.hasListener, isFalse);
    expect(second.hasListener, isTrue);
    expect(releases, 1);
    second.add('new source');
    await tester.pump();
    expect(find.text('new source'), findsOneWidget);
    await tester.pumpWidget(_shell(const SizedBox()));
    await tester.pump();
    expect(second.hasListener, isFalse);
    expect(releases, 2);
  });

  testWidgets('mixed line heights still reveal the newest line', (
    tester,
  ) async {
    final source = StreamController<String>();
    addTearDown(source.close);
    await tester.pumpWidget(
      _shell(
        LogTerminal(
          lines: List.generate(
            100,
            (index) => index < 50 ? 'short $index' : 'x' * 2000,
          ),
          stream: source.stream,
        ),
      ),
    );
    await tester.pump();
    source.add('FINAL_VISIBLE_LINE');
    await tester.pump();
    await tester.pump();
    expect(find.text('FINAL_VISIBLE_LINE'), findsOneWidget);
    final text = tester.getRect(find.text('FINAL_VISIBLE_LINE'));
    final viewport = tester.getRect(find.byType(ListView));
    expect(viewport.overlaps(text), isTrue);
    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.controller!.offset, list.controller!.position.minScrollExtent);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(_shell(const SizedBox()));
  });
}
