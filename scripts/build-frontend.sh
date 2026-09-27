#!/bin/bash
# 前端构建脚本
# 用于构建前端生产版本

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRONTEND_DIR="$ROOT_DIR/evui"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 显示帮助信息
show_help() {
    echo ""
    echo "=========================================="
    echo "    前端构建脚本 - build-frontend.sh"
    echo "=========================================="
    echo ""
    echo "用法:"
    echo "  ./scripts/build-frontend.sh [mode] [--help]"
    echo "  make build [MODE=prod]"
    echo ""
    echo "参数:"
    echo "  mode           构建模式: dev, test, preview, prod (默认: prod)"
    echo "  --help, -h    显示此帮助信息"
    echo ""
    echo "功能:"
    echo "  构建前端生产版本，输出到 public/ 目录"
    echo ""
    echo "示例:"
    echo "  ./scripts/build-frontend.sh prod"
    echo "  ./scripts/build-frontend.sh test"
    echo "  make build MODE=prod"
    echo ""
}

# 检查帮助参数
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

MODE=${1:-prod}

echo ""
echo "=========================================="
echo "    前端构建"
echo "=========================================="
echo ""

# 检查前端目录
if [ ! -d "$FRONTEND_DIR" ]; then
    echo -e "${RED}错误: 前端目录不存在: $FRONTEND_DIR${NC}"
    exit 1
fi

cd "$FRONTEND_DIR"

# 检查 package.json
if [ ! -f "package.json" ]; then
    echo -e "${RED}错误: package.json 不存在${NC}"
    exit 1
fi

# 检查 node_modules
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}警告: node_modules 不存在，正在安装依赖...${NC}"
    npm install
fi

# 检查 npm 命令
if ! command -v npm &> /dev/null; then
    echo -e "${RED}错误: npm 未安装${NC}"
    exit 1
fi

# 根据模式选择构建命令
case "$MODE" in
    dev|development)
        BUILD_CMD="npm run build:dev"
        MODE_DESC="开发环境"
        ;;
    test)
        BUILD_CMD="npm run build:test"
        MODE_DESC="测试环境"
        ;;
    preview)
        BUILD_CMD="npm run build:preview"
        MODE_DESC="预览环境"
        ;;
    prod|production)
        BUILD_CMD="npm run build:prod"
        MODE_DESC="生产环境"
        ;;
    *)
        echo -e "${RED}错误: 无效的构建模式: $MODE${NC}"
        echo "可用模式: dev, test, preview, prod"
        exit 1
        ;;
esac

echo -e "${BLUE}构建模式: ${MODE_DESC}${NC}"
echo -e "${BLUE}构建命令: ${BUILD_CMD}${NC}"
echo ""

# 执行构建
echo -e "${YELLOW}开始构建...${NC}"
if $BUILD_CMD; then
    echo ""
    echo -e "${GREEN}✓ 构建完成${NC}"
    
    # 检查输出目录
    OUTPUT_DIR=$(grep -A 5 "outputDir" vue.config.js 2>/dev/null | grep -o "'[^']*'" | head -1 | tr -d "'" || echo "../public/adminadmin")
    if [ -d "$FRONTEND_DIR/$OUTPUT_DIR" ] || [ -d "$ROOT_DIR/$OUTPUT_DIR" ]; then
        if [ -d "$ROOT_DIR/$OUTPUT_DIR" ]; then
            OUTPUT_PATH="$ROOT_DIR/$OUTPUT_DIR"
        else
            OUTPUT_PATH="$FRONTEND_DIR/$OUTPUT_DIR"
        fi
        
        OUTPUT_SIZE=$(du -sh "$OUTPUT_PATH" 2>/dev/null | cut -f1 || echo "未知")
        echo -e "${GREEN}  输出目录: $OUTPUT_PATH${NC}"
        echo -e "${GREEN}  输出大小: $OUTPUT_SIZE${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}提示:${NC}"
    echo "  构建文件已输出到 public/ 目录"
    echo "  请确保 Web 服务器配置正确指向该目录"
    echo ""
else
    echo ""
    echo -e "${RED}✗ 构建失败${NC}"
    exit 1
fi
