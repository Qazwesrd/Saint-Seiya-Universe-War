# 游戏底层框架与模块边界

## 目标

先把长期可扩展的底层骨架搭好，再集中制作完整内容。当前以 Android 横屏、Godot 4.4、ARM64、完全离线为边界；所有在线依赖都不属于本项目运行必需项。

## 模块分层

| 层级 | 模块 | 主要职责 |
|---|---|---|
| 应用入口 | `project.godot`、`scenes/main_menu.tscn`、`scenes/main.tscn` | 主菜单启动、游戏场景进入、渲染器、窗口方向、AutoLoad |
| 核心服务 | EventBus、SettingsManager、SaveManager、SceneFlowManager | 事件解耦、设置、通用文档存档、场景切换 |
| 内容服务 | ResourcePackManager、LocalizationManager、DialogueManager | 离线章节资源包、语言词条、剧情对话状态 |
| 表现服务 | AudioManager、HUD、Minimap | 音频路由、触控界面、地图标记 |
| 角色与战斗 | RPGState、SkillSystem、ArmorSystem、Enemy、Player | 职业、属性、技能、装备与实时战斗 |
| 玩法系统 | QuestManager、CampaignManager、CollectionSystem、SanctuarySystem | 任务、篇章、收藏、个人圣域 |
| 运营工具 | GMManager | 本地开发测试辅助，不作为玩家付费或联网系统 |

## 应用启动与界面导航

- `scenes/main_menu.tscn` 是应用入口；主菜单只负责开始/继续游戏、设置和退出，不直接持有战斗状态。
- `scenes/main.tscn` 保留为实际游戏场景，由 `SceneFlowManager` 统一进入。
- 主菜单基础设置写入 `SettingsManager`，设置服务负责本地持久化；帧率上限立即应用。
- 角色档案仍由 `RPGState` 管理。主菜单通过 `get_slot_summary` 读取摘要，不复制或维护第二份角色数据。
- `RPGState` 提供 `has_slot`、`get_slot_summary`、`create_new_slot`、`delete_slot` 和 `has_backup_slot`；三个槽位分别独立保存，删除前备份，恢复时校验版本。
- 主菜单提供三个本地槽位的新建、读取、备份、恢复和删除入口；删除前自动备份，且新建只允许空槽位，避免误覆盖。
- 设置页当前提供画质档位、帧率上限和主音量；镜头、触控、语言等其余设置项仍由 SettingsManager 保存，界面入口待补齐。
- 首次建档向导、触控适配验收和完整设置页仍待后续完善。

## 全局服务调用约定

- 系统间广播状态变化优先使用 EventBus 信号。
- 单一数据归属：角色职业/背包/三槽角色存档由 RPGState 管理；任务进度由 QuestManager/CampaignManager 管理；设置由 SettingsManager 管理。
- SaveManager 只负责通用 JSON 文档和备份，不覆盖 RPGState 的角色存档格式。
- ResourcePackManager 只负责本地资源包目录、清单校验、容量统计和卸载；当前不提供网络下载，也不代表章节资源已制作。
- DialogueManager 管理通用逐句对话状态；具体 NPC 对话内容仍由剧情数据提供。
- SceneFlowManager 是统一场景切换入口；当前原型仍以主场景内切换区域为主。
- 音频播放器和总线接口已建立；没有实际音轨/音效资源时保持静默。

## 章节资源包格式

每个安装包放在 `user://content_packs/<pack_id>/`，根目录包含 `pack.json`。示例：

```json
{
  "id": "galaxy_wars",
  "version": 1,
  "size_bytes": 123456,
  "files": [
    {"path": "maps/arena.pck", "sha256": "可选的64位SHA-256"}
  ]
}
```

文件路径必须是资源包目录内的相对路径，不允许绝对路径或 `..`。校验通过后才允许后续加载器接管资源。资源包删除前必须确认不是运行中的必需资源。当前只建立目录、清单和校验/卸载基础接口；PCK 挂载、下载/安装 UI、差分更新和空间预检尚未实现。

## 目录和命名约定

- `game/scripts/`：GDScript 系统逻辑，文件名 snake_case。
- `game/scenes/`：可复用场景，按 world、characters、ui、effects 分类。
- `game/assets/`：只放自制或明确获授权资源，按 characters、armors、environments、animations、audio、vfx、ui 分类。
- `game/content/`：离线内容清单和数据定义，不放大体积原始素材。
- `docs/`：模块职责、资源制作规范、验收记录。
- `tools/`：无第三方依赖的仓库检查脚本。

## 质量边界

- 所有 AutoLoad 必须有且只有一个注册名，路径真实存在。
- 所有静态 `res://` 引用必须指向仓库内文件。
- 存档升级必须保留旧字段并提供默认值，不允许静默清空。
- 资源包需要版本号、大小和可选 SHA-256；缺失文件/校验失败必须明确报错。
- 不在仓库提交 APK、发布签名、私钥、用户存档或引擎缓存。
- 自动检查通过仅代表其覆盖的结构/解析/启动检查通过，不代表完整游戏内容或真机性能已验收。

## 当前底层框架状态

已建立主菜单入口、全局事件、设置、语言、音频、通用存档、离线资源包目录、对话状态和场景切换服务，并注册到 AutoLoad。已有 RPG/战斗/任务/圣衣/收藏/圣域系统保持原有数据归属。GitHub Actions 已覆盖静态检查、Godot 4.4.1 导入解析、主场景启动和框架冒烟测试；具体通过状态以最新工作流结果为准。Android APK 导出、安装、触控与真机性能验收仍未完成。
