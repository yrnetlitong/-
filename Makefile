# Makefile for project management
# 使用方法: make <command>

.PHONY: help install dev dev-stop dev-status dev-restart dev-logs dev-clean dev-open build test lint fix check-standards check-multi-end check-platforms build-platforms clean init check-env db-backup db-restore db-list db-import cleanup-todo cleanup-demo cleanup-debug security-check push-deploy create-project smoke-check

# 默认目标
help:
	@echo "可用命令:"
	@echo "  make install        - 安装所有依赖（PHP + 前端）"
	@echo ""
	@echo "本地开发:"
	@echo "  make dev              启动本地开发环境（自动检测 MySQL/Redis）"
	@echo "                        功能: 检查 MySQL/Redis → 启动 PHP 后端 → 启动 Vue 前端"
	@echo "                        查看帮助: ./scripts/dev/start.sh --help"
	@echo "  make dev-stop         停止本地开发环境（停止 PHP + Vue）"
	@echo "  make dev-status       查看本地环境状态（检查服务是否运行）"
	@echo "  make dev-restart [SERVICE=backend]  重启开发服务"
	@echo "  make dev-logs [SERVICE=backend] [--tail]  查看开发日志"
	@echo "  make dev-clean [TYPE=all]  清理开发环境（日志/缓存/PID）"
	@echo "  make dev-open [PAGE=frontend]  快速打开开发页面"
	@echo ""
	@echo "构建和测试:"
	@echo "  make build          - 构建生产版本"
	@echo "  make test           - 运行测试"
	@echo "  make lint           - 代码检查"
	@echo "  make fix            - 自动修复代码格式"
	@echo "  make check-standards - 全面检查代码标准"
	@echo "  make check-multi-end - 检查后台/API 改动是否同步评估其他端"
	@echo "  make check-platforms - 检查 Flutter/Web 子项目"
	@echo "  make build-platforms - 检查并构建 Flutter/Web 子项目"
	@echo "  make clean          - 清理缓存和临时文件"
	@echo "  make init           - 初始化项目（复制 .env、设置权限等）"
	@echo "  make check-env      - 检查环境配置"
	@echo ""
	@echo "数据库管理:"
	@echo "  make db-backup      - 备份数据库"
	@echo "  make db-restore FILE=xxx  - 恢复数据库"
	@echo "  make db-list       - 列出备份文件"
	@echo "  make db-import     - 导入数据库（交互式）"
	@echo ""
	@echo "前端构建:"
	@echo "  make build [MODE=prod]  - 构建前端（dev/test/preview/prod）"
	@echo ""
	@echo "项目创建:"
	@echo "  make create-project PROJECT_NAME=xxx [PROJECT_TYPE=backend] - 基于模板创建新项目"
	@echo ""
	@echo "清理命令:"
	@echo "  make cleanup-todo   - 清理无意义的 TODO 注释"
	@echo "  make cleanup-demo   - 清理演示文件"
	@echo "  make cleanup-debug  - 清理调试代码"
	@echo ""
	@echo "安全检查:"
	@echo "  make security-check - 运行安全检查脚本"
	@echo ""
	@echo "部署命令:"
	@echo "  make push-deploy            - 推送代码并部署到服务器（Git + SSH）"
	@echo "  make smoke-check BASE_URL=http://xxx  - 线上关键链路冒烟检查"
	@echo ""

# 安装依赖
install:
	@echo "安装 PHP 依赖..."
	composer install
	@echo "安装前端依赖..."
	@if [ -L evui/node_modules ]; then \
		echo "检测到共享 node_modules，跳过重复安装"; \
	else \
		cd evui && npm ci; \
	fi

# ============================================
# 本地开发环境
# ============================================

# 启动本地开发环境
dev:
	@bash scripts/dev/start.sh

# 停止本地开发环境
dev-stop:
	@bash scripts/dev/stop.sh

# 查看本地环境状态
dev-status:
	@bash scripts/dev/status.sh

# 重启开发服务
dev-restart:
	@bash scripts/dev/restart.sh $(SERVICE)

# 查看开发日志
dev-logs:
	@bash scripts/dev/logs.sh $(SERVICE) $(ARGS)

# 清理开发环境
dev-clean:
	@bash scripts/dev/clean.sh $(TYPE)

# 快速打开开发页面
dev-open:
	@bash scripts/dev/open.sh $(PAGE)

# ============================================
# 数据库管理
# ============================================

# 备份数据库
db-backup:
	@bash scripts/db-backup.sh

# 恢复数据库
db-restore:
	@if [ -z "$(FILE)" ]; then \
		echo "用法: make db-restore FILE=backups/database_xxx.sql"; \
	else \
		bash scripts/db-backup.sh --restore $(FILE); \
	fi

# 列出备份文件
db-list:
	@bash scripts/db-backup.sh --list

# 导入数据库
db-import:
	@bash scripts/import-database.sh

# ============================================
# 前端构建
# ============================================

# 构建生产版本
build:
	@bash scripts/build-frontend.sh $(MODE)

# 运行测试
test:
	@echo "运行 PHP 单元测试..."
	@if [ -d tests ]; then \
		./vendor/bin/phpunit; \
	else \
		echo "测试目录不存在，跳过测试"; \
	fi

# 代码检查
lint:
	@echo "检查 PHP 代码..."
	@if [ -f vendor/bin/php-cs-fixer ]; then \
		./vendor/bin/php-cs-fixer fix --dry-run --diff; \
	else \
		echo "PHP CS Fixer 未安装，跳过检查"; \
	fi
	@echo "检查前端代码..."
	cd evui && npm run lint

# 代码标准检查（全面检查）
check-standards:
	@bash scripts/check-code-standards.sh
	@bash scripts/check-multi-end.sh

# 后台、API 与独立客户端同步检查
check-multi-end:
	@bash scripts/check-multi-end.sh

# 按项目实际目录检查独立客户端
check-platforms:
	@bash scripts/check-platforms.sh

# 按项目实际目录检查并执行 Release 构建
build-platforms:
	@bash scripts/check-platforms.sh --build

# 自动修复代码格式
fix:
	@echo "修复 PHP 代码格式..."
	@if [ -f vendor/bin/php-cs-fixer ]; then \
		./vendor/bin/php-cs-fixer fix; \
	else \
		echo "PHP CS Fixer 未安装，跳过修复"; \
	fi
	@echo "修复前端代码格式..."
	cd evui && npm run lint -- --fix

# 清理缓存
clean:
	@echo "清理缓存..."
	rm -rf runtime/cache/*
	rm -rf runtime/temp/*
	rm -rf runtime/log/*
	cd evui && rm -rf node_modules/.cache
	@echo "缓存清理完成"

# 初始化项目
init:
	@bash scripts/init-project.sh

# 检查环境
check-env:
	@bash scripts/env-check.sh

# 清理无意义的 TODO 注释
cleanup-todo:
	@if [ -f scripts/cleanup-todo-comments.sh ]; then \
		bash scripts/cleanup-todo-comments.sh; \
	else \
		echo "脚本不存在: scripts/cleanup-todo-comments.sh（已跳过）"; \
	fi

# 清理演示文件
cleanup-demo:
	@if [ -f scripts/cleanup-demo-files.sh ]; then \
		bash scripts/cleanup-demo-files.sh; \
	else \
		echo "脚本不存在: scripts/cleanup-demo-files.sh（已跳过）"; \
	fi

# 清理调试代码
cleanup-debug:
	@bash scripts/cleanup-debug-code.sh

# 安全检查
security-check:
	@if [ -f scripts/fix-security-issues.sh ]; then \
		bash scripts/fix-security-issues.sh; \
	else \
		echo "脚本不存在: scripts/fix-security-issues.sh（已跳过）"; \
	fi

# 推送代码并部署到服务器（Git + SSH）
push-deploy:
	@MSG="$(MSG)" bash scripts/dev_push_master.sh

# 线上关键链路冒烟检查
smoke-check:
	@if [ -z "$(BASE_URL)" ]; then \
		echo "用法: make smoke-check BASE_URL=http://your-domain.com [API_PREFIX=/admin] [LOGIN_USER=admin] [LOGIN_PASS=123456]"; \
		exit 1; \
	fi
	@API_PREFIX="$(API_PREFIX)" LOGIN_USER="$(LOGIN_USER)" LOGIN_PASS="$(LOGIN_PASS)" bash scripts/smoke-check.sh "$(BASE_URL)"

# 基于模板创建新项目
# 使用方法: make create-project PROJECT_NAME=my-project [TARGET_DIR=../my-project] [PROJECT_TYPE=backend]
create-project:
	@if [ -z "$(PROJECT_NAME)" ]; then \
		echo "错误: 请提供项目名称"; \
		echo "使用方法: make create-project PROJECT_NAME=my-project [TARGET_DIR=../my-project] [PROJECT_TYPE=backend]"; \
		exit 1; \
	fi
	@PROJECT_TYPE="$(or $(PROJECT_TYPE),backend)" bash scripts/create-project.sh $(PROJECT_NAME) $(TARGET_DIR)

.PHONY: build-miniprogram upload-miniprogram
build-miniprogram:
	@bash scripts/build-miniprogram.sh

upload-miniprogram: build-miniprogram
	@if [ -z "$(VERSION)" ]; then echo "请指定 VERSION，例如 make upload-miniprogram VERSION=1.0.0"; exit 1; fi
	wxdev upload "$(or $(ACCOUNT),B)" "$(CURDIR)/miniprogram" "$(VERSION)" "$(or $(DESC),豆知宠物测试版)"
