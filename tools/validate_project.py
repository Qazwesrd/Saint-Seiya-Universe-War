#!/usr/bin/env python3
"""Static integrity checks for the Godot project; no third-party packages required."""
from pathlib import Path
import re
import sys
import subprocess

ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
errors = []
checks = 0

def require(condition, message):
    global checks
    checks += 1
    if not condition:
        errors.append(message)

project_file = GAME / "project.godot"
require(project_file.is_file(), "缺少 game/project.godot")
if project_file.is_file():
    project = project_file.read_text(encoding="utf-8")
    main_match = re.search(r'^run/main_scene="([^"]+)"', project, re.M)
    require(bool(main_match), "project.godot 未配置 run/main_scene")
    if main_match:
        scene_path = GAME / main_match.group(1).replace("res://", "")
        require(scene_path.is_file(), f"主场景不存在：{main_match.group(1)}")

    autoload_section = re.search(r'\[autoload\](.*?)(?=\n\[|\Z)', project, re.S)
    if autoload_section:
        names = []
        for line in autoload_section.group(1).splitlines():
            line = line.strip()
            if not line or line.startswith(";") or "=" not in line:
                continue
            name, value = line.split("=", 1)
            names.append(name.strip())
            path_match = re.search(r'"\*?res://([^"]+)"', value)
            require(bool(path_match), f"AutoLoad 路径格式异常：{line}")
            if path_match:
                target = GAME / path_match.group(1)
                require(target.is_file(), f"AutoLoad 脚本不存在：{path_match.group(1)}")
        require(len(names) == len(set(names)), "AutoLoad 名称存在重复")
    else:
        require(False, "project.godot 缺少 [autoload] 区块")

preset_file = GAME / "export_presets.cfg"
require((GAME / "scenes" / "main_menu.tscn").is_file(), "缺少主菜单场景 game/scenes/main_menu.tscn")
require((GAME / "scripts" / "main_menu.gd").is_file(), "缺少主菜单控制器 game/scripts/main_menu.gd")
require((GAME / "tests" / "framework_smoke_test.tscn").is_file(), "缺少框架冒烟测试场景 game/tests/framework_smoke_test.tscn")
require(preset_file.is_file(), "缺少 Android 导出预设 game/export_presets.cfg")
if preset_file.is_file():
    preset = preset_file.read_text(encoding="utf-8")
    require('platform="Android"' in preset, "导出预设未指定 Android")
    require('architectures/arm64-v8a=true' in preset, "Android 预设未启用 ARM64")
    require('export_filter="all_resources"' in preset, "Android APK 必须打包全部项目资源")
    require('exclude_filter=""' in preset, "Android APK 不允许排除正式资源")
    require('permissions/internet=true' in preset, "Android 安装包必须声明联网权限以下载离线数据")

# Core framework services must be registered as AutoLoads and present on disk.
required_services = [
    "EventBus", "SettingsManager", "LocalizationManager", "AudioManager",
    "SaveManager", "ResourcePackManager", "DialogueManager", "SceneFlowManager",
    "SystemHealthManager", "ApplicationLifecycleManager",
    "RPGState", "QuestManager", "SkillSystem", "CampaignManager",
    "CombatSessionManager", "LootManager", "EquipmentAffixManager", "EnemyDatabase", "DailyBossManager", "EncounterDirector", "ComboPresetManager"
]
if project_file.is_file():
    for service in required_services:
        require(f'{service}="*res://scripts/' in project, f"缺少核心服务 AutoLoad：{service}")

catalog_file = GAME / "content" / "pack_catalog.json"
require(catalog_file.is_file(), "缺少章节资源包目录 game/content/pack_catalog.json")
if catalog_file.is_file():
    import json
    try:
        catalog = json.loads(catalog_file.read_text(encoding="utf-8"))
        require(isinstance(catalog.get("packs"), dict), "资源包目录缺少 packs 字典")
        require(catalog.get("delivery_mode") == "apk_plus_auto_download", "最终交付必须为 APK 加自动下载离线数据")
        require(catalog.get("resource_container") == "versioned_https_cdn_packs", "章节数据必须通过版本化 HTTPS 资源包交付")
        require(catalog.get("cdn_region") == "mainland_china", "资源下载服务必须面向中国大陆网络")
        require(catalog.get("cdn_protocol") == "https", "资源下载必须使用 HTTPS")
        require(catalog.get("range_requests_required") is True, "资源服务器必须支持断点续传")
        require(catalog.get("sha256_required") is True, "资源包必须进行 SHA-256 校验")
        require(catalog.get("manual_file_management_required") is False, "玩家不得手动管理资源文件")
        require(catalog.get("offline_ready_after_all_packs_installed") is True, "全部资源安装后必须可离线运行")
        require(catalog.get("external_downloads_required") is True, "大型章节数据应从国内 CDN 自动下载")
        require(isinstance(catalog.get("cdn_base_url"), str), "缺少 CDN 地址配置")
        for pack_id, pack in catalog.get("packs", {}).items():
            require(bool(re.fullmatch(r"[a-z][a-z0-9_]*", pack_id)), f"资源包编号无效：{pack_id}")
            require(isinstance(pack, dict) and bool(pack.get("name")), f"资源包元数据不完整：{pack_id}")
            if pack.get("required"):
                require(pack.get("install_state") == "bundled", f"必需资源包必须内置：{pack_id}")
    except (json.JSONDecodeError, UnicodeDecodeError):
        require(False, "章节资源包目录不是有效 UTF-8 JSON")

# Validate every literal res:// reference in scenes and scripts.
resource_pattern = re.compile(r'res://([A-Za-z0-9_./-]+)')
for source in list(GAME.rglob("*.gd")) + list(GAME.rglob("*.tscn")):
    content = source.read_text(encoding="utf-8")
    for resource in sorted(set(resource_pattern.findall(content))):
        target = GAME / resource
        require(target.exists(), f"{source.relative_to(ROOT)} 引用了不存在的资源：res://{resource}")

# Every declared script should be non-empty and UTF-8 readable.
scripts = list((GAME / "scripts").glob("*.gd"))
require(bool(scripts), "game/scripts 中没有 GDScript 文件")
for script in scripts:
    require(script.stat().st_size > 0, f"脚本为空：{script.relative_to(ROOT)}")

# Ensure every catalog entry has an explicit art-delivery manifest.
manifest_check = subprocess.run(
    [sys.executable, str(ROOT / "tools" / "art_pipeline" / "build_manifests.py"), "--check"],
    cwd=ROOT, capture_output=True, text=True
)
checks += 1
if manifest_check.returncode != 0:
    errors.append("美术交付清单检查失败：" + (manifest_check.stdout + manifest_check.stderr).strip())

print(f"项目静态检查：{checks} 项")
if errors:
    print(f"发现 {len(errors)} 个问题：")
    for error in errors:
        print(f"  [FAIL] {error}")
    sys.exit(1)
print("结果：全部通过")
