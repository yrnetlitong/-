#!/bin/bash
# 停止本地开发环境

# 不使用 set -e，避免某些命令失败时提前退出
set +e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "    停止本地开发环境"
echo "=========================================="
echo ""

# 停止前端
echo -e "${YELLOW}停止 Vue 前端...${NC}"
FRONTEND_PORT=8080
FRONT_STOPPED=false

# 方法1: 通过 PID 文件停止
if [ -f "$ROOT_DIR/.frontend.pid" ]; then
    FRONT_PID="$(cat "$ROOT_DIR/.frontend.pid" 2>/dev/null)"
    if [ -n "$FRONT_PID" ] && kill -0 "$FRONT_PID" 2>/dev/null; then
        echo "  停止 PID 文件中的进程 (PID $FRONT_PID)..."
        kill "$FRONT_PID" 2>/dev/null || true
        sleep 1
        if ! kill -0 "$FRONT_PID" 2>/dev/null; then
            echo -e "${GREEN}✓ Vue 前端已停止 (PID $FRONT_PID)${NC}"
            FRONT_STOPPED=true
        fi
    fi
    rm -f "$ROOT_DIR/.frontend.pid"
fi

# 方法2: 通过端口查找并停止（无论PID文件是否存在，都检查端口）
if lsof -i :$FRONTEND_PORT >/dev/null 2>&1; then
    PORT_PID=$(lsof -ti :$FRONTEND_PORT 2>/dev/null | head -1)
    if [ -n "$PORT_PID" ]; then
        # 如果PID文件中的进程和端口进程不一致，也要停止
        if [ "$FRONT_STOPPED" = false ] || [ "$FRONT_PID" != "$PORT_PID" ]; then
            echo "  检测到端口 $FRONTEND_PORT 被占用 (PID $PORT_PID)，正在停止..."
            kill "$PORT_PID" 2>/dev/null || true
            sleep 1
            if kill -0 "$PORT_PID" 2>/dev/null; then
                echo "  强制停止进程..."
                kill -9 "$PORT_PID" 2>/dev/null || true
                sleep 1
            fi
            if ! kill -0 "$PORT_PID" 2>/dev/null; then
                echo -e "${GREEN}✓ 已停止占用端口 $FRONTEND_PORT 的进程 (PID $PORT_PID)${NC}"
                FRONT_STOPPED=true
            else
                echo -e "${YELLOW}⚠ 无法停止进程 (PID $PORT_PID)，可能需要管理员权限${NC}"
            fi
        fi
    fi
fi

if [ "$FRONT_STOPPED" = false ]; then
    if lsof -i :$FRONTEND_PORT >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ 端口 $FRONTEND_PORT 仍被占用${NC}"
    else
        echo "  前端已停止或未运行"
    fi
fi

# 停止后端
echo -e "${YELLOW}停止 PHP 后端...${NC}"
BACKEND_PORT=8000
BACK_STOPPED=false

# 方法1: 通过 PID 文件停止
if [ -f "$ROOT_DIR/.backend.pid" ]; then
    BACK_PID="$(cat "$ROOT_DIR/.backend.pid" 2>/dev/null)"
    if [ -n "$BACK_PID" ] && kill -0 "$BACK_PID" 2>/dev/null; then
        echo "  停止 PID 文件中的进程 (PID $BACK_PID)..."
        kill "$BACK_PID" 2>/dev/null || true
        sleep 1
        if ! kill -0 "$BACK_PID" 2>/dev/null; then
            echo -e "${GREEN}✓ PHP 后端已停止 (PID $BACK_PID)${NC}"
            BACK_STOPPED=true
        fi
    fi
    rm -f "$ROOT_DIR/.backend.pid"
fi

# 方法2: 通过端口查找并停止（无论PID文件是否存在，都检查端口）
if lsof -i :$BACKEND_PORT >/dev/null 2>&1; then
    PORT_PID=$(lsof -ti :$BACKEND_PORT 2>/dev/null | head -1)
    if [ -n "$PORT_PID" ]; then
        # 如果PID文件中的进程和端口进程不一致，也要停止
        if [ "$BACK_STOPPED" = false ] || [ "$BACK_PID" != "$PORT_PID" ]; then
            echo "  检测到端口 $BACKEND_PORT 被占用 (PID $PORT_PID)，正在停止..."
            kill "$PORT_PID" 2>/dev/null || true
            sleep 1
            if kill -0 "$PORT_PID" 2>/dev/null; then
                echo "  强制停止进程..."
                kill -9 "$PORT_PID" 2>/dev/null || true
                sleep 1
            fi
            if ! kill -0 "$PORT_PID" 2>/dev/null; then
                echo -e "${GREEN}✓ 已停止占用端口 $BACKEND_PORT 的进程 (PID $PORT_PID)${NC}"
                BACK_STOPPED=true
            else
                echo -e "${YELLOW}⚠ 无法停止进程 (PID $PORT_PID)，可能需要管理员权限${NC}"
            fi
        fi
    fi
fi

if [ "$BACK_STOPPED" = false ]; then
    if lsof -i :$BACKEND_PORT >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ 端口 $BACKEND_PORT 仍被占用${NC}"
    else
        echo "  后端已停止或未运行"
    fi
fi

# 清理日志（可选）
# rm -f "$ROOT_DIR/.backend.log" "$ROOT_DIR/.frontend.log"

echo ""
echo -e "${GREEN}开发环境已停止${NC}"
echo ""
