# p3ta-tricks

> If this saves you time on an engagement, please ⭐ star the repo — it helps more than you think.
>
> Feature requests, bugs, and ideas → Discord: **p3ta00**

---

A fast, searchable pentest reference that pulls attack techniques, tool syntax, and post-exploitation chains from the best open-source security wikis into one place. No more tab switching mid-engagement.

**Live site → [p3ta-tricks.com](https://p3ta-tricks.com)**

---

## Offline Mode

This repository is the **offline-only** edition and ships fully air-gapped. Installation and runtime never use PyPI, package-manager downloads, GitHub raw fallbacks, CDNs, or Exploit-DB network fallbacks. Missing bundled artifacts cause installation to stop instead of silently going online.

All runtime assets are included:

- **`static/img/adaptix/`** — 194 Adaptix C2 screenshots scraped from GitBook CDN
- **`static/img/external/`** — 1,360 third-party images (blogspot, Medium, GitHub user-attachments, OWASP, CyberArk, Palo Alto, PortSwigger, etc.) downloaded and locally hosted
- **`static/source-assets/sliver/`** — Sliver C2 diagrams
- **`static/source-assets/`** — 1,500 images from the latest upstream wiki snapshots, preserving each source's relative paths

Upstream images that were authentication-gated or already deleted are treated as unavailable; the application never attempts to fetch them at runtime.

### Quick start

```bash
chmod +x install.sh && ./install.sh
./start-offline.sh
# open http://127.0.0.1:5001
```

Custom port / host:
```bash
PORT=8080 HOST=0.0.0.0 ./start-offline.sh
```

The installer creates the Python venv, installs exclusively from `vendor/`, verifies bundled assets, and extracts the bundled archives. It has no network fallback. Python 3.9+ and 7-Zip must already be available on the host.

---

## Bundled Archives

The compiled binaries and the Exploit-DB script corpus are shipped as compressed, password-protected, split 7-Zip archives (the volumes carry a `.txt` suffix). `install.sh` extracts them automatically on first run; you don't need to do anything manually.

| Archive | Extracts to | Contents |
|---|---|---|
| `binaries.7z.001.txt` … `.003.txt` | `binaries/` | ~75 compiled offline pentest binaries — Potatoes (GodPotato, JuicyPotato, PrintSpoofer), Mimikatz, Kerbrute, Kekeo, LaZagne, GoldenGMSA, nanodump, chisel, reverse-ssh, PEASS-ng, PrivescCheck, pspy, bettercap, dnSpy, Windows kernel exploits, ysoserial.net, and more (`.versions.json` tracks versions) |
| `exploitdb.7z.001.txt` | `sources/exploitdb/` | The full Exploit-DB corpus (~48k exploit + shellcode scripts) backing the offline Exploit-DB browser |

**Password:** `root`

Extraction is automatic, but if you ever need to do it by hand:

```bash
# 7z reads split volumes named .7z.001/.002/… — drop the .txt first
for f in binaries.7z.*.txt; do ln -s "$f" "${f%.txt}"; done
7z x -proot binaries.7z.001          # -> binaries/
7z x -proot exploitdb.7z.001         # -> sources/exploitdb/
```

The extracted `binaries/` and `sources/exploitdb/` directories are git-ignored — the archives are the source of truth, so the repository download stays lean.

---

## What's in it

BloodHound · HackTricks · HackTricks Cloud · The Hacker Recipes · PayloadsAllTheThings · InternalAllTheThings · HardwareAllTheThings · GTFOBins · LOLBAS · WADComs · NetExec · Impacket · Certipy · bloodyAD · Rubeus · Mimikatz · Ligolo-ng · Sliver · Adaptix C2 · goexec · Metasploit · All About Bug Bounty · Exploit-DB · Church of Malware · Misc Cheatsheets

**5,082 indexed pages · 31 sources**

---

## Features

**Search** — `Ctrl+K` from anywhere. Searches all sources at once and ranks by relevance.

**Variables** — Every code block uses `<placeholders>` like `<target-ip>`, `<domain>`, `<username>`. Fill them in once and they populate across every block for the session.

**Distro toggle** — Switch Impacket syntax between Kali (`impacket-secretsdump`), Exegol (`secretsdump.py`), and Script (`python3 secretsdump.py`).

**Tools toggle** — Swap between Python Impacket and Go-style equivalents site-wide.

**Themes** — Retro, Tokyo Night, Catppuccin Mocha, Catppuccin Latte, Rosé Pine, Dracula, Nord, Gruvbox, Hacker Green, Wonderland.

**Favorites** — Star any page with the ☆ button next to the title. Favorites persist in localStorage.

**Mobile friendly** — Works on phone. Sidebar drawer, full-width search, touch-sized targets.

---

## Offline maintenance scripts

Only local-data transformation scripts are shipped. The release contains no
download, scrape, clone, update, or fetch utilities.

| Script | Purpose |
|---|---|
| `scripts/rebuild_sources.py` | Rebuild processed content JSON from already-bundled source markdown |
| `scripts/rebuild_nav.py` | Rebuild navigation JSON from bundled content |
| `scripts/enhance_search_index.py` | Enhance the bundled local search index |

---

## Credits

This project stands entirely on the work of others. Every page traces back to researchers and developers who shared their knowledge publicly.

| Project | Author |
|---|---|
| [BloodHound](https://github.com/SpecterOps/BloodHound) | SpecterOps |
| [The Hacker Recipes](https://github.com/ShutdownRepo/The-Hacker-Recipes) | ShutdownRepo |
| [HackTricks](https://github.com/HackTricks-wiki/hacktricks) | carlospolop |
| [HackTricks Cloud](https://github.com/HackTricks-wiki/hacktricks-cloud) | HackTricks-wiki |
| [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings) | swisskyrepo |
| [InternalAllTheThings](https://github.com/swisskyrepo/InternalAllTheThings) | swisskyrepo |
| [HardwareAllTheThings](https://github.com/swisskyrepo/HardwareAllTheThings) | swisskyrepo |
| [NetExec Wiki](https://github.com/Pennyw0rth/NetExec-Wiki) | Pennyw0rth |
| [GTFOBins](https://github.com/GTFOBins/GTFOBins.github.io) | GTFOBins |
| [LOLBAS](https://github.com/LOLBAS-Project/LOLBAS) | LOLBAS-Project |
| [WADComs](https://github.com/WADComs/WADComs.github.io) | WADComs |
| [Certipy](https://github.com/ly4k/Certipy) | ly4k |
| [bloodyAD](https://github.com/CravateRouge/bloodyAD) | CravateRouge |
| [Impacket](https://github.com/fortra/impacket) | fortra |
| [Rubeus](https://github.com/GhostPack/Rubeus) | GhostPack |
| [Mimikatz](https://github.com/gentilkiwi/mimikatz) | gentilkiwi |
| [Ligolo-ng](https://github.com/nicocha30/ligolo-ng) | nicocha30 |
| [Sliver C2](https://github.com/BishopFox/sliver) | BishopFox |
| [Adaptix C2](https://adaptix-framework.gitbook.io/adaptix-framework/) | Adaptix Framework |
| [goexec](https://github.com/FalconOpsLLC/goexec) | FalconOpsLLC |
| [Metasploit](https://github.com/rapid7/metasploit-framework) | rapid7 |
| [All About Bug Bounty](https://github.com/daffainfo/AllAboutBugBounty) | daffainfo |
| [Church of Malware](https://churchofmalware.org) | 0xXyc et al. |

---

Built by vibe coding with Claude and too much coffee ☕
