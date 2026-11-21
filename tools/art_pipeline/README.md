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
