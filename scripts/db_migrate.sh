#!/bin/bash

###############################################################################
# 数据库迁移工具
#
# 功能：
# - 数据库版本控制
# - 执行迁移脚本
# - 回滚功能
# - 迁移历史追踪
#
# 使用：
#   ./db_migrate.sh up              # 执行所有待执行的迁移
#   ./db_migrate.sh down            # 回滚最后一次迁移
#   ./db_migrate.sh status          # 查看迁移状态
#   ./db_migrate.sh create <name>   # 创建新的迁移文件
###############################################################################

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MIGRATIONS_DIR="$PROJECT_ROOT/backend/database/migrations"
DB_CONFIG_FILE="$PROJECT_ROOT/backend/.env"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 打印函数
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 读取数据库配置
load_db_config() {
    if [ ! -f "$DB_CONFIG_FILE" ]; then
        print_error "配置文件不存在: $DB_CONFIG_FILE"
        exit 1
    fi

    export $(grep -v '^#' "$DB_CONFIG_FILE" | grep -E '^DB_' | xargs)

    DB_HOST=${DB_HOST:-127.0.0.1}
    DB_PORT=${DB_PORT:-3306}
    DB_USERNAME=${DB_USERNAME:-root}
    DB_PASSWORD=${DB_PASSWORD:-}
    DB_DATABASE=${DB_DATABASE:-running_app}
}

# 执行SQL
exec_sql() {
    local sql=$1
    mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" -e "$sql" 2>&1
}

# 创建迁移表
create_migrations_table() {
    print_info "检查迁移表..."

    local sql="
    CREATE TABLE IF NOT EXISTS migrations (
        id INT AUTO_INCREMENT PRIMARY KEY,
        version VARCHAR(255) NOT NULL UNIQUE,
        migration_name VARCHAR(255) NOT NULL,
        executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_version (version)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    "

    exec_sql "$sql"

    if [ $? -eq 0 ]; then
        print_success "迁移表就绪"
    else
        print_error "创建迁移表失败"
        exit 1
    fi
}

# 获取已执行的迁移
get_executed_migrations() {
    exec_sql "SELECT version FROM migrations ORDER BY version" | tail -n +2
}

# 获取待执行的迁移
get_pending_migrations() {
    mkdir -p "$MIGRATIONS_DIR"

    local executed=$(get_executed_migrations)
    local all_migrations=$(ls -1 "$MIGRATIONS_DIR"/*.sql 2>/dev/null | xargs -n 1 basename | sed 's/.sql$//' | sort)

    for migration in $all_migrations; do
        if ! echo "$executed" | grep -q "^$migration$"; then
            echo "$migration"
        fi
    done
}

# 执行迁移
run_migration_up() {
    local migration_file=$1
    local migration_name=$(basename "$migration_file" .sql)

    print_info "执行迁移: $migration_name"

    # 开始事务
    mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" <<EOF
START TRANSACTION;
SOURCE $migration_file;
INSERT INTO migrations (version, migration_name) VALUES ('$migration_name', '$migration_name');
COMMIT;
EOF

    if [ $? -eq 0 ]; then
        print_success "迁移成功: $migration_name"
        return 0
    else
        print_error "迁移失败: $migration_name"
        return 1
    fi
}

# 执行所有待执行的迁移
migrate_up() {
    print_info "开始数据库迁移..."

    create_migrations_table

    local pending=$(get_pending_migrations)

    if [ -z "$pending" ]; then
        print_success "没有待执行的迁移"
        return 0
    fi

    print_info "待执行迁移:"
    echo "$pending"
    echo ""

    for migration in $pending; do
        local migration_file="$MIGRATIONS_DIR/$migration.sql"

        if [ ! -f "$migration_file" ]; then
            print_error "迁移文件不存在: $migration_file"
            continue
        fi

        run_migration_up "$migration_file"

        if [ $? -ne 0 ]; then
            print_error "迁移中断"
            exit 1
        fi
    done

    print_success "所有迁移执行完成"
}

# 回滚最后一次迁移
migrate_down() {
    print_warning "开始回滚最后一次迁移..."

    create_migrations_table

    # 获取最后一次迁移
    local last_migration=$(exec_sql "SELECT version FROM migrations ORDER BY id DESC LIMIT 1" | tail -n 1)

    if [ -z "$last_migration" ]; then
        print_warning "没有可回滚的迁移"
        return 0
    fi

    print_info "回滚迁移: $last_migration"

    # 查找对应的down文件
    local down_file="$MIGRATIONS_DIR/${last_migration}_down.sql"

    if [ ! -f "$down_file" ]; then
        print_warning "未找到回滚文件: $down_file"
        print_info "手动删除迁移记录..."

        exec_sql "DELETE FROM migrations WHERE version='$last_migration'"
        print_success "迁移记录已删除"
        return 0
    fi

    # 执行回滚
    mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" <<EOF
START TRANSACTION;
SOURCE $down_file;
DELETE FROM migrations WHERE version='$last_migration';
COMMIT;
EOF

    if [ $? -eq 0 ]; then
        print_success "回滚成功: $last_migration"
    else
        print_error "回滚失败: $last_migration"
        exit 1
    fi
}

# 查看迁移状态
migrate_status() {
    print_info "迁移状态："

    create_migrations_table

    local executed=$(get_executed_migrations)
    local pending=$(get_pending_migrations)

    echo ""
    echo "已执行的迁移:"
    if [ -z "$executed" ]; then
        echo "  (无)"
    else
        echo "$executed" | sed 's/^/  ✓ /'
    fi

    echo ""
    echo "待执行的迁移:"
    if [ -z "$pending" ]; then
        echo "  (无)"
    else
        echo "$pending" | sed 's/^/  ○ /'
    fi
}

# 创建新的迁移文件
create_migration() {
    local name=$1

    if [ -z "$name" ]; then
        print_error "请指定迁移名称"
        echo "使用: $0 create <migration_name>"
        exit 1
    fi

    mkdir -p "$MIGRATIONS_DIR"

    local timestamp=$(date +%Y%m%d%H%M%S)
    local filename="${timestamp}_${name}"
    local filepath="$MIGRATIONS_DIR/${filename}.sql"

    cat > "$filepath" <<EOF
-- Migration: $name
-- Created at: $(date '+%Y-%m-%d %H:%M:%S')

-- Up Migration
-- 在此添加升级SQL语句

EOF

    print_success "迁移文件已创建: $filepath"

    # 创建对应的down文件
    local down_filepath="$MIGRATIONS_DIR/${filename}_down.sql"

    cat > "$down_filepath" <<EOF
-- Migration Down: $name
-- Created at: $(date '+%Y-%m-% d %H:%M:%S')

-- Down Migration
-- 在此添加回滚SQL语句

EOF

    print_success "回滚文件已创建: $down_filepath"
}

# 主函数
main() {
    echo ""
    echo "============================================"
    echo "  Running App 数据库迁移工具"
    echo "============================================"
    echo ""

    load_db_config

    local command=${1:-help}

    case $command in
        up)
            migrate_up
            ;;
        down)
            migrate_down
            ;;
        status)
            migrate_status
            ;;
        create)
            create_migration "$2"
            ;;
        help|*)
            echo "使用方法:"
            echo "  $0 up              执行所有待执行的迁移"
            echo "  $0 down            回滚最后一次迁移"
            echo "  $0 status          查看迁移状态"
            echo "  $0 create <name>   创建新的迁移文件"
            echo ""
            exit 0
            ;;
    esac
}

# 执行主函数
main "$@"
