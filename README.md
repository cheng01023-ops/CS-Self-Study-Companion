# CS 自学

面向 Mac 零基础自学者的 iOS 17+ / macOS 14+ 学习 App，覆盖终端、计算机通识、C 语言、Linux、数学与计算理论、数据结构、系统编程、网络、编译原理、数据库和方向专精。

项目使用 SwiftUI、SwiftData 和 XCTest，同一套 Xcode 工程同时构建 iOS 与 macOS 版本。

## 功能概览

- 13 个学习阶段、28 篇分步教程、89 条外部免费资源和 52 个概念
- 每篇教程带六步可验证实验课：目标、预测、准备、执行、验证、复盘
- 六轨真实工程阶梯：C/Linux、系统并发、网络服务、数据存储、编译语言和 Apple 平台
- 六级开源代码阅读阶梯：coreutils、jq、Git、curl、Redis、SQLite、Nginx、Linux、LLVM 和 Swift
- Markdown 教程、代码高亮、收藏和笔记
- C 代码工作台、测试用例和自动判题
- iPhone 通过局域网 Mac Companion 远程编译运行代码
- 错题本、主动回忆、教回去五维评估和 1/3/7/30 天复习
- 代码阅读、错误定位和输出预测训练
- 项目制课程、互动实验室、逻辑/自动机/概率/复杂度实验室和项目作品集
- 全局搜索、命令速查和 Linux 命令参考
- 知识依赖图谱驱动的自适应学习路线，自动识别可开始、建议复习和需要补桥的内容
- 工程验收工作台，支持目录扫描、结构检查、构建命令运行和 Markdown 报告
- 动态练习、薄弱概念优先、掌握度热力图和间隔训练回流
- 进度、掌握度、每日计划和提醒
- Mac ↔ iPhone 记录级增量同步
- JSON/AES-GCM 数据备份、课程包导入导出和更新历史
- 可选的 CloudKit 跨网络同步能力检测
- Spotlight、Handoff、深链接和无障碍支持

## 环境要求

- macOS 14 或更高版本
- Xcode 15 或更高版本
- iOS 17 或更高版本
- 可选：已配对的 iPhone，用于真机测试和无线安装

## 首次配置

1. 用 Xcode 打开 `CSSelfStudyCompanion.xcodeproj`。
2. 选择 `CSSelfStudyCompanion` Target。
3. 在 `Signing & Capabilities` 中选择自己的 Apple ID 和 Personal Team。
4. 把 Bundle Identifier 从 `com.example.CSXuexi` 改成自己在全球唯一的 ID。
5. 如果需要 CloudKit，配置 iCloud Container 和相应 Entitlement。
6. 选择 macOS 或 iPhone 后运行。

仓库没有包含证书、描述文件、IPA、App 包、DerivedData、学习数据或本机日志。

## 构建和测试

```bash
./scripts/build-macos.sh
./scripts/test-macos.sh
./scripts/build-ios.sh
./scripts/run-tests.sh
```

## 安装到 iPhone

首次安装需要数据线和信任：

1. 解锁 iPhone。
2. 连接 Mac 并信任此电脑。
3. 开启“设置 → 隐私与安全性 → 开发者模式”。
4. 运行：

```bash
./scripts/renew-and-install-iphone.sh
```

配对完成后，只要 Mac 和 iPhone 在同一 Wi-Fi、iPhone 已解锁，脚本即可通过局域网重新签名、构建、安装和启动，不需要一直插数据线。

Personal Team 免费签名通常每 7 天需要重新续签。

## 项目结构

```text
CSSelfStudyCompanion.xcodeproj   Xcode 工程
CSSelfStudyCompanion/            App 源码、课程内容和资源
CSSelfStudyCompanionTests/       macOS/iOS 单元测试
CSSelfStudyCompanionUITests/     iOS UI 测试
docs/                            架构、使用指南、测试和发布文档
design/                          App 图标和设计源文件
scripts/                         构建、测试、安装和发布脚本
.github/workflows/               GitHub Actions
```

## 数据与隐私

- 默认数据存储在本地 SwiftData 数据库。
- 局域网同步仅在用户设备之间传输。
- CloudKit 默认关闭，只有用户配置 Container 后才启用。
- 仓库不包含用户学习记录。
- 上传公开仓库前请先决定许可证，并检查自己的 Bundle ID、CloudKit 和品牌信息。

## 开发状态

- macOS 自动化测试：59 个通过
- iOS 单元测试：56 个通过
- iOS UI 测试：8 个通过

详细内容见 [`docs/USER-GUIDE.md`](docs/USER-GUIDE.md)、[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) 和 [`docs/TEST-REPORT.md`](docs/TEST-REPORT.md)。

## 许可证

仓库尚未附带开源许可证。在公开分发或允许他人复用代码前，请添加合适的 `LICENSE`。
