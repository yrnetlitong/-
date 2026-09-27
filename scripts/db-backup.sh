#!/bin/bash
# 数据库备份脚本
# 用法: ./db-backup.sh [--help] [--restore backup_file.sql] [--list]

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$ROOT_DIR/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 显示帮助信息
show_help() {
    echo ""
    echo "=========================================="
    echo "    数据库备份/恢复脚本 - db-backup.sh"
    echo "=========================================="
    echo ""
    echo "用法:"
    echo "  ./scripts/db-backup.sh                  # 备份数据库"
    echo "  ./scripts/db-backup.sh --restore <file> # 恢复数据库"
    echo "  ./scripts/db-backup.sh --list           # 列出备份文件"
    echo "  ./scripts/db-backup.sh --help           # 显示帮助"
    echo ""
    echo "功能:"
    echo "  备份: 导出MySQL数据库到SQL文件"
    echo "  恢复: 从SQL文件恢复数据库"
    echo "  列表: 查看所有备份文件"
    echo ""
    echo "备份文件位置: backups/"
    echo ""
    echo "示例:"
    echo "  ./scripts/db-backup.sh"
    echo "  ./scripts/db-backup.sh --restore backups/database_20260130_120000.sql"
    echo "  ./scripts/db-backup.sh --list"
    echo "  make db-backup"
    echo "  make db-restore FILE=backups/database_20260130_120000.sql"
    echo ""
}

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
    
    # 如果数据库名未配置，提示输入
    if [ -z "$DB_NAME" ]; then
        echo -e "${YELLOW}数据库名未在 .env 中配置，请手动输入${NC}"
        read -p "数据库名称: " DB_NAME
        if [ -z "$DB_NAME" ]; then
            echo -e "${RED}错误: 数据库名称不能为空${NC}"
            exit 1
        fi
    fi
}

# 备份数据库
backup_database() {
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}    数据库备份${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo ""
    
    load_db_config
    
    # 创建备份目录
    mkdir -p "$BACKUP_DIR"
    
    BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql"
    
    echo -e "${YELLOW}数据库: ${DB_NAME}${NC}"
    echo -e "${YELLOW}主机: ${DB_HOST}:${DB_PORT}${NC}"
    echo -e "${YELLOW}备份到: ${BACKUP_FILE}${NC}"
    echo ""
    
    # 检查 MySQL 客户端
    if ! command -v mysqldump &> /dev/null; then
        echo -e "${RED}错误: mysqldump 未安装${NC}"
        exit 1
    fi
    
    # 执行备份
    echo -e "${YELLOW}正在备份...${NC}"
    if [ -n "$DB_PASS" ]; then
        mysqldump --default-character-set=utf8mb4 -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_FILE" 2>/dev/null
    else
        mysqldump --default-character-set=utf8mb4 -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" "$DB_NAME" > "$BACKUP_FILE" 2>/dev/null
    fi
    
    if [ $? -eq 0 ] && [ -f "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
        FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
        echo -e "${GREEN}✓ 备份完成${NC}"
        echo -e "  文件: $BACKUP_FILE"
        echo -e "  大小: $FILE_SIZE"
        
        # 压缩备份（可选）
        read -p "是否压缩备份文件？[Y/n]: " COMPRESS
        COMPRESS=${COMPRESS:-Y}
        if [[ "$COMPRESS" =~ ^[Yy]$ ]]; then
            if command -v gzip &> /dev/null; then
                gzip "$BACKUP_FILE"
                echo -e "${GREEN}✓ 已压缩: ${BACKUP_FILE}.gz${NC}"
            else
                echo -e "${YELLOW}! gzip 未安装，跳过压缩${NC}"
            fi
        fi
    else
        echo -e "${RED}✗ 备份失败，请检查数据库配置和连接${NC}"
        rm -f "$BACKUP_FILE"
        exit 1
    fi
}

# 恢复数据库
restore_database() {
    local backup_file=$1
    
    if [ -z "$backup_file" ]; then
        echo -e "${RED}错误: 请指定备份文件${NC}"
        echo "用法: ./db-backup.sh --restore <backup_file>"
        exit 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        # 尝试在backups目录查找
        if [ -f "$BACKUP_DIR/$backup_file" ]; then
            backup_file="$BACKUP_DIR/$backup_file"
        else
            echo -e "${RED}错误: 备份文件不存在: $backup_file${NC}"
            exit 1
        fi
    fi
    
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}    数据库恢复${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo ""
    
    load_db_config
    
    echo -e "${RED}警告: 此操作将覆盖现有数据库！${NC}"
    echo -e "${YELLOW}数据库: ${DB_NAME}${NC}"
    echo -e "${YELLOW}备份文件: ${backup_file}${NC}"
    echo ""
    read -p "确认恢复？[y/N]: " CONFIRM
    
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "已取消"
        exit 0
    fi
    
    # 检查 MySQL 客户端
    if ! command -v mysql &> /dev/null; then
        echo -e "${RED}错误: mysql 客户端未安装${NC}"
        exit 1
    fi
    
    # 解压（如果是gz文件）
    if [[ "$backup_file" == *.gz ]]; then
        echo -e "${YELLOW}解压备份文件...${NC}"
        if command -v gunzip &> /dev/null; then
            gunzip -c "$backup_file" > "${backup_file%.gz}"
            backup_file="${backup_file%.gz}"
        else
            echo -e "${RED}错误: gunzip 未安装${NC}"
            exit 1
        fi
    fi
    
    # 执行恢复
    echo -e "${YELLOW}正在恢复...${NC}"
    if [ -n "$DB_PASS" ]; then
        mysql --default-character-set=utf8mb4 -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$backup_file" 2>/dev/null
    else
        mysql --default-character-set=utf8mb4 -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" "$DB_NAME" < "$backup_file" 2>/dev/null
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 恢复完成${NC}"
    else
        echo -e "${RED}✗ 恢复失败，请检查数据库配置和备份文件${NC}"
        exit 1
    fi
}

# 列出备份文件
list_backups() {
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}    备份文件列表${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo ""
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        echo "暂无备份文件"
        return
    fi
    
    echo "备份目录: $BACKUP_DIR"
    echo ""
    printf "%-40s %-12s %s\n" "文件名" "大小" "修改时间"
    echo "----------------------------------------------------------------"
    
    for file in "$BACKUP_DIR"/*.sql*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            size=$(du -h "$file" | cut -f1)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                mtime=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$file" 2>/dev/null)
            else
                mtime=$(stat -c "%y" "$file" 2>/dev/null | cut -d. -f1)
            fi
            printf "%-40s %-12s %s\n" "$filename" "$size" "$mtime"
        fi
    done
    echo ""
}

# 主逻辑
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    show_help
    exit 0
fi

if [[ "$1" == "--list" ]] || [[ "$1" == "-l" ]]; then
    list_backups
    exit 0
fi

if [[ "$1" == "--restore" ]] || [[ "$1" == "-r" ]]; then
    restore_database "$2"
    exit 0
fi

# 默认执行备份
backup_database
