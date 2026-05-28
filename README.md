# p3ta-tricks

> If this saves you time on an engagement, please ⭐ star the repo — it helps more than you think.
>
> Feature requests, bugs, and ideas → Discord: **p3ta00**

---

A fast, searchable pentest reference that pulls attack techniques, tool syntax, and post-exploitation chains from the best open-source security wikis into one place. No more tab switching mid-engagement.

**Live site → [p3ta-tricks.com](https://p3ta-tricks.com)**

---

## Offline Mode

This repo ships fully air-gapped. Every image that can be locally hosted is included:

- **`static/img/adaptix/`** — 194 Adaptix C2 screenshots scraped from GitBook CDN
- **`static/img/external/`** — 190 third-party images (blogspot, Medium, GitHub user-attachments, OWASP, CyberArk, Palo Alto, PortSwigger, etc.) downloaded and locally hosted
- **`sources/sliver-docs/images/`** — Sliver C2 diagrams
- GitHub-raw images (HackTricks, Hacker Recipes, PATT, etc.) are served via `_rewrite_images()` at request time — requires internet in online mode, served from `sources/` locally in offline mode

17 images remain external (Google Slides auth-gated or deleted from origin servers) — noted in the home page disclaimer.

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

The installer handles Python venv, dependencies, asset verification, and external image download (idempotent — skips already-cached images).

---

## What's in it

BloodHound · HackTricks · HackTricks Cloud · The Hacker Recipes · PayloadsAllTheThings · InternalAllTheThings · HardwareAllTheThings · GTFOBins · LOLBAS · WADComs · NetExec · Impacket · Certipy · bloodyAD · Rubeus · Mimikatz · Ligolo-ng · Sliver · Adaptix C2 · goexec · Metasploit · All About Bug Bounty · Exploit-DB · Church of Malware · Misc Cheatsheets

**3,383 pages · 31 sources**

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

## Scripts

| Script | Purpose |
|---|---|
| `scripts/fetch_adaptix_images.py` | Scrape GitBook CDN and download all Adaptix screenshots locally |
| `scripts/fetch_external_images.py` | Download third-party images embedded in source docs and host locally |
| `scripts/rebuild_sources.py` | Rebuild processed content JSON from source markdown |

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
