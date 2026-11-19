# CI 门禁镜像：Flutter 3.47.9（AGENTS.md §1.0 基线，版本精确钉死）。
# SDK 走 storage.flutter-io.cn（国内可达）；只支撑 CLI 门禁
# （pub get / build_runner / analyze / test），不含 Android/iOS 工具链。
# Dockerfile 内容即缓存版本键：文件不变则流水线复用已构建镜像。
FROM ubuntu:22.04

ENV LANG=C.UTF-8 \
    PUB_HOSTED_URL=https://pub.flutter-io.cn \
    FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bash ca-certificates curl git xz-utils \
 && rm -rf /var/lib/apt/lists/*

# runner checkout 的工作区属主与容器内用户不一致时 git 会拒绝操作
# （freshness gate 的 git diff --exit-code 依赖 git 可用）
RUN git config --system --add safe.directory '*'

RUN curl -fsSL -o /tmp/flutter.tar.xz \
      https://storage.flutter-io.cn/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.9-stable.tar.xz \
 && tar -xJf /tmp/flutter.tar.xz -C /opt \
 && rm /tmp/flutter.tar.xz

ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# 首次 flutter 命令会补下载 Dart SDK 等工件：构建期预热，关遥测
RUN flutter --version \
 && flutter config --no-analytics \
 && dart --disable-analytics
