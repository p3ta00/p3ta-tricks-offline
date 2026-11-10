#!/usr/bin/env python3
"""Generate file-level provenance and checksums for the binary bundle."""
from pathlib import Path
import hashlib, json

ROOT = Path(__file__).resolve().parent.parent
BIN = ROOT / "binaries"
versions = json.loads((BIN / ".versions.json").read_text(encoding="utf-8"))
known = {
    "chisel": {"source": "https://github.com/jpillora/chisel/releases/tag/v1.12.0"},
    "reverse-ssh": {"source": "https://github.com/NHAS/reverse_ssh/releases/tag/v2.8.1"},
    "PEASS-ng": {"source": "https://github.com/peass-ng/PEASS-ng/releases/tag/20261109-f4fdadd7"},
    "PrivescCheck": {"source": "https://github.com/itm4n/PrivescCheck/releases/tag/2026.10.28-1"},
}
files = []
for path in sorted(BIN.rglob("*")):
    if not path.is_file() or path.name in {".provenance.json"}:
        continue
    rel = path.relative_to(BIN).as_posix()
    family = rel.split("/", 1)[0]
    files.append({
        "path": rel,
        "family": family,
        "version": versions.get(family, "legacy/unversioned"),
        "source": known.get(family, {}).get("source", "legacy bundle; upstream URL not recorded"),
        "size": path.stat().st_size,
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    })
(BIN / ".provenance.json").write_text(json.dumps({"schema": 1, "files": files}, indent=2) + "\n", encoding="utf-8")
print(f"Recorded {len(files)} binary files")
