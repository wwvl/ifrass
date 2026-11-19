import 'package:cna/core/theme/app_tokens.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

/// 底部 Tab 占位页（M2 骨架；M3 按路由表替换为真实页面后删除本文件）。
class PlaceholderPage extends StatelessWidget {
  /// 创建占位页。
  const new({required this.title, super.key});

  /// 占位标题（对应路由表条目）。
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          title,
          style: AppTypography.title.copyWith(
            color: context.tTheme.textColorSecondary,
          ),
        ),
      ),
    );
  }
}
