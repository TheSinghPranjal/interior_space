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
premium_flower_pot = Path('premium_flower_pot.js').read_text()
premium_dining_table = Path('premium_dining_table.js').read_text()
premium_table = Path('premium_table.js').read_text()
cabinet_helpers = Path('cabinet_helpers.js').read_text()
premium_storage_unit = Path('premium_storage_unit.js').read_text()
premium_fridge = Path('premium_fridge.js').read_text()
premium_washing_machine = Path('premium_washing_machine.js').read_text()
premium_shoe_rack = Path('premium_shoe_rack.js').read_text()
premium_sink = Path('premium_sink.js').read_text()
premium_chair = Path('premium_chair.js').read_text()
premium_chimney = Path('premium_chimney.js').read_text()
premium_ac_unit = Path('premium_ac_unit.js').read_text()
premium_catalog = Path('premium_catalog.js').read_text()
renderer = Path('room_renderer.js').read_text()

bundle = (
    html
    .replace('<!-- INJECT_THREE -->', f'<script>\n{three}\n</script>')
    .replace('<!-- INJECT_ORBIT -->', f'<script>\n{orbit}\n</script>')
    .replace('<!-- INJECT_PREMIUM_BED -->', f'<script>\n{premium_bed}\n</script>')
    .replace('<!-- INJECT_PREMIUM_FLOWER_POT -->', f'<script>\n{premium_flower_pot}\n</script>')
    .replace('<!-- INJECT_PREMIUM_DINING_TABLE -->', f'<script>\n{premium_dining_table}\n</script>')
    .replace('<!-- INJECT_PREMIUM_TABLE -->', f'<script>\n{premium_table}\n</script>')
    .replace('<!-- INJECT_CABINET_HELPERS -->', f'<script>\n{cabinet_helpers}\n</script>')
    .replace('<!-- INJECT_PREMIUM_STORAGE_UNIT -->', f'<script>\n{premium_storage_unit}\n</script>')
    .replace('<!-- INJECT_PREMIUM_FRIDGE -->', f'<script>\n{premium_fridge}\n</script>')
    .replace('<!-- INJECT_PREMIUM_WASHING_MACHINE -->', f'<script>\n{premium_washing_machine}\n</script>')
    .replace('<!-- INJECT_PREMIUM_SHOE_RACK -->', f'<script>\n{premium_shoe_rack}\n</script>')
    .replace('<!-- INJECT_PREMIUM_SINK -->', f'<script>\n{premium_sink}\n</script>')
    .replace('<!-- INJECT_PREMIUM_CHAIR -->', f'<script>\n{premium_chair}\n</script>')
    .replace('<!-- INJECT_PREMIUM_CHIMNEY -->', f'<script>\n{premium_chimney}\n</script>')
    .replace('<!-- INJECT_PREMIUM_AC_UNIT -->', f'<script>\n{premium_ac_unit}\n</script>')
    .replace('<!-- INJECT_PREMIUM_CATALOG -->', f'<script>\n{premium_catalog}\n</script>')
    .replace('<!-- INJECT_RENDERER -->', f'<script>\n{renderer}\n</script>')
)

Path('viewer.html').write_text(bundle)
print(f'Built viewer.html ({len(bundle)} bytes)')
PY
