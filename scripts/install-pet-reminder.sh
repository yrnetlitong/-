#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
source .deploy-ssh.conf
[[ "$SERVER_PATH" =~ ^/[A-Za-z0-9._/-]+$ ]] || exit 1
SSH_ARGS=(-o BatchMode=yes -o ConnectTimeout=10 -p "${SSH_PORT:-22}")
[ -z "${SSH_KEY:-}" ] || SSH_ARGS+=(-i "$SSH_KEY")
ssh "${SSH_ARGS[@]}" "$SSH_USER@$SSH_HOST" "/www/server/panel/pyenv/bin/python - '$SERVER_PATH'" <<'PY'
import os, sys, shlex
os.chdir('/www/server/panel')
sys.path.insert(0, '/www/server/panel/class')
import public
from BTPanel import app
from crontab import crontab
project = sys.argv[1]
name = '豆知宠物到期提醒 ' + os.path.basename(os.path.dirname(project))
body = 'cd ' + project + ' && /usr/bin/env php think pet:remind'
with app.test_request_context('/crontab?action=AddCrontab'):
    existing = public.M('crontab').where('name=?', (name,)).field('id,name,status').find()
    if existing:
        if int(existing['status']) != 1:
            raise SystemExit('提醒任务已存在但被暂停，请在宝塔检查')
        print('宝塔提醒任务已存在，ID=' + str(existing['id']))
    else:
        args = public.dict_obj()
        for key, value in dict(name=name, type='minute-n', where1='1', hour='0', minute='0', week='', sType='toShell', sName='', sBody=body, urladdress='', save='7', backupTo='localhost', flock=1, user='www').items():
            setattr(args, key, value)
        result = crontab().AddCrontab(args)
        if not result.get('status'):
            raise SystemExit(str(result.get('msg', '创建宝塔提醒任务失败')))
        print('宝塔提醒任务创建完成，ID=' + str(result.get('id')))
PY
