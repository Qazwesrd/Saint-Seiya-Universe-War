# Blender 原型生成器

需要安装 Blender 4.x（包含 glTF 2.0 导出插件）。在仓库根目录执行：

```bash
blender --background --python tools/art_pipeline/blender/generate_base_rig.py
```

脚本生成两个可导入 Godot 的 GLB：
- `game/assets/_source_templates/humanoid_base/humanoid_base.glb`：带骨架、蒙皮和16类动作轨道的基础人形原型。
- `game/assets/_source_templates/modular_armor_kit/modular_armor_kit.glb`：绑定同一骨架的可拆分圣衣部件原型。

该生成器用程序化几何搭建绑定验证原型，主要用于验证骨骼命名、蒙皮、动作轨道、GLB导出和Godot导入链路。它不是32个职业的最终角色美术，也不是最终圣衣造型；正式美术仍需逐职业设计轮廓、精细拓扑、UV/PBR贴图、面部、发型、饰件、LOD和动作修型。输出文件默认不自动覆盖各职业正式资源清单。
