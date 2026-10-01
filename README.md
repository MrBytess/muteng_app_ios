# 木藤影视 iOS（Flutter）

基于 Flutter 的 iOS 影视客户端，功能与 uni-app 版（`mutengapp_uniapp`）对齐：首页 Banner + 分类 Tab、搜索、播放历史、收藏、个人中心、播放器（分集 / 进度记录 / 收藏）。

## 环境要求

| 工具 | 最低版本 | 说明 |
|------|----------|------|
| Flutter SDK | 3.10+ | 支持 iOS 的最新版即可 |
| Xcode | 15+ | 构建 iOS 应用 |
| CocoaPods | 1.12+ | 依赖管理 |
| iOS 模拟器 | 14+ | 开发调试用 |

## 首次初始化

`ios/` 平台文件已包含在仓库中（`Runner.xcodeproj`、`Info.plist`、`Podfile` 等），可直接打开。

如果后续需要重新生成或同步 Xcode 工程（例如升级 Flutter 版本后），可执行：

```bash
cd muteng_app_ios
flutter create --platforms=ios .
```

## 获取依赖

```bash
flutter pub get

# iOS 端还需要 CocoaPods 安装依赖
cd ios
pod install
```

## 运行到 iOS 模拟器

```bash
# 查看可用设备
flutter devices

# 运行到 iOS 模拟器
flutter run --no-cached
```

或直接在 Xcode 中打开 `ios/Runner.xcodeproj`，选择模拟器 Target 后 Cmd+R。

## 运行到 iPhone 真机

```bash
# 1. 连接 iPhone（开启开发者模式）
# 2. 查看设备
flutter devices

# 3. 指定设备运行
flutter run -d <device-id>
```

> **真机签名说明**：默认使用 Apple 免费开发者账号，需先在 Xcode 中配置 Signing Team，或在 `ios/Runner.xcodeproj` 的 Build Settings 中设置 `DEVELOPMENT_TEAM`。

## 构建 Release 包（.ipa）

```bash
# 1. 构建
flutter build ios --release

# 2. 归档到 Xcode Archive，导出 .ipa
#    Product → Archive → Distribute App → Custom → Export
```

## 项目结构

```
muteng_app_ios/
├── pubspec.yaml                 # 依赖配置
├── analysis_options.yaml        # lint 规则
├── .gitignore
├── lib/                         # Dart 源码
│   ├── main.dart                # 入口（初始化 LocalStorage → RootShell）
│   ├── root_shell.dart          # 底部 TabBar（首页 / 历史 / 我的）
│   ├── app_theme.dart           # 设计常量（AppColors / AppSize）
│   ├── api/
│   │   └── api_client.dart      # HTTP 客户端（https://film.mutengyy.site，15s 超时）
│   ├── storage/
│   │   └── local_storage.dart   # SharedPreferences 封装
│   ├── models/
│   │   ├── movie.dart           # 影片模型（搜索 / 豆瓣双 source 映射）
│   │   ├── history_item.dart    # 观看历史条目
│   │   ├── collect_item.dart    # 收藏条目
│   │   ├── banner_item.dart     # Banner 条目
│   │   └── mp_item.dart         # 小程序条目
│   └── pages/
│       ├── index_page.dart      # 首页（Banner + 分类 Tab + 影片网格）
│       ├── search_page.dart     # 搜索（片类型 Tab + 数据源 Tab + 结果列表）
│       ├── history_page.dart    # 播放历史（时间分组 + 进度条）
│       ├── collect_page.dart    # 收藏（双 key + 取消收藏）
│       ├── mine_page.dart       # 个人中心（快捷功能 + 小程序 + 退出登录）
│       ├── player_page.dart     # 播放器（分集 50/Tab + 历史防抖 + 收藏）
│       ├── login_page.dart      # 登录页（无需登录，直接进入）
│       └── register_page.dart   # 注册页（暂无注册功能）
└── ios/                         # Xcode 平台文件
    ├── Podfile
    ├── Runner.xcodeproj/
    │   └── project.pbxproj      # Xcode 工程文件
    ├── Flutter/
    │   ├── Debug.xcconfig
    │   └── Release.xcconfig
    ├── Runner/
    │   ├── AppDelegate.h / .m / .swift
    │   ├── main.m
    │   ├── Info.plist
    │   ├── Runner.entitlements
    │   ├── Runner-Bridging-Header.h
    │   ├── Assets.xcassets/
    │   │   └── AppIcon.appiconset/Contents.json
    │   ├── Base.lproj/
    │   │   ├── LaunchScreen.storyboard
    │   │   └── Main.storyboard
    │   ├── GeneratedPluginRegistrant.h / .m
    │   └── RunnerTests/
    │       └── RunnerTests.m
    └── RunnerTests/
        └── RunnerTests.m
```

## 主要依赖说明

| 包 | 用途 |
|---|---|
| `http` | 网络请求（API 调用） |
| `shared_preferences` | 本地持久化（历史 / 收藏 / 搜索历史） |
| `video_player` | 视频播放 |
| `cached_network_image` | 图片缓存（海报 / Banner） |
| `intl` | 日期格式化 |

## API 端点

| 端点 | 用途 |
|------|------|
| `/douban/search` | 首页 Banner + 影片列表 |
| `/douban/tags` | 子分类标签 |
| `/api/search` | 搜索（`source: aggregated`） |
| `/api/detail` | 详情分集 + 视频信息 |
| `/mp` | 小程序列表 |
| `/proxy/image-proxy` | 图片代理 |

Base URL：`https://film.mutengyy.site`

## 常见问题

**Q：`flutter create .` 报错？**
确保在 `muteng_app_ios/` 目录内执行，不要有多余的空格或大小写问题。

**Q：真机安装失败 / 签名错误？**
在 Xcode → Signing & Capabilities 中选择你的 Team，或临时使用 "Sign to Run Locally"。

**Q：视频无法播放？**
确认视频 URL 可访问（`/api/detail` 返回的 `episodes` 列表），iOS 支持 `http/https` 流媒体播放；若使用 `HLS`，`video_player` 原生支持。

**Q：依赖拉取失败？**
检查网络后重试；或配置代理 `flutter pub get --verbose`。
