#!/bin/bash

###############################################################################
# 性能压力测试脚本
#
# 功能：
# - API性能压测
# - 并发用户测试
# - 响应时间分析
# - 吞吐量测试
# - 错误率统计
#
# 使用：
#   ./load_test.sh                    # 运行完整测试
#   ./load_test.sh quick              # 快速测试（较少并发）
#   ./load_test.sh api /user/info     # 测试指定API
#   ./load_test.sh report             # 查看最新测试报告
#
# 依赖工具：
#   - Apache Bench (ab)
#   - curl
#   - bc (计算器)
###############################################################################

# 配置
API_BASE_URL="${API_BASE_URL:-http://localhost:8000}"
REPORT_DIR="./tests/load_test_reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="$REPORT_DIR/load_test_$TIMESTAMP.txt"

# 测试配置
declare -A TEST_CONFIGS=(
    ["quick_requests"]=100
    ["quick_concurrency"]=10
    ["normal_requests"]=1000
    ["normal_concurrency"]=50
    ["stress_requests"]=5000
    ["stress_concurrency"]=200
)

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的信息
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

# 检查依赖
check_dependencies() {
    local missing=0

    if ! command -v ab &> /dev/null; then
        print_error "Apache Bench (ab) 未安装"
        print_info "安装方法："
        print_info "  Ubuntu/Debian: sudo apt-get install apache2-utils"
        print_info "  CentOS/RHEL: sudo yum install httpd-tools"
        print_info "  macOS: brew install httpd"
        missing=1
    fi

    if ! command -v curl &> /dev/null; then
        print_error "curl 未安装"
        missing=1
    fi

    if ! command -v bc &> /dev/null; then
        print_error "bc 未安装 (sudo apt-get install bc)"
        missing=1
    fi

    if [ $missing -eq 1 ]; then
        exit 1
    fi

    print_success "依赖检查通过"
}

# 创建报告目录
init_report_dir() {
    mkdir -p "$REPORT_DIR"
    echo "========================================" > "$REPORT_FILE"
    echo "Running App 性能压力测试报告" >> "$REPORT_FILE"
    echo "测试时间: $(date)" >> "$REPORT_FILE"
    echo "API地址: $API_BASE_URL" >> "$REPORT_FILE"
    echo "========================================" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

# 执行API压测
run_ab_test() {
    local url=$1
    local requests=$2
    local concurrency=$3
    local description=$4
    local token=$5

    print_info "测试: $description"
    print_info "  URL: $url"
    print_info "  总请求数: $requests"
    print_info "  并发数: $concurrency"

    echo "" >> "$REPORT_FILE"
    echo "----------------------------------------" >> "$REPORT_FILE"
    echo "测试项: $description" >> "$REPORT_FILE"
    echo "URL: $url" >> "$REPORT_FILE"
    echo "----------------------------------------" >> "$REPORT_FILE"

    # 构建ab命令
    local ab_cmd="ab -n $requests -c $concurrency"

    if [ -n "$token" ]; then
        ab_cmd="$ab_cmd -H \"Authorization: Bearer $token\""
    fi

    ab_cmd="$ab_cmd -T 'application/json' -g /dev/null $url"

    # 执行测试
    local result=$(eval $ab_cmd 2>&1)

    # 解析结果
    local rps=$(echo "$result" | grep "Requests per second" | awk '{print $4}')
    local mean_time=$(echo "$result" | grep "Time per request.*mean\)" | head -1 | awk '{print $4}')
    local failed=$(echo "$result" | grep "Failed requests" | awk '{print $3}')
    local transfer_rate=$(echo "$result" | grep "Transfer rate" | awk '{print $3}')

    # 输出到终端
    echo ""
    echo "  ✓ 吞吐量: $rps 请求/秒"
    echo "  ✓ 平均响应时间: $mean_time ms"
    echo "  ✓ 失败请求: $failed"
    echo "  ✓ 传输速率: $transfer_rate KB/s"

    # 写入报告
    echo "$result" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    # 性能评估
    if (( $(echo "$mean_time < 100" | bc -l) )); then
        print_success "性能: 优秀 (<100ms)"
    elif (( $(echo "$mean_time < 500" | bc -l) )); then
        print_warning "性能: 良好 (100-500ms)"
    elif (( $(echo "$mean_time < 1000" | bc -l) )); then
        print_warning "性能: 一般 (500-1000ms)"
    else
        print_error "性能: 较差 (>1000ms)"
    fi

    echo ""
}

# 快速测试
quick_test() {
    local requests=${TEST_CONFIGS["quick_requests"]}
    local concurrency=${TEST_CONFIGS["quick_concurrency"]}

    print_info "运行快速测试模式..."

    # 测试公开API
    run_ab_test "$API_BASE_URL/" $requests $concurrency "首页健康检查"

    # 测试登录API
    print_info "测试登录接口 (POST请求需使用curl)..."
    test_login_performance $requests $concurrency
}

# 标准测试
normal_test() {
    local requests=${TEST_CONFIGS["normal_requests"]}
    local concurrency=${TEST_CONFIGS["normal_concurrency"]}

    print_info "运行标准测试模式..."

    # 各个端点测试
    run_ab_test "$API_BASE_URL/" $requests $concurrency "首页"
    run_ab_test "$API_BASE_URL/running/list" $requests $concurrency "跑步记录列表"
    run_ab_test "$API_BASE_URL/post/feed" $requests $concurrency "动态信息流"
    run_ab_test "$API_BASE_URL/ranking/distance" $requests $concurrency "距离排行榜"
    run_ab_test "$API_BASE_URL/challenge/list" $requests $concurrency "挑战列表"
}

# 压力测试
stress_test() {
    local requests=${TEST_CONFIGS["stress_requests"]}
    local concurrency=${TEST_CONFIGS["stress_concurrency"]}

    print_warning "运行压力测试模式（高负载）..."
    print_warning "这可能会对服务器造成较大压力，请确认后继续"

    read -p "是否继续? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "已取消压力测试"
        return
    fi

    run_ab_test "$API_BASE_URL/" $requests $concurrency "高并发首页测试"
    run_ab_test "$API_BASE_URL/running/list" $requests $concurrency "高并发列表查询"
}

# 测试登录性能（使用curl）
test_login_performance() {
    local requests=$1
    local concurrency=$2

    print_info "登录接口性能测试 ($requests 请求, $concurrency 并发)"

    local start_time=$(date +%s.%N)
    local success_count=0
    local failed_count=0

    # 并发测试（简化版）
    for i in $(seq 1 $requests); do
        (
            response=$(curl -s -w "\n%{http_code}" \
                -X POST \
                -H "Content-Type: application/json" \
                -d '{"account":"testuser","password":"testpass"}' \
                "$API_BASE_URL/auth/login" 2>/dev/null)

            http_code=$(echo "$response" | tail -n 1)
            if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 400 ]; then
                echo "success"
            else
                echo "failed"
            fi
        ) &

        # 控制并发数
        if [ $((i % concurrency)) -eq 0 ]; then
            wait
        fi
    done
    wait

    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)
    local rps=$(echo "scale=2; $requests / $duration" | bc)

    echo "  ✓ 总耗时: ${duration}s"
    echo "  ✓ 吞吐量: ${rps} 请求/秒"
}

# 生成性能报告摘要
generate_summary() {
    print_info "生成测试摘要..."

    echo "" >> "$REPORT_FILE"
    echo "========================================" >> "$REPORT_FILE"
    echo "测试总结" >> "$REPORT_FILE"
    echo "========================================" >> "$REPORT_FILE"
    echo "报告文件: $REPORT_FILE" >> "$REPORT_FILE"
    echo "测试完成时间: $(date)" >> "$REPORT_FILE"

    print_success "测试完成！"
    print_info "详细报告: $REPORT_FILE"
}

# 查看最新报告
view_latest_report() {
    local latest=$(ls -t $REPORT_DIR/load_test_*.txt 2>/dev/null | head -1)

    if [ -z "$latest" ]; then
        print_error "未找到测试报告"
        return 1
    fi

    print_info "最新测试报告: $latest"
    echo ""
    cat "$latest"
}

# 测试指定API
test_specific_api() {
    local endpoint=$1
    local url="$API_BASE_URL$endpoint"

    print_info "测试指定API: $endpoint"

    run_ab_test "$url" 500 25 "自定义API测试: $endpoint"
}

# 主函数
main() {
    echo ""
    echo "============================================"
    echo "  Running App 性能压力测试工具"
    echo "============================================"
    echo ""

    check_dependencies
    init_report_dir

    local mode=${1:-normal}

    case $mode in
        quick)
            quick_test
            ;;
        normal)
            normal_test
            ;;
        stress)
            stress_test
            ;;
        api)
            test_specific_api "$2"
            ;;
        report)
            view_latest_report
            return 0
            ;;
        *)
            print_error "未知模式: $mode"
            echo ""
            echo "使用方法:"
            echo "  $0 quick          快速测试"
            echo "  $0 normal         标准测试（默认）"
            echo "  $0 stress         压力测试"
            echo "  $0 api <path>     测试指定API"
            echo "  $0 report         查看最新报告"
            exit 1
            ;;
    esac

    if [ "$mode" != "report" ]; then
        generate_summary
    fi
}

# 执行主函数
main "$@"
