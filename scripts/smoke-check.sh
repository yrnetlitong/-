#!/bin/bash

set -euo pipefail

BASE_URL="${1:-}"
if [ -z "$BASE_URL" ]; then
  echo "用法: $0 <BASE_URL>"
  echo "示例: $0 http://init.yun3.yrnet.top"
  exit 1
fi

API_PREFIX="${API_PREFIX:-/admin}"
LOGIN_USER="${LOGIN_USER:-admin}"
LOGIN_PASS="${LOGIN_PASS:-123456}"

API_BASE="${BASE_URL%/}${API_PREFIX}"

echo "[smoke] base: $API_BASE"

CAPTCHA_RESP="$(curl -s -m 20 "$API_BASE/login/captcha")"
CAPTCHA_KEY="$(echo "$CAPTCHA_RESP" | sed -n 's/.*"key":"\([^"]*\)".*/\1/p')"
if [ -z "$CAPTCHA_KEY" ]; then
  echo "[smoke] captcha 接口异常: $CAPTCHA_RESP"
  exit 1
fi
echo "[smoke] captcha ok"

[[ "$CAPTCHA_KEY" =~ ^[A-Za-z0-9_-]+$ ]] || exit 1
if [ -z "${CAPTCHA_CODE:-}" ]; then
  PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
  CAPTCHA_PHP='require "vendor/autoload.php"; $app = new think\App(getcwd()); $app->initialize(); echo think\facade\Cache::get("login_captcha_" . $argv[1], "");'
  if [[ "$BASE_URL" =~ ^http://(127\.0\.0\.1|localhost)(:[0-9]+)?/?$ ]]; then
    CAPTCHA_CODE="$(cd "$PROJECT_ROOT" && php -r "$CAPTCHA_PHP" "$CAPTCHA_KEY")"
  elif [ -f "$PROJECT_ROOT/.deploy-ssh.conf" ]; then
    source "$PROJECT_ROOT/.deploy-ssh.conf"
    if [ "${BASE_URL%/}" != "${DEPLOY_BASE_URL%/}" ] || ! [[ "$SERVER_PATH" =~ ^/[A-Za-z0-9._/-]+$ ]]; then
      echo '[smoke] 请提供本次 CAPTCHA_CODE，或使用已配置的部署地址'
      exit 1
    fi
    SSH_ARGS=(-o BatchMode=yes -o ConnectTimeout=10 -p "${SSH_PORT:-22}")
    [ -z "${SSH_KEY:-}" ] || SSH_ARGS+=(-i "$SSH_KEY")
    CAPTCHA_CODE="$(ssh "${SSH_ARGS[@]}" "$SSH_USER@$SSH_HOST" "cd '$SERVER_PATH' && php -r '$CAPTCHA_PHP' '$CAPTCHA_KEY'")"
  fi
fi
if ! [[ "${CAPTCHA_CODE:-}" =~ ^[0-9]+$ ]]; then
  echo '[smoke] 无法获取本次实际验证码'
  exit 1
fi
LOGIN_RESP="$(curl -s -m 20 "$API_BASE/login/login" -X POST -H 'Content-Type: application/json' -d "{\"username\":\"$LOGIN_USER\",\"password\":\"$LOGIN_PASS\",\"captcha\":\"$CAPTCHA_CODE\",\"key\":\"$CAPTCHA_KEY\"}")"
TOKEN="$(echo "$LOGIN_RESP" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')"
if [ -z "$TOKEN" ]; then
  echo "[smoke] login 接口异常: $LOGIN_RESP"
  exit 1
fi
AUTH_HEADER="Authorization: Bearer $TOKEN"
echo "[smoke] login ok"

MENU_RESP="$(curl -s -m 20 "$API_BASE/index/getMenuList" -H "$AUTH_HEADER")"
if ! echo "$MENU_RESP" | grep -q '"code":0'; then
  echo "[smoke] menu 接口异常: $MENU_RESP"
  exit 1
fi
echo "[smoke] menu ok"

UPLOAD_TMP="/tmp/init_smoke_upload.png"
base64 -d > "$UPLOAD_TMP" <<'EOF'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+yP7kAAAAASUVORK5CYII=
EOF
UPLOAD_RESP="$(curl -s -m 30 "$API_BASE/upload/uploadImage" -H "$AUTH_HEADER" -F "file=@$UPLOAD_TMP;type=image/png")"
if ! echo "$UPLOAD_RESP" | grep -q '"code":0'; then
  echo "[smoke] upload 接口异常: $UPLOAD_RESP"
  exit 1
fi
echo "[smoke] upload ok"

LOGOUT_RESP="$(curl -s -m 20 "$API_BASE/login/logout" -H "$AUTH_HEADER")"
if ! echo "$LOGOUT_RESP" | grep -q '"code":0'; then
  echo "[smoke] logout 接口异常: $LOGOUT_RESP"
  exit 1
fi
echo "[smoke] logout ok"

NO_TOKEN_MENU="$(curl -s -m 20 "$API_BASE/index/getMenuList")"
if ! echo "$NO_TOKEN_MENU" | grep -q '{}'; then
  echo "[smoke] 未登录鉴权返回异常: $NO_TOKEN_MENU"
  exit 1
fi
echo "[smoke] auth guard ok"

echo "[smoke] all passed"
