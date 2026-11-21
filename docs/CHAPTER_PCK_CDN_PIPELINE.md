# 七大篇章 PCK 构建与 CDN 发布流程

本流程把已经制作并通过 Godot 导入的篇章场景资源打成真正可挂载的 Godot PCK，再生成游戏运行时需要的 pack.json、SHA-256 和固定清单大小。它不会生成虚构美术，也不会用占位文件凑数据包体积。

## 1. 资源放置

每个篇章的可交付资源放在以下目录：

- game/assets/environments/galaxy_wars/
- game/assets/environments/sanctuary_twelve_houses/
- game/assets/environments/asgard/
- game/assets/environments/poseidon/
- game/assets/environments/hades/
- game/assets/environments/heaven/
- game/assets/environments/original_final/

目录必须包含实际运行资源（例如 .tscn、.tres、.glb、贴图或音频），仅有 README、Blender 源文件或设计文档时会拒绝生成 PCK。

## 2. Godot 导入与单篇打包

先用项目锁定版本 Godot 4.4.1 导入资源：

~~~powershell
godot --headless --editor --path game --quit
~~~

再逐篇生成 PCK（示例）：

~~~powershell
New-Item -ItemType Directory -Force build\chapter-pcks | Out-Null
godot --headless --path game --script res://tools/build_chapter_pck.gd -- --chapter galaxy_wars --output (Resolve-Path build\chapter-pcks).Path\galaxy_wars.pck
~~~

把命令中的章节 ID 依次替换为七个目录名。打包器会收集场景、模型、材质、贴图、音频和运行时数据；对带 .import 的资源同时收集导入映射和 .godot/imported 缓存，避免 Android 运行时找不到导入资源；拒绝没有真实运行资源的目录；并校验输出 PCK 文件头。

## 3. 生成清单和 CDN 发布目录

将七个 PCK 放在同一输入目录，运行：

~~~powershell
python tools/art_pipeline/build_chapter_manifests.py --input-dir build\chapter-pcks --output-dir build\cdn-release --version 1
~~~

输出结构：

~~~text
build/cdn-release/
  pack_catalog.release.json
  galaxy_wars/
    pack.json
    galaxy_wars.pck
  sanctuary_twelve_houses/
    pack.json
    sanctuary_twelve_houses.pck
  asgard/
    pack.json
    asgard.pck
  poseidon/
    pack.json
    poseidon.pck
  hades/
    pack.json
    hades.pck
  heaven/
    pack.json
    heaven.pck
  original_final/
    pack.json
    original_final.pck
~~~

pack.json 记录实际文件大小与 SHA-256；pack_catalog.release.json 固定每份清单的 SHA-256 和字节数。生成器要求七个 PCK 全部存在且文件头有效，避免只发布部分篇章。

正式发布时再传入真实 HTTPS CDN 地址：

~~~powershell
python tools/art_pipeline/build_chapter_manifests.py --input-dir build\chapter-pcks --output-dir build\cdn-release --version 1 --primary-cdn https://你的国内CDN域名/saint-seiya/ --fallback-cdn https://你的海外备用域名/saint-seiya/
~~~

把输出目录原样上传到两个 CDN 对应目录，并将生成的 pack_catalog.release.json 作为该版本 APK 的 game/content/pack_catalog.json。不要填写示例域名；真实 CDN、证书、跨运营商下载和 Range 请求必须先实测。

## 4. 当前限制

仓库目前没有七个篇章的完整正式环境资源，也没有真实 CDN 域名、上传凭证和发布清单。因此工具链已准备好，但不能凭空产出正式 15–20 GB 内容包。实际包体积由真正制作完成的模型、贴图、场景、音频等决定；不得用重复文件或无意义填充扩大体积。

PCKPacker 使用 pck_start()、add_file()、flush() 创建 Godot 资源包，游戏通过 ProjectSettings.load_resource_pack() 挂载。
