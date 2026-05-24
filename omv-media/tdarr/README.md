# Tdarr on omvt300

**UI:** http://192.168.2.121:8265  
**Containers:** `tdarr`, `tdarr_node` (compose: `/compose/tdarr/tdarr.yml`)  
**Library mount:** `/library` → host `.../Media` (Movies, TV, etc.)

## Codec policy (Phase 3 — Option A: safe seeding)

- **Skip** files that are already HEVC or AV1.
- **Target:** H.265 (x265) CRF 22, MKV, 10-bit where source is 8-bit SDR.
- **Audio:** keep all tracks; add AAC stereo if none.
- **Subtitles:** keep all.
- **Hardware:** `/dev/dri` passed through (AMD ES1000 — expect slow encodes; software fallback OK).

## Transcode cache (required)

Tdarr cannot browse host paths like `/srv/...`. Use the **container** path only.

| Where | What to enter |
|-------|----------------|
| **Tdarr** tab → click node `omvt300-node1` → **Cache** / staging | `/temp` |
| Server staging (if prompted) | `/temp` |

Host mapping (already configured):

- Container: `/temp`
- Host: `/srv/dev-disk-by-uuid-a85e8270-9716-45a0-90e5-d8bd29a801e5/tdarr-transcode` (~3 TB free on media pool)

Type `/temp` manually if the folder picker is empty or disabled — that is normal. Do **not** use `/library/...` for cache.

## Setup in UI (one-time)

1. Open http://192.168.2.121:8265
2. **Libraries** → Add (type paths manually; browse often fails in Docker):

   | Library name | Source folder path |
   |--------------|-------------------|
   | Movies | `/library/Movies` |
   | TV (Sonarr) | `/library/TV/Series` |
   | Kids TV (optional) | `/library/TV/Kids TV` |

   Do **not** rely on the folder picker for TV — paste the path above.

   **Why not `/library/TV` alone?** That parent folder mixes `Series`, `TV_Archive`, `Documentaries`, and a Windows-style folder `02\ Series\ Running` (backslash in the name). Tdarr’s browser often chokes on that. Sonarr’s episodes live under **`/library/TV/Series`** — use that as the main TV library.
3. **Flows** → import or build:
   - Filter: `VideoCodec` not in `hevc,av1`
   - Health check plugin first (run on entire library once)
   - Then: FFmpeg Custom — `hevc_vaapi` or `libx265` with CRF 22
4. **Wave 1 (canaries):** one series folder + 10 movies under `Movies/General`
5. **Wave 2:** files > 8 GB at 1080p
6. **Wave 3:** remainder

## Option B (aggressive)

Re-encode regardless of active torrents; torrents may fail recheck. Use only if seeding is not required.

## Flow JSON

Store exported flows in this directory (`tdarr/flows/`) for version control after you build them in the UI.
