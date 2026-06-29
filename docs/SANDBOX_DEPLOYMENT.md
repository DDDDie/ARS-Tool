# ARS Tool — xCloud Sandbox Deployment

Status: **Active**  
Last updated: **2026-06-29**

Generic procedures: `@xcloud-awp-deploy` skill (`references/sandbox-standard.md`)  
Checklists: skill `assets/checklists/xcloud_awp_*.md`

---

## Instance variables

| Variable | Value |
|----------|-------|
| Profile | B |
| Sandbox host | `10.62.81.112` |
| Web port | `8093` |
| API port | `3004` |
| Site code (网站代号) | `ars-tool` |
| Source on server | `/opt/ars-tool` |
| 1Panel web root | `/opt/1panel/www/sites/ars-tool/index` |
| Git | `https://gitlab.xpaas.lenovo.com/kongxiang2/ars-tool.git` |
| Supervisor | `ars-tool-api` |

---

## Architecture

```text
/opt/ars-tool  --publish-static.sh-->  /opt/1panel/www/sites/ars-tool/index/index.html

Browser :8093
    │
    ▼
1Panel OpenResty (网站代号 ars-tool)
    ├── /              → index.html (built from src/ui)
    └── /spec, /health → reverse proxy → 127.0.0.1:3004 (src/server/lenovo_spec_server.py)
```

| 目录 | 用途 |
|------|------|
| `/opt/ars-tool` | 源码、Python API、`.env`（**不是** 1Panel 网站根） |
| `/opt/1panel/www/sites/ars-tool/index` | 仅发布静态 HTML（`1000:1000`） |

**1Panel 路径规则：** 网站目录 = `/opt/1panel/www/sites/<网站代号>/index`。创建站点时 **代号必须填 `ars-tool`**（不要填 IP），否则发布路径会对不上。

---

## First deploy

### 1. Clone on AWP

```bash
sudo mkdir -p /opt/ars-tool
sudo chown prame001:wheel /opt/ars-tool
cd /opt/ars-tool
git clone https://gitlab.xpaas.lenovo.com/kongxiang2/ars-tool.git .
```

### 2. Build UI + 1Panel static site

`release/index.html` is **not** committed — build on the server after clone/pull:

```bash
cd /opt/ars-tool
npm ci
npm run release:sync    # patch-bump version + build; or ARS_SKIP_VERSION_BUMP=1 npm run build
```

**网站 → 创建网站** → **静态网站**

| Field | Value |
|-------|-------|
| 域名 | `10.62.81.112` |
| 端口 | `8093` |
| 代号 | `ars-tool` |

```bash
sudo ls -la /opt/1panel/www/sites/ars-tool/index/
bash scripts/publish-static.sh
curl -I http://10.62.81.112:8093/
```

### 3. Python API (Supervisor)

```bash
cd /opt/ars-tool
PORT=3004 python3 src/server/lenovo_spec_server.py &
curl http://127.0.0.1:3004/health
# stop foreground trial, then configure 1Panel process guard: ars-tool-api
```

1Panel **反向代理**（网站 `ars-tool`）:

| 路径 | 目标 |
|------|------|
| `/spec` | `127.0.0.1:3004` |
| `/health` | `127.0.0.1:3004` |

Proxy target: `127.0.0.1:3004` — **no** `http://` prefix.

Supervisor env: `PORT=3004`, working directory `/opt/ars-tool`.

### 4. Smoke

- AWP: `curl http://127.0.0.1:3004/health` → `{"ok": true}`
- AWP: `curl -I http://10.62.81.112:8093/` → 200
- PC (office): `Test-NetConnection 10.62.81.112 -Port 8093`
- Browser: upload sample from `data/alm_hardware.xlsx`, verify Lenovo spec lookup

---

## Routine update

```bash
cd /opt/ars-tool
git pull origin main
npm ci
npm run release:sync                    # or ARS_SKIP_VERSION_BUMP=1 npm run build
bash scripts/publish-static.sh
# 1Panel → restart ars-tool-api        # when src/server/lenovo_spec_server.py changed
```

---

## 删站重建（代号曾误填为 IP 时）

`/opt/ars-tool` 源码与 Python API **不用删**；只重建 1Panel 静态网站。

### 0. 重建前记录（可选）

在 1Panel 旧站点 **反向代理** 页截图或记下 `/spec`、`/health` → `127.0.0.1:3004`（重建后要重配）。

### 1. 删除旧站

1Panel → **网站** → 选中 `ars-tool:8093`（或当前 `:8093` 站点）→ **删除**
2. 确认删除（会去掉 `/opt/1panel/www/sites/10.62.81.112/` 等旧目录，**不影响** `/opt/ars-tool`）

### 2. 创建新站

**网站 → 创建网站 → 静态网站**

| 字段 | 填写 |
|------|------|
| 域名 | `10.62.81.112` |
| 端口 | `8093` |
| **代号** | **`ars-tool`**（必填，不要用 IP） |

创建后 **网站目录** 应显示：

```text
/opt/1panel/www/sites/ars-tool/index
```

### 3. 发布静态页

```bash
cd /opt/ars-tool
git pull origin main
npm ci
npm run release:sync
bash scripts/publish-static.sh
sudo grep -o 'id="verTag">[^<]*' /opt/1panel/www/sites/ars-tool/index/index.html
curl -s http://127.0.0.1:8093/ | grep -o 'id="verTag">[^<]*'
```

### 4. 反向代理（新站必做）

网站 `ars-tool` → **反向代理** → 添加：

| 路径 | 目标 |
|------|------|
| `/spec` | `127.0.0.1:3004` |
| `/health` | `127.0.0.1:3004` |

### 5. Python API

若进程守护 `ars-tool-api` 仍在运行，**无需重建**。验证：

```bash
curl http://127.0.0.1:3004/health
```

### 6. 浏览器

`http://10.62.81.112:8093/` → Ctrl+F5 → Tab 栏右侧应见 `v1.0.x`。

---

## Project-specific notes

- **Node required on AWP** for `npm ci` + `npm run build` (devDependencies: `xlsx`, `jszip`).
- `release/` is gitignored; always build before `publish-static.sh`.
- Version SSOT: `package.json`; UI shows `vX.Y.Z` on the tab bar (right).
- Local dev uses port `9527`; Sandbox uses `PORT=3004`.
- Sample workbooks under `data/` are for manual testing only.
