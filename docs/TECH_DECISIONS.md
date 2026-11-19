# 技术决策记录

## 已选主引擎：Godot 4（Android 手机项目）

**当前正式技术方向：使用 Godot 4 开发 Android 横屏 3D 单机动作 RPG。**

选择理由：
- 开发电脑为 Windows 11、16GB RAM，显示适配器目前识别为 AMD Radeon(TM) Graphics。具体芯片型号与 Vulkan 能力尚未确认；在这类开发环境下，Godot 通常比 Unreal Engine 5 更轻量。
- 项目唯一目标平台为 Android 手机，不需要承担 Windows 游戏版本的额外开发工作。
- Godot 支持 Android 导出，具备制作 3D 角色、动画、即时战斗、UI 和本地存档所需的基础能力。
- 首要测试设备魅族 21 Pro（Snapdragon 8 Gen 3、Adreno 750、16GB RAM）具备较强的移动端图形性能。
- Unreal Engine 5 的高端 3D 工具链很强，但编辑器、构建工具和资源工作流对当前开发电脑负担更大，不作为本项目首选。

官方依据：
- Godot 系统要求：https://docs.godotengine.org/en/stable/about/system_requirements.html
- Godot Android 导出说明：https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html

## 渲染方案

- 首选 Godot Mobile 渲染器，面向 Android 移动设备优化。
- Windows 开发电脑需要支持 Godot 所需的 Vulkan 图形能力；若当前 AMD 集成显卡驱动不满足要求，先更新官方显卡驱动并验证。
- 若开发电脑无法稳定运行 Mobile 渲染器，可临时使用 Compatibility 渲染器进行编辑与基础调试；最终 Android 真机仍以 Mobile 渲染器构建和验收为目标。
- 暂不启用大量高成本后处理、实时阴影和超高分辨率材质；优先确保战斗清晰、技能表现醒目、帧率稳定。

## 项目平台与架构

1. 唯一交付平台：Android 手机，横屏。
2. 不开发 Windows 电脑版，也不安排桌面端或其他平台适配。
3. 采用完全离线单机架构：游戏逻辑、任务数据、角色数据、资源管理与存档均在 Android 客户端运行。
4. 不依赖云服务器、账号系统或在线游戏服务。
5. 采用可扩展的数据驱动结构，方便新增职业、技能、任务、地图和章节资源包。

## 首个技术验证目标

在正式铺开大型内容前，先完成一个 Android 真机战斗切片：
- 横屏启动与基础 HUD。
- 第三人称角色移动、镜头跟随和触控摇杆。
- 普通攻击、两个即时技能、闪避和目标锁定。
- 一个基础敌人和一个 Boss。
- 本地保存基础设置与测试进度。
- 在魅族 21 Pro 上验证安装、运行、触控、帧率、温度和耗电。

## 资源与性能原则

- 约 5GB 是首次安装内容的规划目标，不是要求生成一个 5GB 的单体 APK。
- 后续按篇章提供独立离线资源包，容量由用户设备剩余空间决定。
- 通过区域分块加载、LOD、纹理压缩、按需加载和及时释放控制运行时内存。
- 不将游戏总磁盘容量等同于运行时 RAM 占用。
- 目标设备优先测试稳定 60 FPS；根据温度和耗电表现提供 30/45/60 FPS 与低/中/高画质选项。
