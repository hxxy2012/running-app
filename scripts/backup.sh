#!/bin/bash

###############################################################################
# Running App - 数据库备份脚本
#
# 用途: 备份数据库和重要文件
# 用法: ./scripts/backup.sh [backup_dir]
#
# 功能:
#   - 备份MySQL数据库
#   - 备份上传文件
#   - 备份配置文件
#   - 清理过期备份
###############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
BACKUP_DIR="${1:-/var/backups/running-app}"
BACKUP_RETENTION_DAYS=7  # 保留7天的备份
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

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
    echo "   $1"
}

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Running App - 数据库备份             ║${NC}"
echo -e "${BLUE}║   Database Backup Script               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# ==========================================
# 1. 检查环境
# ==========================================

print_header "【1/6】环境检查"

# 检查备份目录
if [ ! -d "$BACKUP_DIR" ]; then
    print_info "创建备份目录: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
fi
print_success "备份目录: $BACKUP_DIR"

# 检查mysqldump
if ! command -v mysqldump &> /dev/null; then
    print_error "mysqldump未找到，请安装MySQL客户端工具"
    exit 1
fi
print_success "mysqldump已安装"

# 检查磁盘空间（至少需要1GB）
AVAILABLE_SPACE=$(df -BG "$BACKUP_DIR" | tail -1 | awk '{print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt 1 ]; then
    print_warning "磁盘空间不足1GB，当前可用: ${AVAILABLE_SPACE}GB"
fi
print_success "磁盘可用空间: ${AVAILABLE_SPACE}GB"

# ==========================================
# 2. 读取数据库配置
# ==========================================

print_header "【2/6】读取数据库配置"

cd backend

if [ ! -f ".env" ]; then
    print_error ".env文件不存在"
    exit 1
fi

# 读取配置
DB_NAME=$(grep "^DATABASE" .env | cut -d '=' -f 2 | tr -d ' ')
DB_USER=$(grep "^USERNAME" .env | cut -d '=' -f 2 | tr -d ' ')
DB_PASS=$(grep "^PASSWORD" .env | cut -d '=' -f 2 | tr -d ' ')
DB_HOST=$(grep "^HOSTNAME" .env | cut -d '=' -f 2 | tr -d ' ')

if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASS" ]; then
    print_error "数据库配置不完整"
    exit 1
fi

print_success "数据库名: $DB_NAME"
print_success "数据库主机: $DB_HOST"
print_success "数据库用户: $DB_USER"

# ==========================================
# 3. 备份数据库
# ==========================================

print_header "【3/6】备份数据库"

BACKUP_FILE="$BACKUP_DIR/db_${DB_NAME}_${TIMESTAMP}.sql"

print_info "正在备份数据库..."
print_info "备份文件: $BACKUP_FILE"

# 执行备份
if mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" \
    --single-transaction \
    --quick \
    --lock-tables=false \
    --routines \
    --triggers \
    --events \
    > "$BACKUP_FILE" 2>/dev/null; then

    # 压缩备份文件
    print_info "正在压缩备份文件..."
    gzip -f "$BACKUP_FILE"
    BACKUP_FILE="${BACKUP_FILE}.gz"

    # 获取文件大小
    FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    print_success "数据库备份完成: $FILE_SIZE"
else
    print_error "数据库备份失败"
    exit 1
fi

# ==========================================
# 4. 备份上传文件
# ==========================================

print_header "【4/6】备份上传文件"

UPLOAD_DIR="public/uploads"
if [ -d "$UPLOAD_DIR" ]; then
    UPLOAD_COUNT=$(find "$UPLOAD_DIR" -type f | wc -l)
    if [ "$UPLOAD_COUNT" -gt 0 ]; then
        UPLOAD_BACKUP="$BACKUP_DIR/uploads_${TIMESTAMP}.tar.gz"

        print_info "正在备份上传文件（共 $UPLOAD_COUNT 个文件）..."
        tar -czf "$UPLOAD_BACKUP" "$UPLOAD_DIR" 2>/dev/null

        UPLOAD_SIZE=$(du -h "$UPLOAD_BACKUP" | cut -f1)
        print_success "上传文件备份完成: $UPLOAD_SIZE"
    else
        print_info "上传目录为空，跳过备份"
    fi
else
    print_warning "上传目录不存在: $UPLOAD_DIR"
fi

# ==========================================
# 5. 备份配置文件
# ==========================================

print_header "【5/6】备份配置文件"

CONFIG_BACKUP="$BACKUP_DIR/config_${TIMESTAMP}.tar.gz"

print_info "正在备份配置文件..."
tar -czf "$CONFIG_BACKUP" \
    .env \
    config/ \
    2>/dev/null || print_warning "部分配置文件备份失败"

CONFIG_SIZE=$(du -h "$CONFIG_BACKUP" | cut -f1)
print_success "配置文件备份完成: $CONFIG_SIZE"

# ==========================================
# 6. 清理过期备份
# ==========================================

print_header "【6/6】清理过期备份"

print_info "保留天数: $BACKUP_RETENTION_DAYS 天"

# 查找并删除过期备份
OLD_BACKUPS=$(find "$BACKUP_DIR" -name "*.gz" -mtime +$BACKUP_RETENTION_DAYS)
OLD_COUNT=$(echo "$OLD_BACKUPS" | grep -v "^$" | wc -l)

if [ "$OLD_COUNT" -gt 0 ]; then
    print_info "发现 $OLD_COUNT 个过期备份文件"
    find "$BACKUP_DIR" -name "*.gz" -mtime +$BACKUP_RETENTION_DAYS -delete
    print_success "已清理过期备份"
else
    print_info "没有过期备份需要清理"
fi

# ==========================================
# 汇总信息
# ==========================================

cd ..

echo ""
print_header "备份完成"

echo "备份时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "备份目录: $BACKUP_DIR"
echo ""
echo "备份文件列表:"
ls -lh "$BACKUP_DIR"/*_${TIMESTAMP}* 2>/dev/null || true

echo ""
echo "总备份大小: $(du -sh $BACKUP_DIR | cut -f1)"
echo ""

# 生成备份报告
REPORT_FILE="$BACKUP_DIR/backup_report_${TIMESTAMP}.txt"
cat > "$REPORT_FILE" << EOF
Running App 备份报告
====================

备份时间: $(date '+%Y-%m-%d %H:%M:%S')
备份目录: $BACKUP_DIR

数据库备份:
- 数据库: $DB_NAME
- 文件: db_${DB_NAME}_${TIMESTAMP}.sql.gz
- 大小: $FILE_SIZE

配置文件备份:
- 文件: config_${TIMESTAMP}.tar.gz
- 大小: $CONFIG_SIZE

上传文件备份:
$(if [ -f "$UPLOAD_BACKUP" ]; then
    echo "- 文件: uploads_${TIMESTAMP}.tar.gz"
    echo "- 大小: $UPLOAD_SIZE"
    echo "- 文件数: $UPLOAD_COUNT"
else
    echo "- 无上传文件"
fi)

清理信息:
- 保留天数: $BACKUP_RETENTION_DAYS 天
- 清理文件数: $OLD_COUNT

备份状态: 成功 ✅
EOF

print_success "备份报告已生成: $REPORT_FILE"

# ==========================================
# 验证备份
# ==========================================

echo ""
print_header "验证备份完整性"

# 验证SQL备份文件
if gunzip -t "$BACKUP_FILE" 2>/dev/null; then
    print_success "数据库备份文件完整性验证通过"
else
    print_error "数据库备份文件可能已损坏"
    exit 1
fi

# ==========================================
# 建议
# ==========================================

echo ""
print_header "备份建议"

print_info "1. 建议将备份文件传输到远程服务器或云存储"
print_info "2. 定期测试备份恢复流程"
print_info "3. 考虑使用cron定时执行此脚本"
print_info "   示例: 0 2 * * * /path/to/backup.sh"
print_info "4. 重要: 将备份文件存储在不同的物理位置"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  🎉 备份成功完成！                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# ==========================================
# 恢复示例
# ==========================================

cat << 'EOF'

💡 恢复备份示例:

1. 恢复数据库:
   gunzip < backup.sql.gz | mysql -u user -p database_name

2. 恢复上传文件:
   tar -xzf uploads_backup.tar.gz -C /path/to/backend/

3. 恢复配置文件:
   tar -xzf config_backup.tar.gz -C /path/to/backend/

EOF

exit 0
