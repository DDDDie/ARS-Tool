# Session Handoff

Status: Active  
Last updated: 2026-06-29

## Current state

- **Sandbox live** at `http://10.62.81.112:8093/` — version badge visible on tab bar (`verTag`).
- 1Panel site recreated with **网站代号 `ars-tool`** → web root `/opt/1panel/www/sites/ars-tool/index`.
- **Restructured** to `src/ui/` + `src/server/` + npm build → `release/index.html` (gitignored).
- Version SSOT: `package.json`; build injects `vX.Y.Z` into HTML + JS.
- GitLab `kongxiang2/ars-tool` — Profile **B** (WEB `:8093`, API `:3004`).
- `scripts/publish-static.sh` → `.../ars-tool/index/index.html`.

## Routine update (AWP)

```bash
cd /opt/ars-tool
git pull origin main
npm ci
npm run release:sync
bash scripts/publish-static.sh
# restart ars-tool-api if src/server/ changed
```

## Optional follow-up

- [ ] Full smoke: upload `data/alm_hardware.xlsx`, Lenovo `/spec` lookup
- [ ] Security group ticket for TCP `8093` if PC off-office cannot reach Sandbox
- [ ] Push doc updates (`SANDBOX_DEPLOYMENT.md` 删站重建) to GitLab if not yet on server

## Verification notes

- `npm run check` — build smoke (VERSION, verTag, key functions)
- Sandbox: `curl -s http://127.0.0.1:8093/ | grep verTag` and `curl http://127.0.0.1:3004/health`
