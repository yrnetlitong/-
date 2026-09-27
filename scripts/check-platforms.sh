#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_RELEASE=0
if [ "${1:-}" = "--build" ]; then
    BUILD_RELEASE=1
fi

FOUND=0

if [ -f "$ROOT_DIR/miniprogram/app.json" ]; then
    FOUND=1
    bash "$ROOT_DIR/scripts/build-miniprogram.sh"
fi

if [ -d "$ROOT_DIR/flutter_app" ]; then
    FOUND=1
    command -v flutter >/dev/null 2>&1 || {
        echo "[platform] 检测到 flutter_app，但未安装 flutter"
        exit 1
    }
    (
        cd "$ROOT_DIR/flutter_app"
        flutter analyze
        if [ -n "$(find test -type f -name '*_test.dart' -print -quit 2>/dev/null)" ]; then
            flutter test
        fi
        if [ "$BUILD_RELEASE" -eq 1 ]; then
            flutter build web --release
        fi
    )
fi

if [ -f "$ROOT_DIR/web/package.json" ]; then
    FOUND=1
    command -v npm >/dev/null 2>&1 || {
        echo "[platform] 检测到 web/package.json，但未安装 npm"
        exit 1
    }
    (
        cd "$ROOT_DIR/web"
        [ -d node_modules ] || npm ci
        npm run lint --if-present
        npm test --if-present
        if [ "$BUILD_RELEASE" -eq 1 ]; then
            npm run build
        fi
    )
fi

if [ "$FOUND" -eq 0 ]; then
    echo "[platform] 未检测到需要独立验证的 Flutter/Web 项目"
else
    echo "[platform] 平台检查通过"
fi
