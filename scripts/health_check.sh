#!/bin/bash

###############################################################################
# Running App - 健康检查脚本
#
# 用途: 检查应用的所有组件是否正常运行
# 用法: ./scripts/health_check.sh
#
# 返回值:
#   0 - 所有检查通过
#   1 - 有检查失败
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
FAILED_CHECKS=0

# 打印函数
print_header() {
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}==========================================${NC}"
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
}

print_info() {
    echo -e "   $1"
}

# 开始检查
echo ""
print_header "Running App - 健康检查"
echo ""

# ==========================================
# 1. 环境检查
# ==========================================

print_header "【1】环境检查"
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

# 检查PHP
if command -v php &> /dev/null; then
    PHP_VERSION=$(php -v | head -n 1 | cut -d ' ' -f 2)
    print_success "PHP 已安装: $PHP_VERSION"
else
    print_error "PHP 未安装"
fi

# 检查MySQL
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if command -v mysql &> /dev/null; then
    MYSQL_VERSION=$(mysql --version | awk '{print $5}' | sed 's/,$//')
    print_success "MySQL 已安装: $MYSQL_VERSION"
else
    print_error "MySQL 未安装"
fi

# 检查Composer
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if command -v composer &> /dev/null; then
    COMPOSER_VERSION=$(composer --version | awk '{print $3}')
    print_success "Composer 已安装: $COMPOSER_VERSION"
else
    print_error "Composer 未安装"
fi

echo ""

# ==========================================
# 2. 项目文件检查
# ==========================================

print_header "【2】项目文件检查"

# 检查后端目录
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if [ -d "backend" ]; then
    print_success "后端目录存在"
else
    print_error "后端目录不存在"
    exit 1
fi

# 检查composer依赖
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if [ -d "backend/vendor" ]; then
    print_success "Composer依赖已安装"
else
    print_error "Composer依赖未安装"
    print_info "请运行: cd backend && composer install"
fi

# 检查数据库配置文件
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if [ -f "backend/config/database.php" ]; then
    print_success "数据库配置文件存在"
else
    print_error "数据库配置文件不存在"
    print_info "请运行: cp backend/config/database_example.php backend/config/database.php"
fi

# 检查.env文件
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if [ -f "backend/.env" ]; then
    print_success ".env 配置文件存在"
else
    print_warning ".env 配置文件不存在（使用默认配置）"
    print_info "建议: cp backend/.env.example backend/.env"
fi

# 检查runtime目录权限
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if [ -w "backend/runtime" ]; then
    print_success "runtime 目录可写"
else
    print_error "runtime 目录不可写"
    print_info "请运行: chmod -R 777 backend/runtime"
fi

echo ""

# ==========================================
# 3. 数据库连接测试
# ==========================================

print_header "【3】数据库连接测试"
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

if [ -f "backend/test_db.php" ]; then
    cd backend
    if php test_db.php > /tmp/db_test.log 2>&1; then
        print_success "数据库连接正常"
        # 显示关键信息
        grep "MySQL版本" /tmp/db_test.log | sed 's/^/   /'
        grep "所有核心表都存在" /tmp/db_test.log | sed 's/^/   /'
    else
        print_error "数据库连接失败"
        print_info "详细信息:"
        cat /tmp/db_test.log | sed 's/^/   /'
    fi
    cd ..
else
    print_warning "数据库测试脚本不存在"
fi

echo ""

# ==========================================
# 4. 后端服务检查
# ==========================================

print_header "【4】后端服务检查"
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

# 检查8000端口是否被占用（ThinkPHP默认端口）
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1 || netstat -an | grep :8000 | grep LISTEN >/dev/null 2>&1; then
    print_success "后端服务正在运行 (端口 8000)"

    # 测试API端点
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000 | grep -q "200\|302\|404"; then
        print_success "后端API可访问"
    else
        print_error "后端API不可访问"
    fi
else
    print_warning "后端服务未运行"
    print_info "启动: cd backend && php think run"
fi

echo ""

# ==========================================
# 5. 数据库优化检查
# ==========================================

print_header "【5】数据库优化检查"
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

if [ -f "backend/database/optimization_v1.5.9.sql" ]; then
    print_success "数据库优化脚本存在"

    # 检查是否已应用优化
    if [ -f "backend/config/database.php" ]; then
        # 这里可以添加更复杂的检查逻辑
        print_info "建议应用优化脚本以提升性能和安全性"
        print_info "mysql -u root -p running_app < backend/database/optimization_v1.5.9.sql"
    fi
else
    print_warning "数据库优化脚本不存在"
fi

echo ""

# ==========================================
# 6. 安全检查
# ==========================================

print_header "【6】安全检查"

# 检查JWT密钥配置
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if [ -f "backend/.env" ]; then
    if grep -q "jwt.secret.*=.*[a-zA-Z0-9]" backend/.env; then
        JWT_SECRET=$(grep "jwt.secret" backend/.env | cut -d '=' -f 2 | tr -d ' ')
        if [ ${#JWT_SECRET} -ge 32 ]; then
            print_success "JWT密钥已配置（长度: ${#JWT_SECRET}）"
        else
            print_warning "JWT密钥长度不足（建议至少32位）"
        fi
    else
        print_warning "JWT密钥未配置"
        print_info "建议在 .env 中配置: jwt.secret=<随机字符串>"
    fi
else
    print_warning "无法检查JWT密钥（.env文件不存在）"
fi

# 检查调试模式
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if [ -f "backend/.env" ]; then
    if grep -q "app_debug.*=.*true" backend/.env; then
        print_warning "调试模式已开启（生产环境应关闭）"
    else
        print_success "调试模式已关闭"
    fi
else
    print_info "无法检查调试模式"
fi

echo ""

# ==========================================
# 7. 客户端配置检查
# ==========================================

print_header "【7】客户端配置检查"

# 检查Android
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if [ -d "android" ]; then
    print_success "Android项目存在"

    # 检查API配置
    if [ -f "android/app/src/main/java/com/runningapp/di/AppModule.kt" ]; then
        API_URL=$(grep "BASE_URL" android/app/src/main/java/com/runningapp/di/AppModule.kt | head -n 1)
        print_info "API地址: ${API_URL}"
    fi
else
    print_warning "Android项目不存在"
fi

# 检查iOS
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if [ -d "ios" ]; then
    print_success "iOS项目存在"

    # 检查API配置
    if [ -f "ios/RunningApp/Services/NetworkService.swift" ]; then
        API_URL=$(grep "baseURL" ios/RunningApp/Services/NetworkService.swift | head -n 1)
        print_info "API地址: ${API_URL}"
    fi
else
    print_warning "iOS项目不存在"
fi

echo ""

# ==========================================
# 汇总结果
# ==========================================

print_header "检查结果汇总"

echo "总检查项: $TOTAL_CHECKS"
echo -e "${GREEN}通过: $PASSED_CHECKS ✅${NC}"

if [ $FAILED_CHECKS -gt 0 ]; then
    echo -e "${RED}失败: $FAILED_CHECKS ❌${NC}"
fi

PASS_RATE=$(echo "scale=2; $PASSED_CHECKS * 100 / $TOTAL_CHECKS" | bc)
echo "通过率: ${PASS_RATE}%"

echo ""

if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}🎉 所有检查通过！应用已准备就绪。${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}⚠️  有 $FAILED_CHECKS 项检查失败，请查看上述错误信息。${NC}"
    echo ""
    exit 1
fi
