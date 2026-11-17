# Full Offline Audit Report

**Audit date:** 2026-11-16  
**Audited tree:** `0c532a9` (the report itself is added afterward)  
**Scope:** Every indexed page, navigation target, internal link, rendered asset, bundled archive, runtime route, major browser UI, offline installer path, placeholder, and Exploit-DB record.

## Result

**PASS — no unresolved page, link, asset, placeholder, or dead-content failures.**

| Check | Result |
|---|---:|
| Indexed pages | 5,085 |
| Navigation URLs discovered | 5,227 |
| Unique application URLs crawled | 5,732 |
| Internal links exercised | 5,169 |
| Rendered local assets exercised | 1,600 |
| Non-200 application URLs/assets | 0 |
| Automatically loaded remote assets | 0 |
| Placeholder pages | 0 |
| Empty/dead-content pages | 0 |
| Invalid processed/nav JSON files | 0 |
| Duplicate `(source, path)` pages | 0 |
| Browser pages sampled with real Firefox/Selenium | 12 |
| Broken images in browser sample | 0 |
| Remote browser resource requests | 0 |

## Repairs made during this audit

- Fixed the Adaptix `Development` navigation target shown returning 404 in the supplied screenshot.
- Rebuilt ten stale Adaptix navigation targets against canonical bundled page paths.
- Added real local index pages for the Adaptix C2 and Development sections.
- Added offline aliases for archived Adaptix, Sliver, Church of Malware, JTAG, TTY, and Minisign routes.
- Repaired old source-prefixed and legacy-format links.
- Removed a Windows case-collision between GTFOBins `R` and `r` while preserving both logical pages.
- Rebuilt the search index to contain every one of the 5,085 processed pages.
- Corrected an escaped iframe example that the browser had interpreted as a real asset request.
- Refreshed Exploit-DB to upstream commit `70bbef3f18b835b0d8bacb978f2bc7b751a7cec9` (DB: 2026-11-12). Its 47,182 CSV rows normalize to 46,710 unique exploits after merging 472 repeated tag rows; every unique exploit has an exact bundled source file.

## Placeholder audit

The earlier crawl found **37 placeholder occurrences across 28 pages**.

- **3 substantive images were recovered and committed locally:** two hardware-kit photographs and the BadSuccessor diagram.
- **34 references were removed rather than hidden behind a fake image.** These were dead upstream URLs, malformed `broken-reference`/`...` image tokens, obsolete badges/contributor widgets, or unavailable historical images whose surrounding article text remains complete.
- The generic `offline-asset-unavailable.svg` placeholder was deleted.
- Final placeholder count: **0**.

## Content and media inventory

- 5,085 processed content pages across 31 sources.
- 1,668 general external images localized in Git.
- 1,413 source-relative media assets localized in Git.
- 194 Adaptix screenshots localized in Git.
- 3 additional assets recovered during this audit.
- 40,810 external documentation-link occurrences (27,451 unique) remain as explicit user-clickable citations only. They are not scripts, styles, fonts, images, media, fetches, redirects, or automatic requests.

## Runtime and browser validation

Real Firefox/Selenium validation passed for:

- Adaptix Development
- Search with `kerberoast` results
- Home
- CyberChef
- JWT Decoder
- Payload Encoder
- lolol.farm index
- Compiled Binaries
- Local Tools
- Recovered hardware media page
- BadSuccessor page
- Cookies Hacking page

Interactive checks also passed:

- Payload URL/Base64 encoding
- JWT sample decoding
- Local CyberChef iframe loading

All sampled pages had zero broken images and zero remote resource requests.

## Offline installation proof

A fresh Git clone was installed under a Linux network namespace with no network stack using:

```bash
unshare -n ./install.sh --no-tools
```

The installer:

- Installed Python dependencies exclusively from bundled packages.
- Extracted the bundled binaries archive.
- Extracted the bundled Exploit-DB archive.
- Found 5,085 content pages and 31 navigation files.
- Verified 194 Adaptix screenshots and all critical static assets.
- Completed without contacting PyPI, GitHub, package mirrors, CDNs, or any other service.

Post-install offline API checks passed for the newest, previous, middle, and oldest Exploit-DB records. The archive was compared file-by-file against all 46,710 unique upstream exploit paths with zero missing files and zero SHA-256 mismatches.

## Archive integrity

| Archive | Bytes | SHA-256 |
|---|---:|---|
| `exploitdb.7z.001.txt` | 26,982,357 | `128f597d57d3123fa0c8980a10078b936b04ccf8e9004563ff5c6f056d184c01` |
| `binaries.7z.001.txt` | 99,614,720 | `236c6253d55f4634faa35a1be3b80474b70ab358ae2482a1ce2e8a59cb2352f5` |
| `binaries.7z.002.txt` | 99,614,720 | `662e21a6e41d1a5598af55167df9bba268d46ce8281870f92833217300318e22` |
| `binaries.7z.003.txt` | 4,335,873 | `06a7d91725a64c05e17de8d88028fdc28ef3fd5c54d2f209e6e7094b31f25c83` |

Both archives passed `7z t` with the installer password.

## Static and dependency checks

Passed:

- `bash -n install.sh`
- `python -m py_compile app.py`
- `node --check static/js/app.js`
- `git diff --check`
- `pip check`
- Full JSON parse/schema-presence scan
- No download/fetch/update utility scripts in the shipped tree
- No `curl`, `wget`, `git clone`, online pip install, `urllib.request`, `urlopen`, or Requests/HTTPX download path in shipped Python/shell runtime scripts
- No remote CSS asset URL; HTTP text in CyberChef CSS is license metadata or an SVG namespace inside local data URIs

## Kali VM cleanup

The temporary test installation and all audit artifacts were removed from the actual Kali VM. The `P3TA_OFFLINE` IPv4/IPv6 firewall chains were removed, port 5000 was stopped, the DHCP default route was present, and external connectivity was successfully rechecked. No project installation remains on that VM.
