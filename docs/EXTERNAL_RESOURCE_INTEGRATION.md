# 外部资源整合记录

## 本次整合：模块化锁定目标选择

- 参考项目：[Souls-Like-Controller](https://github.com/Prashanna135/Souls-Like-Controller)
- 用途：参考其将锁定目标、战斗与角色根节点分离的模块化思路。
- 本仓库实现：新增 `game/scripts/combat_targeting.gd`，并接入现有 `player.gd`。
- 实现内容：筛除无效/死亡/超距离目标；首次锁定优先选择最近敌人；再次点击锁定键可循环切换目标。
- 代码来源说明：本次新增脚本为针对本项目接口独立编写的适配实现，不复制外部仓库代码。
- 外部参考项目标注 Godot 4.x、以 Godot 4.7 测试；其角色模型/动画依赖外部资产，不能直接当作完整可运行游戏移植。
- 外部参考：[Godot Third Person Controller](https://github.com/Jeh3no/Godot-Third-Person-Controller)，Godot Asset Library 标注 MIT，兼容 Godot 4.4–4.7；后续可单独评估其移动状态机和相机，不直接替换当前移动控制器。

## 暂不直接导入的内容

- 未导入 Souls-Like-Controller 的整套 Player/Enemy 场景：其依赖特定人形骨架、AnimationTree 动画库、武器碰撞体节点路径和外部动画资产。
- 未导入完整第三人称控制器：当前玩家控制器已承载任务导航、坐骑速度、圣域跟随等项目逻辑，直接替换会造成系统回归风险。
- 未导入未确认许可或来源不清的圣斗士角色、圣衣、音乐和特效资源。

## 验证状态

- 已完成源码接入和静态接口检查。
- 尚未使用 Godot 4.4 解析器运行，也未完成 Android APK 构建或真机测试。
