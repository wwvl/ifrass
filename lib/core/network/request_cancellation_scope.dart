import 'dart:async';

import 'package:dio/dio.dart';

/// Carries a page-owned cancellation token through an async repository call.
///
/// The shared `PagedListNotifier` wraps its fetch callback in this scope. Data
/// sources can consume the token without changing the existing presentation
/// notifier method signature.
abstract final class RequestCancellationScope {
  static final Object _zoneKey = Object();

  /// The active page request token, if the current async call has one.
  static CancelToken? get currentToken =>
      Zone.current[_zoneKey] as CancelToken?;

  /// Runs [action] with [token] available to downstream data sources.
  static Future<T> run<T>(CancelToken token, Future<T> Function() action) =>
      runZoned<Future<T>>(action, zoneValues: {_zoneKey: token});
}
