#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [ -f .deploy-ssh.conf ]; then
    source .deploy-ssh.conf
fi
export PETKNOW_API_BASE="${PETKNOW_API_BASE:-${DEPLOY_BASE_URL:-}/api}"
python3 - <<'PY'
import json, os, re
from pathlib import Path
from urllib.parse import urlparse
base = os.environ['PETKNOW_API_BASE'].rstrip('/')
if urlparse(base).scheme not in ('https', 'http') or not urlparse(base).hostname:
    raise SystemExit('请配置 PETKNOW_API_BASE 或 DEPLOY_BASE_URL')
root = Path('miniprogram')
(root / 'config.js').write_text('module.exports = ' + json.dumps({'apiBase': base}) + '\n')
app = json.loads((root / 'app.json').read_text())
for page in app['pages']:
    for extension in ['.js', '.json', '.wxml']:
        if not (root / (page + extension)).is_file():
            raise SystemExit('缺少页面文件：' + page + extension)
for file in root.rglob('*.json'):
    json.loads(file.read_text())
for file in root.rglob('*.wxml'):
    if re.search(r'wx:(?:if|elif)="(?!{{)', file.read_text()):
        raise SystemExit('条件必须使用数据绑定：' + str(file))
print('小程序环境、页面、条件绑定与 JSON 校验通过')
PY
while IFS= read -r file; do node --check "$file"; done < <(find miniprogram -type f -name '*.js')
WX_COMPILER="${WX_COMPILER:-/Applications/wechatwebdevtools.app/Contents/Resources/package.nw/node_modules/wcc-exec/wcc}"
if [ -x "$WX_COMPILER" ]; then
    OUTPUT="$(mktemp /tmp/petknow-wxml.XXXXXX)"
    trap 'rm -f "$OUTPUT"' EXIT
    (cd miniprogram && "$WX_COMPILER" -o "$OUTPUT" $(find pages templates -name '*.wxml'))
    echo '微信官方 WXML 编译通过'
else
    echo '[ERROR] 未找到微信 WXML 编译器，请配置 WX_COMPILER'
    exit 1
fi
