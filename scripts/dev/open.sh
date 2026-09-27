#!/bin/bash
# 快速打开开发环境页面
# 用法: ./open.sh [backend|frontend|all] [--help]

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 显示帮助信息
show_help() {
    echo ""
    echo "=========================================="
    echo "    快速打开开发页面 - open.sh"
    echo "=========================================="
    echo ""
    echo "用法:"
    echo "  ./scripts/dev/open.sh [page]"
    echo "  make dev-open [PAGE=frontend]"
    echo ""
    echo "参数:"
    echo "  page          页面: backend, frontend, all (默认: frontend)"
    echo "  --help, -h    显示此帮助信息"
    echo ""
    echo "功能:"
    echo "  在默认浏览器中打开开发环境页面"
    echo ""
    echo "示例:"
    echo "  ./scripts/dev/open.sh frontend"
    echo "  ./scripts/dev/open.sh backend"
    echo "  make dev-open PAGE=all"
    echo ""
}

# 检查帮助参数
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

PAGE=${1:-frontend}

open_url() {
    local url=$1
    local desc=$2
    
    echo -e "${BLUE}打开: $desc${NC}"
    echo -e "  URL: $url"
    
    if command -v open &> /dev/null; then
        # macOS
        open "$url"
    elif command -v xdg-open &> /dev/null; then
        # Linux
        xdg-open "$url"
    elif command -v start &> /dev/null; then
        # Windows (Git Bash)
        start "$url"
    else
        echo -e "${YELLOW}! 无法自动打开浏览器，请手动访问: $url${NC}"
    fi
}

case "$PAGE" in
    backend|php)
        open_url "http://localhost:8000" "PHP 后端"
        ;;
        
    frontend|vue)
        open_url "http://localhost:8080" "Vue 前端"
        ;;
        
    all|*)
        open_url "http://localhost:8000" "PHP 后端"
        sleep 1
        open_url "http://localhost:8080" "Vue 前端"
        ;;
esac

echo ""
