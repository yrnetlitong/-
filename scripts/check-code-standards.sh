#!/bin/bash

# 代码标准检查脚本
# 检查项目代码是否符合 CODE_STANDARDS.md 中定义的标准

set -e

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

section() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# 检查结果统计
ERRORS=0
WARNINGS=0

# 检查标准配置文件是否存在
section "检查代码标准配置文件"

STANDARD_FILES=(
    "AGENTS.md:仓库规则"
    "AI_GUIDE.md:开发执行清单"
    "ADAPTATION_STANDARDS.md:PC/H5 适配规范"
    ".php_cs.dist.php:PHP CS Fixer 配置"
    "phpstan.neon.dist:PHPStan 配置"
    ".editorconfig:编辑器配置"
    ".nvmrc:Node 版本"
    "evui/package-lock.json:前端依赖锁文件"
    "evui/.eslintrc.js:ESLint 配置"
    "evui/.editorconfig:前端编辑器配置"
    "CODE_STANDARDS.md:代码标准文档"
)

for file_info in "${STANDARD_FILES[@]}"; do
    IFS=':' read -r file desc <<< "$file_info"
    if [ -f "$file" ]; then
        info "✓ $file ($desc)"
    else
        error "✗ $file ($desc) - 文件不存在"
        ((ERRORS++))
    fi
done

# 检查 PHP 代码规范工具
section "检查 PHP 代码规范工具"

if [ -f vendor/bin/php-cs-fixer ]; then
    info "✓ PHP CS Fixer 已安装"
    ./vendor/bin/php-cs-fixer --version | head -1
else
    warn "✗ PHP CS Fixer 未安装"
    echo "  安装命令: composer require --dev friendsofphp/php-cs-fixer"
    ((WARNINGS++))
fi

if [ -f vendor/bin/phpstan ]; then
    info "✓ PHPStan 已安装"
    ./vendor/bin/phpstan --version | head -1
else
    warn "✗ PHPStan 未安装"
    echo "  安装命令: composer require --dev phpstan/phpstan"
    ((WARNINGS++))
fi

# 检查前端代码规范工具
section "检查前端代码规范工具"

if [ -d evui/node_modules ]; then
    if [ -f evui/node_modules/.bin/eslint ]; then
        info "✓ ESLint 已安装"
        cd evui && npm list eslint 2>/dev/null | grep eslint | head -1 && cd ..
    else
        warn "✗ ESLint 未安装"
        echo "  安装命令: cd evui && npm install"
        ((WARNINGS++))
    fi
else
    warn "✗ node_modules 目录不存在"
    echo "  安装命令: cd evui && npm install"
    ((WARNINGS++))
fi

# 检查 EditorConfig 支持
section "检查 EditorConfig 支持"

if command -v editorconfig &> /dev/null; then
    info "✓ EditorConfig CLI 工具已安装"
else
    warn "✗ EditorConfig CLI 工具未安装（可选）"
    echo "  建议在编辑器中安装 EditorConfig 插件"
    echo "  VSCode: EditorConfig for VS Code"
    echo "  PhpStorm: 内置支持"
fi

# 检查代码格式（如果工具已安装）
section "检查代码格式"

# PHP 代码检查
if [ -f vendor/bin/php-cs-fixer ]; then
    info "运行 PHP CS Fixer 检查..."
    if ./vendor/bin/php-cs-fixer fix --dry-run --diff > /tmp/php-cs-fixer-check.log 2>&1; then
        info "✓ PHP 代码格式检查通过"
    else
        error "✗ PHP 代码格式检查失败"
        echo "  查看详情: cat /tmp/php-cs-fixer-check.log"
        echo "  自动修复: make fix"
        ((ERRORS++))
    fi
else
    warn "跳过 PHP 代码格式检查（PHP CS Fixer 未安装）"
fi

# 前端代码检查
if [ -f evui/node_modules/.bin/eslint ]; then
    info "运行 ESLint 检查..."
    cd evui
    if npm run lint > /tmp/eslint-check.log 2>&1; then
        info "✓ 前端代码格式检查通过"
    else
        error "✗ 前端代码格式检查失败"
        echo "  查看详情: cat /tmp/eslint-check.log"
        echo "  自动修复: cd evui && npm run lint -- --fix"
        ((ERRORS++))
    fi
    cd ..
else
    warn "跳过前端代码格式检查（ESLint 未安装）"
fi

# 检查文件编码和换行符（示例检查）
section "检查文件编码和换行符（示例）"

# 检查 PHP 文件是否使用 LF 换行符
PHP_FILES=$(find app config route extend -name "*.php" -type f 2>/dev/null | head -5)
if [ -n "$PHP_FILES" ]; then
    CR_COUNT=0
    for file in $PHP_FILES; do
        if file "$file" | grep -q "CRLF"; then
            ((CR_COUNT++))
        fi
    done
    
    if [ $CR_COUNT -eq 0 ]; then
        info "✓ 示例 PHP 文件使用 LF 换行符"
    else
        warn "✗ 发现 $CR_COUNT 个 PHP 文件使用 CRLF 换行符（应使用 LF）"
        ((WARNINGS++))
    fi
fi

# 检查缩进（示例检查）
section "检查缩进规范（示例）"

# 检查 PHP 文件是否使用 4 空格缩进
PHP_SAMPLE=$(find app -name "*.php" -type f 2>/dev/null | head -1)
if [ -n "$PHP_SAMPLE" ] && [ -f "$PHP_SAMPLE" ]; then
    if grep -q "^    " "$PHP_SAMPLE" 2>/dev/null; then
        info "✓ PHP 文件使用 4 空格缩进（示例检查）"
    else
        warn "✗ PHP 文件可能未使用 4 空格缩进（示例检查）"
        ((WARNINGS++))
    fi
fi

# 检查 Vue 文件是否使用 2 空格缩进
VUE_SAMPLE=$(find evui/src -name "*.vue" -type f 2>/dev/null | head -1)
if [ -n "$VUE_SAMPLE" ] && [ -f "$VUE_SAMPLE" ]; then
    if grep -q "^  " "$VUE_SAMPLE" 2>/dev/null; then
        info "✓ Vue 文件使用 2 空格缩进（示例检查）"
    else
        warn "✗ Vue 文件可能未使用 2 空格缩进（示例检查）"
        ((WARNINGS++))
    fi
fi

# 检查占位内容（TODO/开发中/占位跳转）
section "检查占位内容"

PLACEHOLDER_MATCHES=$(
    rg -n \
    --glob '!docs/**' \
    --glob '!scripts/**' \
    --glob '!public/tinymce/**' \
    --glob '!vendor/**' \
    --glob '!runtime/**' \
    "TODO|FIXME|开发中|敬请期待|占位|href=\"#\"|javascript:void\\(0\\)" \
    app evui/src 2>/dev/null || true
)

if [ -n "$PLACEHOLDER_MATCHES" ]; then
    error "✗ 检测到占位内容，请清理后再提交"
    echo "$PLACEHOLDER_MATCHES"
    ((ERRORS++))
else
    info "✓ 未检测到 TODO/开发中/占位跳转"
fi

# 总结
section "检查总结"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    info "✓ 所有检查通过！代码符合标准。"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    warn "检查完成，发现 $WARNINGS 个警告"
    echo ""
    echo "建议："
    echo "  - 安装缺失的工具: make install"
    echo "  - 查看 CODE_STANDARDS.md 了解详细标准"
    exit 0
else
    error "检查完成，发现 $ERRORS 个错误，$WARNINGS 个警告"
    echo ""
    echo "修复建议："
    echo "  - 运行 make fix 自动修复代码格式"
    echo "  - 查看 CODE_STANDARDS.md 了解详细标准"
    exit 1
fi
