#!/bin/bash
# 环境检查脚本
# 检查开发/部署环境是否配置正确

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 显示帮助信息
show_help() {
    echo ""
    echo "=========================================="
    echo "    环境检查脚本 - env-check.sh"
    echo "=========================================="
    echo ""
    echo "用法:"
    echo "  ./scripts/env-check.sh [--help]"
    echo "  make check-env"
    echo ""
    echo "功能:"
    echo "  检查开发/部署环境配置："
    echo "  - PHP版本和扩展"
    echo "  - Node.js版本"
    echo "  - Composer依赖"
    echo "  - NPM依赖"
    echo "  - 数据库连接"
    echo "  - Redis连接"
    echo "  - 环境变量配置"
    echo "  - 文件权限"
    echo ""
}

# 检查帮助参数
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

echo ""
echo "=========================================="
echo "    环境检查"
echo "=========================================="
echo ""

ERRORS=0
WARNINGS=0

# 检查PHP
echo -e "${BLUE}[1/8] 检查 PHP...${NC}"
if command -v php &> /dev/null; then
    PHP_VERSION=$(php -r "echo PHP_VERSION;")
    PHP_MAJOR=$(php -r "echo PHP_MAJOR_VERSION;")
    PHP_MINOR=$(php -r "echo PHP_MINOR_VERSION;")
    
    if [ "$PHP_MAJOR" -ge 7 ] && [ "$PHP_MINOR" -ge 3 ]; then
        echo -e "  ${GREEN}✓ PHP版本: $PHP_VERSION${NC}"
    else
        echo -e "  ${RED}✗ PHP版本过低: $PHP_VERSION (需要 >= 7.3)${NC}"
        ((ERRORS++))
    fi
    
    # 检查必需扩展
    REQUIRED_EXTENSIONS=("pdo" "pdo_mysql" "curl" "json" "mbstring" "openssl")
    for ext in "${REQUIRED_EXTENSIONS[@]}"; do
        if php -m | grep -qi "^$ext$"; then
            echo -e "  ${GREEN}✓ 扩展 $ext 已安装${NC}"
        else
            echo -e "  ${RED}✗ 扩展 $ext 未安装${NC}"
            ((ERRORS++))
        fi
    done
    
    # 检查可选扩展
    if php -m | grep -qi "^redis$"; then
        echo -e "  ${GREEN}✓ 扩展 redis 已安装（可选）${NC}"
    else
        echo -e "  ${YELLOW}! 扩展 redis 未安装（可选，用于缓存）${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "  ${RED}✗ PHP 未安装${NC}"
    ((ERRORS++))
fi

# 检查Composer
echo ""
echo -e "${BLUE}[2/8] 检查 Composer...${NC}"
if command -v composer &> /dev/null; then
    COMPOSER_VERSION=$(composer --version | head -n1)
    echo -e "  ${GREEN}✓ $COMPOSER_VERSION${NC}"
    
    if [ -f "$ROOT_DIR/composer.json" ]; then
        if [ -d "$ROOT_DIR/vendor" ]; then
            echo -e "  ${GREEN}✓ 依赖已安装${NC}"
        else
            echo -e "  ${YELLOW}! 依赖未安装，运行: composer install${NC}"
            ((WARNINGS++))
        fi
    fi
else
    echo -e "  ${RED}✗ Composer 未安装${NC}"
    ((ERRORS++))
fi

# 检查Node.js
echo ""
echo -e "${BLUE}[3/8] 检查 Node.js...${NC}"
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    NODE_MAJOR=$(node --version | cut -d. -f1 | sed 's/v//')
    
    if [ "$NODE_MAJOR" -ge 12 ]; then
        echo -e "  ${GREEN}✓ Node.js版本: $NODE_VERSION${NC}"
    else
        echo -e "  ${YELLOW}! Node.js版本较低: $NODE_VERSION (建议 >= 12)${NC}"
        ((WARNINGS++))
    fi
    
    if command -v npm &> /dev/null; then
        NPM_VERSION=$(npm --version)
        echo -e "  ${GREEN}✓ NPM版本: $NPM_VERSION${NC}"
        
        if [ -d "$ROOT_DIR/evui/node_modules" ]; then
            echo -e "  ${GREEN}✓ 前端依赖已安装${NC}"
        else
            echo -e "  ${YELLOW}! 前端依赖未安装，运行: cd evui && npm install${NC}"
            ((WARNINGS++))
        fi
    fi
else
    echo -e "  ${RED}✗ Node.js 未安装${NC}"
    ((ERRORS++))
fi

# 检查数据库连接
echo ""
echo -e "${BLUE}[4/8] 检查数据库连接...${NC}"
if [ -f "$ROOT_DIR/.env" ]; then
    # 读取 .env 文件中的数据库配置
    if grep -q "^\[DATABASE\]" "$ROOT_DIR/.env" 2>/dev/null; then
        # ThinkPHP 格式
        DB_HOST=$(grep "^HOSTNAME=" "$ROOT_DIR/.env" 2>/dev/null | cut -d'=' -f2 | tr -d ' ' || echo "127.0.0.1")
        DB_PORT=$(grep "^HOSTPORT=" "$ROOT_DIR/.env" 2>/dev/null | cut -d'=' -f2 | tr -d ' ' || echo "3306")
        DB_NAME=$(grep "^DATABASE=" "$ROOT_DIR/.env" 2>/dev/null | cut -d'=' -f2 | tr -d ' ' || echo "")
        DB_USER=$(grep "^USERNAME=" "$ROOT_DIR/.env" 2>/dev/null | cut -d'=' -f2 | tr -d ' ' || echo "root")
        DB_PASS=$(grep "^PASSWORD=" "$ROOT_DIR/.env" 2>/dev/null | cut -d'=' -f2 | tr -d ' ' || echo "")
    else
        # 标准格式
        DB_HOST=${MYSQL_HOST:-127.0.0.1}
        DB_PORT=${MYSQL_PORT:-3306}
        DB_NAME=${MYSQL_DATABASE:-}
        DB_USER=${MYSQL_USER:-root}
        DB_PASS=${MYSQL_PASSWORD:-}
    fi
    
    if [ -z "$DB_NAME" ]; then
        echo -e "  ${YELLOW}! 数据库名未配置${NC}"
        ((WARNINGS++))
    else
        # 检查 MySQL 是否运行
        if nc -z "$DB_HOST" "$DB_PORT" 2>/dev/null; then
            echo -e "  ${GREEN}✓ MySQL 服务运行中 ($DB_HOST:$DB_PORT)${NC}"
            
            # 尝试连接数据库
            if command -v mysql &> /dev/null && [ -n "$DB_PASS" ]; then
                if mysql --default-character-set=utf8mb4 -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME" &>/dev/null 2>&1; then
                    echo -e "  ${GREEN}✓ 数据库连接成功${NC}"
                else
                    echo -e "  ${YELLOW}! 数据库连接失败，请检查配置${NC}"
                    ((WARNINGS++))
                fi
            fi
        else
            echo -e "  ${YELLOW}! MySQL 服务未运行或无法连接 ($DB_HOST:$DB_PORT)${NC}"
            ((WARNINGS++))
        fi
    fi
else
    echo -e "  ${YELLOW}! .env 文件不存在${NC}"
    ((WARNINGS++))
fi

# 检查Redis连接
echo ""
echo -e "${BLUE}[5/8] 检查 Redis 连接...${NC}"
if nc -z 127.0.0.1 6379 2>/dev/null; then
    if command -v redis-cli &> /dev/null; then
        if redis-cli -h 127.0.0.1 -p 6379 ping &>/dev/null 2>&1; then
            echo -e "  ${GREEN}✓ Redis 连接成功${NC}"
        else
            echo -e "  ${YELLOW}! Redis 连接失败${NC}"
            ((WARNINGS++))
        fi
    else
        echo -e "  ${GREEN}✓ Redis 服务运行中（端口 6379）${NC}"
    fi
else
    echo -e "  ${YELLOW}! Redis 未运行或无法连接（可选）${NC}"
    ((WARNINGS++))
fi

# 检查环境变量
echo ""
echo -e "${BLUE}[6/8] 检查环境变量...${NC}"
if [ -f "$ROOT_DIR/.env" ]; then
    echo -e "  ${GREEN}✓ .env 文件存在${NC}"
    
    # 检查关键配置项
    if grep -q "^\[DATABASE\]" "$ROOT_DIR/.env" 2>/dev/null; then
        # ThinkPHP 格式
        REQUIRED_VARS=("DATABASE" "USERNAME" "PASSWORD")
        for var in "${REQUIRED_VARS[@]}"; do
            if grep -q "^${var}=" "$ROOT_DIR/.env"; then
                echo -e "  ${GREEN}✓ $var 已配置${NC}"
            else
                echo -e "  ${YELLOW}! $var 未配置${NC}"
                ((WARNINGS++))
            fi
        done
    else
        echo -e "  ${YELLOW}! 未找到 [DATABASE] 配置段${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "  ${YELLOW}! .env 文件不存在，运行: cp .example.env .env${NC}"
    ((WARNINGS++))
fi

# 检查文件权限
echo ""
echo -e "${BLUE}[7/8] 检查文件权限...${NC}"
RUNTIME_DIR="$ROOT_DIR/runtime"
if [ -d "$RUNTIME_DIR" ]; then
    if [ -w "$RUNTIME_DIR" ]; then
        echo -e "  ${GREEN}✓ runtime 目录可写${NC}"
    else
        echo -e "  ${RED}✗ runtime 目录不可写${NC}"
        echo -e "    修复: chmod -R 777 $RUNTIME_DIR"
        ((ERRORS++))
    fi
else
    echo -e "  ${YELLOW}! runtime 目录不存在${NC}"
    ((WARNINGS++))
fi

UPLOADS_DIR="$ROOT_DIR/public/uploads"
if [ -d "$UPLOADS_DIR" ]; then
    if [ -w "$UPLOADS_DIR" ]; then
        echo -e "  ${GREEN}✓ public/uploads 目录可写${NC}"
    else
        echo -e "  ${YELLOW}! public/uploads 目录不可写${NC}"
        echo -e "    修复: chmod -R 777 $UPLOADS_DIR"
        ((WARNINGS++))
    fi
fi

# 检查Docker（可选）
echo ""
echo -e "${BLUE}[8/8] 检查 Docker（可选）...${NC}"
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    echo -e "  ${GREEN}✓ $DOCKER_VERSION${NC}"
    
    if docker ps &>/dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Docker 服务运行中${NC}"
    else
        echo -e "  ${YELLOW}! Docker 服务未运行${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "  ${YELLOW}! Docker 未安装（可选）${NC}"
fi

# 总结
echo ""
echo "=========================================="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ 环境检查通过！${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}! 检查完成，有 $WARNINGS 个警告${NC}"
    echo ""
    echo "提示：警告不影响基本使用，但建议修复以获得最佳体验"
    exit 0
else
    echo -e "${RED}✗ 检查失败，发现 $ERRORS 个错误，$WARNINGS 个警告${NC}"
    echo ""
    echo "请修复错误后重试"
    exit 1
fi
