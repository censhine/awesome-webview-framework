# Awesome WebView Framework

一个轻量级的 WebView 壳应用框架，同时支持 **iOS** 和 **macOS (Apple Silicon / Intel)**。

## 项目简介

本项目提供了一个基于 SwiftUI + WKWebView 的 WebView 壳应用解决方案，可以快速将响应式网页打包为原生 iOS / macOS 应用。支持 URL 可配置、持久化存储、加载状态指示、错误重试、外部链接自动跳转等特性。

## 目录结构

```
.
├── README.md                 # 项目说明文档
├── .gitignore                # Git 忽略规则
├── docs/                     # 文档目录
│   ├── WebViewApp-Guide.md   # WebViewApp 详细指南
│   └── codebase-memory-mcp-guide.md  # 代码库记忆 MCP 指南
└── WebViewApp/               # WebViewApp 应用源码
    ├── README.md             # 应用说明文档
    ├── build.sh              # 构建脚本
    ├── generate_icon.py      # 图标生成脚本
    ├── project.yml           # 项目配置
    ├── WebViewApp.xcodeproj/ # Xcode 项目文件
    └── WebViewApp/           # 源代码
        ├── WebViewAppApp.swift   # 应用入口
        ├── ContentView.swift     # 主界面 + WebView
        ├── SettingsView.swift    # 设置页面
        ├── Info.plist            # 应用配置
        └── Assets.xcassets/      # 资源文件
```

## 功能特性

- 🌐 内嵌 WKWebView，加载响应式网页
- ⚙️ 可配置 URL 地址，持久化存储
- 🔄 加载状态指示器
- ❌ 错误处理与重试功能
- 🔗 外部链接自动在系统浏览器中打开
- 📱 支持 iOS 16+ / macOS 13+
- 🖥️ 支持 Mac Catalyst（iPad 应用在 Mac 上运行）

## 快速开始

### 方式一：Xcode 打开（推荐）

```bash
# 1. 打开项目
open WebViewApp/WebViewApp.xcodeproj

# 2. 在 Xcode 中选择目标设备（iPhone / My Mac）
# 3. 点击运行按钮 (⌘R)
```

### 方式二：命令行构建

```bash
cd WebViewApp

# 构建 macOS 版本
./build.sh macos

# 构建 iOS 模拟器版本
./build.sh ios

# 构建 iOS 设备版本（无签名）
./build.sh ios-device

# 构建所有平台
./build.sh all
```

## 系统要求

- **Xcode**: 15.0+
- **iOS**: 16.0+
- **macOS**: 13.0+ (Ventura)
- **Swift**: 5.9+

## 技术栈

| 技术 | 说明 |
|------|------|
| **SwiftUI** | 声明式 UI 框架 |
| **WKWebView** | 原生高性能 WebView |
| **@AppStorage** | UserDefaults 持久化 |
| **Mac Catalyst** | iOS 应用直接运行在 macOS |

## 使用说明

1. **启动应用** - 默认加载 `http://47.115.132.109:8081/`
2. **修改 URL** - 点击右上角 ⚙️ 齿轮按钮进入设置
3. **保存设置** - 输入新的 URL 地址，点击"保存并应用"
4. **恢复默认** - 在设置页面点击"恢复默认地址"

## License

MIT License
