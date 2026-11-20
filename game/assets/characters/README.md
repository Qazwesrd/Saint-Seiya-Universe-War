# 角色模型资源

此目录存放自制或已获授权的角色模型、骨骼、材质、贴图、立绘与动画。32 个可玩职业的程序化视觉配置位于 `scripts/character_visual_catalog.gd`；程序化几何仅是可运行的 fallback，不代表最终高品质角色资产。

## 每个职业的正式资源结构

每个 `class_id` 使用独立目录，资源采用以下固定路径，便于自动验收：

```text
characters/<class_id>/
  model/
    character.glb              # 首选；也接受 character.gltf 或 character.tscn
  materials/
    *.tres
  animations/
    animation_library.tres     # 也接受 .res 或 animation_library.glb
  portraits/
    portrait.png               # 也接受 .webp 或 .jpg
  lod/
    lod0/
    lod1/
    lod2/
  manifest.json
```

## 交付要求

- 模型需具备可复用骨骼、正确比例、材质槽和装备挂点。
- 基础动作至少包括 idle、walk、run、jump、fall、land、basic_attack_1/2/3、skill_cast、hit_light、hit_heavy、dodge、block、victory、defeat。
- 飞行职业额外提供 flight_idle、flight_move、flight_rise、flight_dive、air_attack。
- 立绘需与游戏内职业外观一致；不得使用临时占位图冒充最终资源。
- Android 资源需提供 LOD 与贴图压缩版本，并在目标设备上检查内存和帧率。
- 资源必须是原创或具有明确授权来源；概念图不能直接视为已绑定骨骼的游戏模型。

## 自动验收

`scripts/art_asset_audit.gd` 会扫描 32 个职业的模型、立绘和动画库，并分别报告覆盖率及缺失职业。只有对应文件真实存在时才计入完成数量；程序化 fallback 不计入正式美术资产。
