# Flutter 本地日历 App（MVP）

本项目是一个纯本地离线日历 App：

- Flutter + Dart
- Riverpod 状态管理
- Isar 本地数据库
- flutter_local_notifications 本地通知
- 默认中文界面
- 支持深色模式（跟随系统）

## 已实现功能（MVP）

1. 首页默认月历视图
2. 月视图 / 周视图切换
3. 点击日期查看当天日程
4. 日程新增、编辑、删除
5. 日程字段：标题、备注、开始时间、结束时间、全天、提醒时间、分类
6. 数据完全本地存储，离线可用，无登录、无云同步、无后端

## 目录结构

```text
lib/
  database/
    isar_database.dart
  models/
    schedule_item.dart
  pages/
    home_page.dart
    schedule_form_page.dart
  providers/
    app_providers.dart
  services/
    notification_service.dart
    schedule_service.dart
  widgets/
    empty_schedule_view.dart
    schedule_list_item.dart
  main.dart
```

## 先决条件

请先在本机安装：

1. Flutter SDK（并确保 `flutter` 命令可用）
2. Android Studio（含 Android SDK / 模拟器）

## 运行步骤

> 如果当前目录还没有标准 Flutter 原生目录（如 `android/`），先执行：

```bash
flutter create --platforms=android .
```

然后执行：

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

## Android 权限配置（通知）

在 `android/app/src/main/AndroidManifest.xml` 的 `<manifest>` 下添加：

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

## 在 Android Studio 中运行

1. 打开 Android Studio，选择 `Open`，打开本项目目录。
2. 等待 Gradle / Flutter 索引完成。
3. 连接 Android 手机（开启 USB 调试）或启动模拟器。
4. 运行入口选择 `lib/main.dart`。
5. 点击运行按钮（或 `Shift + F10`）。

## 打包 APK（Release）

```bash
flutter build apk --release
```

产物路径：

```text
build/app/outputs/flutter-apk/app-release.apk
```

## 说明

- Isar 使用代码生成，首次拉起必须执行 `build_runner` 命令。
- 当前版本为纯本地单机版，不包含任何网络或云端依赖。
