<?php

namespace app\api\controller;

use think\facade\Db;
use think\Response;

/**
 * Prometheus Metrics导出控制器
 *
 * 提供Prometheus格式的监控指标
 */
class Metrics extends Base
{
    /**
     * 导出Prometheus格式的metrics
     *
     * @return Response
     */
    public function index()
    {
        $metrics = [];

        // 添加各种指标
        $metrics[] = $this->getAppMetrics();
        $metrics[] = $this->getDatabaseMetrics();
        $metrics[] = $this->getBusinessMetrics();
        $metrics[] = $this->getSystemMetrics();

        // 合并所有指标
        $output = implode("\n", array_filter($metrics));

        // 返回Prometheus文本格式
        return response($output, 200, [
            'Content-Type' => 'text/plain; version=0.0.4; charset=utf-8'
        ]);
    }

    /**
     * 应用程序指标
     *
     * @return string
     */
    private function getAppMetrics()
    {
        $metrics = [];

        // 应用信息
        $metrics[] = '# HELP running_app_info Application information';
        $metrics[] = '# TYPE running_app_info gauge';
        $metrics[] = sprintf(
            'running_app_info{version="%s",php_version="%s",environment="%s"} 1',
            '1.5.9',
            PHP_VERSION,
            app()->isDebug() ? 'development' : 'production'
        );

        // 应用启动时间（Unix时间戳）
        $metrics[] = '# HELP running_app_start_time_seconds Application start time in unix timestamp';
        $metrics[] = '# TYPE running_app_start_time_seconds gauge';
        $metrics[] = sprintf('running_app_start_time_seconds %d', $_SERVER['REQUEST_TIME'] ?? time());

        // PHP内存使用
        $metrics[] = '# HELP running_app_memory_usage_bytes Memory usage in bytes';
        $metrics[] = '# TYPE running_app_memory_usage_bytes gauge';
        $metrics[] = sprintf('running_app_memory_usage_bytes %d', memory_get_usage(true));

        $metrics[] = '# HELP running_app_memory_peak_bytes Peak memory usage in bytes';
        $metrics[] = '# TYPE running_app_memory_peak_bytes gauge';
        $metrics[] = sprintf('running_app_memory_peak_bytes %d', memory_get_peak_usage(true));

        return implode("\n", $metrics);
    }

    /**
     * 数据库指标
     *
     * @return string
     */
    private function getDatabaseMetrics()
    {
        try {
            $metrics = [];

            // 数据库连接状态
            $metrics[] = '# HELP running_app_db_up Database availability (1 = up, 0 = down)';
            $metrics[] = '# TYPE running_app_db_up gauge';

            try {
                Db::query('SELECT 1');
                $metrics[] = 'running_app_db_up 1';
            } catch (\Exception $e) {
                $metrics[] = 'running_app_db_up 0';
                return implode("\n", $metrics);
            }

            // 数据库连接数
            $connections = Db::query("SHOW STATUS LIKE 'Threads_connected'");
            if (!empty($connections)) {
                $metrics[] = '# HELP running_app_db_connections Number of database connections';
                $metrics[] = '# TYPE running_app_db_connections gauge';
                $metrics[] = sprintf('running_app_db_connections %d', $connections[0]['Value']);
            }

            // 慢查询数
            $slowQueries = Db::query("SHOW STATUS LIKE 'Slow_queries'");
            if (!empty($slowQueries)) {
                $metrics[] = '# HELP running_app_db_slow_queries_total Total number of slow queries';
                $metrics[] = '# TYPE running_app_db_slow_queries_total counter';
                $metrics[] = sprintf('running_app_db_slow_queries_total %d', $slowQueries[0]['Value']);
            }

            // 查询次数
            $queries = Db::query("SHOW STATUS LIKE 'Questions'");
            if (!empty($queries)) {
                $metrics[] = '# HELP running_app_db_queries_total Total number of queries';
                $metrics[] = '# TYPE running_app_db_queries_total counter';
                $metrics[] = sprintf('running_app_db_queries_total %d', $queries[0]['Value']);
            }

            return implode("\n", $metrics);
        } catch (\Exception $e) {
            return '';
        }
    }

    /**
     * 业务指标
     *
     * @return string
     */
    private function getBusinessMetrics()
    {
        try {
            $metrics = [];

            // 用户总数
            $userCount = Db::name('user')->count();
            $metrics[] = '# HELP running_app_users_total Total number of registered users';
            $metrics[] = '# TYPE running_app_users_total gauge';
            $metrics[] = sprintf('running_app_users_total %d', $userCount);

            // 今日新增用户
            $todayUsers = Db::name('user')
                ->whereTime('create_time', 'today')
                ->count();
            $metrics[] = '# HELP running_app_users_today Users registered today';
            $metrics[] = '# TYPE running_app_users_today gauge';
            $metrics[] = sprintf('running_app_users_today %d', $todayUsers);

            // 跑步记录总数
            $runningCount = Db::name('running_record')->count();
            $metrics[] = '# HELP running_app_running_records_total Total number of running records';
            $metrics[] = '# TYPE running_app_running_records_total gauge';
            $metrics[] = sprintf('running_app_running_records_total %d', $runningCount);

            // 今日跑步记录
            $todayRunning = Db::name('running_record')
                ->whereTime('start_time', 'today')
                ->count();
            $metrics[] = '# HELP running_app_running_records_today Running records created today';
            $metrics[] = '# TYPE running_app_running_records_today gauge';
            $metrics[] = sprintf('running_app_running_records_today %d', $todayRunning);

            // 总跑步距离（公里）
            $totalDistance = Db::name('running_record')->sum('distance');
            $metrics[] = '# HELP running_app_running_distance_km_total Total running distance in kilometers';
            $metrics[] = '# TYPE running_app_running_distance_km_total counter';
            $metrics[] = sprintf('running_app_running_distance_km_total %.2f', $totalDistance);

            // 社交帖子总数
            $postCount = Db::name('post')->count();
            $metrics[] = '# HELP running_app_posts_total Total number of posts';
            $metrics[] = '# TYPE running_app_posts_total gauge';
            $metrics[] = sprintf('running_app_posts_total %d', $postCount);

            // 今日帖子数
            $todayPosts = Db::name('post')
                ->whereTime('create_time', 'today')
                ->count();
            $metrics[] = '# HELP running_app_posts_today Posts created today';
            $metrics[] = '# TYPE running_app_posts_today gauge';
            $metrics[] = sprintf('running_app_posts_today %d', $todayPosts);

            // 活跃挑战数
            $activeChallenges = Db::name('challenge')
                ->where('status', 1)
                ->where('end_time', '>', date('Y-m-d H:i:s'))
                ->count();
            $metrics[] = '# HELP running_app_challenges_active Number of active challenges';
            $metrics[] = '# TYPE running_app_challenges_active gauge';
            $metrics[] = sprintf('running_app_challenges_active %d', $activeChallenges);

            // 跑团数量
            $clubCount = Db::name('running_club')->count();
            $metrics[] = '# HELP running_app_clubs_total Total number of running clubs';
            $metrics[] = '# TYPE running_app_clubs_total gauge';
            $metrics[] = sprintf('running_app_clubs_total %d', $clubCount);

            return implode("\n", $metrics);
        } catch (\Exception $e) {
            return '';
        }
    }

    /**
     * 系统指标
     *
     * @return string
     */
    private function getSystemMetrics()
    {
        $metrics = [];

        // CPU负载（仅Linux）
        if (function_exists('sys_getloadavg')) {
            $load = sys_getloadavg();
            $metrics[] = '# HELP running_app_system_load_1m System load average (1 minute)';
            $metrics[] = '# TYPE running_app_system_load_1m gauge';
            $metrics[] = sprintf('running_app_system_load_1m %.2f', $load[0]);

            $metrics[] = '# HELP running_app_system_load_5m System load average (5 minutes)';
            $metrics[] = '# TYPE running_app_system_load_5m gauge';
            $metrics[] = sprintf('running_app_system_load_5m %.2f', $load[1]);

            $metrics[] = '# HELP running_app_system_load_15m System load average (15 minutes)';
            $metrics[] = '# TYPE running_app_system_load_15m gauge';
            $metrics[] = sprintf('running_app_system_load_15m %.2f', $load[2]);
        }

        // 磁盘空间
        $runtimePath = runtime_path();
        $diskFree = disk_free_space($runtimePath);
        $diskTotal = disk_total_space($runtimePath);

        $metrics[] = '# HELP running_app_disk_free_bytes Free disk space in bytes';
        $metrics[] = '# TYPE running_app_disk_free_bytes gauge';
        $metrics[] = sprintf('running_app_disk_free_bytes %d', $diskFree);

        $metrics[] = '# HELP running_app_disk_total_bytes Total disk space in bytes';
        $metrics[] = '# TYPE running_app_disk_total_bytes gauge';
        $metrics[] = sprintf('running_app_disk_total_bytes %d', $diskTotal);

        return implode("\n", $metrics);
    }

    /**
     * 自定义业务指标（示例）
     *
     * 可以根据业务需求添加更多指标
     */
    private function getCustomMetrics()
    {
        $metrics = [];

        // 示例：按性别统计用户数
        $usersByGender = Db::name('user')
            ->field('gender, COUNT(*) as count')
            ->group('gender')
            ->select()
            ->toArray();

        $metrics[] = '# HELP running_app_users_by_gender Number of users by gender';
        $metrics[] = '# TYPE running_app_users_by_gender gauge';

        $genderMap = [0 => 'unknown', 1 => 'male', 2 => 'female'];
        foreach ($usersByGender as $row) {
            $gender = $genderMap[$row['gender']] ?? 'unknown';
            $metrics[] = sprintf('running_app_users_by_gender{gender="%s"} %d', $gender, $row['count']);
        }

        return implode("\n", $metrics);
    }
}
