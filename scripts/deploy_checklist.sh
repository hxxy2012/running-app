#!/bin/bash

###############################################################################
# Running App - 部署检查清单
#
# 用途: 部署前的完整检查清单，确保生产环境就绪
# 用法: ./scripts/deploy_checklist.sh
#
# 检查项:
#   - 安全配置
#   - 性能优化
#   - 备份策略
#   - 监控告警
#   - 文档完整性
###############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 统计
TOTAL_ITEMS=0
CHECKED_ITEMS=0
WARNING_ITEMS=0
FAILED_ITEMS=0

# 打印函数
print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    CHECKED_ITEMS=$((CHECKED_ITEMS + 1))
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    FAILED_ITEMS=$((FAILED_ITEMS + 1))
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    WARNING_ITEMS=$((WARNING_ITEMS + 1))
}

print_info() {
    echo "   $1"
}

ask_confirmation() {
    TOTAL_ITEMS=$((TOTAL_ITEMS + 1))
    read -p "   $1 (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_success "$1"
        return 0
    else
        print_error "$1"
        return 1
    fi
}

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Running App - 部署检查清单           ║${NC}"
echo -e "${BLUE}║   Production Deployment Checklist      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

print_warning "请仔细检查以下各项，确保生产环境部署安全可靠"
echo ""

# ═══════════════════════════════════════
# 1. 安全配置检查
# ═══════════════════════════════════════

print_header "【1】安全配置检查"

ask_confirmation "JWT密钥已修改（不是默认值）"
ask_confirmation "数据库密码已修改为强密码"
ask_confirmation "已禁用调试模式（APP_DEBUG=false）"
ask_confirmation "已配置HTTPS/SSL证书"
ask_confirmation "已启用防火墙并配置端口规则"
ask_confirmation "已限制数据库远程访问"
ask_confirmation "已修改默认管理员账号密码"
ask_confirmation "已删除或禁用测试账号"
ask_confirmation "已配置文件上传大小限制"
ask_confirmation "已启用CORS限制"

# ═══════════════════════════════════════
# 2. 数据库优化检查
# ═══════════════════════════════════════

print_header "【2】数据库优化检查"

ask_confirmation "已导入数据库结构（running_app.sql）"
ask_confirmation "已应用数据库优化脚本（optimization_v1.5.9.sql）"
ask_confirmation "已创建数据库备份"
ask_confirmation "已配置数据库定时备份任务"
ask_confirmation "已优化数据库配置（my.cnf）"
ask_confirmation "已创建数据库从库（可选）"

# ═══════════════════════════════════════
# 3. 性能优化检查
# ═══════════════════════════════════════

print_header "【3】性能优化检查"

ask_confirmation "已配置Redis缓存"
ask_confirmation "已启用OPcache（PHP）"
ask_confirmation "已配置Nginx gzip压缩"
ask_confirmation "已配置静态资源CDN"
ask_confirmation "已优化PHP-FPM配置"
ask_confirmation "已设置合理的连接池大小"

# ═══════════════════════════════════════
# 4. 环境配置检查
# ═══════════════════════════════════════

print_header "【4】环境配置检查"

ask_confirmation "PHP版本 >= 8.0"
ask_confirmation "MySQL版本 >= 8.0"
ask_confirmation "已安装所有PHP扩展（pdo_mysql, redis, etc.）"
ask_confirmation "已配置正确的时区"
ask_confirmation "已设置正确的文件权限（runtime 777）"
ask_confirmation "已配置日志轮转"

# ═══════════════════════════════════════
# 5. 第三方服务配置
# ═══════════════════════════════════════

print_header "【5】第三方服务配置"

ask_confirmation "已配置短信服务（阿里云/腾讯云）"
ask_confirmation "已配置实名认证服务（可选）"
ask_confirmation "已配置对象存储OSS（可选）"
ask_confirmation "已配置地图服务（可选）"
ask_confirmation "已配置推送服务（可选）"
ask_confirmation "已配置支付服务（可选）"

# ═══════════════════════════════════════
# 6. 监控与日志
# ═══════════════════════════════════════

print_header "【6】监控与日志检查"

ask_confirmation "已配置服务器监控（CPU/内存/磁盘）"
ask_confirmation "已配置应用日志收集"
ask_confirmation "已配置错误日志告警"
ask_confirmation "已配置性能监控（APM）"
ask_confirmation "已配置数据库慢查询日志"
ask_confirmation "已设置日志保留策略"

# ═══════════════════════════════════════
# 7. 备份与恢复
# ═══════════════════════════════════════

print_header "【7】备份与恢复策略"

ask_confirmation "已配置数据库自动备份"
ask_confirmation "已配置文件系统备份"
ask_confirmation "已测试备份恢复流程"
ask_confirmation "已准备灾难恢复方案"
ask_confirmation "备份文件已存储到异地"

# ═══════════════════════════════════════
# 8. 代码与文档
# ═══════════════════════════════════════

print_header "【8】代码与文档检查"

ask_confirmation "代码已通过测试"
ask_confirmation "已运行health_check.sh检查"
ask_confirmation "已运行test_db.php数据库测试"
ask_confirmation "已运行test_api.php接口测试"
ask_confirmation "部署文档已准备"
ask_confirmation "API文档已更新"
ask_confirmation "运维文档已准备"

# ═══════════════════════════════════════
# 9. 客户端配置
# ═══════════════════════════════════════

print_header "【9】客户端配置检查"

ask_confirmation "Android应用已配置生产API地址"
ask_confirmation "iOS应用已配置生产API地址"
ask_confirmation "已配置正确的应用签名"
ask_confirmation "已准备应用商店发布材料"

# ═══════════════════════════════════════
# 10. 运维准备
# ═══════════════════════════════════════

print_header "【10】运维准备检查"

ask_confirmation "已准备回滚方案"
ask_confirmation "已准备应急联系人列表"
ask_confirmation "已配置服务自动重启"
ask_confirmation "已准备运维手册"
ask_confirmation "已进行压力测试"
ask_confirmation "已准备扩容方案"

# ═══════════════════════════════════════
# 11. 合规与法律
# ═══════════════════════════════════════

print_header "【11】合规与法律检查"

ask_confirmation "已准备隐私政策"
ask_confirmation "已准备用户协议"
ask_confirmation "已配置数据加密"
ask_confirmation "已实施数据安全措施"
ask_confirmation "已准备内容审核机制"

# ═══════════════════════════════════════
# 汇总结果
# ═══════════════════════════════════════

echo ""
print_header "检查结果汇总"

echo "总检查项: $TOTAL_ITEMS"
echo -e "${GREEN}已完成: $CHECKED_ITEMS ✅${NC}"
echo -e "${RED}未完成: $FAILED_ITEMS ❌${NC}"

COMPLETION_RATE=$(echo "scale=2; $CHECKED_ITEMS * 100 / $TOTAL_ITEMS" | bc 2>/dev/null || echo "0")
echo "完成率: ${COMPLETION_RATE}%"

echo ""

if [ "$FAILED_ITEMS" -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  🎉 恭喜！所有检查项均已完成！        ║${NC}"
    echo -e "${GREEN}║  您的应用已准备好部署到生产环境      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    exit 0
elif [ "$FAILED_ITEMS" -le 5 ]; then
    echo -e "${YELLOW}╔════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  ⚠️  还有少量检查项未完成             ║${NC}"
    echo -e "${YELLOW}║  建议完成所有检查项后再部署          ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════╝${NC}"
    echo ""
    exit 1
else
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ❌ 未完成的检查项较多                ║${NC}"
    echo -e "${RED}║  请完成所有检查项后再部署到生产环境  ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    echo ""
    exit 1
fi
