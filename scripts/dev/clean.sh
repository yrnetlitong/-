#!/bin/bash
# 清理开发环境
# 清理日志、缓存、PID文件等

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 显示帮助信息
show_help() {
    echo ""
    echo "=========================================="
    echo "    开发环境清理脚本 - clean.sh"
    echo "=========================================="
    echo ""
    echo "用法:"
    echo "  ./scripts/dev/clean.sh [type] [--help]"
    echo "  make dev-clean [TYPE=logs|cache|all]"
    echo ""
    echo "参数:"
    echo "  type          清理类型: logs, cache, pid, all (默认: all)"
    echo "  --help, -h    显示此帮助信息"
    echo ""
    echo "功能:"
    echo "  logs          清理日志文件 (.backend.log, .frontend.log)"
    echo "  cache         清理缓存 (runtime/cache, runtime/temp)"
    echo "  pid           清理PID文件 (.backend.pid, .frontend.pid)"
    echo "  all           清理所有（默认）"
    echo ""
    echo "示例:"
    echo "  ./scripts/dev/clean.sh logs"
    echo "  ./scripts/dev/clean.sh cache"
    echo "  make dev-clean TYPE=all"
    echo ""
}

# 检查帮助参数
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

TYPE=${1:-all}

echo ""
echo "=========================================="
echo "    清理开发环境"
echo "=========================================="
echo ""

cd "$ROOT_DIR"

# 清理日志
if [[ "$TYPE" == "logs" ]] || [[ "$TYPE" == "all" ]]; then
    echo -e "${YELLOW}清理日志文件...${NC}"
    
    if [ -f ".backend.log" ]; then
        rm -f .backend.log
        echo -e "${GREEN}✓ 已删除 .backend.log${NC}"
    fi
    
    if [ -f ".frontend.log" ]; then
        rm -f .frontend.log
        echo -e "${GREEN}✓ 已删除 .frontend.log${NC}"
    fi
    
    # 清理PHP错误日志
    if [ -d "runtime/log" ]; then
        find runtime/log -name "*.log" -type f -mtime +7 -delete 2>/dev/null || true
        echo -e "${GREEN}✓ 已清理7天前的PHP日志${NC}"
    fi
fi

# 清理缓存
if [[ "$TYPE" == "cache" ]] || [[ "$TYPE" == "all" ]]; then
    echo -e "${YELLOW}清理缓存...${NC}"
    
    if [ -d "runtime/cache" ]; then
        rm -rf runtime/cache/*
        echo -e "${GREEN}✓ 已清理 runtime/cache${NC}"
    fi
    
    if [ -d "runtime/temp" ]; then
        rm -rf runtime/temp/*
        echo -e "${GREEN}✓ 已清理 runtime/temp${NC}"
    fi
    
    # 清理前端缓存
    if [ -d "evui/node_modules/.cache" ]; then
        rm -rf evui/node_modules/.cache
        echo -e "${GREEN}✓ 已清理前端构建缓存${NC}"
    fi
fi

# 清理PID文件
if [[ "$TYPE" == "pid" ]] || [[ "$TYPE" == "all" ]]; then
    echo -e "${YELLOW}清理PID文件...${NC}"
    
    if [ -f ".backend.pid" ]; then
        rm -f .backend.pid
        echo -e "${GREEN}✓ 已删除 .backend.pid${NC}"
    fi
    
    if [ -f ".frontend.pid" ]; then
        rm -f .frontend.pid
        echo -e "${GREEN}✓ 已删除 .frontend.pid${NC}"
    fi
fi

echo ""
echo -e "${GREEN}✓ 清理完成${NC}"
echo ""
