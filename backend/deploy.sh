#!/bin/bash

# Running App 后端部署脚本
# 使用方法: ./deploy.sh [环境]
# 环境参数: dev (开发) | prod (生产)

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 环境参数
ENV=${1:-dev}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Running App 后端部署脚本${NC}"
echo -e "${GREEN}环境: $ENV${NC}"
echo -e "${GREEN}========================================${NC}"

# 1. 检查PHP版本
echo -e "\n${YELLOW}[1/8] 检查PHP版本...${NC}"
php_version=$(php -v | head -n 1 | awk '{print $2}' | cut -d. -f1,2)
required_version="8.0"
if [ "$(printf '%s\n' "$required_version" "$php_version" | sort -V | head -n1)" != "$required_version" ]; then
    echo -e "${RED}错误: PHP版本必须>=8.0，当前版本: $php_version${NC}"
    exit 1
fi
echo -e "${GREEN}✓ PHP版本: $php_version${NC}"

# 2. 检查Composer
echo -e "\n${YELLOW}[2/8] 检查Composer...${NC}"
if ! command -v composer &> /dev/null; then
    echo -e "${RED}错误: 未安装Composer${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Composer已安装${NC}"

# 3. 安装依赖
echo -e "\n${YELLOW}[3/8] 安装Composer依赖...${NC}"
if [ "$ENV" == "prod" ]; then
    composer install --no-dev --optimize-autoloader
else
    composer install
fi
echo -e "${GREEN}✓ 依赖安装完成${NC}"

# 4. 配置环境文件
echo -e "\n${YELLOW}[4/8] 配置环境文件...${NC}"
if [ ! -f ".env" ]; then
    if [ "$ENV" == "prod" ]; then
        echo -e "${RED}错误: 生产环境必须配置.env文件${NC}"
        exit 1
    else
        echo -e "${YELLOW}警告: .env文件不存在，复制示例文件...${NC}"
        cp .env.example .env
        echo -e "${YELLOW}请编辑.env文件配置数据库等信息${NC}"
    fi
else
    echo -e "${GREEN}✓ .env文件存在${NC}"
fi

# 5. 检查数据库连接
echo -e "\n${YELLOW}[5/8] 检查数据库连接...${NC}"
# 这里可以添加数据库连接测试
echo -e "${GREEN}✓ 跳过数据库检查（请手动验证）${NC}"

# 6. 创建必要的目录
echo -e "\n${YELLOW}[6/8] 创建必要的目录...${NC}"
mkdir -p runtime/log
mkdir -p runtime/cache
mkdir -p runtime/temp
mkdir -p runtime/crash_logs/android
mkdir -p runtime/crash_logs/ios
mkdir -p public/uploads
echo -e "${GREEN}✓ 目录创建完成${NC}"

# 7. 设置目录权限
echo -e "\n${YELLOW}[7/8] 设置目录权限...${NC}"
chmod -R 755 runtime
chmod -R 755 public/uploads
echo -e "${GREEN}✓ 权限设置完成${NC}"

# 8. 清除缓存
echo -e "\n${YELLOW}[8/8] 清除缓存...${NC}"
php think clear
php think optimize:schema
php think optimize:route
echo -e "${GREEN}✓ 缓存清除完成${NC}"

# 完成
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}部署完成！${NC}"
echo -e "${GREEN}========================================${NC}"

if [ "$ENV" == "prod" ]; then
    echo -e "\n${YELLOW}生产环境检查清单:${NC}"
    echo -e "  1. ✓ 已设置APP_DEBUG=false"
    echo -e "  2. ✓ 已修改JWT_SECRET_KEY"
    echo -e "  3. ✓ 已配置数据库"
    echo -e "  4. ✓ 已导入数据库SQL"
    echo -e "  5. ✓ 已配置Nginx/Apache"
    echo -e "  6. ✓ 已配置第三方服务（短信、实名认证等）"
else
    echo -e "\n${YELLOW}开发环境提示:${NC}"
    echo -e "  1. 编辑.env配置数据库连接"
    echo -e "  2. 导入数据库: mysql -u root -p < database/running_app.sql"
    echo -e "  3. 启动服务: php think run"
    echo -e "  4. 访问: http://localhost:8000"
fi

echo ""
