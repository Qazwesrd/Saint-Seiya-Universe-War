# 离线剧情战役系统（本阶段）

## 本阶段交付

- `game/scripts/campaign_database.gd`：六大篇章的任务数据目录，包含任务 ID、等级建议、类型、目标和奖励。
- `game/scripts/campaign_manager.gd`：剧情任务解锁、接取、目标计数、完成、奖励发放和本地存档。
- `game/project.godot`：注册 `CampaignManager` 自动加载单例。
- `game/scripts/game.gd`：将银河战争篇前三个任务接入现有引导员交谈、普通敌人击败和 Boss 击败事件。

## 六大篇章

1. 银河战争篇
2. 圣域十二宫篇
3. 海皇篇
4. 冥王篇
5. 天界篇
6. 原创终极篇

当前每篇章先建立可扩展的任务骨架。后续会继续增加职业专属、NPC、隐藏、支线和 Boss 剧情任务；不会把目录数据误称为完整剧情成品。

## 运行时接口

- `CampaignManager.get_chapter_overview()`：读取篇章解锁和完成进度。
- `CampaignManager.get_active_mission()`：读取当前任务。
- `CampaignManager.get_mission_progress(mission_id)`：读取目标进度。
- `CampaignManager.accept_mission(mission_id)`：接取已解锁任务。
- `CampaignManager.add_objective_progress(objective_id, amount)`：推进当前任务目标。
- `CampaignManager.can_complete_active_mission()`：检查目标是否完成。
- `CampaignManager.complete_active_mission()`：完成任务、发放经验/星币并解锁后续篇章。

剧情进度保存在 Android 应用私有目录的 `user://campaign_progress.json`，不依赖网络。RPG 角色数据仍由既有 `RPGState` 存档管理。

## 当前验收边界

本次已提交源码并完成事件接线，但尚未在 Godot 4.4 编辑器中解析运行，也未在魅族 21 Pro 上进行 APK 和真机测试。正式剧情对白、角色演出、授权/原创美术、配音、章节地图仍是后续内容制作工作。
