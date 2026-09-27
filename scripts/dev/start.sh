#!/bin/bash
# 本地开发环境启动脚本
# 自动检测 MySQL/Redis，优先使用本地服务，没有则启动共享Docker服务

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SERVER_DIR=""

# 自动检测共享 server 目录，支持 SHARED_SERVER_DIR 环境变量覆盖
detect_server_dir() {
    if [ -n "$SHARED_SERVER_DIR" ] && [ -f "$SHARED_SERVER_DIR/docker-compose-database.yml" ]; then
        printf '%s' "$SHARED_SERVER_DIR"
        return 0
    fi

    local candidates=(
        "$ROOT_DIR/../../.."
        "$ROOT_DIR/../.."
        "/Users/pro/Documents/www/server"
    )
    local candidate
    for candidate in "${candidates[@]}"; do
        if [ -f "$candidate/docker-compose-database.yml" ]; then
            printf '%s' "$candidate"
            return 0
        fi
    done

    return 1
}

# 显示帮助信息
show_help() {
    echo ""
    echo "=========================================="
    echo "    本地开发环境启动脚本 - start.sh"
    echo "=========================================="
    echo ""
    echo "用法:"
    echo "  ./scripts/dev/start.sh [--help]"
    echo "  make dev"
    echo ""
    echo "功能:"
    echo "  1. 检查并启动 MySQL（优先本地，无则启动 Docker）"
    echo "  2. 检查并启动 Redis（优先本地，无则启动 Docker）"
    echo "  3. 启动 PHP 后端（ThinkPHP，端口 8000）"
    echo "  4. 启动 Vue 前端（端口 8080）"
    echo ""
    echo "服务地址:"
    echo "  后端: http://localhost:8000"
    echo "  前端: http://localhost:8080"
    echo ""
    echo "日志文件:"
    echo "  后端日志: .backend.log"
    echo "  前端日志: .frontend.log"
    echo ""
    echo "管理命令:"
    echo "  make dev-stop     停止开发环境"
    echo "  make dev-status   查看服务状态"
    echo ""
    echo "PID 文件:"
    echo "  .backend.pid      PHP 后端进程ID"
    echo "  .frontend.pid     Vue 前端进程ID"
    echo ""
}

# 检查帮助参数
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

cd "$ROOT_DIR"
SERVER_DIR="$(detect_server_dir || true)"

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=========================================="
echo "    初始化项目 - 本地开发环境"
echo "=========================================="
echo ""

# 检查 MySQL
echo -e "${YELLOW}[1/4] 检查 MySQL...${NC}"
if nc -z 127.0.0.1 3306 2>/dev/null; then
    echo -e "${GREEN}✓ MySQL 已运行 (127.0.0.1:3306)${NC}"
else
    echo -e "${YELLOW}! MySQL 未运行${NC}"
    if command -v docker &> /dev/null && [ -n "$SERVER_DIR" ]; then
        echo "  正在启动共享 Docker MySQL..."
        cd "$SERVER_DIR"
        docker compose -f docker-compose-database.yml up -d mysql 2>/dev/null || true
        cd "$ROOT_DIR"
        sleep 5
        if nc -z 127.0.0.1 3306 2>/dev/null; then
            echo -e "${GREEN}✓ 共享 MySQL 已启动${NC}"
        else
            echo -e "${YELLOW}⚠ 无法启动 MySQL，请手动启动${NC}"
        fi
    elif command -v docker &> /dev/null; then
        echo -e "${YELLOW}⚠ 未找到 docker-compose-database.yml，跳过共享 Docker MySQL 启动${NC}"
    else
        echo -e "${YELLOW}⚠ 请先安装 MySQL 或 Docker${NC}"
    fi
fi

# 检查 Redis
echo -e "${YELLOW}[2/4] 检查 Redis...${NC}"
if nc -z 127.0.0.1 6379 2>/dev/null; then
    echo -e "${GREEN}✓ Redis 已运行 (127.0.0.1:6379)${NC}"
else
    echo -e "${YELLOW}! Redis 未运行${NC}"
    if command -v docker &> /dev/null && [ -n "$SERVER_DIR" ]; then
        echo "  正在启动共享 Docker Redis..."
        cd "$SERVER_DIR"
        docker compose -f docker-compose-database.yml up -d redis 2>/dev/null || true
        cd "$ROOT_DIR"
        sleep 2
        if nc -z 127.0.0.1 6379 2>/dev/null; then
            echo -e "${GREEN}✓ 共享 Redis 已启动${NC}"
        else
            echo -e "${YELLOW}⚠ 无法启动 Redis，请手动启动${NC}"
        fi
    elif command -v docker &> /dev/null; then
        echo -e "${YELLOW}⚠ 未找到 docker-compose-database.yml，跳过共享 Docker Redis 启动${NC}"
    else
        echo -e "${YELLOW}⚠ 请先安装 Redis 或 Docker${NC}"
    fi
fi

# 启动 PHP 后端
echo -e "${YELLOW}[3/4] 启动 PHP 后端...${NC}"
BACKEND_PORT=8000

# 检查端口是否被占用
if lsof -i :$BACKEND_PORT >/dev/null 2>&1; then
    OLD_PID=$(lsof -ti :$BACKEND_PORT | head -1)
    if [ -f "$ROOT_DIR/.backend.pid" ] && [ "$(cat "$ROOT_DIR/.backend.pid")" = "$OLD_PID" ]; then
        echo -e "${GREEN}✓ PHP 后端已在运行 (PID $OLD_PID)${NC}"
    else
        echo -e "${YELLOW}⚠ 端口 $BACKEND_PORT 已被占用 (PID $OLD_PID)，正在强制停止...${NC}"
        # 尝试优雅停止
        kill "$OLD_PID" 2>/dev/null || true
        sleep 1
        # 如果还在运行，强制停止
        if kill -0 "$OLD_PID" 2>/dev/null; then
            echo "  强制停止进程 (kill -9)..."
            kill -9 "$OLD_PID" 2>/dev/null || true
            sleep 1
        fi
        # 验证是否已停止
        if ! kill -0 "$OLD_PID" 2>/dev/null; then
            echo -e "${GREEN}✓ 已停止占用端口的进程${NC}"
        else
            echo -e "${RED}✗ 无法停止进程 (PID $OLD_PID)，请手动停止${NC}"
            exit 1
        fi
    fi
fi

# 如果 PID 文件存在但进程不存在，清理 PID 文件
if [ -f "$ROOT_DIR/.backend.pid" ]; then
    PID_FROM_FILE=$(cat "$ROOT_DIR/.backend.pid" 2>/dev/null)
    if [ -n "$PID_FROM_FILE" ] && ! kill -0 "$PID_FROM_FILE" 2>/dev/null; then
        rm -f "$ROOT_DIR/.backend.pid"
    fi
fi

# 启动后端（如果未运行）
if [ -f "$ROOT_DIR/.backend.pid" ] && kill -0 "$(cat "$ROOT_DIR/.backend.pid")" 2>/dev/null; then
    echo -e "${GREEN}✓ PHP 后端已在运行 (PID $(cat "$ROOT_DIR/.backend.pid"))${NC}"
else
    nohup php think run -H 0.0.0.0 -p $BACKEND_PORT > "$ROOT_DIR/.backend.log" 2>&1 &
    echo $! > "$ROOT_DIR/.backend.pid"
    sleep 2
    if kill -0 "$(cat "$ROOT_DIR/.backend.pid")" 2>/dev/null; then
        echo -e "${GREEN}✓ PHP 后端已启动 (PID $(cat "$ROOT_DIR/.backend.pid"), 端口 $BACKEND_PORT)${NC}"
    else
        echo -e "${RED}✗ PHP 后端启动失败，查看日志: tail -f .backend.log${NC}"
        rm -f "$ROOT_DIR/.backend.pid"
        exit 1
    fi
fi

# 启动 Vue 前端
echo -e "${YELLOW}[4/4] 启动 Vue 前端...${NC}"
FRONTEND_PORT=8080

# 检查端口是否被占用
if lsof -i :$FRONTEND_PORT >/dev/null 2>&1; then
    OLD_PID=$(lsof -ti :$FRONTEND_PORT | head -1)
    if [ -f "$ROOT_DIR/.frontend.pid" ] && [ "$(cat "$ROOT_DIR/.frontend.pid")" = "$OLD_PID" ]; then
        echo -e "${GREEN}✓ Vue 前端已在运行 (PID $OLD_PID)${NC}"
    else
        echo -e "${YELLOW}⚠ 端口 $FRONTEND_PORT 已被占用 (PID $OLD_PID)，正在强制停止...${NC}"
        # 尝试优雅停止
        kill "$OLD_PID" 2>/dev/null || true
        sleep 1
        # 如果还在运行，强制停止
        if kill -0 "$OLD_PID" 2>/dev/null; then
            echo "  强制停止进程 (kill -9)..."
            kill -9 "$OLD_PID" 2>/dev/null || true
            sleep 1
        fi
        # 验证是否已停止
        if ! kill -0 "$OLD_PID" 2>/dev/null; then
            echo -e "${GREEN}✓ 已停止占用端口的进程${NC}"
        else
            echo -e "${RED}✗ 无法停止进程 (PID $OLD_PID)，请手动停止${NC}"
            exit 1
        fi
    fi
fi

# 如果 PID 文件存在但进程不存在，清理 PID 文件
if [ -f "$ROOT_DIR/.frontend.pid" ]; then
    PID_FROM_FILE=$(cat "$ROOT_DIR/.frontend.pid" 2>/dev/null)
    if [ -n "$PID_FROM_FILE" ] && ! kill -0 "$PID_FROM_FILE" 2>/dev/null; then
        rm -f "$ROOT_DIR/.frontend.pid"
    fi
fi

# 启动前端（如果未运行）
if [ -f "$ROOT_DIR/.frontend.pid" ] && kill -0 "$(cat "$ROOT_DIR/.frontend.pid")" 2>/dev/null; then
    echo -e "${GREEN}✓ Vue 前端已在运行 (PID $(cat "$ROOT_DIR/.frontend.pid"))${NC}"
else
    echo "  正在启动 Vue 前端..."
    cd "$ROOT_DIR/evui"
    
    # 检查 node_modules 是否存在
    if [ ! -d "node_modules" ]; then
        echo -e "${YELLOW}⚠ node_modules 不存在，正在安装依赖...${NC}"
        npm install
    fi
    
    # 启动前端服务
    nohup npm run dev > "$ROOT_DIR/.frontend.log" 2>&1 &
    FRONTEND_PID=$!
    echo $FRONTEND_PID > "$ROOT_DIR/.frontend.pid"
    cd "$ROOT_DIR"
    
    # 等待服务启动
    sleep 5
    
    # 检查进程是否还在运行
    if kill -0 "$FRONTEND_PID" 2>/dev/null; then
        # 检查端口是否被占用（说明服务已启动）
        if lsof -i :$FRONTEND_PORT >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Vue 前端已启动 (PID $FRONTEND_PID, 端口 $FRONTEND_PORT)${NC}"
        else
            echo -e "${YELLOW}⚠ 进程已启动但端口未监听，请查看日志: tail -f .frontend.log${NC}"
        fi
    else
        echo -e "${RED}✗ Vue 前端启动失败，查看日志: tail -f .frontend.log${NC}"
        rm -f "$ROOT_DIR/.frontend.pid"
        exit 1
    fi
fi

echo ""
echo "=========================================="
echo "    启动完成！"
echo "=========================================="
echo ""
echo "  后端: http://localhost:8000"
echo "  前端: http://localhost:8080"
echo ""
echo "  查看后端日志: tail -f .backend.log"
echo "  查看前端日志: tail -f .frontend.log"
echo "  停止开发环境: make dev-stop"
echo ""
