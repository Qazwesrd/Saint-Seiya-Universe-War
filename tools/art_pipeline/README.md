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


## 原版客户端资产盘点（只读）

如果已合法取得 Saint Seiya Online / Angelica 客户端，可先对客户端目录做只读盘点，再决定是否进行格式解析。此步骤不会运行客户端文件、解包或修改原始文件，也不会联网。

在仓库根目录执行：

```bash
python3 tools/art_pipeline/inventory_angelica_client.py "/path/to/your/client" --output "/path/to/separate/inventory"
```

Windows PowerShell 示例：

```powershell
py tools/art_pipeline/inventory_angelica_client.py "D:\\Games\\SeiyaClient\\element" --output "D:\\SeiyaInventory"
```

输出：
- `client_inventory.json`：完整清单、文件大小、文件头提示、SHA-256（默认开启）。
- `client_inventory.csv`：便于 Excel 筛选的文件清单。
- 重点统计 `.pck/.pkx/.ski/.smd/.bon/.stck/.ecm/.anm/.data` 等格式。

如果客户端很大，可先加 `--no-hash` 快速盘点；正式留档时建议重新运行默认哈希模式。输出目录必须位于客户端目录之外。请不要把原版客户端、提取出的专有资源或哈希清单上传到公开仓库；先在本地检查并确认资源来源及授权。


## PCK / PKX 资源包目录（只读）

仓库使用 MIT 许可证的 AutoAngel Python 库作为可选解析依赖，不复制其源代码。AutoAngel 支持 Angelica PCK/PKX、ECM、SMD、BON、SKI、STCK 和 GFX 等格式。安装：

```powershell
py -m pip install autoangel
```

对本地合法取得的资源包建立目录：

```powershell
py tools/art_pipeline/inventory_angelica_pck.py "D:\\Games\\SeiyaClient\\element\\models.pck" --pkx "D:\\Games\\SeiyaClient\\element\\models.pkx" --output "D:\\SeiyaInventory\\models"
```

若没有分卷文件，可省略 `--pkx`。如果有多个 PKX 分卷，可重复指定 `--pkx`。工具调用 AutoAngel 的 `read_pck`、`file_list` 和只读 `scan_entries` 读取索引与压缩数据元信息，不调用提取、构建或保存接口；报告写到独立目录。JSON/CSV 会记录资源路径、扩展名、原始大小、压缩大小和归档哈希，可用于筛选 SKI、BON、SMD、STCK、ECM、GFX 和纹理文件。

注意：AutoAngel 的 MIT 许可证允许按其许可证条件使用；本项目仅将其作为用户本机的可选依赖，不把客户端文件或提取资源提交到公开仓库。首次接入具体游戏客户端仍需用真实样本验证版本和配置是否匹配。


## 从 PCK 中导出 SKI 网格数据

安装 AutoAngel 后，可将资源包内一个 SKI 文件转换为中立 JSON 网格数据，供 Blender 导入脚本使用。该步骤会提取选定 SKI 的顶点、法线、UV、三角形索引、材质、纹理引用和蒙皮权重；不会修改 PCK/PKX。

```powershell
py tools/art_pipeline/export_angelica_ski_json.py "D:\\Games\\SeiyaClient\\element\\models.pck" --pkx "D:\\Games\\SeiyaClient\\element\\models.pkx" --entry "models\\characters\\pegasus.ski" --output "D:\\SeiyaInventory\\pegasus_ski.json"
```

`--entry` 必须使用 PCK 清单中的实际路径。若 PCK 没有 PKX 分卷，可省略 `--pkx`。输出包含 SKI 版本、骨骼名称及每个网格的顶点和蒙皮数据；当前输出是网格交换数据，不是完整带骨骼动画的 GLB，也不代表已经完成原版角色重建。


## 在 Blender 中查看 SKI 网格

先按上面的步骤生成 `pegasus_ski.json`，再在安装了 Blender 4.x 的电脑上执行：

```powershell
blender --background --python tools/art_pipeline/blender/import_angelica_ski_json.py -- --input "D:\\SeiyaInventory\\pegasus_ski.json" --output "D:\\SeiyaInventory\\pegasus_preview.blend"
```

该导入器会创建网格对象、UV、材质槽和顶点组（保留骨骼权重索引，供后续绑定使用）。当前是静态网格检查场景：尚未生成 BON 骨架、骨骼动作、材质贴图连接或完整 GLB；没有真实客户端样本前，也不能保证所有 SKI 版本都兼容。


## 导出 BON 骨架与 STCK 动画数据

从资源包中选择一个实际存在的 `.bon` 或 `.stck` 路径，可将骨骼层级、骨骼矩阵、挂点、动画轨道、关键帧和帧率导出为 JSON：

```powershell
py tools/art_pipeline/export_angelica_rig_json.py "D:\\Games\\SeiyaClient\\element\\models.pck" --pkx "D:\\Games\\SeiyaClient\\element\\models.pkx" --entry "models\\characters\\pegasus.bon" --output "D:\\SeiyaInventory\\pegasus_bon.json"
py tools/art_pipeline/export_angelica_rig_json.py "D:\\Games\\SeiyaClient\\element\\models.pck" --pkx "D:\\Games\\SeiyaClient\\element\\models.pkx" --entry "models\\characters\\idle.stck" --output "D:\\SeiyaInventory\\pegasus_idle.json"
```

BON 旧版本中内嵌的动画也会随骨架 JSON 一起保存。当前阶段完成了数据导出接口，尚未完成矩阵坐标系校准、Blender Armature 自动重建和动作重定向；这些必须使用真实客户端样本逐个验证。


## Blender 骨架与网格组合预览（实验性）

当 SKI 与 BON JSON 都准备好后，可以用新导入器将人物网格、蒙皮权重和 BON 骨骼层级组合成一个 Blender 场景：

```powershell
blender --background --python tools/art_pipeline/blender/import_angelica_rigged_character.py -- --ski "D:\\SeiyaInventory\\pegasus_ski.json" --bon "D:\\SeiyaInventory\\pegasus_bon.json" --output "D:\\SeiyaInventory\\pegasus_rigged_preview.blend"
```

导入器会创建 Armature、骨骼父子关系、网格对象、顶点组和 Armature 修改器，并把原始 BON 矩阵保存为骨骼自定义属性，便于后续校准。它目前使用 BON 的相对矩阵推导预览骨骼位置；Direct3D/Angelica 坐标轴、骨骼 bind pose、骨骼朝向和动作重定向尚未通过真实《圣斗士星矢 OL》客户端样本验收。因此该结果是用于检查层级与蒙皮绑定的实验预览，不是已确认正确的最终模型。


补充：SKI v9 及以上可能包含自己的骨骼名称映射表，网格顶点中的骨骼索引应按该表解释；旧版 SKI 没有此表时才使用 BON 的全骨架索引。实验性 rigged importer 已按这两种情况分别处理，仍需真实角色样本验证索引映射及坐标轴。


## 将 STCK 动作关键帧导入 Blender（实验性）

完成 SKI + BON 的 Armature 预览后，可以将单独导出的 STCK JSON 应用到当前打开的 Blender rigged preview：

```powershell
blender --background "D:\\SeiyaInventory\\pegasus_rigged_preview.blend" --python tools/art_pipeline/blender/import_angelica_stck_animation.py -- --bon "D:\\SeiyaInventory\\pegasus_bon.json" --stck "D:\\SeiyaInventory\\pegasus_idle.json" --output "D:\\SeiyaInventory\\pegasus_idle_preview.blend" --action-name "idle"
```

导入器会按 BON 骨骼索引定位 Armature pose bone，把 STCK 的位置轨道写入 Location，把 XYZW 四元数重排为 Blender 的 WXYZ 并写入 Quaternion Rotation。轨道有 `key_frame_ids` 时使用实际帧编号；旧版 V1 缺少帧编号时按数组顺序生成样本。时间换算会分别使用动画帧率、轨道帧率和 Blender 场景帧率。

纯 Python 时间/数据转换函数位于 `angelica_animation.py`，可在没有 Blender 或游戏客户端的情况下运行单元测试：

```powershell
py -m unittest discover -s tools/art_pipeline -p "test_angelica_animation.py" -v
```

**重要限制：** 该阶段只把离散关键帧样本写入 Blender 动作，不实现 Angelica 插值模式、根运动/骨骼坐标基校准、事件轨道、动作融合或 SMD 动作片段切分。动画起始帧与轨道帧编号的时间解释仍需用真实客户端样本校准；没有原版客户端时，自动化测试只能证明数据转换逻辑，不证明原版动作播放正确。运行时需先打开与 BON 对应的 rigged preview 文件。


## 导出 ECM 组合模型与装备挂接关系（实验性）

ECM（Composite Model）描述一个组合模型的主体 SMD、子模型装备槽位、父模型挂点名、子模型对应挂点、骨骼缩放，以及组合动作中的 GFX/声音事件。AutoAngel 的 ECM 解析接口提供 get_child()、get_bone_scale()、get_event() 等读取入口；本项目只把解析结果转换为中立 JSON，不复制第三方解析库源码。

```powershell
py tools/art_pipeline/export_angelica_ecm_json.py "D:\\Games\\SeiyaClient\\element\\models.pck" --pkx "D:\\Games\\SeiyaClient\\element\\models.pkx" --entry "models\\characters\\pegasus.ecm" --output "D:\\SeiyaInventory\\pegasus_ecm.json"
```

可省略不存在的 PKX 参数；有多个分卷时重复添加 --pkx。输出包括主体 SMD 路径、子模型路径和槽位、父/子挂点名、骨骼缩放格式、组合动作事件及持续 GFX 引用。源 PCK/PKX 只读，JSON 必须写到归档目录之外。

ECM 结构验证与依赖图检查：

```powershell
py -m unittest discover -s tools/art_pipeline -p "test_angelica_ecm.py" -v
```

验证器检查资源路径安全性、重复装备槽位、挂点名称、骨骼缩放数值、组合动作事件，并可在提供 BON 挂点名集合时检查父挂点是否存在。validate_ecm_graph() 可对多个 ECM JSON 检查子模型引用是否闭合及是否存在循环引用。单个 ECM 文件无法证明其引用的子模型一定存在；只有把同一资源包中相关 ECM 都导出后，图检查才可完成跨文件解析。

**限制：** 目前是 ECM 元数据导出和结构校验，不是 Blender 装备挂接成品。挂点矩阵的坐标轴、父子模型局部变换、装备比例、child hook 语义和真实人物组合外观仍需原版客户端样本校准。当前没有原版客户端，因此不能宣称已验证天马圣衣或其他原版装备的正确挂接。
