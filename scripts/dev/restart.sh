#!/bin/bash
# 重启开发环境服务
# 用法: ./restart.sh [backend|frontend|all] [--help]

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
    echo "    开发环境重启脚本 - restart.sh"
    echo "=========================================="
    echo ""
    echo "用法:"
    echo "  ./scripts/dev/restart.sh [service]"
    echo "  make dev-restart [SERVICE=backend]"
    echo ""
    echo "参数:"
    echo "  service       服务名称: backend, frontend, all (默认: all)"
    echo "  --help, -h    显示此帮助信息"
    echo ""
    echo "功能:"
    echo "  backend       重启 PHP 后端"
    echo "  frontend      重启 Vue 前端"
    echo "  all           重启所有服务"
    echo ""
    echo "示例:"
    echo "  ./scripts/dev/restart.sh backend"
    echo "  ./scripts/dev/restart.sh frontend"
    echo "  make dev-restart SERVICE=backend"
    echo ""
}

# 检查帮助参数
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

SERVICE=${1:-all}

echo ""
echo "=========================================="
echo "    重启开发环境"
echo "=========================================="
echo ""

# 重启后端
restart_backend() {
    echo -e "${YELLOW}重启 PHP 后端...${NC}"
    
    # 停止
    if [ -f "$ROOT_DIR/.backend.pid" ]; then
        BACK_PID="$(cat "$ROOT_DIR/.backend.pid")"
        if kill -0 "$BACK_PID" 2>/dev/null; then
            kill "$BACK_PID" 2>/dev/null || true
            sleep 1
        fi
        rm -f "$ROOT_DIR/.backend.pid"
    fi
    
    # 启动
    nohup php think run -H 0.0.0.0 -p 8000 > "$ROOT_DIR/.backend.log" 2>&1 &
    echo $! > "$ROOT_DIR/.backend.pid"
    sleep 2
    
    if kill -0 "$(cat "$ROOT_DIR/.backend.pid")" 2>/dev/null; then
        echo -e "${GREEN}✓ PHP 后端已重启 (PID $(cat "$ROOT_DIR/.backend.pid"))${NC}"
    else
        echo -e "${RED}✗ PHP 后端启动失败，查看日志: tail -f .backend.log${NC}"
        rm -f "$ROOT_DIR/.backend.pid"
        exit 1
    fi
}

# 重启前端
restart_frontend() {
    echo -e "${YELLOW}重启 Vue 前端...${NC}"
    
    # 停止
    if [ -f "$ROOT_DIR/.frontend.pid" ]; then
        FRONT_PID="$(cat "$ROOT_DIR/.frontend.pid")"
        if kill -0 "$FRONT_PID" 2>/dev/null; then
            kill "$FRONT_PID" 2>/dev/null || true
            sleep 1
        fi
        rm -f "$ROOT_DIR/.frontend.pid"
    fi
    
    # 启动
    (cd "$ROOT_DIR/evui" && nohup npm run dev > "$ROOT_DIR/.frontend.log" 2>&1 & echo $! > "$ROOT_DIR/.frontend.pid")
    sleep 3
    
    if [ -f "$ROOT_DIR/.frontend.pid" ] && kill -0 "$(cat "$ROOT_DIR/.frontend.pid")" 2>/dev/null; then
        echo -e "${GREEN}✓ Vue 前端已重启 (PID $(cat "$ROOT_DIR/.frontend.pid"))${NC}"
    else
        echo -e "${RED}✗ Vue 前端启动失败，查看日志: tail -f .frontend.log${NC}"
        rm -f "$ROOT_DIR/.frontend.pid"
        exit 1
    fi
}

case "$SERVICE" in
    backend|php)
        restart_backend
        ;;
        
    frontend|vue)
        restart_frontend
        ;;
        
    all|*)
        restart_backend
        echo ""
        restart_frontend
        ;;
esac

echo ""
echo "=========================================="
echo -e "${GREEN}    重启完成！${NC}"
echo "=========================================="
echo ""
echo "  后端: http://localhost:8000"
echo "  前端: http://localhost:8080"
echo ""
