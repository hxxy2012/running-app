#!/bin/bash

###############################################################################
# Running App - 一键启动脚本
#
# 用途: 快速启动完整的开发环境
# 用法: ./scripts/quick_start.sh
#
# 功能:
#   1. 检查环境依赖
#   2. 安装后端依赖
#   3. 配置数据库
#   4. 导入数据库结构和优化
#   5. 启动后端服务
#   6. 运行健康检查
###############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "   $1"
}

# 清屏
clear

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Running App - 一键启动脚本           ║${NC}"
echo -e "${BLUE}║   Quick Start Development Environment  ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo ""

# ==========================================
# 1. 检查环境依赖
# ==========================================

print_header "【步骤 1/7】检查环境依赖"

# 检查PHP
if ! command -v php &> /dev/null; then
    print_error "PHP未安装，请先安装PHP 8.0+"
    exit 1
fi
PHP_VERSION=$(php -v | head -n 1 | cut -d ' ' -f 2)
print_success "PHP已安装: $PHP_VERSION"

# 检查Composer
if ! command -v composer &> /dev/null; then
    print_error "Composer未安装，请先安装Composer"
    exit 1
fi
COMPOSER_VERSION=$(composer --version | awk '{print $3}')
print_success "Composer已安装: $COMPOSER_VERSION"

# 检查MySQL
if ! command -v mysql &> /dev/null; then
    print_error "MySQL未安装，请先安装MySQL 8.0+"
    exit 1
fi
MYSQL_VERSION=$(mysql --version | awk '{print $5}' | sed 's/,$//')
print_success "MySQL已安装: $MYSQL_VERSION"

# ==========================================
# 2. 安装后端依赖
# ==========================================

print_header "【步骤 2/7】安装后端依赖"

cd backend

if [ -d "vendor" ]; then
    print_info "依赖已存在，跳过安装"
else
    print_info "正在安装Composer依赖..."
    composer install --no-interaction --prefer-dist
    print_success "依赖安装完成"
fi

# ==========================================
# 3. 配置环境文件
# ==========================================

print_header "【步骤 3/7】配置环境文件"

# 配置.env
if [ ! -f ".env" ]; then
    print_info "创建.env配置文件..."
    cp .env.example .env

    # 生成随机JWT密钥
    JWT_SECRET=$(openssl rand -base64 32 | tr -d '\n' 2>/dev/null || cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

    # 替换JWT密钥
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/SECRET_KEY = .*/SECRET_KEY = $JWT_SECRET/" .env
    else
        # Linux
        sed -i "s/SECRET_KEY = .*/SECRET_KEY = $JWT_SECRET/" .env
    fi

    print_success ".env文件已创建"
    print_warning "JWT密钥已自动生成: ${JWT_SECRET:0:10}..."
    print_info "请编辑.env文件配置数据库密码等信息"

    # 询问是否现在配置
    read -p "是否现在配置数据库密码? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "请输入MySQL root密码: " -s DB_PASSWORD
        echo
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/PASSWORD = .*/PASSWORD = $DB_PASSWORD/" .env
        else
            sed -i "s/PASSWORD = .*/PASSWORD = $DB_PASSWORD/" .env
        fi
        print_success "数据库密码已配置"
    fi
else
    print_info ".env文件已存在"
fi

# 配置database.php
if [ ! -f "config/database.php" ]; then
    print_info "创建数据库配置文件..."
    cp config/database_example.php config/database.php
    print_success "数据库配置文件已创建"
else
    print_info "数据库配置文件已存在"
fi

# ==========================================
# 4. 创建数据库
# ==========================================

print_header "【步骤 4/7】创建数据库"

# 读取数据库配置
DB_NAME=$(grep "^DATABASE" .env | cut -d '=' -f 2 | tr -d ' ')
DB_USER=$(grep "^USERNAME" .env | cut -d '=' -f 2 | tr -d ' ')
DB_PASS=$(grep "^PASSWORD" .env | cut -d '=' -f 2 | tr -d ' ')

print_info "数据库名: $DB_NAME"
print_info "数据库用户: $DB_USER"

# 检查数据库是否存在
if mysql -u "$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME" 2>/dev/null; then
    print_info "数据库已存在，跳过创建"
else
    print_info "正在创建数据库..."
    mysql -u "$DB_USER" -p"$DB_PASS" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || {
        print_error "数据库创建失败，请检查MySQL密码"
        print_info "您可以手动执行: CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
        exit 1
    }
    print_success "数据库创建成功"
fi

# ==========================================
# 5. 导入数据库结构
# ==========================================

print_header "【步骤 5/7】导入数据库结构"

# 检查表是否存在
TABLE_COUNT=$(mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "SHOW TABLES;" 2>/dev/null | wc -l)

if [ "$TABLE_COUNT" -gt 1 ]; then
    print_info "数据库表已存在（$((TABLE_COUNT - 1))张表）"
    read -p "是否重新导入数据库? 这将删除所有现有数据! (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "正在导入数据库结构..."
        mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < database/running_app.sql 2>/dev/null || {
            print_error "数据库导入失败"
            exit 1
        }
        print_success "数据库结构导入成功"
    else
        print_info "跳过数据库导入"
    fi
else
    print_info "正在导入数据库结构..."
    mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < database/running_app.sql 2>/dev/null || {
        print_error "数据库导入失败"
        exit 1
    }
    print_success "数据库结构导入成功"
fi

# ==========================================
# 6. 应用数据库优化
# ==========================================

print_header "【步骤 6/7】应用数据库优化"

read -p "是否应用数据库优化脚本? (添加外键、索引等) (Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    print_info "正在应用数据库优化..."
    mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < database/optimization_v1.5.9.sql 2>/dev/null || {
        print_warning "数据库优化失败（可能已经应用过）"
    }
    print_success "数据库优化完成"
else
    print_info "跳过数据库优化"
fi

# ==========================================
# 7. 启动服务
# ==========================================

print_header "【步骤 7/7】启动后端服务"

# 检查端口是否被占用
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1 || netstat -an 2>/dev/null | grep :8000 | grep LISTEN >/dev/null 2>&1; then
    print_warning "端口8000已被占用"
    read -p "是否在其他端口启动? (输入端口号，默认8001) " CUSTOM_PORT
    PORT=${CUSTOM_PORT:-8001}
else
    PORT=8000
fi

print_info "正在启动后端服务 (端口: $PORT)..."
print_info "按 Ctrl+C 停止服务"
echo ""

# 返回项目根目录
cd ..

# 运行健康检查
print_header "运行健康检查"
./scripts/health_check.sh

echo ""
print_header "启动信息"
print_success "后端服务将在端口 $PORT 启动"
print_info "API地址: http://localhost:$PORT"
print_info "API文档: 参见 API.md"
print_info "测试脚本: php backend/test_api.php http://localhost:$PORT"
echo ""
print_warning "提示: 请在新终端中配置和启动Android/iOS客户端"
print_info "Android配置: 编辑 android/app/src/main/java/com/runningapp/di/AppModule.kt"
print_info "iOS配置: 编辑 ios/RunningApp/Services/NetworkService.swift"
echo ""

# 启动服务
cd backend
php think run -p $PORT
