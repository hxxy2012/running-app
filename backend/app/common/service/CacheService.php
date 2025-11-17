<?php

namespace app\common\service;

use think\facade\Cache;

/**
 * 缓存服务类
 *
 * 提供统一的缓存接口，支持Redis和文件缓存
 * 包含常用的缓存模式：缓存穿透、缓存雪崩、缓存击穿防护
 */
class CacheService
{
    /**
     * 缓存键前缀
     */
    const PREFIX = 'running_app:';

    /**
     * 默认缓存时间（秒）
     */
    const DEFAULT_TTL = 3600; // 1小时

    /**
     * 短期缓存时间
     */
    const SHORT_TTL = 300; // 5分钟

    /**
     * 长期缓存时间
     */
    const LONG_TTL = 86400; // 24小时

    /**
     * 缓存键分类
     */
    const KEY_USER = 'user:';
    const KEY_RUNNING = 'running:';
    const KEY_POST = 'post:';
    const KEY_RANKING = 'ranking:';
    const KEY_CHALLENGE = 'challenge:';
    const KEY_CLUB = 'club:';
    const KEY_ACHIEVEMENT = 'achievement:';

    /**
     * 生成缓存键
     *
     * @param string $category 分类
     * @param string $key 键名
     * @return string
     */
    public static function key($category, $key)
    {
        return self::PREFIX . $category . $key;
    }

    /**
     * 获取缓存
     *
     * @param string $key 缓存键
     * @param mixed $default 默认值
     * @return mixed
     */
    public static function get($key, $default = null)
    {
        try {
            $value = Cache::get($key);
            return $value !== false ? $value : $default;
        } catch (\Exception $e) {
            // 缓存失败降级到默认值
            return $default;
        }
    }

    /**
     * 设置缓存
     *
     * @param string $key 缓存键
     * @param mixed $value 缓存值
     * @param int $ttl 过期时间（秒）
     * @return bool
     */
    public static function set($key, $value, $ttl = self::DEFAULT_TTL)
    {
        try {
            return Cache::set($key, $value, $ttl);
        } catch (\Exception $e) {
            return false;
        }
    }

    /**
     * 删除缓存
     *
     * @param string $key 缓存键
     * @return bool
     */
    public static function delete($key)
    {
        try {
            return Cache::delete($key);
        } catch (\Exception $e) {
            return false;
        }
    }

    /**
     * 批量删除缓存（支持模糊匹配）
     *
     * @param string $pattern 匹配模式
     * @return bool
     */
    public static function deleteByPattern($pattern)
    {
        try {
            return Cache::tag($pattern)->clear();
        } catch (\Exception $e) {
            return false;
        }
    }

    /**
     * 判断缓存是否存在
     *
     * @param string $key 缓存键
     * @return bool
     */
    public static function has($key)
    {
        try {
            return Cache::has($key);
        } catch (\Exception $e) {
            return false;
        }
    }

    /**
     * 缓存穿透防护：remember模式
     *
     * 如果缓存不存在，则执行回调函数获取数据并缓存
     * 支持缓存空值防止穿透
     *
     * @param string $key 缓存键
     * @param callable $callback 获取数据的回调函数
     * @param int $ttl 缓存时间
     * @return mixed
     */
    public static function remember($key, $callback, $ttl = self::DEFAULT_TTL)
    {
        // 尝试从缓存获取
        $value = self::get($key);

        if ($value !== null) {
            // 处理缓存的空值标记
            if ($value === '__NULL__') {
                return null;
            }
            return $value;
        }

        // 缓存未命中，执行回调获取数据
        try {
            $value = $callback();

            // 如果数据为空，缓存特殊标记（防止穿透）
            if ($value === null || $value === false) {
                self::set($key, '__NULL__', min($ttl, 60)); // 空值缓存时间较短
                return $value;
            }

            // 缓存数据
            self::set($key, $value, $ttl);

            return $value;
        } catch (\Exception $e) {
            // 回调执行失败，返回null
            return null;
        }
    }

    /**
     * 获取用户缓存
     *
     * @param int $userId 用户ID
     * @return mixed
     */
    public static function getUserInfo($userId)
    {
        $key = self::key(self::KEY_USER, "info:{$userId}");
        return self::get($key);
    }

    /**
     * 设置用户缓存
     *
     * @param int $userId 用户ID
     * @param array $userInfo 用户信息
     * @param int $ttl 缓存时间
     * @return bool
     */
    public static function setUserInfo($userId, $userInfo, $ttl = self::LONG_TTL)
    {
        $key = self::key(self::KEY_USER, "info:{$userId}");
        return self::set($key, $userInfo, $ttl);
    }

    /**
     * 删除用户缓存
     *
     * @param int $userId 用户ID
     * @return bool
     */
    public static function deleteUserInfo($userId)
    {
        $key = self::key(self::KEY_USER, "info:{$userId}");
        return self::delete($key);
    }

    /**
     * 获取跑步记录列表缓存
     *
     * @param int $userId 用户ID
     * @param int $page 页码
     * @return mixed
     */
    public static function getRunningList($userId, $page = 1)
    {
        $key = self::key(self::KEY_RUNNING, "list:{$userId}:{$page}");
        return self::get($key);
    }

    /**
     * 设置跑步记录列表缓存
     *
     * @param int $userId 用户ID
     * @param int $page 页码
     * @param array $list 列表数据
     * @return bool
     */
    public static function setRunningList($userId, $page, $list)
    {
        $key = self::key(self::KEY_RUNNING, "list:{$userId}:{$page}");
        return self::set($key, $list, self::SHORT_TTL);
    }

    /**
     * 删除用户的所有跑步记录缓存
     *
     * @param int $userId 用户ID
     * @return bool
     */
    public static function deleteRunningList($userId)
    {
        $pattern = self::key(self::KEY_RUNNING, "list:{$userId}:*");
        return self::deleteByPattern($pattern);
    }

    /**
     * 获取排行榜缓存
     *
     * @param string $type 排行类型
     * @param string $period 时间周期
     * @return mixed
     */
    public static function getRanking($type, $period)
    {
        $key = self::key(self::KEY_RANKING, "{$type}:{$period}");
        return self::get($key);
    }

    /**
     * 设置排行榜缓存
     *
     * @param string $type 排行类型
     * @param string $period 时间周期
     * @param array $ranking 排行数据
     * @return bool
     */
    public static function setRanking($type, $period, $ranking)
    {
        $key = self::key(self::KEY_RANKING, "{$type}:{$period}");
        return self::set($key, $ranking, self::DEFAULT_TTL);
    }

    /**
     * 刷新所有排行榜缓存
     *
     * @return bool
     */
    public static function refreshAllRankings()
    {
        $pattern = self::key(self::KEY_RANKING, '*');
        return self::deleteByPattern($pattern);
    }

    /**
     * 获取动态信息流缓存
     *
     * @param int $userId 用户ID
     * @param int $page 页码
     * @return mixed
     */
    public static function getPostFeed($userId, $page = 1)
    {
        $key = self::key(self::KEY_POST, "feed:{$userId}:{$page}");
        return self::get($key);
    }

    /**
     * 设置动态信息流缓存
     *
     * @param int $userId 用户ID
     * @param int $page 页码
     * @param array $feed 信息流数据
     * @return bool
     */
    public static function setPostFeed($userId, $page, $feed)
    {
        $key = self::key(self::KEY_POST, "feed:{$userId}:{$page}");
        return self::set($key, $feed, self::SHORT_TTL);
    }

    /**
     * 增加计数器
     *
     * @param string $key 计数器键
     * @param int $step 增加步长
     * @return int|false
     */
    public static function increment($key, $step = 1)
    {
        try {
            return Cache::inc($key, $step);
        } catch (\Exception $e) {
            return false;
        }
    }

    /**
     * 减少计数器
     *
     * @param string $key 计数器键
     * @param int $step 减少步长
     * @return int|false
     */
    public static function decrement($key, $step = 1)
    {
        try {
            return Cache::dec($key, $step);
        } catch (\Exception $e) {
            return false;
        }
    }

    /**
     * 限流检查（令牌桶算法）
     *
     * @param string $identifier 限流标识（如用户ID、IP等）
     * @param int $maxRequests 最大请求数
     * @param int $timeWindow 时间窗口（秒）
     * @return bool true表示允许请求，false表示限流
     */
    public static function checkRateLimit($identifier, $maxRequests, $timeWindow)
    {
        $key = self::PREFIX . 'rate_limit:' . $identifier;

        try {
            $current = self::get($key, 0);

            if ($current >= $maxRequests) {
                return false; // 达到限流阈值
            }

            // 增加计数
            if ($current == 0) {
                self::set($key, 1, $timeWindow);
            } else {
                self::increment($key, 1);
            }

            return true;
        } catch (\Exception $e) {
            // 缓存失败时允许请求（fail-open策略）
            return true;
        }
    }

    /**
     * 清空所有缓存
     *
     * @return bool
     */
    public static function flush()
    {
        try {
            return Cache::clear();
        } catch (\Exception $e) {
            return false;
        }
    }
}
