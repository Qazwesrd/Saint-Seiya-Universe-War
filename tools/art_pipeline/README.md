# 美术资产制作流水线

此目录建立 32 个职业、49 套装备和 11 类技能元素的资源交付清单。

## 生成与检查

在仓库根目录运行：

```bash
python3 tools/art_pipeline/build_manifests.py
python3 tools/art_pipeline/build_manifests.py --check
```

脚本直接读取 Godot 的 `CharacterVisualCatalog.PROFILES` 和 `EquipmentDatabase.EQUIPMENT`，为每个 ID 生成 `manifest.json`。清单明确标记 `pending` / `not_created`，不会伪装成已完成模型。

## 人物模型

- GLB / glTF 2.0，米制单位，角色高度建议约 1.8m。
- 统一骨架和装备挂点，支持头盔、胸甲、肩甲、护臂、腰甲、腿甲。
- 必备 idle、walk、run、jump、fall、land、三段普攻、skill_cast、受击、闪避、防御、胜利和失败动画。
- 32 职业要有轮廓和结构差异，不接受只改颜色的最终交付。
- 提供 LOD0/1/2，Android 贴图需压缩并在目标设备验证。

## 圣衣

每套装备拆分头盔、胸甲、左右肩甲、左右护臂、腰甲、左右腿甲，绑定统一角色骨架，包含材质、图标和 LOD。作品设定未核实的装备继续标注待核实，不擅自生成官方造型。

## 技能特效

每种元素交付可复用特效场景、命中特效及低/中/高画质配置。特效只负责表现，伤害、碰撞和控制由游戏逻辑负责。优先共享材质，控制透明层、粒子数量和生命周期。

**重要：** 目前生成的只是制作清单，不是正式3D模型。只有真实资源导入、检查并通过设备测试后，才能更新交付状态。
