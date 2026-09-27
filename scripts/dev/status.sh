#!/bin/bash
# 查看本地开发环境状态

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "    本地开发环境状态"
echo "=========================================="
echo ""

# MySQL
echo -e "${YELLOW}MySQL:${NC}"
if nc -z 127.0.0.1 3306 2>/dev/null; then
    echo -e "  ${GREEN}● 运行中${NC} (127.0.0.1:3306)"
else
    echo -e "  ${RED}○ 未运行${NC}"
fi

# Redis
echo -e "${YELLOW}Redis:${NC}"
if nc -z 127.0.0.1 6379 2>/dev/null; then
    echo -e "  ${GREEN}● 运行中${NC} (127.0.0.1:6379)"
else
    echo -e "  ${RED}○ 未运行${NC}"
fi

# PHP 后端
echo -e "${YELLOW}PHP 后端:${NC}"
if [ -f "$ROOT_DIR/.backend.pid" ] && kill -0 "$(cat "$ROOT_DIR/.backend.pid")" 2>/dev/null; then
    echo -e "  ${GREEN}● 运行中${NC} (PID $(cat "$ROOT_DIR/.backend.pid")) http://localhost:8000"
else
    echo -e "  ${RED}○ 未运行${NC}"
fi

# Vue 前端
echo -e "${YELLOW}Vue 前端:${NC}"
if [ -f "$ROOT_DIR/.frontend.pid" ] && kill -0 "$(cat "$ROOT_DIR/.frontend.pid")" 2>/dev/null; then
    echo -e "  ${GREEN}● 运行中${NC} (PID $(cat "$ROOT_DIR/.frontend.pid")) http://localhost:8080"
else
    echo -e "  ${RED}○ 未运行${NC}"
fi

echo ""
