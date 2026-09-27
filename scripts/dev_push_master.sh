#!/bin/bash

# 开发环境推送到主分支并部署脚本
# 自动推送代码到 Git，并在服务器上拉取更新
# 用法: make push-deploy [MSG="提交信息"]

set -euo pipefail

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

# 从环境变量获取提交信息（可通过 make push-deploy MSG="xxx" 传入）
COMMIT_MSG="${MSG:-deploy}"

# 读取配置文件
CONFIG_FILE=".deploy-ssh.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    error "配置文件 $CONFIG_FILE 不存在"
    exit 1
fi

source "$CONFIG_FILE"

# 验证配置
if [ -z "$SSH_HOST" ] || [ -z "$SSH_USER" ] || [ -z "$SERVER_PATH" ] || [ -z "$GIT_REPO" ]; then
    error "配置文件不完整，请检查 $CONFIG_FILE"
    exit 1
fi

GIT_BRANCH="${GIT_BRANCH:-main}"
WEB_USER="${WEB_USER:-www}"
WEB_GROUP="${WEB_GROUP:-www}"

if ! [[ "$WEB_USER" =~ ^[a-zA-Z_][a-zA-Z0-9_-]*$ ]] ||
   ! [[ "$WEB_GROUP" =~ ^[a-zA-Z_][a-zA-Z0-9_-]*$ ]]; then
    error "WEB_USER/WEB_GROUP 格式不合法"
    exit 1
fi

title "开发环境推送部署"

info "配置信息："
echo "  服务器: $SSH_USER@$SSH_HOST"
echo "  项目路径: $SERVER_PATH"
echo "  Git 仓库: $GIT_REPO"
echo "  Git 分支: $GIT_BRANCH"
echo ""

# 构建 SSH 命令
SSH_CMD="ssh"
if [ -n "${SSH_PORT:-}" ] && [ "$SSH_PORT" != "22" ]; then
    SSH_CMD="$SSH_CMD -p $SSH_PORT"
fi

# 如果配置了 SSH_KEY，使用指定的密钥
if [ -n "${SSH_KEY:-}" ] && [ -f "$SSH_KEY" ]; then
    SSH_CMD="$SSH_CMD -i $SSH_KEY"
fi

cd "$(dirname "$0")/.."

# 先确认站点和数据库由宝塔管理，避免部署出面板不可见的资源。
title "检查宝塔面板资源"
bash scripts/check-bt-resources.sh "$CONFIG_FILE"

# 0. 检测 evui 是否有改动，有则先本地 build
title "检查前端改动"
EVUI_DIRTY=""
if [ -n "$(git status --porcelain -- evui/src/ evui/public/ evui/package.json 2>/dev/null)" ]; then
    EVUI_DIRTY=1
elif [ -n "$(git diff --name-only HEAD -- evui/src/ evui/public/ evui/package.json 2>/dev/null)" ]; then
    EVUI_DIRTY=1
fi

if [ "$EVUI_DIRTY" = "1" ]; then
    info "检测到 evui 源码有改动，本地构建前端..."
    cd evui && npm run build && cd ..
    echo ""
fi

# 0.1 独立客户端存在时，提交和部署前必须完成跨端评估与发布构建
title "检查独立客户端"
bash scripts/check-multi-end.sh
if [ "${CHECK_PLATFORMS_ON_DEPLOY:-true}" = "true" ]; then
    bash scripts/check-platforms.sh --build
else
    warn "已通过 CHECK_PLATFORMS_ON_DEPLOY=false 跳过独立客户端构建"
fi

# 1. 确保在正确的分支
title "检查 Git 分支"
CUR_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [ "$CUR_BRANCH" != "$GIT_BRANCH" ]; then
    warn "当前分支: $CUR_BRANCH，切换到: $GIT_BRANCH"
    git checkout "$GIT_BRANCH" 2>/dev/null || git checkout -b "$GIT_BRANCH"
fi

# 检查远程仓库
if ! git remote | grep -q "origin"; then
    info "添加远程仓库..."
    git remote add origin "$GIT_REPO"
fi

# 更新远程 URL（如果已更改）
git remote set-url origin "$GIT_REPO"

# 2. 自动 add + commit（如果有未提交的更改）
title "处理本地更改"
if [ -n "$(git status --porcelain)" ]; then
    info "存在未提交修改，自动 add + commit..."
    git add -A
    git commit -m "$COMMIT_MSG"
    echo ""
else
    info "工作区干净，无需处理"
fi

# 3. 同步远程代码
title "同步远程代码"
info "检查远程分支..."
REMOTE_BRANCH_EXISTS=0
if git ls-remote --exit-code --heads origin "$GIT_BRANCH" >/dev/null 2>&1; then
    REMOTE_BRANCH_EXISTS=1
    git fetch origin "$GIT_BRANCH" --prune
else
    LS_REMOTE_STATUS=$?
    if [ "$LS_REMOTE_STATUS" -ne 2 ]; then
        error "无法访问远程仓库或检查分支，请检查网络和 Git 权限"
        exit 1
    fi
fi

REMOTE_REF="origin/$GIT_BRANCH"
if [ "$REMOTE_BRANCH_EXISTS" -eq 1 ] && git rev-parse --verify "$REMOTE_REF" >/dev/null 2>&1; then
    LOCAL_COMMIT="$(git rev-parse HEAD)"
    REMOTE_COMMIT="$(git rev-parse "$REMOTE_REF")"
    if [ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]; then
        if git merge-base --is-ancestor "$REMOTE_COMMIT" HEAD 2>/dev/null; then
            info "本地领先于远程，可以推送"
        else
            warn "本地落后于远程，尝试 pull..."
            git pull --rebase origin "$GIT_BRANCH" || {
                error "无法同步远程代码，请手动解决冲突"
                exit 1
            }
        fi
    else
        info "本地代码已是最新"
    fi
else
    warn "远程分支不存在，将创建新分支"
fi

# 4. 推送到远程
title "推送到 Git 仓库"
info "推送到分支: $GIT_BRANCH"
git push -u origin "$GIT_BRANCH" || {
    error "Git 推送失败"
    exit 1
}
info "Git 推送成功"

# 5. 在服务器上拉取更新
title "服务器拉取更新"
info "连接到服务器: $SSH_USER@$SSH_HOST"
info "项目路径: $SERVER_PATH"

$SSH_CMD "$SSH_USER@$SSH_HOST" "
set -e
cd '$SERVER_PATH'
ENV_BACKUP=''
restore_env() {
  if [ -n \"\$ENV_BACKUP\" ] && [ -f \"\$ENV_BACKUP\" ]; then
    mv -f \"\$ENV_BACKUP\" .env
  fi
}
trap restore_env EXIT
if [ -f .env ]; then
  ENV_BACKUP=\"\$(mktemp /tmp/deploy-env.XXXXXX)\"
  mv .env \"\$ENV_BACKUP\"
fi
git pull --ff-only origin '$GIT_BRANCH'
restore_env
trap - EXIT
"

LOCAL_HEAD="$(git rev-parse HEAD)"
REMOTE_HEAD="$($SSH_CMD "$SSH_USER@$SSH_HOST" "cd '$SERVER_PATH' && git rev-parse HEAD")"
if [ "$LOCAL_HEAD" != "$REMOTE_HEAD" ]; then
    error "服务器提交与本地不一致：$REMOTE_HEAD != $LOCAL_HEAD"
    exit 1
fi
info "服务器提交校验通过: ${LOCAL_HEAD:0:12}"

# 6. 服务器初始化依赖与目录权限
title "服务器初始化"
info "执行 composer install 与目录权限初始化..."
$SSH_CMD "$SSH_USER@$SSH_HOST" "
set -e
cd '$SERVER_PATH'
if [ ! -f .env ]; then
  if [ -f .example.env ]; then
    cp .example.env .env
    echo '[WARN] 远端缺少 .env，已由 .example.env 自动创建'
  else
    echo '[ERROR] 远端缺少 .env 且无 .example.env，无法继续'
    exit 1
  fi
fi

# 生产部署禁止继续使用示例数据库配置。
ENV_INVALID=0
if grep -Eq '^DATABASE\\s*=\\s*(test|your_database|)$' .env; then
  echo '[ERROR] .env DATABASE 仍为默认值或空值'
  ENV_INVALID=1
fi
if grep -Eq '^USERNAME\\s*=\\s*(username|)$' .env; then
  echo '[ERROR] .env USERNAME 仍为默认值或空值'
  ENV_INVALID=1
fi
if grep -Eq '^PASSWORD\\s*=\\s*(password|root123456|)$' .env; then
  echo '[ERROR] .env PASSWORD 仍为默认值或空值'
  ENV_INVALID=1
fi
[ \"\$ENV_INVALID\" -eq 0 ] || exit 1

if [ \"\$(id -u)\" -eq 0 ] && id '$WEB_USER' >/dev/null 2>&1; then
  chown '$WEB_USER:$WEB_GROUP' .env
fi
chmod 600 .env

if [ -f composer.json ]; then
  COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
fi
mkdir -p runtime/cache runtime/log runtime/temp public/uploads
chmod 775 runtime runtime/cache runtime/log runtime/temp public/uploads
if [ \"\$(id -u)\" -eq 0 ] && id '$WEB_USER' >/dev/null 2>&1; then
  chown -R '$WEB_USER:$WEB_GROUP' runtime public/uploads
fi
"

# 7. 可选初始化数据库导入（仅当显式开启）
if [ "${AUTO_IMPORT_SQL:-false}" = "true" ] && [ -f app/command/PetInstall.php ]; then
    error "宠物业务项目禁止 AUTO_IMPORT_SQL=true，请使用 php think pet:install 增量升级"
    exit 1
fi
if [ "${AUTO_IMPORT_SQL:-false}" = "true" ]; then
    title "初始化数据库导入"
    if [ -z "${INIT_SQL_FILE:-}" ] || [ -z "${DB_NAME:-}" ] || [ -z "${DB_USER:-}" ]; then
        error "AUTO_IMPORT_SQL=true 但缺少 INIT_SQL_FILE/DB_NAME/DB_USER"
        exit 1
    else
        DB_HOST="${DB_HOST:-127.0.0.1}"
        DB_PORT="${DB_PORT:-3306}"
        info "导入 SQL: $INIT_SQL_FILE -> $DB_NAME"
        $SSH_CMD "$SSH_USER@$SSH_HOST" "
set -e
cd $SERVER_PATH
[ -f '$INIT_SQL_FILE' ] || { echo 'SQL 文件不存在: $INIT_SQL_FILE'; exit 1; }
if [ -n '${DB_PASS:-}' ]; then
  mysql --default-character-set=utf8mb4 -h'$DB_HOST' -P'$DB_PORT' -u'$DB_USER' -p'${DB_PASS}' '$DB_NAME' < '$INIT_SQL_FILE'
else
  mysql --default-character-set=utf8mb4 -h'$DB_HOST' -P'$DB_PORT' -u'$DB_USER' '$DB_NAME' < '$INIT_SQL_FILE'
fi
"
    fi
fi

# 宠物业务只做幂等升级，禁止反复导入初始化数据。
if [ -f app/command/PetInstall.php ]; then
    $SSH_CMD "$SSH_USER@$SSH_HOST" "cd '$SERVER_PATH' && php think pet:install"
fi

if [ -f scripts/install-pet-reminder.sh ]; then
    bash scripts/install-pet-reminder.sh
fi

# 8. 可选在线冒烟检查
if [ -n "${DEPLOY_BASE_URL:-}" ]; then
    title "在线冒烟检查"
    bash scripts/smoke-check.sh "$DEPLOY_BASE_URL"
    info "冒烟检查通过"
fi

title "部署完成"
info "代码已推送到 Git 并部署到服务器"
