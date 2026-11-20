import 'dart:async';

import 'package:cna/core/error/failure.dart';
import 'package:cna/core/theme/app_tokens.dart';
import 'package:cna/shared/widgets/empty_view.dart';
import 'package:cna/shared/widgets/error_view.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// A bounded, monospace log view with optional owned stream subscription.
///
/// No network connection is created here. A later build feature may supply
/// [stream] and release its upstream resource through [onCancel].
class LogTerminal extends StatefulWidget {
  /// Creates a terminal from a snapshot and an optional source of new lines.
  const new({
    super.key,
    this.lines = const [],
    this.stream,
    this.onCancel,
    this.maxLines = 1000,
  }) : assert(maxLines > 0, 'maxLines must be positive');

  /// Initial log snapshot, replaced when the host supplies a new snapshot.
  final List<String> lines;

  /// Optional lines supplied by the host; the terminal owns its subscription.
  final Stream<String>? stream;

  /// Releases the host's source when stopped, replaced, or disposed.
  final FutureOr<void> Function()? onCancel;

  /// Maximum retained lines, so a future build log cannot grow without bounds.
  final int maxLines;

  @override
  State<LogTerminal> createState() => _LogTerminalState();
}

class _LogTerminalState extends State<LogTerminal> {
  final _scroll = ScrollController();
  final _lines = <String>[];
  StreamSubscription<String>? _subscription;
  Failure? _failure;
  bool _paused = false;
  bool _stopped = false;
  bool _scrollScheduled = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _replaceSnapshot();
    _listen();
    _scheduleScroll();
  }

  @override
  void didUpdateWidget(LogTerminal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lines != widget.lines) _replaceSnapshot();
    if (oldWidget.stream != widget.stream) {
      _detach(oldWidget.onCancel);
      _paused = false;
      _stopped = false;
      _failure = null;
      _listen();
    }
    _trim();
    _scheduleScroll();
  }

  void _replaceSnapshot() {
    _lines
      ..clear()
      ..addAll(widget.lines);
    _trim();
  }

  void _trim() {
    if (_lines.length > widget.maxLines) {
      _lines.removeRange(0, _lines.length - widget.maxLines);
    }
  }

  void _listen() {
    final source = widget.stream;
    if (source == null) return;
    final generation = ++_generation;
    _subscription = source.listen(
      (line) {
        if (!mounted || generation != _generation) return;
        setState(() {
          _lines.add(line);
          _trim();
        });
        _scheduleScroll();
      },
      onError: (Object error) {
        if (!mounted || generation != _generation) return;
        setState(() {
          _failure = error is Failure ? error : const FailureUnknown('日志订阅失败');
        });
      },
    );
  }

  void _detach(FutureOr<void> Function()? release) {
    _generation++;
    final subscription = _subscription;
    _subscription = null;
    if (subscription == null) return;
    unawaited(
      Future.wait<void>([
        subscription.cancel(),
        if (release != null) Future<void>.sync(release),
      ]),
    );
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    if (_paused) {
      _subscription?.pause();
    } else {
      _subscription?.resume();
      _scheduleScroll();
    }
  }

  void _stop() {
    _detach(widget.onCancel);
    setState(() {
      _paused = false;
      _stopped = true;
    });
  }

  void _scheduleScroll() {
    if (_paused || _scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (!mounted || _paused || !_scroll.hasClients) return;
      // A reversed list follows its exact zero extent even when wrapped lines
      // have not all been laid out; the far extent is only an estimate.
      _scroll.jumpTo(_scroll.position.minScrollExtent);
    });
  }

  @override
  void dispose() {
    _detach(widget.onCancel);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.tTheme.bgColorSecondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _stopped ? '日志已停止' : (_paused ? '日志已暂停' : '构建日志'),
                  style: AppTypography.label.copyWith(
                    color: context.tTheme.textColorSecondary,
                  ),
                ),
                TButton(
                  size: TButtonSize.large,
                  variant: TButtonVariant.text,
                  onPressed: _stopped ? null : _togglePause,
                  child: Text(_paused ? '继续' : '暂停'),
                ),
                TButton(
                  size: TButtonSize.large,
                  variant: TButtonVariant.text,
                  onPressed: _stopped ? null : _stop,
                  child: const Text('停止'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(child: _buildContent(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_failure case final failure?) return ErrorView(failure: failure);
    if (_lines.isEmpty) {
      return const EmptyView(title: '暂无日志', description: '构建输出会显示在这里。');
    }
    return SelectionArea(
      child: ListView.builder(
        controller: _scroll,
        reverse: true,
        itemCount: _lines.length,
        itemBuilder: (context, index) => Text(
          _lines[_lines.length - index - 1],
          style: AppTypography.code.copyWith(
            color: context.tTheme.textColorPrimary,
          ),
        ),
      ),
    );
  }
}
