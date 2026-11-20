# Blender 人物与圣衣资产交付规范

目标格式：Blender 4.x 源文件（.blend）和 Godot 4.4.1 可导入的 glTF 2.0 GLB。

## 人物模型
- 使用米制单位，角色高度约 1.8m；骨架根骨骼为 Root。
- GLB 必须包含真实网格、Armature、Skin 和可用权重。
- 动作库必须提供 idle、walk、run、jump、fall、land、basic_attack_1/2/3、skill_cast、hit_light、hit_heavy、dodge、block、victory、defeat。
- 每个职业必须具有可辨识的轮廓、头饰、身体比例或专属结构差异；只换颜色不算独立职业模型。
- 提供 LOD0/1/2，并在 Android 目标设备检查动画变形、穿模和帧率。

## 圣衣模型
- 拆分头盔、胸甲、左右肩甲、左右护臂、腰甲、左右腿甲。
- 部件绑定统一角色骨架，保留独立材质槽、图标和 LOD。
- 未核实的原作装备名称或造型保持待核实，不将原创补充宣称为官方设定。

## 技能特效
- 每类元素交付 Godot 可复用特效场景、命中特效及低/中/高画质配置。
- 特效只负责表现；伤害、碰撞和控制仍由游戏逻辑负责。
- 移动端建议每个效果最多 96 粒子、3 层透明叠加、2.5 秒生命周期，复杂技能需实机性能验证。

## 验收规则
- manifest、README、空文件和占位模型不算正式资产。
- 只有真实模型/动画/肖像或图标/特效文件存在且通过校验后，才能设置 delivery_status=complete 和 authored_asset=true。
- 来源和授权未核实的素材不得进入正式发布包。
