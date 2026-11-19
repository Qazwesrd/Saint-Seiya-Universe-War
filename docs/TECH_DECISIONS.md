# 技术决策记录

## 已确定：Godot 4，Android 手机单平台

- **主引擎：Godot 4（稳定版系列）**
- **目标平台：Android 手机，横屏**
- **首要测试设备：魅族 21 Pro（Snapdragon 8 Gen 3、Adreno 750、16GB RAM）**
- **渲染方向：优先采用 Mobile 渲染器**，以实际真机测试结果决定是否调整个别效果或兼容性设置。
- **脚本方向：优先使用 GDScript**，避免首期引入不必要的 C# Android 导出复杂度。

## 选型依据

开发电脑配置：
- CPU：AMD Ryzen 7 4800U
- GPU：AMD Radeon 集成显卡
- RAM：16GB
- OS：Windows 11

Godot 4 能满足本项目 3D 即时动作玩法和 Android 导出需求，编辑器资源负担通常比 Unreal Engine 5 更适合当前开发电脑。Godot 官方文档列出 Android 导出流程，并提供 Mobile、Compatibility 等渲染器选项。

这项决定是以开发效率、Android 单机交付和当前硬件条件作出的务实选择，不代表 Godot 没有大型 3D 项目的性能边界。复杂场景、角色数量、阴影、粒子和后处理都必须通过真机逐步验证。

## 开发与运行策略

1. 开发电脑用于编辑、脚本编写、基础场景预览和 Android 构建；不把电脑预览帧率当作手机性能结论。
2. 所有核心体验以 Android 横屏触控为中心，不开发 Windows 电脑版。
3. 首个原型先完成角色移动、镜头跟随、普攻、技能、闪避、锁定目标和一个 Boss。
4. 首期采用 GDScript，项目结构保持模块化，便于后续维护和性能优化。
5. 不依赖云服务器、账号系统或在线游戏服务。

## Android 导出工具链

根据 Godot 官方 Android 导出文档配置 Android SDK 与 OpenJDK。当前官方文档推荐 OpenJDK 17，并要求配置 Android SDK 路径；具体版本以所选 Godot 稳定版的导出说明为准。

## 资源与性能原则

- 约 5GB 是首次安装内容的规划目标，不是要求生成一个 5GB 的单体 APK。
- 后续按篇章提供独立离线资源包，容量由用户设备剩余空间决定。
- 通过区域分块加载、LOD、纹理压缩、按需加载和及时释放控制运行时内存。
- 不将游戏总磁盘容量等同于运行时 RAM 占用。
- 优先测试触控响应、帧率稳定性、设备温度、耗电和长时间运行表现。
- 目标设备性能较强，但仍需提供画质档位并限制高负载特效，避免持续过热。

## 官方技术参考

- Godot 系统需求：https://docs.godotengine.org/en/stable/about/system_requirements.html
- Godot Android 导出：https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
- Godot 渲染器说明：https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html
