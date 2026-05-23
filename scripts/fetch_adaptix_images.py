#!/usr/bin/env python3
"""
Download Adaptix C2 images from GitBook CDN.

For each source markdown file containing <!-- gitbook-image:ID --> markers:
  1. Fetch the corresponding GitBook page
  2. Extract content image URLs in order
  3. Download images to static/img/adaptix/
  4. Patch the source markdown replacing markers with local paths
  5. Re-run rebuild_sources.py for adaptix to update processed JSON

Usage:
    python3 scripts/fetch_adaptix_images.py
"""
import re, json, sys, time, urllib.parse, urllib.request, hashlib
from pathlib import Path

ROOT        = Path(__file__).parent.parent
SOURCES     = ROOT / "sources" / "adaptix"
IMG_OUT     = ROOT / "static" / "img" / "adaptix"
GITBOOK_BASE = "https://adaptix-framework.gitbook.io/adaptix-framework/"
UA          = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/120.0.0.0"

IMG_OUT.mkdir(parents=True, exist_ok=True)

# Regex to find gitbook-image markers in markdown
MARKER_RE = re.compile(r'!\[([^\]]*)\]\(<!-- gitbook-image:([^)]*?) -->\)')

# Regex to extract content images from GitBook HTML (space-specific)
# The space ID for Adaptix Framework
SPACE_PATTERN = re.compile(
    r'src="(https://adaptix-framework\.gitbook\.io/adaptix-framework/~gitbook/image\?url=[^"]+S8p8XLFtLmf0NkofQvoa[^"]+)"',
    re.I
)


def md_path_to_gitbook_url(md_path: str) -> str:
    """Convert source markdown relative path to GitBook page URL."""
    # Strip .md extension, convert to URL path
    path = md_path.replace('\\', '/')
    if path.endswith('.md'):
        path = path[:-3]
    # GitBook uses lowercase paths
    path = path.lower()
    # Handle README -> root
    if path.endswith('/readme'):
        path = path[:-7]
    return GITBOOK_BASE + path.lstrip('/')


def fetch_page(url: str) -> str:
    req = urllib.request.Request(url, headers={
        'User-Agent': UA,
        'Accept': 'text/html,application/xhtml+xml',
    })
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            return r.read().decode('utf-8', errors='ignore')
    except Exception as e:
        print(f"  FETCH ERROR: {e}")
        return ''


def extract_content_images(html: str) -> list:
    """Extract unique content image proxy URLs from GitBook HTML."""
    seen_decoded = set()
    results = []
    for m in SPACE_PATTERN.finditer(html):
        proxy_url = m.group(1).replace('&amp;', '&')
        # Decode the inner URL to get the canonical identifier
        qs = urllib.parse.parse_qs(urllib.parse.urlparse(proxy_url).query)
        inner = qs.get('url', [''])[0]
        if inner and inner not in seen_decoded:
            seen_decoded.add(inner)
            results.append((proxy_url, inner))
    return results


def download_image(proxy_url: str, dest: Path) -> bool:
    req = urllib.request.Request(proxy_url, headers={'User-Agent': UA})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            data = r.read()
        # Verify it's actually an image
        if data[:4] in (b'\x89PNG', b'\xff\xd8\xff', b'GIF8', b'RIFF', b'<svg'):
            dest.write_bytes(data)
            return True
        if data[:4] == b'\x89PNG' or b'PNG' in data[:16]:
            dest.write_bytes(data)
            return True
        # Try checking content-type via header
        print(f"  WARN: unexpected content ({data[:16]!r}) at {dest.name}")
        return False
    except Exception as e:
        print(f"  DOWNLOAD ERROR: {e}")
        return False


def process_md_file(md_path: Path, rel_path: str) -> bool:
    """Fetch GitBook page, download images, patch markdown. Returns True if changed."""
    text = md_path.read_text(encoding='utf-8', errors='ignore')
    markers = MARKER_RE.findall(text)
    if not markers:
        return False

    gb_url = md_path_to_gitbook_url(rel_path)
    print(f"\n[{rel_path}] {len(markers)} markers → {gb_url}")

    html = fetch_page(gb_url)
    if not html:
        return False

    images = extract_content_images(html)
    print(f"  Found {len(images)} images on page")

    if not images:
        return False

    # If marker count doesn't match image count, use available images (positional)
    matched = min(len(markers), len(images))

    # Build replacement map: for each marker, get the image
    replacements = []
    for i, (alt, marker_id) in enumerate(markers):
        if i >= len(images):
            break
        proxy_url, inner_url = images[i]

        # Build a stable filename from the inner URL
        upload_id = re.search(r'uploads/([^/]+)/', inner_url)
        if upload_id:
            img_id = upload_id.group(1)
        else:
            img_id = hashlib.md5(inner_url.encode()).hexdigest()[:12]

        # Guess extension from URL
        ext = 'png'
        fname_match = re.search(r'/([^/?]+\.(png|jpg|gif|webp|svg))', inner_url, re.I)
        if fname_match:
            ext = fname_match.group(2).lower()

        page_stem = md_path.stem.replace(' ', '-')
        local_name = f"{page_stem}_{i+1}_{img_id}.{ext}"
        dest = IMG_OUT / local_name
        local_url = f"/static/img/adaptix/{local_name}"

        if dest.exists():
            print(f"  [{i+1}] CACHED: {local_name}")
            downloaded = True
        else:
            print(f"  [{i+1}] Downloading: {local_name}")
            downloaded = download_image(proxy_url, dest)
            time.sleep(0.3)  # polite delay

        if downloaded:
            replacements.append((alt, marker_id, local_url, alt))

    if not replacements:
        return False

    # Patch the markdown — replace each marker with local img path
    new_text = text
    for alt, marker_id, local_url, orig_alt in replacements:
        old = f'![{alt}](<!-- gitbook-image:{marker_id} -->)'
        new = f'![{orig_alt or "screenshot"}]({local_url})'
        new_text = new_text.replace(old, new, 1)

    if new_text != text:
        md_path.write_text(new_text, encoding='utf-8')
        print(f"  PATCHED: {md_path.name}")
        return True

    return False


def collect_all_md_files() -> list:
    """Walk the adaptix source dir and return (md_path, rel_path) for files with markers."""
    results = []
    for md in sorted(SOURCES.rglob('*.md')):
        text = md.read_text(encoding='utf-8', errors='ignore')
        if MARKER_RE.search(text):
            rel = str(md.relative_to(SOURCES)).replace('\\', '/')
            results.append((md, rel))
    return results


def main():
    files = collect_all_md_files()
    print(f"Found {len(files)} adaptix markdown files with gitbook-image markers")

    changed = 0
    for md_path, rel_path in files:
        if process_md_file(md_path, rel_path):
            changed += 1

    print(f"\n{'='*60}")
    print(f"Done. Patched {changed}/{len(files)} files.")

    if changed > 0:
        print("\nRebuilding adaptix processed content...")
        import subprocess, sys
        result = subprocess.run(
            [sys.executable, str(ROOT / 'scripts' / 'rebuild_sources.py'), 'adaptix'],
            cwd=ROOT
        )
        if result.returncode == 0:
            print("Rebuild complete.")
        else:
            print("Rebuild failed — run manually: python3 scripts/rebuild_sources.py adaptix")


if __name__ == '__main__':
    main()
