# 美术模型展厅使用说明

## 目的

`game/scenes/art_gallery.tscn` 是独立的 3D 美术审阅场景，用来查看 Blender 美术流水线导出的 GLB 资源。它不是最终游戏菜单，也不把占位特效冒充成正式技能成品。

## 在 Godot 中打开

1. 从 GitHub 获取仓库 `Qazwesrd/Saint-Seiya-Universe-War` 的最新 `main`。
2. 使用 Godot 4.4 打开仓库中的 `game/project.godot`。
3. 在文件系统面板打开 `res://scenes/art_gallery.tscn`，点击运行当前场景。
4. 顶部选择“人物 / 圣衣 / BOSS / 技能特效”，使用“上一个 / 下一个”切换项目。
5. 3D 展台自动旋转；鼠标或触屏拖动可转动模型。

## 模型资源来源

展厅预期读取以下路径：

- 人物：`res://assets/characters/<id>/model/character.glb`
- 圣衣：`res://assets/armors/<id>/model/armor.glb`
- BOSS：`res://assets/enemies/<id>/model/enemy.glb`

这些 GLB 由 `Blender Art Prototype Export` 工作流构建，并作为 GitHub Actions artifact 发布。当前流水线产物保留期有限；正式交付前必须进入正式离线资源包并通过完整导入验收。资源缺失时展厅会显示缺失路径，不会静默生成假模型。

## 当前验收边界

- 人物、圣衣、BOSS：展厅加载成功只代表 GLB 可查看，不代表外观达到最终品质。仍需人工审阅轮廓、细节、材质、骨骼、动画、LOD 和设备表现。
- 技能特效：天马闪影流星拳已有独立场景 `game/assets/vfx/pegasus/meteor_fist_finisher.tscn`，并由 `game/scripts/vfx/pegasus_meteor_finisher_animator.gd` 驱动残影突进、冲击环和碎片爆发；其他元素目录有通用效果场景。它们仍属于首轮视觉样板，必须继续制作技能专属动作同步、碰撞命中、音效和 Android 粒子预算。
- 若模型路径不存在，先确认对应 Blender artifact 是否已下载并解压到 `game/assets/`，不要把 catalog 条目数当成模型文件数量。

## 当前样板审阅顺序

1. 天马座人物（当前为专属青铜圣衣细节原型）+ 独立青铜圣衣档案模型。
2. 教皇撒加 BOSS。
3. 天马流星拳、天马彗星拳和天龙座庐山升龙霸的独立技能特效。
4. 样板通过后再扩展全量角色、圣衣、BOSS 和技能。