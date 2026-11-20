# Android ARM64 APK 测试构建

项目提供 GitHub Actions 手动导出流程，使用 Godot 4.4.1 的 Android 预设生成 ARM64 Debug APK。

## 触发构建

1. 打开 GitHub 仓库：Qazwesrd/Saint-Seiya-Universe-War。
2. 进入 **Actions**。
3. 选择 **Android APK Export**。
4. 点击 **Run workflow**，选择默认分支并确认。
5. 等待工作流完成；成功后在本次运行页面的 Artifacts 中下载 **Saint-Seiya-Universe-War-Android-ARM64-debug**。

## 构建类型与验收边界

- 当前工作流导出 Debug APK，面向安装和功能测试，不是正式签名发布包。
- APK 仅针对 Android ARM64；导出成功不等于真机测试通过。
- 安装后需验证横屏、启动、角色创建、战斗触控、左右手布局、飞行、存档读写、Boss刷新和长时间运行。
- 正式发布前仍需确定正式签名密钥、版本号、应用图标、隐私与发行信息；不要把调试签名包当成正式发行包。
