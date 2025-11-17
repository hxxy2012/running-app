#!/bin/bash

###############################################################################
# Running App - 日志分析工具
#
# 用途: 分析应用日志，统计错误、性能问题
# 用法: ./scripts/analyze_logs.sh [options]
#
# 选项:
#   --errors      分析错误日志
#   --access      分析访问日志
#   --slow        分析慢查询日志
#   --today       只分析今天的日志
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
LOG_DIR="${LOG_DIR:-backend/runtime/log}"
REPORT_DIR="${REPORT_DIR:-./reports/logs}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TODAY=$(date +"%Y-%m-%d")

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
# 分析错误日志
# ==========================================

analyze_errors() {
    print_header "分析错误日志"

    if [ ! -d "$LOG_DIR" ]; then
        print_error "日志目录不存在: $LOG_DIR"
        return 1
    fi

    local report_file="$REPORT_DIR/error_analysis_${TIMESTAMP}.txt"

    echo "Error Log Analysis Report - $(date)" > "$report_file"
    echo "========================================" >> "$report_file"
    echo "" >> "$report_file"

    # 查找错误日志文件
    local error_logs=$(find "$LOG_DIR" -name "*.log" -type f 2>/dev/null)

    if [ -z "$error_logs" ]; then
        print_warning "未找到日志文件"
        return 0
    fi

    # 统计总错误数
    print_info "统计错误数量..."
    local total_errors=$(cat $error_logs 2>/dev/null | grep -i "error\|exception\|fatal" | wc -l)
    echo "Total Errors: $total_errors" >> "$report_file"
    print_info "总错误数: $total_errors"

    # 今天的错误
    if [ "$ANALYZE_TODAY" = true ]; then
        print_info "统计今天的错误..."
        local today_errors=$(cat $error_logs 2>/dev/null | grep "$TODAY" | grep -i "error\|exception\|fatal" | wc -l)
        echo "Today's Errors: $today_errors" >> "$report_file"
        print_info "今天的错误: $today_errors"
    fi

    # Top 10错误类型
    print_info "统计错误类型..."
    echo "" >> "$report_file"
    echo "Top 10 Error Types:" >> "$report_file"
    echo "==================" >> "$report_file"

    cat $error_logs 2>/dev/null | \
        grep -i "error\|exception\|fatal" | \
        sed 's/.*\(Error\|Exception\|Fatal\)[: ].*/\1/' | \
        sort | uniq -c | sort -rn | head -10 >> "$report_file"

    # Top 10错误消息
    echo "" >> "$report_file"
    echo "Top 10 Error Messages:" >> "$report_file"
    echo "=====================" >> "$report_file"

    cat $error_logs 2>/dev/null | \
        grep -i "error\|exception" | \
        cut -d']' -f2- | \
        sort | uniq -c | sort -rn | head -10 >> "$report_file"

    # PHP错误
    echo "" >> "$report_file"
    echo "PHP Errors:" >> "$report_file"
    echo "===========" >> "$report_file"

    local php_errors=$(cat $error_logs 2>/dev/null | grep -i "PHP Fatal error\|PHP Warning\|PHP Notice" | wc -l)
    echo "PHP Fatal Errors: $(cat $error_logs 2>/dev/null | grep -i "PHP Fatal error" | wc -l)" >> "$report_file"
    echo "PHP Warnings: $(cat $error_logs 2>/dev/null | grep -i "PHP Warning" | wc -l)" >> "$report_file"
    echo "PHP Notices: $(cat $error_logs 2>/dev/null | grep -i "PHP Notice" | wc -l)" >> "$report_file"

    print_info "PHP错误: $php_errors"

    # 数据库错误
    echo "" >> "$report_file"
    echo "Database Errors:" >> "$report_file"
    echo "================" >> "$report_file"

    local db_errors=$(cat $error_logs 2>/dev/null | grep -i "SQL\|MySQL\|database" | grep -i "error" | wc -l)
    echo "Total: $db_errors" >> "$report_file"
    print_info "数据库错误: $db_errors"

    # 最近的错误
    echo "" >> "$report_file"
    echo "Latest 20 Errors:" >> "$report_file"
    echo "=================" >> "$report_file"

    cat $error_logs 2>/dev/null | \
        grep -i "error\|exception\|fatal" | \
        tail -20 >> "$report_file"

    print_success "报告已生成: $report_file"

    # 警告检查
    if [ "$total_errors" -gt 100 ]; then
        print_warning "错误数量较多，建议检查日志"
    fi

    if [ "$php_errors" -gt 0 ]; then
        print_warning "发现PHP错误，建议修复"
    fi
}

# ==========================================
# 分析访问日志
# ==========================================

analyze_access() {
    print_header "分析访问日志"

    # 检查是否有Nginx/Apache访问日志
    local access_log=""

    if [ -f "/var/log/nginx/access.log" ]; then
        access_log="/var/log/nginx/access.log"
    elif [ -f "/var/log/apache2/access.log" ]; then
        access_log="/var/log/apache2/access.log"
    elif [ -f "/usr/local/var/log/nginx/access.log" ]; then
        access_log="/usr/local/var/log/nginx/access.log"
    fi

    if [ -z "$access_log" ] || [ ! -f "$access_log" ]; then
        print_warning "未找到访问日志文件"
        return 0
    fi

    local report_file="$REPORT_DIR/access_analysis_${TIMESTAMP}.txt"

    echo "Access Log Analysis Report - $(date)" > "$report_file"
    echo "========================================" >> "$report_file"
    echo "Log File: $access_log" >> "$report_file"
    echo "" >> "$report_file"

    # 总请求数
    print_info "统计总请求数..."
    local total_requests=$(wc -l < "$access_log" 2>/dev/null || echo "0")
    echo "Total Requests: $total_requests" >> "$report_file"
    print_info "总请求数: $total_requests"

    # 今天的请求
    if [ "$ANALYZE_TODAY" = true ]; then
        local today_requests=$(grep "$TODAY" "$access_log" 2>/dev/null | wc -l)
        echo "Today's Requests: $today_requests" >> "$report_file"
        print_info "今天的请求: $today_requests"
    fi

    # Top 10访问的URL
    echo "" >> "$report_file"
    echo "Top 10 URLs:" >> "$report_file"
    echo "============" >> "$report_file"

    awk '{print $7}' "$access_log" 2>/dev/null | \
        sort | uniq -c | sort -rn | head -10 >> "$report_file"

    # Top 10 IP地址
    echo "" >> "$report_file"
    echo "Top 10 IP Addresses:" >> "$report_file"
    echo "====================" >> "$report_file"

    awk '{print $1}' "$access_log" 2>/dev/null | \
        sort | uniq -c | sort -rn | head -10 >> "$report_file"

    # HTTP状态码统计
    echo "" >> "$report_file"
    echo "HTTP Status Codes:" >> "$report_file"
    echo "==================" >> "$report_file"

    awk '{print $9}' "$access_log" 2>/dev/null | \
        sort | uniq -c | sort -rn >> "$report_file"

    local errors_4xx=$(awk '{print $9}' "$access_log" 2>/dev/null | grep "^4" | wc -l)
    local errors_5xx=$(awk '{print $9}' "$access_log" 2>/dev/null | grep "^5" | wc -l)

    print_info "4xx错误: $errors_4xx"
    print_info "5xx错误: $errors_5xx"

    # 慢请求（响应时间 > 1s）
    echo "" >> "$report_file"
    echo "Slow Requests (> 1s):" >> "$report_file"
    echo "=====================" >> "$report_file"

    awk '{if ($NF > 1.0) print}' "$access_log" 2>/dev/null | head -20 >> "$report_file" || echo "No slow request data" >> "$report_file"

    print_success "报告已生成: $report_file"

    if [ "$errors_5xx" -gt 10 ]; then
        print_warning "5xx错误较多，建议检查服务器"
    fi
}

# ==========================================
# 分析慢查询日志
# ==========================================

analyze_slow_queries() {
    print_header "分析数据库慢查询"

    # 检查慢查询日志
    local slow_log=""

    if [ -f "/var/log/mysql/mysql-slow.log" ]; then
        slow_log="/var/log/mysql/mysql-slow.log"
    elif [ -f "/var/log/mysqld-slow.log" ]; then
        slow_log="/var/log/mysqld-slow.log"
    elif [ -f "/usr/local/var/mysql/$(hostname)-slow.log" ]; then
        slow_log="/usr/local/var/mysql/$(hostname)-slow.log"
    fi

    if [ -z "$slow_log" ] || [ ! -f "$slow_log" ]; then
        print_warning "未找到慢查询日志文件"
        print_info "请在MySQL配置中启用慢查询日志"
        return 0
    fi

    local report_file="$REPORT_DIR/slow_query_analysis_${TIMESTAMP}.txt"

    echo "Slow Query Analysis Report - $(date)" > "$report_file"
    echo "========================================" >> "$report_file"
    echo "Log File: $slow_log" >> "$report_file"
    echo "" >> "$report_file"

    # 统计慢查询数量
    print_info "统计慢查询数量..."
    local slow_count=$(grep -c "Query_time:" "$slow_log" 2>/dev/null || echo "0")
    echo "Total Slow Queries: $slow_count" >> "$report_file"
    print_info "慢查询数: $slow_count"

    if [ "$slow_count" -eq 0 ]; then
        print_success "没有慢查询，性能良好"
        return 0
    fi

    # 最慢的查询
    echo "" >> "$report_file"
    echo "Slowest Queries:" >> "$report_file"
    echo "================" >> "$report_file"

    grep "Query_time:" "$slow_log" 2>/dev/null | \
        sort -t: -k2 -rn | head -10 >> "$report_file"

    # 慢查询的表
    echo "" >> "$report_file"
    echo "Most Queried Tables in Slow Queries:" >> "$report_file"
    echo "=====================================" >> "$report_file"

    grep -i "FROM\|JOIN" "$slow_log" 2>/dev/null | \
        sed 's/.*FROM //; s/.*JOIN //; s/ .*//' | \
        sort | uniq -c | sort -rn | head -10 >> "$report_file"

    print_success "报告已生成: $report_file"
    print_warning "发现 $slow_count 个慢查询，建议优化"
}

# ==========================================
# 生成综合报告
# ==========================================

generate_summary() {
    print_header "生成综合日志分析报告"

    local summary_file="$REPORT_DIR/log_summary_${TIMESTAMP}.txt"

    cat > "$summary_file" << EOF
Running App - Log Analysis Summary
===================================
Generated: $(date)
===================================

日志分析结果:
- 错误日志: $LOG_DIR
- 访问日志: 已分析
- 慢查询: 已分析

===================================
建议:
===================================

1. 错误处理
   - 错误数 > 100: 需要立即处理
   - PHP错误: 应为 0
   - 数据库错误: 应为 0

2. 访问监控
   - 4xx错误率: 应 < 5%
   - 5xx错误率: 应 < 1%
   - 慢请求: 应优化

3. 数据库优化
   - 慢查询: 应为 0
   - 添加必要的索引
   - 优化SQL语句

4. 日志管理
   - 定期清理旧日志
   - 配置日志轮转
   - 设置日志级别

===================================
日志轮转配置示例:
===================================

/path/to/backend/runtime/log/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 www-data www-data
}

===================================
EOF

    print_success "综合报告已生成: $summary_file"
}

# ==========================================
# 主程序
# ==========================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Running App - 日志分析工具           ║${NC}"
echo -e "${BLUE}║   Log Analysis Tool                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# 解析参数
ANALYZE_ERRORS=false
ANALYZE_ACCESS=false
ANALYZE_SLOW=false
ANALYZE_TODAY=false
GENERATE_SUMMARY=false

if [ $# -eq 0 ]; then
    # 默认分析所有
    ANALYZE_ERRORS=true
    ANALYZE_ACCESS=true
    ANALYZE_SLOW=true
    GENERATE_SUMMARY=true
else
    for arg in "$@"; do
        case $arg in
            --errors)
                ANALYZE_ERRORS=true
                ;;
            --access)
                ANALYZE_ACCESS=true
                ;;
            --slow)
                ANALYZE_SLOW=true
                ;;
            --today)
                ANALYZE_TODAY=true
                ;;
            --report)
                GENERATE_SUMMARY=true
                ;;
            *)
                echo "Unknown option: $arg"
                echo "Usage: $0 [--errors] [--access] [--slow] [--today] [--report]"
                exit 1
                ;;
        esac
    done
fi

# 执行分析
if [ "$ANALYZE_ERRORS" = true ]; then
    analyze_errors
fi

if [ "$ANALYZE_ACCESS" = true ]; then
    analyze_access
fi

if [ "$ANALYZE_SLOW" = true ]; then
    analyze_slow_queries
fi

if [ "$GENERATE_SUMMARY" = true ]; then
    generate_summary
fi

echo ""
print_header "分析完成"
echo "分析时间: $(date)"
echo "报告目录: $REPORT_DIR"
echo ""

exit 0
