# 项目搭建与验收总清单

本文用于统一项目目录、工具链、资源管理、自动检查和 Android 交付步骤。它不把“代码已提交”误写成“游戏已完成”。

## 1. 固定技术范围

- 唯一目标平台：Android 手机，横屏，ARM64。
- 引擎：Godot 4.4.x 标准版（非 .NET）。
- 渲染：Compatibility / Mobile 兼容路径；最终以目标手机实测为准。
- 游戏模式：完全离线单机，本地存档；不依赖账号、服务器或联网授权。
- 主场景：`game/scenes/main.tscn`。
- 工程入口：`game/project.godot`。
- Android 预设：`game/export_presets.cfg`。

## 2. 仓库目录约定

```
.github/workflows/   自动检查工作流
docs/                设计、技术决策、验收和操作说明
game/scenes/         Godot 场景
game/scripts/        GDScript 逻辑
game/assets/         后续自制或获授权的模型、贴图、音频、动画
game/build/          本地构建产物（不提交）
tools/               本地静态检查工具
```

新增资源必须放入工程目录并通过 `res://` 引用。不要提交 .godot、导入缓存、APK、签名文件或密钥。大体积资源应先确认授权，再决定是否用 Git LFS 或分章节资源包。

## 3. Windows 11 本机搭建

1. 安装 Godot 4.4.x 标准版。
2. 下载并安装 Godot 对应版本的 Export Templates。
3. 安装 OpenJDK 17 和 Android SDK（Platform Tools、Platform、Build Tools）。
4. 在 Godot：Editor > Editor Settings > Export > Android 中设置 Java SDK 与 Android SDK 路径。
5. 克隆仓库后，在 Godot Project Manager 中导入 `game/project.godot`。
6. 等待首次资源导入结束，按 F6/F5 运行主场景。
7. 先执行静态检查，再执行引擎检查，最后才导出 APK。

PowerShell（在仓库根目录执行）：

```powershell
py -3 tools/validate_project.py
```

预期最后显示“结果：全部通过”。如果提示找不到 py，可安装 Python 3 并勾选 PATH；该静态检查仅使用 Python 标准库。

Godot 命令行检查（按实际安装位置调整）：

```powershell
godot --headless --editor --path game --quit
if ($LASTEXITCODE -ne 0) { throw "Godot 项目解析失败" }
godot --headless --path game --quit-after 3
if ($LASTEXITCODE -ne 0) { throw "主场景启动检查失败" }
```

## 4. Android ARM64 Debug APK

先在 Godot Editor 的 Project > Export 中确认 Android 预设、SDK/JDK 和导出模板均有效。Debug 验收阶段不要使用个人发布签名密钥。

```powershell
New-Item -ItemType Directory -Force game/build/android | Out-Null
godot --headless --path game --export-debug "Android" game/build/android/saint-seiya-universe-war-debug.apk
if ($LASTEXITCODE -ne 0) { throw "Android APK 导出失败" }
Test-Path game/build/android/saint-seiya-universe-war-debug.apk
```

只有最后一行返回 `True` 才表示本机生成了 APK；还需安装到手机测试。发布版签名密钥只能由项目所有者安全保管，禁止提交仓库或发到聊天中。

## 5. 每次提交的自动检查

GitHub Actions 在游戏源码或工作流变化时执行：
- Python 静态完整性检查：主场景、AutoLoad、Android 预设和字面量 `res://` 引用。
- Godot 4.4.1 headless 编辑器导入/解析。
- 主场景 headless 启动。

自动检查通过只代表工程结构与无界面启动检查通过，不代表触控体验、完整战斗平衡、资源完整性或真机性能已验收。

## 6. 手机验收清单（魅族 21 Pro）

- [ ] APK 能安装、启动、横屏显示和正常退出。
- [ ] 首次启动、无网络启动和断网持续游玩均正常。
- [ ] 左摇杆、普攻、技能、闪避、锁定、任务和对话可触控。
- [ ] 普通敌人、Boss、击退、霸体、状态效果正常。
- [ ] 职业切换、技能冷却/能量、小宇宙、装备属性正确。
- [ ] 退出重进后角色、任务、装备和收藏存档正确。
- [ ] 连续运行 30 分钟，记录 FPS、温度、耗电、内存和崩溃。
- [ ] 低/中/高画质与帧率设置经过实机对比。
- [ ] 资源下载/安装/校验/删除/容量统计（功能完成后）通过测试。

## 7. 尚未能标记为“项目全部完成”的内容

当前仓库仍是持续开发中的原型。正式人物与敌人模型、骨骼动画、技能特效音效、完整篇章地图/剧情、装备图鉴 UI 和完整装备成长界面、分章节资源管理、性能优化、Godot 实机运行、APK 导出与手机验收均需要继续完成。原作版权内容公开发行前必须取得授权；无授权时使用原创替代资源。

## 8. 交付定义

- **工程搭建完成**：目录、入口、依赖约定、自动检查、导出预设和文档齐全。
- **可运行原型**：Godot 解析及主场景运行通过。
- **Android 测试包**：成功导出并安装 Debug APK。
- **可验收版本**：目标手机核心玩法、离线存档和性能测试通过。
- **正式完成**：所有约定功能、内容资源、质量、安全、授权和发布检查全部通过。

以上状态必须分别记录，不可互相替代。
