#!/bin/bash

###############################################################################
# Running App - 安全检查脚本
#
# 用途: 检查依赖安全漏洞、配置安全、文件权限等
# 用法: ./scripts/security_check.sh
###############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 统计
TOTAL_CHECKS=0
PASSED_CHECKS=0
WARNING_CHECKS=0
FAILED_CHECKS=0

# 打印函数
print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    WARNING_CHECKS=$((WARNING_CHECKS + 1))
}

print_info() {
    echo "   $1"
}

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Running App - 安全检查工具           ║${NC}"
echo -e "${BLUE}║   Security Check Tool                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# ==========================================
# 1. Composer依赖安全检查
# ==========================================

print_header "【1/7】Composer依赖安全检查"

TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
cd backend

if [ ! -f "composer.lock" ]; then
    print_error "composer.lock 文件不存在"
else
    print_info "检查已知的安全漏洞..."

    # 使用composer audit检查安全漏洞
    if composer audit --no-interaction 2>&1 | grep -qi "no known security vulnerabilities"; then
        print_success "未发现已知安全漏洞"
    else
        composer audit --no-interaction || true
        print_warning "发现安全漏洞，请更新依赖"
    fi
fi

cd ..

# ==========================================
# 2. 配置文件安全检查
# ==========================================

print_header "【2/7】配置文件安全检查"

# 检查JWT密钥
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if [ -f "backend/.env" ]; then
    JWT_SECRET=$(grep "SECRET_KEY" backend/.env | cut -d '=' -f 2 | tr -d ' ')

    if [ -z "$JWT_SECRET" ]; then
        print_error "JWT密钥未配置"
    elif [ "$JWT_SECRET" = "your_random_secret_key_here_change_this_in_production" ]; then
        print_error "JWT密钥使用默认值，严重安全风险！"
    elif [ ${#JWT_SECRET} -lt 32 ]; then
        print_warning "JWT密钥长度不足32位"
    else
        print_success "JWT密钥配置正确"
    fi
else
    print_error ".env文件不存在"
fi

# 检查调试模式
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if [ -f "backend/.env" ]; then
    if grep -q "APP_DEBUG.*=.*true" backend/.env; then
        print_warning "调试模式已开启（生产环境应关闭）"
    else
        print_success "调试模式已关闭"
    fi
fi

# 检查数据库密码
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if [ -f "backend/.env" ]; then
    DB_PASS=$(grep "^PASSWORD" backend/.env | cut -d '=' -f 2 | tr -d ' ')

    if [ -z "$DB_PASS" ]; then
        print_error "数据库密码未配置"
    elif [ "$DB_PASS" = "your_password_here" ]; then
        print_error "数据库密码使用默认值"
    elif [ ${#DB_PASS} -lt 8 ]; then
        print_warning "数据库密码过于简单"
    else
        print_success "数据库密码已配置"
    fi
fi

# ==========================================
# 3. 文件权限检查
# ==========================================

print_header "【3/7】文件权限检查"

# 检查敏感文件权限
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if [ -f "backend/.env" ]; then
    PERMS=$(stat -c "%a" backend/.env 2>/dev/null || stat -f "%Lp" backend/.env 2>/dev/null)

    if [ "$PERMS" = "644" ] || [ "$PERMS" = "640" ] || [ "$PERMS" = "600" ]; then
        print_success ".env 文件权限正确 ($PERMS)"
    else
        print_warning ".env 文件权限: $PERMS (建议: 640或600)"
    fi
fi

# 检查runtime目录权限
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if [ -d "backend/runtime" ]; then
    if [ -w "backend/runtime" ]; then
        print_success "runtime 目录可写"
    else
        print_error "runtime 目录不可写"
    fi
fi

# 检查.git目录是否暴露
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if [ -f "backend/public/.htaccess" ]; then
    if grep -q "\.git" backend/public/.htaccess; then
        print_success ".git 目录已保护"
    else
        print_warning ".htaccess 未配置 .git 目录保护"
    fi
fi

# ==========================================
# 4. 代码安全检查
# ==========================================

print_header "【4/7】代码安全检查"

# 检查敏感信息泄露
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
print_info "检查硬编码的密码和密钥..."

SENSITIVE_PATTERNS=(
    "password.*=.*['\"][^'\"]*['\"]"
    "secret.*=.*['\"][^'\"]*['\"]"
    "api_key.*=.*['\"][^'\"]*['\"]"
)

FOUND_SENSITIVE=false
for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if grep -r -i "$pattern" backend/app --include="*.php" 2>/dev/null | grep -v "TODO\|FIXME" | head -5; then
        FOUND_SENSITIVE=true
    fi
done

if [ "$FOUND_SENSITIVE" = true ]; then
    print_warning "发现可能的硬编码敏感信息"
else
    print_success "未发现硬编码敏感信息"
fi

# 检查SQL注入风险
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
print_info "检查潜在的SQL注入风险..."

if grep -r "DB::query.*\$_" backend/app --include="*.php" 2>/dev/null | head -5; then
    print_warning "发现可能的SQL注入风险"
else
    print_success "未发现明显的SQL注入风险"
fi

# ==========================================
# 5. SSL/TLS检查
# ==========================================

print_header "【5/7】SSL/TLS检查"

TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
print_info "检查HTTPS配置..."

# 检查是否强制HTTPS
if [ -f "backend/public/.htaccess" ]; then
    if grep -q "RewriteCond.*HTTPS.*off" backend/public/.htaccess; then
        print_success "已配置HTTPS重定向"
    else
        print_warning "未配置HTTPS重定向"
    fi
fi

# 检查代码中的SSL验证
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if grep -r "CURLOPT_SSL_VERIFYPEER.*false" backend/app --include="*.php" 2>/dev/null; then
    print_error "发现禁用SSL验证的代码"
else
    print_success "未发现禁用SSL验证"
fi

# ==========================================
# 6. 依赖版本检查
# ==========================================

print_header "【6/7】依赖版本检查"

TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
cd backend

# 检查过时的依赖
print_info "检查过时的依赖..."
if composer outdated --direct 2>&1 | grep -v "^$" | head -10; then
    print_warning "发现过时的依赖包"
else
    print_success "所有依赖都是最新的"
fi

cd ..

# ==========================================
# 7. 安全Headers检查
# ==========================================

print_header "【7/7】安全Headers建议"

print_info "建议在Nginx/Apache配置中添加以下安全Headers:"
echo ""
echo "  X-Content-Type-Options: nosniff"
echo "  X-Frame-Options: SAMEORIGIN"
echo "  X-XSS-Protection: 1; mode=block"
echo "  Strict-Transport-Security: max-age=31536000"
echo "  Content-Security-Policy: default-src 'self'"
echo ""

# ==========================================
# 汇总结果
# ==========================================

echo ""
print_header "安全检查结果汇总"

echo "总检查项: $TOTAL_CHECKS"
echo -e "${GREEN}通过: $PASSED_CHECKS ✅${NC}"
echo -e "${YELLOW}警告: $WARNING_CHECKS ⚠️${NC}"
echo -e "${RED}失败: $FAILED_CHECKS ❌${NC}"

PASS_RATE=$(echo "scale=2; $PASSED_CHECKS * 100 / $TOTAL_CHECKS" | bc 2>/dev/null || echo "0")
echo "通过率: ${PASS_RATE}%"

echo ""

if [ "$FAILED_CHECKS" -eq 0 ] && [ "$WARNING_CHECKS" -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  🎉 安全检查全部通过！                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    exit 0
elif [ "$FAILED_CHECKS" -eq 0 ]; then
    echo -e "${YELLOW}╔════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  ⚠️  有警告项，建议处理               ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ❌ 发现安全问题，请立即处理！        ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    exit 1
fi
