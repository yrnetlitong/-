#!/bin/bash

# 项目初始化脚本
# 用于快速初始化新项目

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印信息
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

# 检查 PHP 扩展
check_php_extension() {
    local ext=$1
    if php -m | grep -qi "^$ext$"; then
        return 0
    else
        return 1
    fi
}

# 主函数
main() {
    title "项目初始化"
    echo ""
    
    # 检查必需的命令
    info "[1/7] 检查环境..."
    check_command php
    check_command composer
    check_command npm
    
    # 检查 PHP 版本
    PHP_VERSION=$(php -r "echo PHP_VERSION_ID;")
    if [ "$PHP_VERSION" -lt 70300 ]; then
        error "PHP 版本需要 >= 7.3，当前版本: $(php -v | head -n 1)"
        exit 1
    fi
    info "✓ PHP 版本检查通过: $(php -v | head -n 1)"
    
    # 检查 PHP 扩展
    info "[2/7] 检查 PHP 扩展..."
    REQUIRED_EXTENSIONS=("pdo" "pdo_mysql" "curl" "json" "mbstring" "openssl")
    MISSING_EXTENSIONS=()
    for ext in "${REQUIRED_EXTENSIONS[@]}"; do
        if check_php_extension "$ext"; then
            info "  ✓ $ext 已安装"
        else
            warn "  ✗ $ext 未安装"
            MISSING_EXTENSIONS+=("$ext")
        fi
    done
    
    if [ ${#MISSING_EXTENSIONS[@]} -gt 0 ]; then
        warn "缺少以下 PHP 扩展: ${MISSING_EXTENSIONS[*]}"
        warn "请安装缺失的扩展后再继续"
    fi
    
    # 检查 Redis 扩展（可选）
    if check_php_extension "redis"; then
        info "  ✓ redis 已安装（可选）"
    else
        warn "  ! redis 未安装（可选，用于缓存）"
    fi
    
    # 创建必要的目录
    info "[3/7] 创建必要的目录..."
    DIRS=("runtime" "runtime/cache" "runtime/temp" "runtime/log" "public/uploads")
    for dir in "${DIRS[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            info "  ✓ 已创建目录: $dir"
        else
            info "  ✓ 目录已存在: $dir"
        fi
    done
    
    # 复制环境配置文件
    info "[4/7] 配置环境文件..."
    if [ ! -f .env ]; then
        if [ -f .example.env ]; then
            cp .example.env .env
            info "  ✓ 已创建 .env 文件（从 .example.env 复制）"
            warn "  请编辑 .env 文件配置数据库等信息"
        else
            warn "  ! .example.env 文件不存在，跳过环境配置"
        fi
    else
        warn "  ! .env 文件已存在，跳过复制"
    fi
    
    # 安装 PHP 依赖
    info "[5/7] 安装 PHP 依赖..."
    if [ -f composer.json ]; then
        if [ ! -d vendor ]; then
            composer install --no-interaction
            info "  ✓ PHP 依赖安装完成"
        else
            info "  ✓ PHP 依赖已安装，跳过"
        fi
    else
        warn "  ! composer.json 不存在，跳过 PHP 依赖安装"
    fi
    
    # 设置目录权限
    info "[6/7] 设置目录权限..."
    if [ -d runtime ]; then
        chmod -R 755 runtime 2>/dev/null || chmod -R 777 runtime
        info "  ✓ runtime 目录权限已设置"
    fi
    
    if [ -d public/uploads ]; then
        chmod -R 755 public/uploads 2>/dev/null || chmod -R 777 public/uploads
        info "  ✓ public/uploads 目录权限已设置"
    fi
    
    # 安装前端依赖
    info "[7/7] 安装前端依赖..."
    if [ -d evui ]; then
        cd evui
        if [ -f package.json ]; then
            if [ ! -d node_modules ]; then
                npm install
                info "  ✓ 前端依赖安装完成"
            else
                info "  ✓ 前端依赖已安装，跳过"
            fi
        else
            warn "  ! package.json 不存在，跳过前端依赖安装"
        fi
        cd ..
    else
        warn "  ! evui 目录不存在，跳过前端依赖安装"
    fi
    
    # 完成
    echo ""
    title "初始化完成"
    echo ""
    info "项目初始化完成！"
    echo ""
    info "下一步操作："
    echo "  1. 编辑 .env 文件配置数据库等信息"
    if compgen -G "document/*.sql" > /dev/null; then
        FIRST_SQL_FILE=$(ls document/*.sql 2>/dev/null | head -n 1)
        echo "  2. 导入数据库（按需选择 SQL 文件）："
        echo "     mysql -u username -p database < $FIRST_SQL_FILE"
        echo "     可选文件："
        ls document/*.sql 2>/dev/null | sed 's/^/       - /'
    else
        echo "  2. 当前未检测到 document/*.sql，跳过数据库导入"
    fi
    echo "  3. 启动开发环境："
    echo "     make dev"
    echo "     或"
    echo "     php think run          # 后端"
    echo "     cd evui && npm run dev  # 前端"
    echo ""
    info "其他命令："
    echo "  make dev-status    - 查看开发环境状态"
    echo "  make check-env     - 检查环境配置"
    echo "  make dev-stop      - 停止开发环境"
    echo ""
    info "更多信息请查看文档："
    echo "  - docs/getting-started/QUICKSTART.md"
    echo "  - scripts/dev/README.md"
    echo ""
}

# 运行主函数
main "$@"
