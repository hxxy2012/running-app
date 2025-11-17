#!/bin/bash

###############################################################################
# Running App - 系统清理脚本
#
# 用途: 清理日志、缓存、临时文件，释放磁盘空间
# 用法: ./scripts/cleanup.sh [options]
#
# 选项:
#   --logs        清理旧日志文件
#   --cache       清理缓存文件
#   --tmp         清理临时文件
#   --uploads     清理旧的上传文件（谨慎）
#   --dry-run     仅显示将要删除的文件，不实际删除
#   --all         清理所有（不包括uploads）
###############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
LOG_RETENTION_DAYS=7     # 保留7天的日志
CACHE_RETENTION_DAYS=3   # 保留3天的缓存
TMP_RETENTION_DAYS=1     # 保留1天的临时文件
UPLOAD_RETENTION_DAYS=90 # 保留90天的上传文件
DRY_RUN=false

# 统计
TOTAL_FILES=0
TOTAL_SIZE=0
DELETED_FILES=0
FREED_SPACE=0

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

# 人类可读的文件大小
human_readable_size() {
    local size=$1
    if [ "$size" -lt 1024 ]; then
        echo "${size}B"
    elif [ "$size" -lt 1048576 ]; then
        echo "$((size / 1024))KB"
    elif [ "$size" -lt 1073741824 ]; then
        echo "$((size / 1048576))MB"
    else
        echo "$((size / 1073741824))GB"
    fi
}

# ==========================================
# 清理日志文件
# ==========================================

cleanup_logs() {
    print_header "清理旧日志文件"

    local log_dirs=(
        "backend/runtime/log"
        "backend/runtime/cache/log"
        "/var/log/nginx"
        "/var/log/apache2"
    )

    print_info "保留最近 $LOG_RETENTION_DAYS 天的日志"

    for log_dir in "${log_dirs[@]}"; do
        if [ ! -d "$log_dir" ]; then
            continue
        fi

        print_info "检查目录: $log_dir"

        # 查找旧日志文件
        local old_logs=$(find "$log_dir" -name "*.log" -type f -mtime +$LOG_RETENTION_DAYS 2>/dev/null || true)

        if [ -n "$old_logs" ]; then
            local count=$(echo "$old_logs" | wc -l)
            local size=$(du -cb $old_logs 2>/dev/null | tail -1 | cut -f1 || echo "0")

            TOTAL_FILES=$((TOTAL_FILES + count))
            TOTAL_SIZE=$((TOTAL_SIZE + size))

            print_info "找到 $count 个旧日志文件，共 $(human_readable_size $size)"

            if [ "$DRY_RUN" = false ]; then
                echo "$old_logs" | xargs rm -f 2>/dev/null || true
                DELETED_FILES=$((DELETED_FILES + count))
                FREED_SPACE=$((FREED_SPACE + size))
                print_success "已删除"
            else
                print_warning "模拟模式：不会实际删除"
            fi
        else
            print_info "没有需要清理的日志文件"
        fi
    done

    # 清理压缩的日志
    print_info "清理压缩的日志文件..."
    local gz_logs=$(find backend/runtime/log -name "*.log.gz" -type f -mtime +$LOG_RETENTION_DAYS 2>/dev/null || true)

    if [ -n "$gz_logs" ]; then
        local count=$(echo "$gz_logs" | wc -l)
        local size=$(du -cb $gz_logs 2>/dev/null | tail -1 | cut -f1 || echo "0")

        print_info "找到 $count 个压缩日志，共 $(human_readable_size $size)"

        if [ "$DRY_RUN" = false ]; then
            echo "$gz_logs" | xargs rm -f 2>/dev/null || true
            DELETED_FILES=$((DELETED_FILES + count))
            FREED_SPACE=$((FREED_SPACE + size))
        fi
    fi
}

# ==========================================
# 清理缓存文件
# ==========================================

cleanup_cache() {
    print_header "清理缓存文件"

    local cache_dirs=(
        "backend/runtime/cache"
        "backend/runtime/temp"
    )

    print_info "保留最近 $CACHE_RETENTION_DAYS 天的缓存"

    for cache_dir in "${cache_dirs[@]}"; do
        if [ ! -d "$cache_dir" ]; then
            continue
        fi

        print_info "检查目录: $cache_dir"

        # 查找旧缓存文件
        local old_cache=$(find "$cache_dir" -type f -mtime +$CACHE_RETENTION_DAYS 2>/dev/null || true)

        if [ -n "$old_cache" ]; then
            local count=$(echo "$old_cache" | wc -l)
            local size=$(du -cb $old_cache 2>/dev/null | tail -1 | cut -f1 || echo "0")

            TOTAL_FILES=$((TOTAL_FILES + count))
            TOTAL_SIZE=$((TOTAL_SIZE + size))

            print_info "找到 $count 个缓存文件，共 $(human_readable_size $size)"

            if [ "$DRY_RUN" = false ]; then
                echo "$old_cache" | xargs rm -f 2>/dev/null || true
                DELETED_FILES=$((DELETED_FILES + count))
                FREED_SPACE=$((FREED_SPACE + size))
                print_success "已删除"
            else
                print_warning "模拟模式：不会实际删除"
            fi
        else
            print_info "没有需要清理的缓存文件"
        fi
    done

    # 清空缓存目录（保留目录结构）
    if [ "$DRY_RUN" = false ]; then
        if [ -d "backend/runtime/cache" ]; then
            print_info "清空缓存目录..."
            find backend/runtime/cache -type f -name "*.php" -delete 2>/dev/null || true
            print_success "缓存目录已清空"
        fi
    fi
}

# ==========================================
# 清理临时文件
# ==========================================

cleanup_temp() {
    print_header "清理临时文件"

    local temp_dirs=(
        "backend/runtime/temp"
        "/tmp"
    )

    print_info "保留最近 $TMP_RETENTION_DAYS 天的临时文件"

    for temp_dir in "${temp_dirs[@]}"; do
        if [ ! -d "$temp_dir" ]; then
            continue
        fi

        print_info "检查目录: $temp_dir"

        # 只清理running-app相关的临时文件
        local pattern="running_app_*"
        if [ "$temp_dir" = "/tmp" ]; then
            pattern="running_app_*"
        fi

        local old_temp=$(find "$temp_dir" -name "$pattern" -type f -mtime +$TMP_RETENTION_DAYS 2>/dev/null || true)

        if [ -n "$old_temp" ]; then
            local count=$(echo "$old_temp" | wc -l)
            local size=$(du -cb $old_temp 2>/dev/null | tail -1 | cut -f1 || echo "0")

            TOTAL_FILES=$((TOTAL_FILES + count))
            TOTAL_SIZE=$((TOTAL_SIZE + size))

            print_info "找到 $count 个临时文件，共 $(human_readable_size $size)"

            if [ "$DRY_RUN" = false ]; then
                echo "$old_temp" | xargs rm -f 2>/dev/null || true
                DELETED_FILES=$((DELETED_FILES + count))
                FREED_SPACE=$((FREED_SPACE + size))
                print_success "已删除"
            else
                print_warning "模拟模式：不会实际删除"
            fi
        else
            print_info "没有需要清理的临时文件"
        fi
    done
}

# ==========================================
# 清理旧的上传文件（谨慎）
# ==========================================

cleanup_uploads() {
    print_header "清理旧的上传文件"

    print_warning "这将删除 $UPLOAD_RETENTION_DAYS 天前的上传文件！"
    print_warning "请确保这些文件不再需要！"

    if [ "$DRY_RUN" = false ]; then
        read -p "是否继续? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "跳过上传文件清理"
            return 0
        fi
    fi

    local upload_dir="backend/public/uploads"

    if [ ! -d "$upload_dir" ]; then
        print_warning "上传目录不存在: $upload_dir"
        return 0
    fi

    print_info "检查目录: $upload_dir"

    # 查找旧的上传文件
    local old_uploads=$(find "$upload_dir" -type f -mtime +$UPLOAD_RETENTION_DAYS 2>/dev/null || true)

    if [ -n "$old_uploads" ]; then
        local count=$(echo "$old_uploads" | wc -l)
        local size=$(du -cb $old_uploads 2>/dev/null | tail -1 | cut -f1 || echo "0")

        TOTAL_FILES=$((TOTAL_FILES + count))
        TOTAL_SIZE=$((TOTAL_SIZE + size))

        print_info "找到 $count 个上传文件，共 $(human_readable_size $size)"

        if [ "$DRY_RUN" = false ]; then
            echo "$old_uploads" | xargs rm -f 2>/dev/null || true
            DELETED_FILES=$((DELETED_FILES + count))
            FREED_SPACE=$((FREED_SPACE + size))
            print_success "已删除"
        else
            print_warning "模拟模式：不会实际删除"
        fi
    else
        print_info "没有需要清理的上传文件"
    fi
}

# ==========================================
# 清理空目录
# ==========================================

cleanup_empty_dirs() {
    print_header "清理空目录"

    local dirs=(
        "backend/runtime/log"
        "backend/runtime/cache"
        "backend/runtime/temp"
    )

    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            continue
        fi

        print_info "检查目录: $dir"

        local empty_dirs=$(find "$dir" -type d -empty 2>/dev/null || true)

        if [ -n "$empty_dirs" ]; then
            local count=$(echo "$empty_dirs" | wc -l)
            print_info "找到 $count 个空目录"

            if [ "$DRY_RUN" = false ]; then
                echo "$empty_dirs" | xargs rmdir 2>/dev/null || true
                print_success "已删除"
            fi
        fi
    done
}

# ==========================================
# 显示磁盘使用情况
# ==========================================

show_disk_usage() {
    print_header "磁盘使用情况"

    echo "Before cleanup:"
    df -h / | tail -1

    if [ "$DELETED_FILES" -gt 0 ]; then
        echo ""
        echo "After cleanup:"
        df -h / | tail -1
    fi

    echo ""
    print_info "项目目录大小:"
    du -sh backend/runtime 2>/dev/null || echo "N/A"
}

# ==========================================
# 主程序
# ==========================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Running App - 系统清理工具           ║${NC}"
echo -e "${BLUE}║   System Cleanup Tool                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# 解析参数
CLEANUP_LOGS=false
CLEANUP_CACHE=false
CLEANUP_TEMP=false
CLEANUP_UPLOADS=false

if [ $# -eq 0 ]; then
    # 默认清理日志和缓存
    CLEANUP_LOGS=true
    CLEANUP_CACHE=true
    CLEANUP_TEMP=true
else
    for arg in "$@"; do
        case $arg in
            --logs)
                CLEANUP_LOGS=true
                ;;
            --cache)
                CLEANUP_CACHE=true
                ;;
            --tmp)
                CLEANUP_TEMP=true
                ;;
            --uploads)
                CLEANUP_UPLOADS=true
                ;;
            --dry-run)
                DRY_RUN=true
                print_warning "模拟模式：不会实际删除文件"
                ;;
            --all)
                CLEANUP_LOGS=true
                CLEANUP_CACHE=true
                CLEANUP_TEMP=true
                ;;
            *)
                echo "Unknown option: $arg"
                echo "Usage: $0 [--logs] [--cache] [--tmp] [--uploads] [--dry-run] [--all]"
                exit 1
                ;;
        esac
    done
fi

# 显示清理前的磁盘使用
show_disk_usage

# 执行清理
if [ "$CLEANUP_LOGS" = true ]; then
    cleanup_logs
fi

if [ "$CLEANUP_CACHE" = true ]; then
    cleanup_cache
fi

if [ "$CLEANUP_TEMP" = true ]; then
    cleanup_temp
fi

if [ "$CLEANUP_UPLOADS" = true ]; then
    cleanup_uploads
fi

# 清理空目录
cleanup_empty_dirs

# 汇总
echo ""
print_header "清理汇总"

echo "扫描文件数: $TOTAL_FILES"
echo "扫描大小: $(human_readable_size $TOTAL_SIZE)"

if [ "$DRY_RUN" = false ]; then
    echo "已删除文件: $DELETED_FILES"
    echo "释放空间: $(human_readable_size $FREED_SPACE)"

    if [ "$DELETED_FILES" -gt 0 ]; then
        print_success "清理完成！"
    else
        print_info "没有需要清理的文件"
    fi
else
    print_warning "模拟模式：实际未删除任何文件"
    print_info "移除 --dry-run 参数以实际执行清理"
fi

echo ""

# 显示清理后的磁盘使用
if [ "$DELETED_FILES" -gt 0 ] && [ "$DRY_RUN" = false ]; then
    show_disk_usage
fi

echo ""
print_header "建议"
print_info "1. 定期运行清理脚本（建议每周）"
print_info "2. 配置日志轮转避免日志文件过大"
print_info "3. 监控磁盘使用情况"
print_info "4. 重要文件请定期备份"
echo ""

exit 0
