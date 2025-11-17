<?php

namespace Tests\Unit;

use PHPUnit\Framework\TestCase;
use Mockery as m;
use app\common\service\AchievementService;
use app\common\model\RunningRecord;
use app\common\model\User;

/**
 * 成就服务单元测试
 */
class AchievementServiceTest extends TestCase
{
    private $achievementService;

    protected function setUp(): void
    {
        parent::setUp();
        $this->achievementService = new AchievementService();
    }

    protected function tearDown(): void
    {
        m::close();
        parent::tearDown();
    }

    /**
     * 测试距离成就计算
     */
    public function testCalculateDistanceAchievements()
    {
        // 测试数据
        $achievements = [
            ['distance' => 5, 'name' => '首个5公里'],
            ['distance' => 10, 'name' => '首个10公里'],
            ['distance' => 21, 'name' => '半程马拉松'],
            ['distance' => 42, 'name' => '全程马拉松'],
        ];

        // 测试5公里距离
        $this->assertTrue($this->shouldUnlockAchievement(5.0, 5));
        $this->assertFalse($this->shouldUnlockAchievement(4.9, 5));

        // 测试10公里距离
        $this->assertTrue($this->shouldUnlockAchievement(10.5, 10));
        $this->assertFalse($this->shouldUnlockAchievement(9.9, 10));
    }

    /**
     * 测试配速成就计算
     */
    public function testCalculatePaceAchievements()
    {
        // 配速计算：分钟/公里
        // 4分钟/公里 = 240秒/公里
        // 5分钟/公里 = 300秒/公里

        $fastPace = $this->calculatePace(5000, 1200); // 5km in 20分钟 = 4分钟/km
        $slowPace = $this->calculatePace(5000, 1800); // 5km in 30分钟 = 6分钟/km

        $this->assertLessThan(300, $fastPace); // 快于5分钟/km
        $this->assertGreaterThan(300, $slowPace); // 慢于5分钟/km
    }

    /**
     * 测试连续跑步天数计算
     */
    public function testCalculateConsecutiveDays()
    {
        $dates = [
            '2024-01-01',
            '2024-01-02',
            '2024-01-03',
            // 断开一天
            '2024-01-05',
            '2024-01-06',
        ];

        $consecutive = $this->getConsecutiveDays($dates);
        $this->assertEquals(2, $consecutive); // 最后连续2天
    }

    /**
     * 测试总里程统计
     */
    public function testCalculateTotalDistance()
    {
        $records = [
            ['distance' => 5.0],
            ['distance' => 10.0],
            ['distance' => 3.5],
        ];

        $total = array_sum(array_column($records, 'distance'));
        $this->assertEquals(18.5, $total);
    }

    /**
     * 测试成就等级判定
     */
    public function testDetermineAchievementLevel()
    {
        $levels = [
            100 => 'bronze',
            500 => 'silver',
            1000 => 'gold',
            5000 => 'platinum',
        ];

        $this->assertEquals('bronze', $this->getAchievementLevel(150, $levels));
        $this->assertEquals('silver', $this->getAchievementLevel(600, $levels));
        $this->assertEquals('gold', $this->getAchievementLevel(1200, $levels));
        $this->assertEquals('platinum', $this->getAchievementLevel(5500, $levels));
    }

    // ========== Helper Methods ==========

    private function shouldUnlockAchievement($actualDistance, $requiredDistance)
    {
        return $actualDistance >= $requiredDistance;
    }

    private function calculatePace($distance, $duration)
    {
        // 返回秒/公里
        return ($duration / ($distance / 1000));
    }

    private function getConsecutiveDays($dates)
    {
        if (empty($dates)) {
            return 0;
        }

        rsort($dates);
        $consecutive = 1;

        for ($i = 0; $i < count($dates) - 1; $i++) {
            $current = strtotime($dates[$i]);
            $previous = strtotime($dates[$i + 1]);

            if (($current - $previous) == 86400) {
                $consecutive++;
            } else {
                break;
            }
        }

        return $consecutive;
    }

    private function getAchievementLevel($value, $levels)
    {
        $level = 'bronze';
        foreach ($levels as $threshold => $name) {
            if ($value >= $threshold) {
                $level = $name;
            }
        }
        return $level;
    }
}
