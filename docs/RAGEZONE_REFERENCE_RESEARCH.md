# RaGEZONE Research Notes — Saint Seiya Online

Date checked: 2026-11-21

This document records how RaGEZONE material may inform the independent Android offline project. It is a research index, not a grant of rights to third-party code, game data, models, textures, animations, audio, or client files.

## Verified forum findings

### 1. Saint Seiya Online Open Source thread (2021)
URL: https://forum.ragezone.com/threads/development-saint-seiya-online-open-source.1198346/

The thread describes an early community server-emulator effort. Its author explicitly says the project had only just started and basic connection work existed. Later posts mention an old client archive (SDSElement.rar) and server archive (saintdev.tgz); a reply reports that files were missing. Treat this as incomplete historical research material, not a complete client/server implementation and not a verified asset license.

### 2. Saint Seiya Online release thread (2021)
URL: https://forum.ragezone.com/threads/release-saint-seiya-online.1200232/

A forum developer comment states that the released source did not match the server and that skill content was missing for a proper build. Therefore, code fragments and data from this release must not be assumed to be mutually compatible or complete.

### 3. Age of Hades release thread (2024; updated discussion through 2025)
URL: https://forum.ragezone.com/threads/release-server-files-saint-seiya-age-of-hades-client-installation-tutorial-news-updates-2025.1226902/

The thread contains community-shared client/server installation material. A 2025 reply reports mixed/incomplete translations; another says the complete server source was never present in the thread and that the available source was outdated and missing files. It is a version-mismatched and incomplete reference, not a reliable production dependency.

### 4. Later source availability discussion (2025)
URL: https://forum.ragezone.com/threads/is-complete-client-and-server-source-code-for-this-game-something-that-doesnt-already-exist-here.1252635/

Replies report that the source being discussed was from 2016, incomplete, and lacked a full client/server set. Use this as a warning against treating forum archives as a complete reconstruction kit.

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
