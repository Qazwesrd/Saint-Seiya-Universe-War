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


## Broader web search findings (2026-11-21)

The following sources were found beyond the original RaGEZONE threads. They materially improve the asset-recovery route, but none by itself grants permission to redistribute proprietary game assets.

### 6. Angelica / Saint Seiya Online extractor toolkit (public GitHub)
Repository: https://github.com/diegochagas/games-extractor
Angelica-specific documentation: https://github.com/diegochagas/games-extractor/blob/main/angelica/README.md

This is the strongest practical discovery in this search. The public repository contains a Python extraction and review pipeline explicitly built for the Seiya Reborn Saint Seiya Online client (documented build 290, client path example C:\\Seiya\\element). It is not a game client or a model/texture asset dump: the repository README says client archives are not committed and generated dumps are written separately.

The Angelica pipeline documents:
- PCK v2.0.2 archive listing/extraction, split .pck + .pkx handling, zlib entries, and SSO-specific archive keys;
- DDS/TGA/BMP/JPG texture conversion to PNG and image indexing/contact sheets;
- LANG text, quest/NPC text, map and media indexing;
- parsing .SKI meshes and .SMD descriptors to render character/NPC meshes in Blender;
- linking NPC/monster IDs in elements.data and path.data to .ECM model containers;
- player cloth assembly from sex-specific cloth sets, eight armor-piece SKI files, base head, pupils and class hair;
- a gallery-organizing step for portraits, maps, loading screens, videos, music, voice lines, concept art and press images, where such files exist in the client dump.

Important limitations stated by the toolkit itself: .BON skeletons and .STCK animations are not applied; renders are bind-pose/T-pose only; .ANM cutscenes are not played; task trees and some data files are only string-scraped. The toolkit's existence does not prove every model or animation can be recovered, nor that its outputs are licensed for redistribution. The repository currently has no declared license in its GitHub metadata; review its code and obtain permission before copying code into this project. It is suitable as a research candidate and a source of format knowledge, not an automatic production dependency.

### 7. New Angelica model viewer research (RaGEZONE, 2026)
URL: https://forum.ragezone.com/threads/pw-maybe-angelica-models-viewer-wip-showcase.1263235/

A 2026 work-in-progress Rust + Bevy viewer reports support for PCK v2/v3 and split PKX archives, SKI versions 8/9/100/101, BON skeleton hierarchy/bind poses, STCK v1/v2 animations, ECM containers, DDS/TGA textures and Chinese GBK filenames. It reports GPU skinning, animation playback and browsing more than 50,000 entries. The author later says GLB export was added, while GLB import and project packaging were still planned; a public GitHub release was not linked in the visible thread. Treat it as a promising research lead, not a downloadable verified tool. Its stated format coverage could help recover real animation data missing from the Python extractor's current render path.

### 8. Historical QuickBMS / ZenHAX format research
URL: https://www.zenhax.com/viewtopic.php@t=8056.html
Script reference: http://aluigi.org/bms/saint_seya_online_lang.bms

A 2018 discussion records community extraction/repacking of many SSO files and identifies multiple distinct .data formats (including DIMT and LANG); the site administrator points to a QuickBMS script for lang_base.data. This is historical format research only. Validate against the exact client build before using any script, and do not assume it handles current PCK or every .data family.

### 9. Additional client/server distribution leads (unverified third-party uploads)
- MiR6 listing: https://www.mir6.com/pcgame/81218.html — advertises a 15.1 GB Linux server + PC client + GM tools package labelled “天琴端”, dated 2026-08-28, behind a paid site currency. The page itself warns of quest progression problems requiring GM commands and says the download is not guaranteed. Its setup guide contains unsafe practices (disabling the firewall, opening all ports, world-readable permissions, weak database credentials). Do not execute its setup instructions or run an included VM/server as-is.
- MiR6 older listing: https://www.mir6.com/pcgame/31341.html — advertises a 22.7 GB Linux server/client/source package dated 2024-11-12 and claims added equipment, costumes, guardian stars and GM tooling. Contents, provenance, completeness and rights have not been verified.
- Paijishu repost: https://t.paijishu.net/thread-66126-1-1.html — advertises a “天琴端” package and Baidu Pan link, but requires login and repeats an “internet collected / delete after 24 hours” disclaimer. No archive was downloaded or checked.
- Xiaorong repost: https://www.xiaoronghuaijiu.com/forum.php?mod=viewthread&tid=8288 — advertises client/server plus GM tools, but requires forum currency and says resources were collected from the internet. No archive was downloaded or checked.
- Reborn Gaming Network client page: https://seiya.reborngn.com/page.php?page=download — lists a roughly 9 GB Windows client behind an account login. This is a live private-server client distribution, not an offline server source or a redistribution license.

These are leads only. Do not pay for any package or download/run unknown executables without the user's explicit approval. Prioritize archives from a verifiable original source, then record uploader, archive hashes, directory listing, executable inventory, client build and permission evidence. Do not use insecure setup recipes from repack sites.

### 10. Community art references and model services
- Cerberus_Rack's Saint Seiya Online gallery index: https://www.pharaonwebsite.com/users/cerberus_rack/fanarts/190-schemas-des-armures/529-saint-seiya-online/ — indexed fan art / cloth maps and character drawings; visual reference only, not game model files or reuse permission.
- RaGEZONE model commission posts (2025) mention custom armor, weapon, shield and hairstyle modeling, but are service advertisements rather than freely licensed asset repositories.

## Updated recommended acquisition workflow

1. First acquire a legitimate copy of the matching SSO client build (Seiya Reborn build 290 is the build documented by the public extractor) and preserve the original archive read-only.
2. Run PCK listing and file inventory before extraction; calculate SHA-256 for every archive and record the exact client build. Keep parsing in an isolated, non-networked workspace.
3. Use the public extractor as a format-research candidate. Independently review its code and license status before copying or embedding it. Use its output initially for a private visual inventory only.
4. In parallel, track down the 2026 Rust/Bevy Angelica viewer author's public release or request source access; it may be the better route for BON/STCK animation playback and GLB export.
5. Compare the recovered inventory against our character, cloth, boss, NPC, map, VFX, animation and story catalogs. Mark each item as found, missing, damaged, build-mismatched, or rights-unclear.
6. Keep extracted proprietary resources out of public Git and the distributable APK unless written permission or a suitable license explicitly permits redistribution. Publicly downloadable, paid, leaked, or forum-attached does not mean open-licensed.
