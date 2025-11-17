#!/usr/bin/env php
<?php
/**
 * Running App - 数据库连接测试脚本
 *
 * 用法: php test_db.php
 */

// 设置错误报告
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "==========================================\n";
echo "Running App - 数据库测试脚本\n";
echo "==========================================\n\n";

// 加载配置文件
$configFile = __DIR__ . '/config/database.php';
if (!file_exists($configFile)) {
    echo "❌ 错误: 配置文件不存在\n";
    echo "   文件: {$configFile}\n";
    echo "   请先复制 config/database_example.php 为 config/database.php\n";
    exit(1);
}

$config = include $configFile;
$dbConfig = $config['connections']['mysql'];

echo "【阶段 1】读取数据库配置\n";
echo "==========================================\n";
echo "主机: {$dbConfig['hostname']}\n";
echo "端口: {$dbConfig['hostport']}\n";
echo "数据库: {$dbConfig['database']}\n";
echo "用户: {$dbConfig['username']}\n";
echo "字符集: {$dbConfig['charset']}\n";
echo "✅ 配置文件加载成功\n\n";

// 测试MySQL连接
echo "【阶段 2】测试MySQL连接\n";
echo "==========================================\n";

try {
    $dsn = sprintf(
        "mysql:host=%s;port=%s;dbname=%s;charset=%s",
        $dbConfig['hostname'],
        $dbConfig['hostport'],
        $dbConfig['database'],
        $dbConfig['charset']
    );

    $pdo = new PDO($dsn, $dbConfig['username'], $dbConfig['password']);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    echo "✅ 数据库连接成功\n\n";

    // 获取MySQL版本
    $version = $pdo->query('SELECT VERSION()')->fetchColumn();
    echo "MySQL版本: {$version}\n\n";

    // 检查必要的表
    echo "【阶段 3】检查数据库表\n";
    echo "==========================================\n";

    $requiredTables = [
        'user' => '用户表',
        'running_record' => '跑步记录表',
        'track_point' => '轨迹点表',
        'post' => '动态表',
        'challenge' => '挑战赛表',
        'achievement' => '成就表',
        'training_plan' => '训练计划表',
        'running_club' => '跑团表',
        'ranking' => '排行榜表',
        'message' => '消息表'
    ];

    $missingTables = [];
    $existingTables = [];

    foreach ($requiredTables as $table => $description) {
        $stmt = $pdo->prepare("SHOW TABLES LIKE ?");
        $stmt->execute([$table]);
        $exists = $stmt->fetch();

        if ($exists) {
            echo "✅ {$table} ({$description})\n";
            $existingTables[] = $table;
        } else {
            echo "❌ {$table} ({$description}) - 不存在\n";
            $missingTables[] = $table;
        }
    }

    echo "\n";

    if (count($missingTables) > 0) {
        echo "⚠️  警告: 发现 " . count($missingTables) . " 个缺失的表\n";
        echo "请执行以下命令导入数据库:\n";
        echo "  mysql -u {$dbConfig['username']} -p {$dbConfig['database']} < database/running_app.sql\n\n";
    } else {
        echo "✅ 所有核心表都存在\n\n";
    }

    // 检查表结构（外键、索引等）
    if (count($existingTables) > 0) {
        echo "【阶段 4】检查数据库优化\n";
        echo "==========================================\n";

        // 检查外键约束
        $stmt = $pdo->query("
            SELECT COUNT(*) as fk_count
            FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
            WHERE TABLE_SCHEMA = '{$dbConfig['database']}'
            AND REFERENCED_TABLE_NAME IS NOT NULL
        ");
        $fkCount = $stmt->fetchColumn();

        if ($fkCount > 0) {
            echo "✅ 外键约束: {$fkCount} 个\n";
        } else {
            echo "⚠️  外键约束: 未配置（建议应用优化脚本）\n";
        }

        // 检查索引数量
        $stmt = $pdo->query("
            SELECT COUNT(DISTINCT INDEX_NAME) as index_count
            FROM INFORMATION_SCHEMA.STATISTICS
            WHERE TABLE_SCHEMA = '{$dbConfig['database']}'
            AND INDEX_NAME != 'PRIMARY'
        ");
        $indexCount = $stmt->fetchColumn();
        echo "✅ 索引数量: {$indexCount} 个\n\n";

        if ($fkCount == 0) {
            echo "💡 建议:\n";
            echo "  应用数据库优化脚本可提升性能和数据完整性:\n";
            echo "  mysql -u {$dbConfig['username']} -p {$dbConfig['database']} < database/optimization_v1.5.9.sql\n\n";
        }
    }

    // 检查示例数据
    echo "【阶段 5】检查初始数据\n";
    echo "==========================================\n";

    if (in_array('achievement', $existingTables)) {
        $stmt = $pdo->query("SELECT COUNT(*) FROM achievement");
        $achievementCount = $stmt->fetchColumn();
        echo "成就数量: {$achievementCount}\n";
    }

    if (in_array('training_plan', $existingTables)) {
        $stmt = $pdo->query("SELECT COUNT(*) FROM training_plan WHERE is_preset = 1");
        $planCount = $stmt->fetchColumn();
        echo "预设训练计划: {$planCount}\n";
    }

    if (in_array('config', $existingTables)) {
        $stmt = $pdo->query("SELECT COUNT(*) FROM config");
        $configCount = $stmt->fetchColumn();
        echo "系统配置项: {$configCount}\n";

        // 检查JWT密钥
        $stmt = $pdo->query("SELECT value FROM config WHERE `key` = 'jwt_key'");
        $jwtKey = $stmt->fetchColumn();
        if ($jwtKey === 'your-secret-key-change-this' || empty($jwtKey)) {
            echo "\n⚠️  安全警告: JWT密钥使用默认值或为空！\n";
            echo "   请在 .env 文件中配置 jwt.secret\n";
        }
    }

    echo "\n";

    // 测试写入权限
    echo "【阶段 6】测试数据库写入\n";
    echo "==========================================\n";

    if (in_array('user', $existingTables)) {
        try {
            $pdo->beginTransaction();

            // 尝试插入测试数据
            $testPhone = 'test_' . time();
            $stmt = $pdo->prepare("
                INSERT INTO user (phone, password, nickname, create_time)
                VALUES (?, ?, ?, NOW())
            ");
            $stmt->execute([$testPhone, password_hash('test', PASSWORD_DEFAULT), '测试用户']);

            // 读取刚插入的数据
            $lastId = $pdo->lastInsertId();
            $stmt = $pdo->prepare("SELECT * FROM user WHERE id = ?");
            $stmt->execute([$lastId]);
            $user = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($user) {
                echo "✅ 写入测试成功 (ID: {$lastId})\n";
            }

            // 回滚测试数据
            $pdo->rollBack();
            echo "✅ 事务回滚成功\n\n";

        } catch (Exception $e) {
            $pdo->rollBack();
            echo "❌ 写入测试失败: {$e->getMessage()}\n\n";
        }
    }

    // 汇总
    echo "==========================================\n";
    echo "测试结果汇总\n";
    echo "==========================================\n";
    echo "✅ 数据库连接: 正常\n";
    echo "✅ 表结构: " . count($existingTables) . "/" . count($requiredTables) . " 存在\n";

    if (count($missingTables) > 0) {
        echo "⚠️  缺失表: " . implode(', ', $missingTables) . "\n";
        echo "\n请先导入数据库文件\n";
        exit(1);
    } else {
        echo "\n🎉 数据库配置正常，可以启动应用！\n";
        exit(0);
    }

} catch (PDOException $e) {
    echo "❌ 数据库连接失败\n";
    echo "错误信息: {$e->getMessage()}\n\n";

    echo "常见问题排查:\n";
    echo "1. MySQL服务是否启动？\n";
    echo "   检查: systemctl status mysql (Linux)\n";
    echo "   检查: brew services list (macOS)\n\n";

    echo "2. 数据库配置是否正确？\n";
    echo "   文件: {$configFile}\n";
    echo "   主机: {$dbConfig['hostname']}\n";
    echo "   用户: {$dbConfig['username']}\n";
    echo "   数据库: {$dbConfig['database']}\n\n";

    echo "3. 数据库用户权限是否足够？\n";
    echo "   尝试: mysql -u {$dbConfig['username']} -p\n\n";

    echo "4. 数据库是否已创建？\n";
    echo "   创建: CREATE DATABASE {$dbConfig['database']} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;\n\n";

    exit(1);
}
