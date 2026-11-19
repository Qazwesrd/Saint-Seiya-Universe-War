# Godot 工程打开与 Android 构建说明

## 当前开发工程

项目目录：game/

请使用 Godot 4.4.x 稳定版打开 game/project.godot。当前代码使用 GDScript，不需要安装 .NET 版本。

## 第一次打开

1. 安装 Godot 4.4.x 标准版。
2. 启动 Godot Project Manager。
3. 点击 Import。
4. 选择本仓库中的 game/project.godot。
5. 点击 Import & Edit。
6. 等待首次导入完成，再按 F6/F5 运行主场景。

## Android 导出

1. 在 Godot Editor 的 Editor Settings 中配置 Android SDK 路径。
2. 安装 Android SDK Platform、Build Tools、Platform Tools 和 OpenJDK 17（具体版本以 Godot 4.4 Android 导出文档为准）。
3. 在 Godot Editor 中安装匹配版本的 Android Export Templates。
4. 打开 Project > Export，确认 Android 预设。
5. 生成 ARM64 APK。预设输出位置为 game/build/android/saint-seiya-universe-war.apk。
6. 首次测试建议使用 Debug 构建；发布签名密钥应由项目所有者自行安全保管，不要提交到 GitHub。

## 真机验收

将 APK 传到魅族 21 Pro 安装，检查：
- 横屏启动和画面比例；
- 左下虚拟摇杆的移动响应；
- 普攻、天马流星拳、小宇宙爆发、闪避和目标锁定；
- 普通敌人与 Boss 的追击和攻击；
- 角色生命值、能量条、技能冷却和小地图；
- 连续游玩 15～30 分钟后的帧率、发热和耗电。

## 重要说明

仓库包含原型源码与 Android ARM64 导出预设，但 APK 需要在具备 Godot、导出模板和 Android SDK/JDK 的环境中生成。GitHub 源码提交本身不等于已经生成或通过真机测试。
