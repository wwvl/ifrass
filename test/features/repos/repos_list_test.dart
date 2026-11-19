import 'package:cna/core/error/failure.dart';
import 'package:cna/core/network/pagination.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 可编程假列表：errors 队列非空时 fetch 依序抛出；
/// 否则按 page 返回确定数据（`page*100 .. page*100+pageSize-1`）。
/// static 队列：riverpod 3 每次 build 重建 notifier 实例，实例字段会丢。
class _SequencedList extends PagedListNotifier<int> {
  static final List<Failure> errors = <Failure>[];

  @override
  Future<PagedListState<int>> build() {
    registerDisposeGuard();
    return loadFirstPage();
  }

  @override
  Future<List<int>> fetch(int page, String? search) async {
    if (errors.isNotEmpty) {
      throw errors.removeAt(0);
    }
    final start = page * 100;
    return List<int>.generate(pageSize, (i) => start + i);
  }
}

void main() {
  late ProviderContainer container;

  setUp(() {
    _SequencedList.errors.clear();
    container = ProviderContainer.test(
      retry: (_, _) => null, // AGENTS.md §5：自动重试关闭，error 态稳定断言
    );
    addTearDown(container.dispose);
  });

  AsyncNotifierProvider<_SequencedList, PagedListState<int>> buildProvider() =>
      AsyncNotifierProvider<_SequencedList, PagedListState<int>>(
        _SequencedList.new,
      );

  test('首屏 build → data（20 条 = pageSize）+ hasMore=true', () async {
    final provider = buildProvider();

    await container.read(provider.future);

    final state = container.read(provider).value!;
    expect(state.items, hasLength(20));
    expect(state.items.first, 100); // page 1 → 100..119
    expect(state.hasMore, isTrue);
    expect(state.search, isNull);
    expect(state.loadMoreFailed, isFalse);
  });

  test('首屏失败 → AsyncError（AsyncStateHost error 态数据源）', () async {
    _SequencedList.errors.add(const FailureHttp(403, body: 'denied'));
    final provider = buildProvider();

    await expectLater(container.read(provider.future), throwsA(isA<Failure>()));

    expect(container.read(provider).error, isA<FailureHttp>());
  });

  test('loadMore：追加 page2（20 条）', () async {
    final provider = buildProvider();
    await container.read(provider.future);

    await container.read(provider.notifier).loadMore();

    final state = container.read(provider).value!;
    expect(state.items, hasLength(40)); // page1 20 + page2 20
    expect(state.items[20], 200); // page2 从 200 起
    expect(state.loadMoreFailed, isFalse);
  });

  test('loadMore 失败：置 loadMoreFailed 且列表保留；重试成功恢复', () async {
    final provider = buildProvider();
    await container.read(provider.future);

    final notifier = container.read(provider.notifier);
    _SequencedList.errors.add(const FailureNetwork(message: 'down'));
    await expectLater(notifier.loadMore(), throwsA(isA<FailureNetwork>()));

    final failed = container.read(provider).value!;
    expect(failed.items, hasLength(20)); // 列表保留
    expect(failed.loadMoreFailed, isTrue);

    await notifier.loadMore(); // footer 重试（errors 已空）成功
    final recovered = container.read(provider).value!;
    expect(recovered.items, hasLength(40));
    expect(recovered.loadMoreFailed, isFalse);
  });

  test('refresh 失败：旧列表保留（下拉刷新不掉数据）', () async {
    final provider = buildProvider();
    await container.read(provider.future);
    final before = container.read(provider).value!;

    _SequencedList.errors.add(const FailureNetwork(message: 'flap'));
    await expectLater(
      container.read(provider.notifier).refresh(),
      throwsA(isA<FailureNetwork>()),
    );

    final after = container.read(provider).value!;
    expect(after.items, before.items); // 旧列表保留
    expect(after.loadMoreFailed, before.loadMoreFailed);
  });

  test('epoch 竞态：慢搜索响应被新搜索取代后丢弃', () async {
    final provider = buildProvider();
    await container.read(provider.future);

    final notifier = container.read(provider.notifier);
    final slowFuture = notifier.search('slow');
    await notifier.search('fast');

    expect(container.read(provider).value!.search, 'fast');

    // 慢搜索「迟到」：其结果被 epoch 丢弃，状态仍是 fast
    await slowFuture;
    expect(container.read(provider).value!.search, 'fast');
  });

  test('search 失败 → AsyncError（AsyncStateHost 呈现；search 不上抛）', () async {
    final provider = buildProvider();
    await container.read(provider.future);

    _SequencedList.errors.add(const FailureNetwork(message: 'down'));
    await container.read(provider.notifier).search('anything');

    expect(container.read(provider).error, isA<FailureNetwork>());
    // riverpod 3 语义：AsyncError 保留旧值（hasValue true + hasError true）；
    // AsyncStateHost 的 phase 判定 hasError 优先 → error 态稳定呈现
    expect(container.read(provider).hasValue, isTrue);
  });

  test('dispose 后迟到的响应不写回状态也不抛异常', () async {
    final provider = buildProvider();
    final stateFuture = container.read(provider.future);

    container.dispose(); // dispose guard：_seq 失效
    await stateFuture; // build 的响应正常落定（dispose 前发起）
  });
}
