#!/bin/bash
# Rebuild the self-contained 3D viewer HTML after editing JS files.
set -euo pipefail
cd "$(dirname "$0")/../assets/three"

python3 - <<'PY'
from pathlib import Path

html = Path('index.html').read_text()
three = Path('three.min.js').read_text()
orbit = Path('OrbitControls.js').read_text()
premium_bed = Path('premium_bed.js').read_text()
renderer = Path('room_renderer.js').read_text()

bundle = (
    html
    .replace('<!-- INJECT_THREE -->', f'<script>\n{three}\n</script>')
    .replace('<!-- INJECT_ORBIT -->', f'<script>\n{orbit}\n</script>')
    .replace('<!-- INJECT_PREMIUM_BED -->', f'<script>\n{premium_bed}\n</script>')
    .replace('<!-- INJECT_RENDERER -->', f'<script>\n{renderer}\n</script>')
)

Path('viewer.html').write_text(bundle)
print(f'Built viewer.html ({len(bundle)} bytes)')
PY
