#!/bin/bash

set -euo pipefail

CONFIG_FILE="${1:-.deploy-ssh.conf}"
[ -f "$CONFIG_FILE" ] || { echo "[ERROR] 配置文件不存在: $CONFIG_FILE"; exit 1; }

# shellcheck disable=SC1090
source "$CONFIG_FILE"

if [ "${REQUIRE_BT_RECORDS:-true}" != "true" ]; then
    echo "[WARN] 已跳过宝塔面板资源检查"
    exit 0
fi

SITE_DOMAIN="${SITE_DOMAIN:-}"
if [ -z "$SITE_DOMAIN" ] && [ -n "${DEPLOY_BASE_URL:-}" ]; then
    SITE_DOMAIN="$(printf '%s' "$DEPLOY_BASE_URL" | sed -E 's#^[a-zA-Z]+://##; s#/.*$##; s/:.*$//')"
fi

for name in SSH_HOST SSH_USER SERVER_PATH SITE_DOMAIN DB_NAME DB_USER; do
    [ -n "${!name:-}" ] || { echo "[ERROR] 宝塔资源检查缺少配置: $name"; exit 1; }
done

[[ "$SITE_DOMAIN" =~ ^[A-Za-z0-9.-]+$ ]] || { echo "[ERROR] SITE_DOMAIN 格式不合法"; exit 1; }
[[ "$DB_NAME" =~ ^[A-Za-z0-9_]+$ ]] || { echo "[ERROR] DB_NAME 格式不合法"; exit 1; }
[[ "$DB_USER" =~ ^[A-Za-z0-9_]+$ ]] || { echo "[ERROR] DB_USER 格式不合法"; exit 1; }
[[ "$SERVER_PATH" =~ ^/[A-Za-z0-9._/-]+$ ]] || { echo "[ERROR] SERVER_PATH 必须是安全的绝对路径"; exit 1; }
[[ "${REQUIRE_HTTPS:-true}" =~ ^(true|false)$ ]] || { echo "[ERROR] REQUIRE_HTTPS 只能是 true 或 false"; exit 1; }

SSH_ARGS=(-o BatchMode=yes -o ConnectTimeout=10)
[ -z "${SSH_PORT:-}" ] || [ "$SSH_PORT" = "22" ] || SSH_ARGS+=(-p "$SSH_PORT")
[ -z "${SSH_KEY:-}" ] || [ ! -f "$SSH_KEY" ] || SSH_ARGS+=(-i "$SSH_KEY")

echo "[INFO] 检查宝塔面板记录: $SITE_DOMAIN / $DB_NAME"
ssh "${SSH_ARGS[@]}" "$SSH_USER@$SSH_HOST" \
    "PYTHON=/www/server/panel/pyenv/bin/python; [ -x \"\$PYTHON\" ] || PYTHON=python3; exec \"\$PYTHON\" - '$SITE_DOMAIN' '$SERVER_PATH' '$DB_NAME' '$DB_USER' '${REQUIRE_HTTPS:-true}'" <<'PY'
import os
import sys

domain, project_path, db_name, db_user, require_https = sys.argv[1:]
panel_dir = "/www/server/panel"
vhost_dir = "/www/server/panel/vhost/nginx"

if not os.path.isdir(panel_dir):
    raise SystemExit("[ERROR] 未检测到宝塔面板，禁止按宝塔部署")

os.chdir(panel_dir)
sys.path.insert(0, panel_dir + "/class")
import public

site = public.M("sites").where("name=?", (domain,)).field("id,name,path").find()
if not site:
    domain_row = public.M("domain").where("name=?", (domain,)).field("pid").find()
    if domain_row:
        site = public.M("sites").where("id=?", (domain_row["pid"],)).field("id,name,path").find()
if not site:
    raise SystemExit(f"[ERROR] 宝塔面板中看不到站点/域名: {domain}")

database = public.M("databases").where(
    "name=? AND username=?", (db_name, db_user)
).field("name,username").find()
if not database:
    raise SystemExit(f"[ERROR] 宝塔面板中看不到数据库或用户不匹配: {db_name}/{db_user}")

site_path = os.path.realpath(site["path"])
project_path = os.path.realpath(project_path)
if os.path.commonpath((site_path, project_path)) not in (site_path, project_path):
    raise SystemExit(f"[ERROR] 宝塔站点目录与部署目录不匹配: {site['path']} / {project_path}")

configs = []
if os.path.isdir(vhost_dir):
    for filename in os.listdir(vhost_dir):
        if not filename.endswith(".conf"):
            continue
        path = os.path.join(vhost_dir, filename)
        try:
            content = open(path, encoding="utf-8", errors="ignore").read()
        except OSError:
            continue
        if domain in content:
            configs.append(content)

if not configs:
    raise SystemExit(f"[ERROR] 未找到域名对应的宝塔 nginx 配置: {domain}")
if require_https == "true":
    config = "\n".join(configs)
    if "listen 443" not in config or "ssl_certificate" not in config:
        raise SystemExit(f"[ERROR] 域名尚未在宝塔中启用 HTTPS: {domain}")

print(f"[INFO] 宝塔资源检查通过: {domain} / {db_name}")
PY
