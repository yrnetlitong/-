<?php


namespace app\admin\service;

/**
 * 服务基类
 * @author admin
 * @since 2020/11/14
 * Class BaseService
 * @package app\admin\service
 */
class BaseService
{
    // 模型
    protected $model;

    /**
     * 获取数据列表
     * @return array
     * @since 2020/11/14
     * @author admin
     */
    public function getList()
    {
        // 初始化变量
        $map = [];
        $sort = 'id desc';
        $is_sql = 0;

        // 获取参数
        $argList = func_get_args();
        if (!empty($argList)) {
            // 查询条件
            $map = (isset($argList[0]) && !empty($argList[0])) ? $argList[0] : [];
            // 排序
            $sort = (isset($argList[1]) && !empty($argList[1])) ? $argList[1] : 'id desc';
            // 是否打印SQL
            $is_sql = isset($argList[2]) ? (bool)$argList[2] : false;
        }

        // 常规查询条件
        $param = request()->param();
        if ($param) {
            // 筛选名称
            $name = getter($param, 'name', '');
            if ($name) {
                $map[] = ['name', 'like', "%{$name}%"];
            }

            // 筛选标题
            $title = getter($param, 'title', '');
            if ($title) {
                $map[] = ['title', 'like', "%{$title}%"];
            }

            // 筛选类型
            $type = getter($param, 'type', '');
            if ($type !== '') {
                $map[] = ['type', '=', $type];
            }

            // 筛选状态
            $status = getter($param, 'status', '');
            if ($status !== '') {
                $map[] = ['status', '=', $status];
            }

            // 手机号码
            $mobile = getter($param, 'mobile', '');
            if ($mobile) {
                $map[] = ['mobile', '=', $mobile];
            }
        }

        // 设置查询条件
        if (is_array($map)) {
            $map[] = ['mark', '=', 1];
        } elseif ($map) {
            $map .= " AND mark=1 ";
        } else {
            $map .= " mark=1 ";
        }
        // 整页一次查询并批量格式化，避免逐条 getInfo 造成 N+1
        $result = $this->model->where($map)->order($sort)->page(PAGE, PERPAGE)->select()->toArray();

        // 打印SQL
        if ($is_sql) {
            echo $this->model->getLastSql();
        }

        $list = $result ? $this->model->formatList($result) : [];

        //获取数据总数
        $count = $this->model->where($map)->count();

        //返回结果（只返回数组，不返回 message() 格式）
        return [
            'list' => $list,
            'total' => $count
        ];
    }

    /**
     * 获取记录详情
     * @return array
     * @since 2020/11/15
     * @author admin
     */
    public function info()
    {
        // 记录ID
        $argList = func_get_args();
        // 查询条件
        $data = isset($argList[0]) ? $argList[0] : [];
        if (!$data) {
            $data = request()->param();
        }
        $id =  getter($data, "id");
        $info = [];
        if ($id) {
            $info = $this->model->getInfo($id);
        }
        // 返回数组数据，不返回 message() 格式
        return $info ?: false;
    }

    /**
     * 添加或编辑
     * @return array
     * @since 2020/11/14
     * @author admin
     */
    public function edit()
    {
        // 获取参数
        $argList = func_get_args();
        // 查询条件
        $data = isset($argList[0]) ? $argList[0] : [];
        // 是否打印SQL
        $is_sql = isset($argList[1]) ? $argList[1] : false;
        if (!$data) {
            $data = request()->param();
        }
        $error = '';
        $rowId = $this->model->edit($data, $error, $is_sql);
        if ($rowId) {
            // 成功返回数据数组
            return ['id' => $rowId];
        }
        // 失败返回错误信息字符串
        return $error ?: '操作失败';
    }

    /**
     * 删除记录
     * @return array
     * @since 2020/11/12
     * @author admin
     */
    public function delete()
    {
        $argList = func_get_args();
        // 查询条件
        $data = isset($argList[0]) ? $argList[0] : [];
        if (!$data) {
            $data = request()->param();
        }
        // 记录ID
        $ids = getter($data, "id");
        if (empty($ids)) {
            return '记录ID不能为空';
        }
        if (is_array($ids)) {
            // 批量删除
            $result = $this->model->deleteDAll($ids);
            if (!$result) {
                return '删除失败';
            }
            return ['deleted' => count($ids)];
        } else {
            // 单个删除
            $info = $this->model->getInfo($ids);
            if ($info) {
                $result = $this->model->drop($ids);
                if ($result !== false) {
                    return ['id' => $ids];
                }
            }
            return $this->model->getError() ?: '删除失败';
        }
    }

    /**
     * 设置状态
     * @return array
     * @since 2020/11/14
     * @author admin
     */
    public function status()
    {
        $data = request()->param();
        // 记录ID
        $id = getter($data, "id", 0);
        if (!$id) {
            return '记录ID不能为空';
        }
        // 状态
        $status = getter($data, "status", 0);
        if (!$status) {
            return '记录状态不能为空';
        }
        $error = '';
        $item = [
            'id' => $id,
            'status' => $status
        ];
        $rowId = $this->model->edit($item, $error);
        if (!$rowId) {
            return $error ?: '设置状态失败';
        }
        return ['id' => $rowId, 'status' => $status];
    }

}
