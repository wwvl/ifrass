import 'package:cna/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// AppConfig 契约：baseUrl 是 app 侧唯一一份（AGENTS.md §5），取值必须
/// 对齐 AGENTS.md §0「后端唯一事实源：https://api.cnb.cool」；
/// 超时 / 退避集中配置；`useFakeApi` 生产默认 false（remote）。
void main() {
  test('baseUrl 锁定为 api.cnb.cool 且结尾无 /', () {
    expect(AppConfig.apiBaseUrl, 'https://api.cnb.cool');
    expect(AppConfig.apiBaseUrl.endsWith('/'), isFalse);
  });

  test('三类超时齐备且为正（禁止散落魔法数字）', () {
    expect(AppConfig.connectTimeout, greaterThan(Duration.zero));
    expect(AppConfig.sendTimeout, greaterThan(Duration.zero));
    expect(AppConfig.receiveTimeout, greaterThan(Duration.zero));
    expect(AppConfig.receiveTimeout, greaterThan(AppConfig.connectTimeout));
  });

  test('重试退避基数为正；useFakeApi 生产默认 false', () {
    expect(AppConfig.retryBackoffBase, greaterThan(Duration.zero));
    expect(AppConfig.useFakeApi, isFalse);
  });
}
