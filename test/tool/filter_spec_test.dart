import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/filter_spec.dart' as fs;

/// 最小 fixture：p1 命中 Users 并引用 RepoList→Repo 闭包；
/// p2 tags 不在白名单；p3 只有 path 级 parameters；
/// Unused 是孤立 definition，应被裁掉。
Map<String, dynamic> _fixture() => <String, dynamic>{
  'swagger': '2.0',
  'paths': <String, dynamic>{
    '/repos': <String, dynamic>{
      'get': <String, dynamic>{
        'tags': <String>['Users'],
        'responses': <String, dynamic>{
          '200': <String, dynamic>{
            'schema': <String, dynamic>{r'$ref': '#/definitions/RepoList'},
          },
        },
      },
    },
    '/other': <String, dynamic>{
      'get': <String, dynamic>{
        'tags': <String>['Other'],
        'responses': <String, dynamic>{},
      },
    },
    '/only-params': <String, dynamic>{'parameters': <dynamic>[]},
  },
  'definitions': <String, dynamic>{
    'RepoList': <String, dynamic>{
      'properties': <String, dynamic>{
        'items': <String, dynamic>{
          'type': 'array',
          'items': <String, dynamic>{r'$ref': '#/definitions/Repo'},
        },
      },
    },
    'Repo': <String, dynamic>{
      'properties': <String, dynamic>{
        'name': <String, dynamic>{'type': 'string'},
      },
    },
    'Unused': <String, dynamic>{
      'properties': <String, dynamic>{
        'x': <String, dynamic>{'type': 'string'},
      },
    },
  },
};

void main() {
  group('trimSpec', () {
    test(r'按白名单裁剪 paths 并保留 $ref 传递闭包', () {
      final doc = _fixture();
      final outcome = fs.trimSpec(doc: doc, whitelist: <String>['Users']);

      expect(outcome.missingTags, isEmpty);
      expect(outcome.originalPaths, 3);
      expect(outcome.keptPaths, 1);
      expect(outcome.keptOperations, 1);
      expect(outcome.originalDefinitions, 3);
      expect(outcome.keptDefinitions, 2);
      expect((doc['paths'] as Map).keys, <String>['/repos']);
      expect((doc['definitions'] as Map).keys.toSet(), <String>{
        'RepoList',
        'Repo',
      });
    });

    test('命中的 operation 的 tags 收敛为白名单子集（防生成器多归组）', () {
      final doc = _fixture();
      final op = ((doc['paths'] as Map)['/repos'] as Map)['get'] as Map;
      op['tags'] = <String>['Other', 'Users'];

      fs.trimSpec(doc: doc, whitelist: <String>['Users']);

      expect(op['tags'], <String>['Users']);
    });

    test('白名单未命中项进入 missingTags（main 层负责非零退出）', () {
      final doc = _fixture();
      final outcome = fs.trimSpec(
        doc: doc,
        whitelist: <String>['Users', 'Ghost'],
      );

      expect(outcome.missingTags, <String>['Ghost']);
    });

    test('大小写不敏感匹配且保留原始大小写', () {
      final doc = _fixture();
      final op = ((doc['paths'] as Map)['/repos'] as Map)['get'] as Map;
      op['tags'] = <String>['USERS'];

      final outcome = fs.trimSpec(doc: doc, whitelist: <String>['users']);

      expect(outcome.missingTags, isEmpty);
      expect(outcome.matchedTags, <String>{'USERS'});
      expect(op['tags'], <String>['USERS']);
    });

    test('同一输入两次裁剪输出完全一致（幂等）', () {
      final first = fs.trimSpec(doc: _fixture(), whitelist: <String>['Users']);
      final second = fs.trimSpec(doc: _fixture(), whitelist: <String>['Users']);

      expect(jsonEncode(first.doc), jsonEncode(second.doc));
      expect(first.keptPaths, second.keptPaths);
      expect(first.keptDefinitions, second.keptDefinitions);
    });
  });
}
