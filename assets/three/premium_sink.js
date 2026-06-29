/* global THREE */
(function (global) {
  'use strict';

  const FT = 0.3048;

  function rBox(w, h, d, r, mat) {
    r = Math.min(r, w / 2, h / 2, d / 2);
    const g = new THREE.BoxGeometry(w, h, d, 6, 6, 6);
    const p = g.attributes.position;
    for (let i = 0; i < p.count; i++) {
      let x = p.getX(i), y = p.getY(i), z = p.getZ(i);
      const sx = Math.sign(x) || 1, sy = Math.sign(y) || 1, sz = Math.sign(z) || 1;
      const cx = sx * (w / 2 - r), cy = sy * (h / 2 - r), cz = sz * (d / 2 - r);
      const dx = x - cx, dy = y - cy, dz = z - cz;
      const len = Math.sqrt(dx * dx + dy * dy + dz * dz) || 1;
      p.setXYZ(i, cx + dx / len * r, cy + dy / len * r, cz + dz / len * r);
    }
    p.needsUpdate = true;
    g.computeVertexNormals();
    return new THREE.Mesh(g, mat);
  }

  function mkMat(color, emissive, rough, metal, eInt) {
    return new THREE.MeshStandardMaterial({
      color, emissive, emissiveIntensity: eInt ?? 0.18,
      roughness: rough, metalness: metal,
      envMapIntensity: 1.4,
    });
  }

  const WHITE   = 0xf5f5f3, WHITE_E  = 0x909090;
  const CERAMIC = 0xfbfbf9, CER_E    = 0xb8b8b6;
  const CHROME  = 0xe0e4e8, CHR_E    = 0x9098a0;
  const DARK    = 0x1a1a1a, DARK_E   = 0x060606;
  const BOWL_IN = 0xd8dce0, BOWL_E   = 0x7880888;

  /* ══════════════════════════════════════
     COUNTER TOP with real CUT-OUT hole for basin
  ══════════════════════════════════════ */
  function buildCounterWithHole(group, fw, fd, topY, cerMat) {
    const CT  = 0.032 * FT;   // counter thickness
    const RIM = 0.028 * FT;   // rim border width
    const BW  = fw - RIM * 2; // bowl opening width
    const BD  = fd - RIM * 2; // bowl opening depth

    // Build counter as 4 L-shaped strips around the hole (left, right, front, back)
    // This creates a real opening you can see INTO

    const strips = [
      // left strip
      { w: RIM, h: CT, d: fd, x: -(fw / 2 - RIM / 2), z: 0 },
      // right strip
      { w: RIM, h: CT, d: fd, x: (fw / 2 - RIM / 2),  z: 0 },
      // front strip (between left and right)
      { w: BW,  h: CT, d: RIM, x: 0, z: fd / 2 - RIM / 2 },
      // back strip
      { w: BW,  h: CT, d: RIM, x: 0, z: -(fd / 2 - RIM / 2) },
    ];

    strips.forEach(s => {
      const m = rBox(s.w, s.h, s.d, 0.006 * FT, cerMat);
      m.position.set(s.x, topY + CT / 2, s.z);
      group.add(m);
    });

    // Rim edge highlight (subtle bevel sheen on top face of rim)
    const sheenMat = new THREE.MeshBasicMaterial({
      color: 0xffffff, transparent: true, opacity: 0.12, depthWrite: false
    });
    const rimSheen = new THREE.Mesh(new THREE.PlaneGeometry(fw * 0.98, fd * 0.98), sheenMat);
    rimSheen.rotation.x = -Math.PI / 2;
    rimSheen.position.set(0, topY + CT + 0.0001, 0);
    group.add(rimSheen);
  }

  /* ══════════════════════════════════════
     BASIN — deep visible bowl
  ══════════════════════════════════════ */
  function buildBasin(group, fw, fd, topY, cerMat, bowlMat, chrMat) {
    const RIM   = 0.028 * FT;
    const BW    = fw - RIM * 2;
    const BD    = fd - RIM * 2;
    const DEPTH = 0.18 * FT;
    const WT    = 0.016 * FT;
    const BR    = 0.008 * FT;

    const floorY = topY - DEPTH + WT;

    // Bowl floor
    const floor = rBox(BW - WT * 2, WT, BD - WT * 2, BR, bowlMat);
    floor.position.set(0, floorY, 0);
    group.add(floor);

    // Bowl walls (4)
    [
      { w: BW,        h: DEPTH, d: WT,   x: 0,              z: BD / 2 - WT / 2 },  // front
      { w: BW,        h: DEPTH, d: WT,   x: 0,              z: -(BD / 2 - WT / 2) },// back
      { w: WT,        h: DEPTH, d: BD,   x: -(BW / 2 - WT / 2), z: 0 },             // left
      { w: WT,        h: DEPTH, d: BD,   x: BW / 2 - WT / 2,    z: 0 },             // right
    ].forEach(s => {
      const m = rBox(s.w, s.h, s.d, BR, bowlMat);
      m.position.set(s.x, topY - DEPTH / 2, s.z);
      group.add(m);
    });

    // Inner floor — slightly darker/wetter look
    const innerMat = mkMat(0xc8ccce, 0x707478, 0.08, 0.06, 0.18);
    innerMat.envMapIntensity = 0.8;
    const inner = new THREE.Mesh(
      new THREE.PlaneGeometry(BW - WT * 2.4, BD - WT * 2.4), innerMat);
    inner.rotation.x = -Math.PI / 2;
    inner.position.set(0, floorY + WT * 0.52, 0);
    group.add(inner);

    // Subtle inner wall gradient shading (AO panels)
    const aoMat = new THREE.MeshBasicMaterial({
      color: 0x000000, transparent: true, opacity: 0.18, depthWrite: false
    });
    [
      { w: BW - WT * 2, h: 0.006 * FT, x: 0, z: BD / 2 - WT * 1.1 },
      { w: BW - WT * 2, h: 0.006 * FT, x: 0, z: -(BD / 2 - WT * 1.1) },
    ].forEach(c => {
      const crease = new THREE.Mesh(new THREE.PlaneGeometry(c.w, c.h), aoMat);
      crease.rotation.x = -Math.PI / 2;
      crease.position.set(c.x, floorY + WT * 0.53, c.z);
      group.add(crease);
    });

    // Drain ring
    const drainMat = mkMat(CHROME, CHR_E, 0.08, 0.96, 0.22);
    const drain = new THREE.Mesh(
      new THREE.TorusGeometry(0.022 * FT, 0.005 * FT, 12, 40), drainMat);
    drain.rotation.x = -Math.PI / 2;
    drain.position.set(0, floorY + WT * 0.55, BD * 0.05);
    group.add(drain);

    const drainHole = new THREE.Mesh(
      new THREE.CircleGeometry(0.017 * FT, 32),
      new THREE.MeshStandardMaterial({ color: 0x080808, roughness: 0.9, metalness: 0 }));
    drainHole.rotation.x = -Math.PI / 2;
    drainHole.position.set(0, floorY + WT * 0.56, BD * 0.05);
    group.add(drainHole);

    // Specular water-line gloss on bowl floor
    const glossMat = new THREE.MeshBasicMaterial({
      color: 0xffffff, transparent: true, opacity: 0.08, depthWrite: false
    });
    const gloss = new THREE.Mesh(
      new THREE.PlaneGeometry(BW * 0.55, BD * 0.18), glossMat);
    gloss.rotation.x = -Math.PI / 2;
    gloss.position.set(-BW * 0.12, floorY + WT * 0.57, 0);
    group.add(gloss);
  }

  /* ══════════════════════════════════════
     SMOOTH GOOSENECK FAUCET — TubeGeometry along CatmullRomCurve3
  ══════════════════════════════════════ */
  function buildFaucet(group, x, baseY, z, chrMat, dkMat) {
    // Base plate
    const base = new THREE.Mesh(
      new THREE.CylinderGeometry(0.038 * FT, 0.043 * FT, 0.022 * FT, 32), chrMat);
    base.position.set(x, baseY + 0.011 * FT, z);
    group.add(base);

    // Lower stem collar
    const collar = new THREE.Mesh(
      new THREE.CylinderGeometry(0.022 * FT, 0.028 * FT, 0.018 * FT, 24), chrMat);
    collar.position.set(x, baseY + 0.030 * FT, z);
    group.add(collar);

    // ── Smooth gooseneck using CatmullRomCurve3 + TubeGeometry ──
    // Points define the path: rises vertically, curves forward, droops down
    const H  = 0.38 * FT;   // total rise height
    const OV = 0.09 * FT;   // forward overhang
    const DR = 0.04 * FT;   // downward droop at spout

    const curvePoints = [
      new THREE.Vector3(x, baseY + 0.038 * FT, z),
      new THREE.Vector3(x, baseY + H * 0.25,   z),
      new THREE.Vector3(x, baseY + H * 0.55,   z),
      new THREE.Vector3(x, baseY + H * 0.78,   z - OV * 0.2),
      new THREE.Vector3(x, baseY + H * 0.92,   z - OV * 0.6),
      new THREE.Vector3(x, baseY + H,           z - OV),
      new THREE.Vector3(x, baseY + H - DR,      z - OV * 1.3),
      new THREE.Vector3(x, baseY + H - DR * 2,  z - OV * 1.5),
    ];

    const curve = new THREE.CatmullRomCurve3(curvePoints);

    // Main tube
    const tubeGeo = new THREE.TubeGeometry(curve, 60, 0.018 * FT, 20, false);
    const tube = new THREE.Mesh(tubeGeo, chrMat);
    group.add(tube);

    // Spout end cap (aerator housing)
    const spoutTip = curvePoints[curvePoints.length - 1];
    const aeratorHousing = new THREE.Mesh(
      new THREE.CylinderGeometry(0.018 * FT, 0.022 * FT, 0.032 * FT, 20), chrMat);
    aeratorHousing.position.copy(spoutTip);
    aeratorHousing.position.y -= 0.016 * FT;
    group.add(aeratorHousing);

    const aerator = new THREE.Mesh(
      new THREE.CylinderGeometry(0.013 * FT, 0.014 * FT, 0.016 * FT, 16), dkMat);
    aerator.position.copy(spoutTip);
    aerator.position.y -= 0.034 * FT;
    group.add(aerator);

    // Lever handle (mounted at mid-curve height on side)
    const leverY  = baseY + H * 0.40;
    const leverMat = chrMat;

    // Ball joint where lever meets tube
    const ball = new THREE.Mesh(new THREE.SphereGeometry(0.020 * FT, 20, 16), leverMat);
    ball.position.set(x, leverY, z);
    group.add(ball);

    // Horizontal lever arm
    const lever = new THREE.Mesh(
      new THREE.CylinderGeometry(0.009 * FT, 0.009 * FT, 0.110 * FT, 14), leverMat);
    lever.rotation.z = Math.PI / 2;
    lever.position.set(x + 0.055 * FT, leverY, z);
    group.add(lever);

    // Lever end cap
    const lCap = new THREE.Mesh(new THREE.SphereGeometry(0.011 * FT, 14, 12), leverMat);
    lCap.position.set(x + 0.112 * FT, leverY, z);
    group.add(lCap);

    // Subtle highlight stripe along tube
    const hlMat = new THREE.MeshBasicMaterial({
      color: 0xffffff, transparent: true, opacity: 0.20, depthWrite: false
    });

    // specular highlight tube (slightly thinner, offset)
    const hlCurvePoints = curvePoints.map(p =>
      new THREE.Vector3(p.x - 0.008 * FT, p.y, p.z + 0.010 * FT));
    const hlCurve = new THREE.CatmullRomCurve3(hlCurvePoints);
    const hlGeo   = new THREE.TubeGeometry(hlCurve, 60, 0.004 * FT, 8, false);
    const hl      = new THREE.Mesh(hlGeo, hlMat);
    group.add(hl);
  }

  /* ══ VERTICAL BAR HANDLE ══ */
  function addBarHandle(group, x, y, z, chrMat) {
    const len = 0.095 * FT, r = 0.009 * FT;
    const bar = new THREE.Mesh(new THREE.CylinderGeometry(r, r, len, 16), chrMat);
    bar.position.set(x, y, z);
    group.add(bar);
    [-1, 1].forEach(s => {
      const cap = new THREE.Mesh(new THREE.SphereGeometry(r * 1.1, 12, 10), chrMat);
      cap.position.set(x, y + s * len * 0.5, z);
      group.add(cap);
      const mnt = new THREE.Mesh(
        new THREE.CylinderGeometry(r * 0.55, r * 0.55, 0.020 * FT, 10), chrMat);
      mnt.rotation.x = Math.PI / 2;
      mnt.position.set(x, y + s * len * 0.28, z - 0.013 * FT);
      group.add(mnt);
    });
  }

  /* ════════════════════════════════════════
     MAIN BUILDER
  ════════════════════════════════════════ */
  function buildSink(renderer, item, _textureUrl) {
    const fw = item.width  * FT;
    const fh = item.height * FT;
    const fd = item.depth  * FT;
    const group = new THREE.Group();

    // ── HDR tone mapping on renderer ──
    if (renderer) {
      renderer.toneMapping = THREE.ACESFilmicToneMapping;
      renderer.toneMappingExposure = 1.15;
      renderer.outputColorSpace = THREE.SRGBColorSpace;
      renderer.shadowMap.enabled = true;
      renderer.shadowMap.type    = THREE.PCFSoftShadowMap;
    }

    const cabMat = mkMat(WHITE,   WHITE_E,  0.22, 0.04, 0.20);
    const cerMat = mkMat(CERAMIC, CER_E,    0.08, 0.05, 0.22);
    const bowMat = mkMat(BOWL_IN, BOWL_E,   0.10, 0.04, 0.20);
    const chrMat = mkMat(CHROME,  CHR_E,    0.06, 0.95, 0.24);
    const dkMat  = mkMat(DARK,    DARK_E,   0.50, 0.55, 0.12);

    // Give chrome clearcoat-like feel
    chrMat.envMapIntensity = 2.2;

    const wall    = 0.018 * FT;
    const toeH    = fh * 0.08;
    const cabiH   = fh - toeH;
    const doorD   = 0.022 * FT;
    const doorGap = 0.005 * FT;
    const CT      = 0.032 * FT;   // counter thickness

    /* ── TOE KICK ── */
    const toeDepth = fd * 0.16;
    const toe = rBox(fw - wall * 2, toeH, toeDepth, 0.005 * FT, dkMat);
    toe.position.set(0, toeH * 0.5, fd / 2 - toeDepth * 0.5);
    group.add(toe);

    /* ── CABINET BODY ── */
    const cab = rBox(fw, cabiH, fd, 0.010 * FT, cabMat);
    cab.position.set(0, toeH + cabiH * 0.5, 0);
    group.add(cab);

    /* ── TWO DOORS ── */
    const dw     = (fw - wall - doorGap) / 2;
    const dh     = cabiH - wall * 2.0;
    const dBaseY = toeH + wall * 1.0;
    const dFaceZ = fd / 2 + doorD * 0.5;

    [-1, 1].forEach(side => {
      const cx = side * (dw / 2 + doorGap / 2 + wall / 2);
      const door = rBox(dw, dh, doorD, 0.008 * FT, cabMat);
      door.position.set(cx, dBaseY + dh * 0.5, dFaceZ);
      group.add(door);

      const sheen = new THREE.Mesh(
        new THREE.PlaneGeometry(dw * 0.88, dh * 0.88),
        new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.06, depthWrite: false }));
      sheen.position.set(cx, dBaseY + dh * 0.5, dFaceZ + doorD * 0.51);
      group.add(sheen);

      const hx = cx - side * dw * 0.24;
      addBarHandle(group, hx, dBaseY + dh * 0.52, dFaceZ + doorD + 0.013 * FT, chrMat);
    });

    // Center seam
    const seam = rBox(doorGap, dh, doorD * 0.65, 0.001 * FT, dkMat);
    seam.position.set(0, dBaseY + dh * 0.5, dFaceZ);
    group.add(seam);

    /* ── COUNTER TOP with real HOLE ── */
    const cabiTopY = toeH + cabiH;
    buildCounterWithHole(group, fw, fd, cabiTopY, cerMat);

    /* ── DEEP BASIN ── */
    buildBasin(group, fw, fd, cabiTopY + CT, bowMat, bowMat, chrMat);

    /* ── FAUCET — placed at back, well above basin level ── */
    const faucetBaseY = cabiTopY + CT;
    const faucetZ     = -fd * 0.26;
    buildFaucet(group, 0, faucetBaseY, faucetZ, chrMat, dkMat);

    /* ── Face sheen ── */
    const faceSheen = new THREE.Mesh(
      new THREE.PlaneGeometry(fw * 0.86, cabiH * 0.84),
      new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.04, depthWrite: false }));
    faceSheen.position.set(0, toeH + cabiH * 0.5, fd / 2 + doorD + 0.001 * FT);
    group.add(faceSheen);

    /* ── Floor AO shadow ── */
    const ao = new THREE.Mesh(
      new THREE.CircleGeometry(Math.max(fw, fd) * 0.62, 64),
      new THREE.MeshBasicMaterial({ color: 0x000000, transparent: true, opacity: 0.14, depthWrite: false }));
    ao.rotation.x = -Math.PI / 2;
    ao.position.y = 0.001;
    group.add(ao);

    group.traverse(m => {
      if (!m.isMesh) return;
      m.castShadow    = true;
      m.receiveShadow = true;
    });

    return group;
  }

  global.PremiumSinkBuilder = { build: buildSink };

})(typeof window !== 'undefined' ? window : global);