#!/bin/bash
# 查看开发环境日志
# 用法: ./logs.sh [backend|frontend|all] [--tail]

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
    echo "    开发环境日志查看 - logs.sh"
    echo "=========================================="
    echo ""
    echo "用法:"
    echo "  ./scripts/dev/logs.sh [service] [--tail]"
    echo "  make dev-logs [SERVICE=backend]"
    echo ""
    echo "参数:"
    echo "  service       服务名称: backend, frontend, all (默认: all)"
    echo "  --tail, -f    实时查看（类似 tail -f）"
    echo ""
    echo "示例:"
    echo "  ./scripts/dev/logs.sh backend --tail"
    echo "  ./scripts/dev/logs.sh frontend"
    echo "  make dev-logs SERVICE=backend --tail"
    echo ""
}

# 检查帮助参数
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

SERVICE=${1:-all}
TAIL_MODE=false

if [[ "$2" == "--tail" ]] || [[ "$2" == "-f" ]]; then
    TAIL_MODE=true
fi

show_log() {
    local service=$1
    local log_file=$2
    local desc=$3
    
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}    $desc${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo ""
    
    if [ ! -f "$log_file" ]; then
        echo -e "${YELLOW}日志文件不存在: $log_file${NC}"
        echo -e "${YELLOW}提示: 先启动服务 (make dev)${NC}"
        return
    fi
    
    if [ "$TAIL_MODE" = true ]; then
        echo -e "${YELLOW}实时查看日志 (Ctrl+C 退出)...${NC}"
        echo ""
        tail -f "$log_file"
    else
        echo -e "${YELLOW}最后100行日志:${NC}"
        echo ""
        tail -n 100 "$log_file"
    fi
}

case "$SERVICE" in
    backend|php)
        show_log "backend" "$ROOT_DIR/.backend.log" "PHP 后端日志"
        ;;
        
    frontend|vue)
        show_log "frontend" "$ROOT_DIR/.frontend.log" "Vue 前端日志"
        ;;
        
    all|*)
        if [ "$TAIL_MODE" = true ]; then
            echo -e "${RED}错误: 实时查看模式不支持 'all'，请指定具体服务${NC}"
            exit 1
        fi
        
        show_log "backend" "$ROOT_DIR/.backend.log" "PHP 后端日志"
        echo ""
        echo ""
        show_log "frontend" "$ROOT_DIR/.frontend.log" "Vue 前端日志"
        ;;
esac
