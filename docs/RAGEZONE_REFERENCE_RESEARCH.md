# RaGEZONE Research Notes — Saint Seiya Online

Date checked: 2026-11-21

This document records how RaGEZONE material may inform the independent Android offline project. It is a research index, not a grant of rights to third-party code, game data, models, textures, animations, audio, or client files.

## Verified forum findings

### 1. Saint Seiya Online Open Source thread (2021)
URL: https://forum.ragezone.com/threads/development-saint-seiya-online-open-source.1198346/

The thread describes an early community server-emulator effort. Its author explicitly says the project had only just started and basic connection work existed. Later posts mention an old client archive (SDSElement.rar) and server archive (saintdev.tgz); a reply reports that files were missing. Treat this as incomplete historical research material, not a complete client/server implementation and not a verified asset license.

### 2. Saint Seiya Online release thread (2021)
URL: https://forum.ragezone.com/threads/release-saint-seiya-online.1200232/

The first post advertises a one-click server VM plus a client, with a 2021 installation recipe and a Baidu Pan link. A developer reply says they also had original server packages and tools, and identifies tools for gshop, npcgen, and sEledit. The thread is useful as a possible route to inspect the original data formats and client assets, but its attachments require forum access and their current availability/integrity has not been verified. The post itself says the release was not tested by its poster.

Do not treat the posted VM credentials, old network configuration, or one-click instructions as safe defaults. Any archive must be scanned and inspected in an isolated environment before execution.

### 3. Angelica engine source discussion (2021; later replies through 2025)
URL: https://forum.ragezone.com/threads/angelica-engine-missing-som-files.1200707/

The discussion concerns missing headers and dependencies when compiling the Saint Seiya Online client. A participant explicitly says the client skill library has no source code and the client source is incomplete, suitable only for study/reference. Fyyre later points to Angelica 3 / 3.1 material behind forum access. This may help explain file formats and engine dependencies, but does not establish a complete buildable SSO client or a redistribution license.

### 4. Age of Hades release thread (2024; updated discussion through 2025)
URL: https://forum.ragezone.com/threads/release-server-files-saint-seiya-age-of-hades-client-installation-tutorial-news-updates-2025.1226902/

The thread contains community-shared client/server installation material. A 2025 reply reports mixed/incomplete translations; another says the complete server source was never present in the thread and that the available source was outdated and missing files. It is a version-mismatched and incomplete reference, not a reliable production dependency.

### 5. Later source availability discussion (2025)
URL: https://forum.ragezone.com/threads/is-complete-client-and-server-source-code-for-this-game-something-that-doesnt-already-exist-here.1252635/

Replies report that the source being discussed was from 2016, incomplete, and lacked a full client/server set. Use this as a warning against treating forum archives as a complete reconstruction kit.

## Next acquisition and inspection targets

1. Obtain the 2021 client + server VM archive from the release thread, if the attachment remains accessible to the user.
2. Obtain the separately mentioned gshop, npcgen, and sEledit tools, if available and authorized for inspection.
3. Obtain the Angelica 3 / 3.1 source archive only for understanding engine/file-format dependencies; do not assume it is a complete game client.
4. Ask the uploader/rightsholder for explicit permission before redistributing source or extracted proprietary assets in a public APK/repository.
5. Record archive filename, source post, uploader, file size, SHA-256, archive listing, detected executables, and license/permission evidence before any extraction or execution.

## Permitted engineering use

Until a specific file has a clear license or written permission covering reuse and redistribution, use forum material only for:
- high-level feature research and historical behavior notes;
- identifying terminology, equipment categories, encounter structure, and progression concepts;
- designing original data schemas and original implementations;
- comparing our independently authored systems against publicly described behavior.

Do not copy or package proprietary client/server source, extracted game assets, textures, meshes, animations, audio, proprietary databases, or other redistributed materials without a verified license or permission. Public availability on a forum is not proof of permission.

## Art-production consequences

1. Keep all production meshes, textures, rigs, animation clips, VFX, icons, and audio in our project marked as original or explicitly licensed.
2. For each imported third-party asset, require a manifest with source URL, author, license, permission evidence, modifications, and redistribution scope. Reject assets with unknown provenance from release bundles.
3. Use forum screenshots or descriptions only as visual research; create fresh topology, silhouettes, materials, textures, and effects rather than tracing or extracting proprietary assets.
4. Model families should be independently authored: bronze/silver/gold cloth, divine cloth, scale armor, surplice, god-warrior armor, celestial armor, and original endgame designs. Avoid presenting uncertain forum data as official canon.
5. Build original character and boss identities that reproduce broad genre/gameplay roles without copying protected expressive details where rights are unclear.

## Current repository implementation boundary

The existing Blender pipeline creates stylized prototype meshes and modular armor templates. Its own generator describes its output as prototypes, not final profession-specific art. The visual catalogs and skill effect profiles are presentation metadata; they are not proof that every character, armor set, boss, or ability already has a finished unique production asset.

The art pipeline must continue to validate actual exported GLB files, textures, rigs, animation clips, VFX scenes, Godot imports, and Android packaging. Catalog counts alone are not acceptance evidence.
