#!/bin/bash

# 数据库导入脚本
# 用于导入数据库结构或数据到已存在的数据库

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

check_command mysql

title "数据库导入工具"

# 检查 SQL 文件目录
SQL_DIR="$ROOT_DIR/document"
if [ ! -d "$SQL_DIR" ]; then
    warn "SQL 文件目录不存在: $SQL_DIR"
    warn "将使用当前目录查找 SQL 文件"
    SQL_DIR="$ROOT_DIR"
fi

# 查找可用的 SQL 文件
info "查找可用的 SQL 文件..."
SQL_FILES=()
if [ -d "$SQL_DIR" ]; then
    while IFS= read -r file; do
        SQL_FILES+=("$file")
    done < <(find "$SQL_DIR" -maxdepth 1 -name "*.sql" -type f 2>/dev/null | sort)
fi

if [ ${#SQL_FILES[@]} -eq 0 ]; then
    echo ""
    echo "未找到 SQL 文件，请输入 SQL 文件路径："
    read -p "SQL 文件路径: " SQL_FILE
    if [ ! -f "$SQL_FILE" ]; then
        error "SQL 文件不存在: $SQL_FILE"
        exit 1
    fi
else
    echo ""
    echo "可用的 SQL 文件："
    for i in "${!SQL_FILES[@]}"; do
        filename=$(basename "${SQL_FILES[$i]}")
        echo "  $((i+1)). $filename"
    done
    echo "  $(( ${#SQL_FILES[@]} + 1 )). 自定义 SQL 文件路径"
    echo ""
    
    read -p "请选择要导入的 SQL 文件 (1-$(( ${#SQL_FILES[@]} + 1 ))): " SQL_CHOICE
    
    if [ "$SQL_CHOICE" -ge 1 ] && [ "$SQL_CHOICE" -le "${#SQL_FILES[@]}" ]; then
        SQL_FILE="${SQL_FILES[$((SQL_CHOICE-1))]}"
        SQL_DESC=$(basename "$SQL_FILE")
    elif [ "$SQL_CHOICE" -eq $(( ${#SQL_FILES[@]} + 1 )) ]; then
        read -p "请输入 SQL 文件路径: " SQL_FILE
        SQL_DESC="自定义文件"
    else
        error "无效的选择"
        exit 1
    fi
fi

# 检查文件是否存在
if [ ! -f "$SQL_FILE" ]; then
    error "SQL 文件不存在: $SQL_FILE"
    exit 1
fi

info "选择的 SQL 文件: $SQL_FILE"
if [ -n "$SQL_DESC" ]; then
    info "文件描述: $SQL_DESC"
fi
echo ""

# 加载数据库配置
load_db_config() {
    DB_HOST="127.0.0.1"
    DB_PORT="3306"
    DB_NAME=""
    DB_USER="root"
    DB_PASS=""
    
    if [ -f "$ROOT_DIR/.env" ]; then
        # 读取 ThinkPHP 格式的配置
        if grep -q "^\[DATABASE\]" "$ROOT_DIR/.env" 2>/dev/null; then
            DB_HOST=$(grep "^HOSTNAME=" "$ROOT_DIR/.env" 2>/dev/null | cut -d'=' -f2 | tr -d ' ' || echo "127.0.0.1")
            DB_PORT=$(grep "^HOSTPORT=" "$ROOT_DIR/.env" 2>/dev/null | cut -d'=' -f2 | tr -d ' ' || echo "3306")
            DB_NAME=$(grep "^DATABASE=" "$ROOT_DIR/.env" 2>/dev/null | cut -d'=' -f2 | tr -d ' ' || echo "")
            DB_USER=$(grep "^USERNAME=" "$ROOT_DIR/.env" 2>/dev/null | cut -d'=' -f2 | tr -d ' ' || echo "root")
            DB_PASS=$(grep "^PASSWORD=" "$ROOT_DIR/.env" 2>/dev/null | cut -d'=' -f2 | tr -d ' ' || echo "")
        else
            # 标准格式
            source "$ROOT_DIR/.env" 2>/dev/null || true
            DB_HOST=${MYSQL_HOST:-127.0.0.1}
            DB_PORT=${MYSQL_PORT:-3306}
            DB_NAME=${MYSQL_DATABASE:-}
            DB_USER=${MYSQL_USER:-root}
            DB_PASS=${MYSQL_PASSWORD:-}
        fi
    fi
    
    # 如果配置不完整，提示输入
    if [ -z "$DB_NAME" ]; then
        echo "数据库配置未在 .env 中找到，请手动输入："
        read -p "数据库主机 [127.0.0.1]: " DB_HOST
        DB_HOST="${DB_HOST:-127.0.0.1}"
        
        read -p "数据库端口 [3306]: " DB_PORT
        DB_PORT="${DB_PORT:-3306}"
        
        read -p "数据库名称: " DB_NAME
        if [ -z "$DB_NAME" ]; then
            error "数据库名称不能为空"
            exit 1
        fi
        
        read -p "数据库用户名 [root]: " DB_USER
        DB_USER="${DB_USER:-root}"
        
        read -sp "数据库密码: " DB_PASS
        echo ""
    fi
}

load_db_config

# 测试数据库连接
title "测试数据库连接"
info "数据库: $DB_NAME"
info "主机: $DB_HOST:$DB_PORT"
info "用户: $DB_USER"
echo ""

info "测试数据库连接..."
if [ -n "$DB_PASS" ]; then
    if mysql --default-character-set=utf8mb4 -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME;" 2>/dev/null; then
        info "✓ 数据库连接成功"
    else
        error "✗ 数据库连接失败，请检查配置"
        exit 1
    fi
else
    if mysql --default-character-set=utf8mb4 -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -e "USE $DB_NAME;" 2>/dev/null; then
        info "✓ 数据库连接成功"
    else
        error "✗ 数据库连接失败，请检查配置"
        exit 1
    fi
fi

# 确认导入
echo ""
warn "⚠️  警告：这将导入数据到数据库: $DB_NAME"
read -p "确认导入? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "已取消"
    exit 0
fi

# 导入数据库
title "导入数据库"
info "开始导入数据库..."
info "文件: $SQL_FILE"
echo ""

if [ -n "$DB_PASS" ]; then
    if mysql --default-character-set=utf8mb4 -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$SQL_FILE" 2>/dev/null; then
        info "✓ 数据库导入成功"
    else
        error "✗ 数据库导入失败"
        exit 1
    fi
else
    if mysql --default-character-set=utf8mb4 -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" "$DB_NAME" < "$SQL_FILE" 2>/dev/null; then
        info "✓ 数据库导入成功"
    else
        error "✗ 数据库导入失败"
        exit 1
    fi
fi

title "导入完成"

info "✓ 数据库导入成功完成！"
echo ""
info "📋 后续步骤："
echo "  1. 检查数据库表是否正确创建"
echo "  2. 验证数据是否正确导入"
echo "  3. 如果导入了初始数据，请检查默认账号信息"
echo ""
