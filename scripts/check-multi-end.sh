#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "[multi-end] 当前目录不是 Git 仓库，跳过改动检查"
    exit 0
fi

if git rev-parse --verify HEAD >/dev/null 2>&1; then
    DIFF_BASE=(HEAD)
else
    DIFF_BASE=(--cached)
fi

CHANGED="$({
    git diff --name-only "${DIFF_BASE[@]}"
    git ls-files --others --exclude-standard
} | sort -u)"

if [ -z "$CHANGED" ]; then
    echo "[multi-end] 工作区无改动"
    exit 0
fi

SHARED_CHANGED="$(printf '%s\n' "$CHANGED" | grep -E '^(app/admin/|app/api/|app/common\.php$|config/|route/|evui/src/)' || true)"
if [ -z "$SHARED_CHANGED" ]; then
    echo "[multi-end] 未检测到需要跨端评估的改动"
    exit 0
fi

TARGET_DIRS="${MULTI_END_DIRS:-}"
if [ -z "$TARGET_DIRS" ]; then
    for dir in flutter_app uniapp miniprogram mini-program wxapp; do
        if [ -d "$dir" ]; then
            TARGET_DIRS="$TARGET_DIRS $dir"
        fi
    done
fi

TARGET_DIRS="$(printf '%s' "$TARGET_DIRS" | tr ',' ' ' | xargs)"
if [ -z "$TARGET_DIRS" ]; then
    echo "[multi-end] 当前项目没有独立客户端目录，跳过同步检查"
    exit 0
fi

CLIENT_CHANGED=""
for dir in $TARGET_DIRS public/h5; do
    MATCHES="$(printf '%s\n' "$CHANGED" | awk -v prefix="$dir/" 'index($0, prefix) == 1')"
    if [ -n "$MATCHES" ]; then
        CLIENT_CHANGED="${CLIENT_CHANGED}${CLIENT_CHANGED:+
}${MATCHES}"
    fi
done

if [ -z "$CLIENT_CHANGED" ]; then
    if [ "${MULTI_END_SYNC_NOT_APPLICABLE:-0}" = "1" ]; then
        echo "[multi-end] 已明确标记本次改动不影响独立客户端"
        exit 0
    fi
    echo "[multi-end] 检测到后台/API/共享定义改动，但没有客户端同步改动："
    printf '%s\n' "$SHARED_CHANGED"
    echo "[multi-end] 客户端目录: $TARGET_DIRS"
    echo "[multi-end] 请同步修改；确认不影响时使用 MULTI_END_SYNC_NOT_APPLICABLE=1，并在提交说明中记录原因。"
    exit 1
fi

echo "[multi-end] 跨端改动检查通过"
