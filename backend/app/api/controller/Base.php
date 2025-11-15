<?php
/**
 * API基础控制器
 */

namespace app\api\controller;

use think\App;
use think\Response;

abstract class Base
{
    /**
     * Request实例
     * @var \think\Request
     */
    protected $request;

    /**
     * 应用实例
     * @var \think\App
     */
    protected $app;

    /**
     * 当前登录用户ID
     * @var int
     */
    protected $userId;

    /**
     * 当前登录用户信息
     * @var array
     */
    protected $user;

    /**
     * 构造方法
     * @param App $app
     */
    public function __construct(App $app)
    {
        $this->app = $app;
        $this->request = $this->app->request;

        // 控制器初始化
        $this->initialize();
    }

    /**
     * 初始化
     */
    protected function initialize()
    {
        // 获取当前登录用户信息（由中间件注入）
        $this->userId = $this->request->userId ?? 0;
        $this->user = $this->request->user ?? [];
    }

    /**
     * 成功响应
     * @param mixed $data 数据
     * @param string $message 消息
     * @param int $code 状态码
     * @return Response
     */
    protected function success($data = [], string $message = 'success', int $code = 200): Response
    {
        return json([
            'code' => $code,
            'message' => $message,
            'data' => $data,
            'timestamp' => time(),
        ]);
    }

    /**
     * 失败响应
     * @param string $message 错误消息
     * @param int $code 错误码
     * @param mixed $data 附加数据
     * @return Response
     */
    protected function error(string $message = 'error', int $code = 400, $data = []): Response
    {
        return json([
            'code' => $code,
            'message' => $message,
            'data' => $data,
            'timestamp' => time(),
        ]);
    }

    /**
     * 分页响应
     * @param array $list 列表数据
     * @param int $total 总数
     * @param int $page 当前页
     * @param int $pageSize 每页数量
     * @return Response
     */
    protected function paginate(array $list, int $total, int $page = 1, int $pageSize = 20): Response
    {
        return $this->success([
            'list' => $list,
            'pagination' => [
                'total' => $total,
                'page' => $page,
                'page_size' => $pageSize,
                'total_page' => ceil($total / $pageSize),
            ],
        ]);
    }
}
