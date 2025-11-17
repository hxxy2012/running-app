#!/bin/bash

###############################################################################
# Running App - 性能监控脚本
#
# 用途: 监控API性能、数据库性能、系统资源使用情况
# 用法: ./scripts/monitor.sh [options]
#
# 选项:
#   --api         监控API性能
#   --db          监控数据库性能
#   --system      监控系统资源
#   --all         监控所有（默认）
#   --report      生成报告
###############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
API_URL="${API_URL:-http://localhost:8000}"
REPORT_DIR="${REPORT_DIR:-./reports/monitor}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# 创建报告目录
mkdir -p "$REPORT_DIR"

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

# ==========================================
# API性能监控
# ==========================================

monitor_api() {
    print_header "API性能监控"

    local report_file="$REPORT_DIR/api_performance_${TIMESTAMP}.txt"

    echo "API Performance Report - $(date)" > "$report_file"
    echo "========================================" >> "$report_file"
    echo "" >> "$report_file"

    # 测试端点列表
    local endpoints=(
        "/"
        "/user/info"
        "/running/list"
        "/post/feed"
        "/challenge/list"
    )

    local total_time=0
    local success_count=0
    local fail_count=0

    for endpoint in "${endpoints[@]}"; do
        print_info "测试: ${API_URL}${endpoint}"

        # 使用curl测试响应时间
        local response=$(curl -o /dev/null -s -w "%{http_code}|%{time_total}" "${API_URL}${endpoint}" 2>&1 || echo "000|0")

        local http_code=$(echo "$response" | cut -d'|' -f1)
        local time_total=$(echo "$response" | cut -d'|' -f2)

        echo "Endpoint: $endpoint" >> "$report_file"
        echo "  HTTP Code: $http_code" >> "$report_file"
        echo "  Response Time: ${time_total}s" >> "$report_file"

        if [ "$http_code" = "200" ] || [ "$http_code" = "401" ]; then
            success_count=$((success_count + 1))

            # 转换为毫秒
            local time_ms=$(echo "$time_total * 1000" | bc 2>/dev/null || echo "0")

            # 评估性能
            if (( $(echo "$time_total > 1.0" | bc -l 2>/dev/null || echo 0) )); then
                echo "  Status: ⚠️  SLOW" >> "$report_file"
                print_warning "$endpoint: ${time_ms}ms (慢)"
            elif (( $(echo "$time_total > 0.5" | bc -l 2>/dev/null || echo 0) )); then
                echo "  Status: ✅ OK" >> "$report_file"
                print_info "$endpoint: ${time_ms}ms"
            else
                echo "  Status: ✅ FAST" >> "$report_file"
                print_success "$endpoint: ${time_ms}ms (快)"
            fi

            total_time=$(echo "$total_time + $time_total" | bc 2>/dev/null || echo "$total_time")
        else
            fail_count=$((fail_count + 1))
            echo "  Status: ❌ FAILED" >> "$report_file"
            print_error "$endpoint: HTTP $http_code"
        fi

        echo "" >> "$report_file"
    done

    # 统计信息
    echo "========================================" >> "$report_file"
    echo "Summary:" >> "$report_file"
    echo "  Total Endpoints: ${#endpoints[@]}" >> "$report_file"
    echo "  Successful: $success_count" >> "$report_file"
    echo "  Failed: $fail_count" >> "$report_file"

    if [ "$success_count" -gt 0 ]; then
        local avg_time=$(echo "scale=3; $total_time / $success_count" | bc 2>/dev/null || echo "0")
        echo "  Average Response Time: ${avg_time}s" >> "$report_file"
        print_info "平均响应时间: ${avg_time}s"
    fi

    print_success "报告已生成: $report_file"
}

# ==========================================
# 数据库性能监控
# ==========================================

monitor_database() {
    print_header "数据库性能监控"

    if [ ! -f "backend/.env" ]; then
        print_error "backend/.env 文件不存在"
        return 1
    fi

    cd backend

    # 读取数据库配置
    local DB_USER=$(grep "^USERNAME" .env | cut -d '=' -f 2 | tr -d ' ')
    local DB_PASS=$(grep "^PASSWORD" .env | cut -d '=' -f 2 | tr -d ' ')
    local DB_NAME=$(grep "^DATABASE" .env | cut -d '=' -f 2 | tr -d ' ')

    local report_file="../$REPORT_DIR/db_performance_${TIMESTAMP}.txt"

    echo "Database Performance Report - $(date)" > "$report_file"
    echo "========================================" >> "$report_file"
    echo "" >> "$report_file"

    # 数据库连接数
    print_info "检查数据库连接..."
    local connections=$(mysql -u "$DB_USER" -p"$DB_PASS" -e "SHOW STATUS LIKE 'Threads_connected';" 2>/dev/null | tail -1 | awk '{print $2}')
    echo "Active Connections: $connections" >> "$report_file"
    print_info "活跃连接: $connections"

    # 查询缓存
    print_info "检查查询缓存..."
    mysql -u "$DB_USER" -p"$DB_PASS" -e "SHOW STATUS LIKE 'Qcache%';" 2>/dev/null >> "$report_file" || true

    # 慢查询
    print_info "检查慢查询..."
    local slow_queries=$(mysql -u "$DB_USER" -p"$DB_PASS" -e "SHOW STATUS LIKE 'Slow_queries';" 2>/dev/null | tail -1 | awk '{print $2}')
    echo "" >> "$report_file"
    echo "Slow Queries: $slow_queries" >> "$report_file"

    if [ "$slow_queries" -gt 0 ]; then
        print_warning "发现 $slow_queries 个慢查询"
    else
        print_success "无慢查询"
    fi

    # 表大小
    print_info "检查表大小..."
    echo "" >> "$report_file"
    echo "Top 10 Largest Tables:" >> "$report_file"
    mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
        SELECT
            table_name AS 'Table',
            ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)'
        FROM information_schema.TABLES
        WHERE table_schema = '$DB_NAME'
        ORDER BY (data_length + index_length) DESC
        LIMIT 10;
    " 2>/dev/null >> "$report_file" || true

    # 索引使用情况
    print_info "检查索引使用..."
    echo "" >> "$report_file"
    echo "Index Statistics:" >> "$report_file"
    mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "
        SELECT
            COUNT(*) as index_count,
            SUM(CASE WHEN non_unique = 0 THEN 1 ELSE 0 END) as unique_indexes,
            SUM(CASE WHEN non_unique = 1 THEN 1 ELSE 0 END) as non_unique_indexes
        FROM information_schema.STATISTICS
        WHERE table_schema = '$DB_NAME';
    " 2>/dev/null >> "$report_file" || true

    cd ..
    print_success "报告已生成: $report_file"
}

# ==========================================
# 系统资源监控
# ==========================================

monitor_system() {
    print_header "系统资源监控"

    local report_file="$REPORT_DIR/system_resources_${TIMESTAMP}.txt"

    echo "System Resources Report - $(date)" > "$report_file"
    echo "========================================" >> "$report_file"
    echo "" >> "$report_file"

    # CPU使用率
    print_info "检查CPU使用率..."
    echo "CPU Usage:" >> "$report_file"
    top -bn1 | grep "Cpu(s)" >> "$report_file" || mpstat 1 1 >> "$report_file" || echo "CPU info not available" >> "$report_file"

    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}' 2>/dev/null || echo "N/A")
    print_info "CPU使用率: ${cpu_usage}%"

    # 内存使用
    print_info "检查内存使用..."
    echo "" >> "$report_file"
    echo "Memory Usage:" >> "$report_file"
    free -h >> "$report_file"

    local mem_usage=$(free | grep Mem | awk '{printf("%.1f"), $3/$2 * 100.0}' 2>/dev/null || echo "N/A")
    print_info "内存使用率: ${mem_usage}%"

    # 磁盘使用
    print_info "检查磁盘使用..."
    echo "" >> "$report_file"
    echo "Disk Usage:" >> "$report_file"
    df -h >> "$report_file"

    local disk_usage=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
    print_info "磁盘使用率: ${disk_usage}%"

    if [ "$disk_usage" -gt 90 ]; then
        print_warning "磁盘使用率超过90%"
    fi

    # 进程信息
    print_info "检查PHP进程..."
    echo "" >> "$report_file"
    echo "PHP Processes:" >> "$report_file"
    ps aux | grep php | grep -v grep >> "$report_file" || echo "No PHP processes" >> "$report_file"

    # MySQL进程
    print_info "检查MySQL进程..."
    echo "" >> "$report_file"
    echo "MySQL Processes:" >> "$report_file"
    ps aux | grep mysql | grep -v grep >> "$report_file" || echo "No MySQL processes" >> "$report_file"

    # 网络连接
    print_info "检查网络连接..."
    echo "" >> "$report_file"
    echo "Network Connections:" >> "$report_file"
    netstat -an | grep ESTABLISHED | wc -l >> "$report_file" 2>/dev/null || ss -an | grep ESTAB | wc -l >> "$report_file" 2>/dev/null || echo "N/A" >> "$report_file"

    print_success "报告已生成: $report_file"
}

# ==========================================
# 生成综合报告
# ==========================================

generate_report() {
    print_header "生成综合监控报告"

    local summary_file="$REPORT_DIR/monitoring_summary_${TIMESTAMP}.txt"

    cat > "$summary_file" << EOF
Running App - Monitoring Summary Report
========================================
Generated: $(date)
========================================

System Information:
- Hostname: $(hostname)
- OS: $(uname -s)
- Kernel: $(uname -r)
- Uptime: $(uptime -p 2>/dev/null || uptime)

========================================
监控建议:
========================================

1. API性能优化
   - 响应时间 > 1s: 需要优化
   - 响应时间 > 0.5s: 可以优化
   - 响应时间 < 0.5s: 性能良好

2. 数据库优化
   - 慢查询数: 应为 0
   - 活跃连接: 不应超过配置的最大值
   - 索引使用: 确保所有查询都使用索引

3. 系统资源
   - CPU使用率: 应 < 80%
   - 内存使用率: 应 < 80%
   - 磁盘使用率: 应 < 90%

4. 建议检查频率
   - API性能: 每小时
   - 数据库性能: 每天
   - 系统资源: 每15分钟

========================================
Cron定时任务示例:
========================================

# 每小时API监控
0 * * * * /path/to/scripts/monitor.sh --api >> /var/log/monitor.log 2>&1

# 每天数据库监控
0 2 * * * /path/to/scripts/monitor.sh --db >> /var/log/monitor.log 2>&1

# 每15分钟系统监控
*/15 * * * * /path/to/scripts/monitor.sh --system >> /var/log/monitor.log 2>&1

========================================
EOF

    print_success "综合报告已生成: $summary_file"
    print_info "报告目录: $REPORT_DIR"
}

# ==========================================
# 主程序
# ==========================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Running App - 性能监控工具           ║${NC}"
echo -e "${BLUE}║   Performance Monitoring Tool          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# 解析参数
MONITOR_API=false
MONITOR_DB=false
MONITOR_SYSTEM=false
GENERATE_REPORT=false

if [ $# -eq 0 ]; then
    # 默认监控所有
    MONITOR_API=true
    MONITOR_DB=true
    MONITOR_SYSTEM=true
    GENERATE_REPORT=true
else
    for arg in "$@"; do
        case $arg in
            --api)
                MONITOR_API=true
                ;;
            --db)
                MONITOR_DB=true
                ;;
            --system)
                MONITOR_SYSTEM=true
                ;;
            --all)
                MONITOR_API=true
                MONITOR_DB=true
                MONITOR_SYSTEM=true
                ;;
            --report)
                GENERATE_REPORT=true
                ;;
            *)
                echo "Unknown option: $arg"
                echo "Usage: $0 [--api] [--db] [--system] [--all] [--report]"
                exit 1
                ;;
        esac
    done
fi

# 执行监控
if [ "$MONITOR_API" = true ]; then
    monitor_api
fi

if [ "$MONITOR_DB" = true ]; then
    monitor_database
fi

if [ "$MONITOR_SYSTEM" = true ]; then
    monitor_system
fi

if [ "$GENERATE_REPORT" = true ]; then
    generate_report
fi

echo ""
print_header "监控完成"
echo "监控时间: $(date)"
echo "报告目录: $REPORT_DIR"
echo ""

exit 0
