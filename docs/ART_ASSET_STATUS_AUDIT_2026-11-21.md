# 美术资源与流水线状态审计（2026-11-21）

## 审计范围

- 仓库：`Qazwesrd/Saint-Seiya-Universe-War`
- 分支：`main`
- 本次审计时间：2026-11-21 14:06 UTC
- 当前审计基线：`182789f3a5ba8288179ef972102143e9f308ba92`

## 当前仓库实际资源情况

对 main 分支执行递归 Git Tree 清单检查，结果为：

- Tree 条目：164
- 普通文件：129
- GDScript：59
- Godot 场景：16
- Markdown 文档：36
- 当前已提交的 GLB/GLTF/BLEND/FBX/OBJ/DAE 网格模型：0
- 当前已提交的模型预览 PNG/WebP：0

因此，职业目录数量、装备目录数量、数据库条目数量和场景文件数量，不能被当作已完成的实际模型数量。当前人物、圣衣和 BOSS 的正式网格模型仍须由 Blender 流水线产出并通过检查。

## 最近一次美术流水线

- 工作流：Blender Art Prototype Export
- Run ID：`44908987010`
- 源码提交：`d3337141aa74121beb837edeb6a9e6b7b1c42040`
- 本次查询状态：`in_progress`
- 已完成：Runner 初始化、仓库检出、Blender 安装
- 正在执行：生成并结构验证 GLB 原型
- 尚未完成：32 个职业模型及动画库检查、模型包上传

该工作流定义的资源验收数量为：

- 7 个篇章环境模型
- 32 个职业人物模型
- 32 个职业动画库
- 82 套装备/圣衣模型
- 57 个敌人与 BOSS 模型
- 768 个职业专属技能动画片段（每职业 24 个）

以上是流水线的验收目标，不是当前已经完成的数量。

## Android 导出失败的已确认原因

- Android APK Export Run ID：`44909188116`
- 源码提交：`182789f3a5ba8288179ef972102143e9f308ba92`
- 失败步骤：Resolve latest successful Blender asset bundle
- 日志明确报错：`No successful Blender asset bundle exists for this exact source commit; refusing to reuse stale assets.`

因此，本次 APK 工作流没有进入模型下载、Godot 导入、Android 导出或 APK 内容验证步骤。不能把这次失败描述为 Android 打包器或游戏代码本身已经失败；当前直接阻塞是：该源码提交没有同一提交号对应的成功 Blender 资源包。

## Godot 检查状态

- Godot Android Prototype Checks Run ID：`44909188112`
- 源码提交：`182789f3a5ba8288179ef972102143e9f308ba92`
- 结果：`success`

这只证明该提交通过了对应的 Godot 原型检查，不代表 32/82/57 模型已经生成，也不代表 APK 已成功导出。

## 下一步执行顺序

1. 等待并检查 Run `44908987010` 的 Blender 生成、模型结构检查和 artifact 上传结果。
2. 若成功，检查 artifact 中人物、圣衣、BOSS、环境模型及预览图的实际数量和文件大小。
3. 把样板资源导入 Godot 美术展厅，检查比例、材质、骨骼、动画和移动端显示；不以“文件存在”代替外观验收。
4. 修复 Android 工作流的触发/提交匹配策略，确保在 Blender 成功上传对应资源包后再执行 APK 导出，且检出与 artifact 同一源码提交。
5. 样板审阅通过后，再扩展全量资源；技能特效另行进行场景播放、命中帧同步、粒子预算和 Android 性能检查。

## 版权与来源约束

RaGEZONE 资料仅用于研究协议、数据组织、版本差异和实现思路。未取得明确授权的原版代码、模型、贴图、音乐和其他资源不得直接打包进公开发布的 APK。正式模型应为原创资源或具备可核实再分发授权的资源，并在 manifest 中记录来源与授权状态。
