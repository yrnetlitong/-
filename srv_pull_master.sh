#!/bin/bash

# 服务器拉取主分支脚本
# 在服务器上执行，用于拉取最新代码并执行部署操作

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

title() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# 检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        error "$1 未安装，请先安装 $1"
        exit 1
    fi
}

# 检查必需命令
check_command git

title "服务器拉取更新"

# 获取当前目录
CURRENT_DIR=$(pwd)
info "当前目录: $CURRENT_DIR"

# 检查是否是 Git 仓库
if [ ! -d ".git" ]; then
    error "当前目录不是 Git 仓库"
    exit 1
fi

# 读取配置（如果存在）
CONFIG_FILE=".deploy-ssh.conf"
GIT_BRANCH="master"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    GIT_BRANCH="${GIT_BRANCH:-master}"
fi

info "拉取分支: $GIT_BRANCH"

# 1. 备份当前代码（可选，仅备份关键文件）
title "备份当前代码"
BACKUP_DIR="${CURRENT_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
if [ -d "$BACKUP_DIR" ]; then
    warn "备份目录已存在，跳过备份"
else
    info "创建备份: $BACKUP_DIR"
    # 只备份关键文件，不备份整个目录（避免太慢）
    mkdir -p "$BACKUP_DIR"
    # 备份 .env 文件（如果存在）
    [ -f ".env" ] && cp .env "$BACKUP_DIR/" 2>/dev/null || true
    # 备份 composer.lock（如果存在）
    [ -f "composer.lock" ] && cp composer.lock "$BACKUP_DIR/" 2>/dev/null || true
    info "关键文件已备份到: $BACKUP_DIR"
fi

# 2. 拉取最新代码
title "拉取最新代码"
info "执行 git pull..."

# 检查是否有未提交的更改
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    warn "检测到未提交的更改"
    git status --short
    read -p "是否暂存更改？(y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "暂存更改..."
        git stash save "Auto stash before pull $(date '+%Y-%m-%d %H:%M:%S')"
    fi
fi

# 拉取代码（优先使用 rebase）
info "尝试使用 rebase 拉取..."
if git pull --rebase origin "$GIT_BRANCH" 2>&1; then
    info "代码拉取成功（rebase）"
else
    warn "rebase 失败，尝试 merge..."
    git rebase --abort 2>/dev/null || true
    if git pull origin "$GIT_BRANCH" 2>&1; then
        info "代码拉取成功（merge）"
    else
        error "代码拉取失败"
        warn "请手动解决冲突后重试"
        exit 1
    fi
fi

# 3. 恢复暂存的更改（如果有）
if git stash list | grep -q "Auto stash"; then
    info "恢复暂存的更改..."
    git stash pop || warn "恢复暂存失败"
fi

# 4. 安装/更新依赖
title "更新依赖"

# PHP 依赖
if [ -f "composer.json" ]; then
    info "更新 PHP 依赖..."
    if command -v composer &> /dev/null; then
        composer install --no-dev --optimize-autoloader || warn "Composer 更新失败"
    else
        warn "Composer 未安装，跳过 PHP 依赖更新"
    fi
fi

# 前端依赖
if [ -d "evui" ] && [ -f "evui/package.json" ]; then
    info "更新前端依赖..."
    cd evui
    if command -v npm &> /dev/null; then
        npm install || warn "NPM 安装失败"
        npm run build:prod || warn "前端构建失败"
    else
        warn "NPM 未安装，跳过前端依赖更新"
    fi
    cd ..
fi

# 5. 清理缓存
title "清理缓存"
if [ -d "runtime" ]; then
    info "清理运行时缓存..."
    rm -rf runtime/cache/* runtime/temp/* 2>/dev/null || true
fi

# 使用 ThinkPHP 命令清理缓存（如果可用）
if command -v php &> /dev/null && [ -f "think" ]; then
    info "使用 ThinkPHP 命令清理缓存..."
    php think clear 2>/dev/null || warn "ThinkPHP 缓存清理失败或跳过"
fi

# 6. 设置文件权限
title "设置文件权限"
info "设置文件权限..."
chmod -R 777 runtime 2>/dev/null || true
chmod -R 777 public/uploads 2>/dev/null || true
chmod -R 755 public 2>/dev/null || true

title "部署完成"
info "代码已更新并部署完成"
info "备份位置: $BACKUP_DIR"

