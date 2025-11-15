<?php
/**
 * 装备控制器
 */

namespace app\api\controller;

use app\common\model\Equipment as EquipmentModel;

class Equipment extends Base
{
    /**
     * 添加装备
     * POST /api/equipment
     */
    public function create()
    {
        $data = $this->request->param();

        $data['user_id'] = $this->userId;
        $data['status'] = 1;

        try {
            $equipment = EquipmentModel::create($data);

            return $this->success($equipment->toArray(), '添加成功');

        } catch (\Exception $e) {
            return $this->error('添加失败: ' . $e->getMessage());
        }
    }

    /**
     * 装备列表
     * GET /api/equipment/list
     */
    public function list()
    {
        $status = $this->request->param('status', 1);

        $list = EquipmentModel::where('user_id', $this->userId)
            ->where('status', $status)
            ->order('purchase_date', 'desc')
            ->select()
            ->toArray();

        return $this->success($list);
    }

    /**
     * 更新装备
     * PUT /api/equipment/:id
     */
    public function update()
    {
        $id = $this->request->param('id', 0);
        $data = $this->request->param();

        $equipment = EquipmentModel::where('id', $id)
            ->where('user_id', $this->userId)
            ->find();

        if (!$equipment) {
            return $this->error('装备不存在');
        }

        unset($data['id'], $data['user_id']);

        $equipment->save($data);

        return $this->success($equipment->toArray(), '更新成功');
    }

    /**
     * 删除装备
     * DELETE /api/equipment/:id
     */
    public function delete()
    {
        $id = $this->request->param('id', 0);

        $equipment = EquipmentModel::where('id', $id)
            ->where('user_id', $this->userId)
            ->find();

        if (!$equipment) {
            return $this->error('装备不存在');
        }

        $equipment->delete();

        return $this->success([], '删除成功');
    }
}
