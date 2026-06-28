#!/bin/bash
# WebViewApp 构建脚本
# 用法: ./build.sh [macos|ios|ios-device|all]

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_FILE="$PROJECT_DIR/WebViewApp.xcodeproj"
SCHEME="WebViewApp"
BUILD_DIR="$PROJECT_DIR/build"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     WebViewApp 构建工具 v1.0        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
echo ""

# 检查 Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}错误: 未找到 xcodebuild，请安装 Xcode${NC}"
    exit 1
fi

# 检查项目文件
if [ ! -d "$PROJECT_FILE" ]; then
    echo -e "${RED}错误: 未找到项目文件 $PROJECT_FILE${NC}"
    exit 1
fi

build_macos() {
    echo -e "${YELLOW}▶ 构建 macOS 版本...${NC}"
    
    xcodebuild \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME" \
        -configuration Release \
        -destination "platform=macOS" \
        -derivedDataPath "$BUILD_DIR" \
        build \
        | grep -E "(BUILD|error:|warning:|Compiling|Linking)" || true
    
    APP_PATH="$BUILD_DIR/Build/Products/Release/WebViewApp.app"
    
    if [ -d "$APP_PATH" ]; then
        echo -e "${GREEN}✓ macOS 构建成功!${NC}"
        echo -e "  应用路径: $APP_PATH"
        echo -e "  运行命令: open \"$APP_PATH\""
    else
        echo -e "${RED}✗ macOS 构建失败${NC}"
        return 1
    fi
}

build_ios_simulator() {
    echo -e "${YELLOW}▶ 构建 iOS 模拟器版本...${NC}"
    
    # 获取最新的 iPhone 模拟器
    SIMULATOR=$(xcrun simctl list devices available | grep "iPhone" | tail -1 | sed 's/.*(\(.*\)).*/\1/')
    
    if [ -z "$SIMULATOR" ]; then
        SIMULATOR="iPhone 15"
    fi
    
    echo -e "  使用模拟器: $SIMULATOR"
    
    xcodebuild \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME" \
        -configuration Release \
        -destination "platform=iOS Simulator,name=$SIMULATOR" \
        -derivedDataPath "$BUILD_DIR" \
        build \
        | grep -E "(BUILD|error:|warning:|Compiling|Linking)" || true
    
    APP_PATH="$BUILD_DIR/Build/Products/Release-iphonesimulator/WebViewApp.app"
    
    if [ -d "$APP_PATH" ]; then
        echo -e "${GREEN}✓ iOS 模拟器构建成功!${NC}"
        echo -e "  应用路径: $APP_PATH"
    else
        echo -e "${RED}✗ iOS 模拟器构建失败${NC}"
        return 1
    fi
}

build_ios_device() {
    echo -e "${YELLOW}▶ 构建 iOS 设备版本 (无签名)...${NC}"
    
    xcodebuild \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME" \
        -configuration Release \
        -destination "generic/platform=iOS" \
        -derivedDataPath "$BUILD_DIR" \
        CODE_SIGNING_ALLOWED=NO \
        build \
        | grep -E "(BUILD|error:|warning:|Compiling|Linking)" || true
    
    APP_PATH="$BUILD_DIR/Build/Products/Release-iphoneos/WebViewApp.app"
    
    if [ -d "$APP_PATH" ]; then
        echo -e "${GREEN}✓ iOS 设备构建成功!${NC}"
        echo -e "  应用路径: $APP_PATH"
        echo -e "  ${YELLOW}注意: 需要签名后才能安装到真机${NC}"
    else
        echo -e "${RED}✗ iOS 设备构建失败${NC}"
        return 1
    fi
}

clean() {
    echo -e "${YELLOW}▶ 清理构建目录...${NC}"
    rm -rf "$BUILD_DIR"
    echo -e "${GREEN}✓ 清理完成${NC}"
}

# 主逻辑
case "${1:-macos}" in
    macos)
        build_macos
        ;;
    ios)
        build_ios_simulator
        ;;
    ios-device)
        build_ios_device
        ;;
    all)
        build_macos
        echo ""
        build_ios_simulator
        echo ""
        build_ios_device
        ;;
    clean)
        clean
        ;;
    *)
        echo "用法: $0 [macos|ios|ios-device|all|clean]"
        echo ""
        echo "  macos       - 构建 macOS 版本 (默认)"
        echo "  ios         - 构建 iOS 模拟器版本"
        echo "  ios-device  - 构建 iOS 设备版本 (无签名)"
        echo "  all         - 构建所有平台"
        echo "  clean       - 清理构建目录"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}构建完成!${NC}"
