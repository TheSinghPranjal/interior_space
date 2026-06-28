/* global THREE */
(function (global) {
  'use strict';

  const FT = 0.3048;

  /* ── rounded box ── */
  function rBox(w, h, d, r, mat) {
    r = Math.min(r, w / 2, h / 2, d / 2);
    const g = new THREE.BoxGeometry(w, h, d, 4, 4, 4);
    const p = g.attributes.position;
    for (let i = 0; i < p.count; i++) {
      let x = p.getX(i), y = p.getY(i), z = p.getZ(i);
      const sx = Math.sign(x), sy = Math.sign(y), sz = Math.sign(z);
      const cx = sx*(w/2-r), cy = sy*(h/2-r), cz = sz*(d/2-r);
      const dx = x-cx, dy = y-cy, dz = z-cz;
      const len = Math.sqrt(dx*dx+dy*dy+dz*dz)||1;
      p.setXYZ(i, cx+dx/len*r, cy+dy/len*r, cz+dz/len*r);
    }
    p.needsUpdate = true;
    g.computeVertexNormals();
    return new THREE.Mesh(g, mat);
  }

  /* ── material with emissive ── */
  function mkMat(color, emissive, rough, metal, eInt) {
    return new THREE.MeshStandardMaterial({
      color, emissive, emissiveIntensity: eInt ?? 0.18,
      roughness: rough, metalness: metal,
    });
  }

  /* ── colours ── */
  const WHITE     = 0xf4f4f2,  WHITE_E  = 0x9a9a98;
  const OFFWHITE  = 0xe8e8e6,  OW_E     = 0x909090;
  const CERAMIC   = 0xfafaf8,  CER_E    = 0xaaaaaa;
  const CHROME    = 0xd8dcdf,  CHR_E    = 0x909498;
  const DARK      = 0x222222,  DARK_E   = 0x080808;
  const BASIN_INT = 0xf0f4f8,  BAS_E    = 0xb0b8c0; // basin interior (slight blue-white)

  /* ── build a basin shape: wide rectangular tub with curved front ── */
  function buildBasin(group, fw, fd, basinY, ceramicMat, interiorMat, chromeMat) {
    const bw  = fw * 0.98;
    const bd  = fd * 0.90;
    const bh  = 0.095 * FT;   // basin total height
    const wall= 0.018 * FT;   // basin wall thickness

    // ── outer ceramic shell (the whole basin body) ──
    // We build it as a rounded box sitting on top of counter
    const outer = rBox(bw, bh, bd, 0.022*FT, ceramicMat);
    outer.position.set(0, basinY + bh*0.5, fd*0.05);
    group.add(outer);

    // ── front curved apron (the distinctive belly curve of the reference) ──
    // Achieved by scaling a half-cylinder
    const apronGeo = new THREE.CylinderGeometry(bh*0.55, bh*0.55, bw, 48, 1, true, -Math.PI*0.5, Math.PI);
    const apron = new THREE.Mesh(apronGeo, ceramicMat);
    apron.rotation.z = Math.PI / 2;   // axis along X
    apron.rotation.y = Math.PI;
    apron.scale.set(1, 0.55, 0.9);
    apron.position.set(0, basinY + bh*0.28, fd*0.5 - 0.002*FT);
    group.add(apron);

    // ── interior bowl (recessed, slightly blue-white) ──
    const iw = bw - wall*2;
    const id = bd - wall*2;
    const ih = bh - wall;    // depth of bowl

    // interior floor
    const floor = new THREE.Mesh(new THREE.PlaneGeometry(iw * 0.80, id * 0.70), interiorMat);
    floor.rotation.x = -Math.PI / 2;
    floor.position.set(0, basinY + wall + 0.001*FT, fd*0.05);
    group.add(floor);

    // interior walls (4 planes giving depth)
    // front inner wall (slight slope)
    const fwall = new THREE.Mesh(new THREE.PlaneGeometry(iw*0.80, ih*0.88), interiorMat);
    fwall.rotation.x = Math.PI*0.08;
    fwall.position.set(0, basinY + wall + ih*0.44, fd*0.05 + id*0.32);
    group.add(fwall);

    // back inner wall
    const bwall = new THREE.Mesh(new THREE.PlaneGeometry(iw*0.80, ih*0.88), interiorMat);
    bwall.rotation.x = -Math.PI*0.08;
    bwall.position.set(0, basinY + wall + ih*0.44, fd*0.05 - id*0.32);
    group.add(bwall);

    // left inner wall
    const lwall = new THREE.Mesh(new THREE.PlaneGeometry(id*0.70, ih*0.88), interiorMat);
    lwall.rotation.y = Math.PI*0.08;
    lwall.position.set(-iw*0.38, basinY + wall + ih*0.44, fd*0.05);
    group.add(lwall);

    // right inner wall
    const rwall = new THREE.Mesh(new THREE.PlaneGeometry(id*0.70, ih*0.88), interiorMat);
    rwall.rotation.y = -Math.PI*0.08;
    rwall.position.set(iw*0.38, basinY + wall + ih*0.44, fd*0.05);
    group.add(rwall);

    // ── drain ──
    const drainRim = new THREE.Mesh(
      new THREE.TorusGeometry(0.018*FT, 0.004*FT, 10, 32), chromeMat);
    drainRim.rotation.x = -Math.PI/2;
    drainRim.position.set(0, basinY + wall + 0.003*FT, fd*0.05);
    group.add(drainRim);

    const drainHole = new THREE.Mesh(
      new THREE.CircleGeometry(0.014*FT, 24),
      mkMat(0x111111, 0x050505, 0.9, 0, 0.10));
    drainHole.rotation.x = -Math.PI/2;
    drainHole.position.set(0, basinY + wall + 0.002*FT, fd*0.05);
    group.add(drainHole);

    // ── overflow slot (small oval near back-top of basin) ──
    const overflow = new THREE.Mesh(
      new THREE.CylinderGeometry(0.010*FT, 0.010*FT, 0.006*FT, 14),
      mkMat(0xcccccc, 0x888888, 0.3, 0.5, 0.15));
    overflow.rotation.x = Math.PI/2;
    overflow.position.set(0, basinY + bh*0.78, fd*0.05 - bd*0.36);
    group.add(overflow);

    // ── sheen on basin top rim ──
    const rimSheen = new THREE.Mesh(
      new THREE.PlaneGeometry(bw*0.90, bd*0.85),
      new THREE.MeshBasicMaterial({color:0xffffff, transparent:true, opacity:0.07, depthWrite:false})
    );
    rimSheen.rotation.x = -Math.PI/2;
    rimSheen.position.set(0, basinY + bh + 0.001*FT, fd*0.05);
    group.add(rimSheen);
  }

  /* ── single-lever tall faucet ── */
  function buildFaucet(group, x, y, z, chromeMat, darkMat) {
    // base plate
    const base = new THREE.Mesh(
      new THREE.CylinderGeometry(0.022*FT, 0.024*FT, 0.012*FT, 20), chromeMat);
    base.position.set(x, y, z);
    group.add(base);

    // main stem (tall, slight taper)
    const stem = new THREE.Mesh(
      new THREE.CylinderGeometry(0.012*FT, 0.016*FT, 0.22*FT, 16), chromeMat);
    stem.position.set(x, y + 0.12*FT, z);
    group.add(stem);

    // spout neck (horizontal, curves forward)
    const neckGeo = new THREE.CylinderGeometry(0.010*FT, 0.012*FT, 0.055*FT, 14);
    const neck = new THREE.Mesh(neckGeo, chromeMat);
    neck.rotation.x = Math.PI/2;
    neck.position.set(x, y + 0.225*FT, z + 0.022*FT);
    group.add(neck);

    // spout tip (slightly wider)
    const tip = new THREE.Mesh(
      new THREE.CylinderGeometry(0.011*FT, 0.010*FT, 0.018*FT, 14), chromeMat);
    tip.position.set(x, y + 0.212*FT, z + 0.048*FT);
    group.add(tip);

    // spout aerator (dark end)
    const aerator = new THREE.Mesh(
      new THREE.CylinderGeometry(0.009*FT, 0.009*FT, 0.010*FT, 12), darkMat);
    aerator.position.set(x, y + 0.200*FT, z + 0.048*FT);
    group.add(aerator);

    // lever handle (horizontal bar near top of stem)
    const lever = new THREE.Mesh(
      new THREE.CylinderGeometry(0.007*FT, 0.007*FT, 0.065*FT, 10), chromeMat);
    lever.rotation.z = Math.PI/2;
    lever.position.set(x, y + 0.215*FT, z - 0.005*FT);
    group.add(lever);

    // lever end cap
    const leverCap = new THREE.Mesh(new THREE.SphereGeometry(0.009*FT, 10, 8), chromeMat);
    leverCap.position.set(x + 0.034*FT, y + 0.215*FT, z - 0.005*FT);
    group.add(leverCap);

    // stem highlight
    const stemHL = new THREE.Mesh(
      new THREE.PlaneGeometry(0.008*FT, 0.18*FT),
      new THREE.MeshBasicMaterial({color:0xffffff, transparent:true, opacity:0.18, depthWrite:false})
    );
    stemHL.position.set(x - 0.005*FT, y + 0.12*FT, z + 0.013*FT);
    group.add(stemHL);
  }

  /* ── vertical bar handle ── */
  function addBarHandle(group, x, y, z, chromeMat) {
    const len = 0.080 * FT;
    const r   = 0.007 * FT;

    const bar = new THREE.Mesh(new THREE.CylinderGeometry(r, r, len, 12), chromeMat);
    bar.position.set(x, y, z);
    group.add(bar);

    [-1, 1].forEach(s => {
      const cap = new THREE.Mesh(new THREE.SphereGeometry(r, 10, 8), chromeMat);
      cap.position.set(x, y + s*len*0.5, z);
      group.add(cap);

      const mount = new THREE.Mesh(
        new THREE.CylinderGeometry(r*0.55, r*0.55, 0.016*FT, 8), chromeMat);
      mount.rotation.x = Math.PI/2;
      mount.position.set(x, y + s*len*0.30, z - 0.010*FT);
      group.add(mount);
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

    // materials
    const cabinetMat  = mkMat(WHITE,    WHITE_E,  0.28, 0.04, 0.22);  // glossy white cabinet
    const doorMat     = mkMat(OFFWHITE, OW_E,     0.25, 0.04, 0.20);  // doors slightly different
    const ceramicMat  = mkMat(CERAMIC,  CER_E,    0.10, 0.04, 0.22);  // shiny ceramic basin
    const interiorMat = mkMat(BASIN_INT,BAS_E,    0.08, 0.03, 0.20);  // basin interior
    const chromeMat   = mkMat(CHROME,   CHR_E,    0.12, 0.92, 0.20);  // chrome faucet/handles
    const darkMat     = mkMat(DARK,     DARK_E,   0.55, 0.50, 0.14);

    /* ── dims ── */
    const R        = Math.min(fw, fd) * 0.025;
    const toeH     = fh * 0.070;      // toe-kick height
    const cabiH    = fh - toeH;       // cabinet body height (doors)
    const basinH   = fh * 0.155;      // basin rises above cabinet top
    const wall     = 0.016 * FT;
    const doorGap  = 0.005 * FT;
    const doorD    = 0.022 * FT;      // door panel protrusion

    /* ════ TOE KICK ════ */
    const toeKick = rBox(fw - 0.020*FT, toeH, fd*0.18, 0.004*FT, darkMat);
    toeKick.position.set(0, toeH*0.5, fd/2 - fd*0.09);
    group.add(toeKick);

    /* ════ CABINET SHELL ════ */
    // left side
    const lSide = rBox(wall, cabiH, fd, R*0.5, cabinetMat);
    lSide.position.set(-fw/2 + wall*0.5, toeH + cabiH*0.5, 0);
    group.add(lSide);

    // right side
    const rSide = rBox(wall, cabiH, fd, R*0.5, cabinetMat);
    rSide.position.set(fw/2 - wall*0.5, toeH + cabiH*0.5, 0);
    group.add(rSide);

    // back panel
    const back = rBox(fw - wall*2, cabiH, wall*0.6, R*0.3, cabinetMat);
    back.position.set(0, toeH + cabiH*0.5, -fd/2 + wall*0.3);
    group.add(back);

    // top shelf (sits under basin)
    const topShelf = rBox(fw, wall*1.2, fd, R*0.3, cabinetMat);
    topShelf.position.set(0, toeH + cabiH - wall*0.6, 0);
    group.add(topShelf);

    // bottom shelf
    const botShelf = rBox(fw - wall*2, wall, fd - wall, R*0.3, cabinetMat);
    botShelf.position.set(0, toeH + wall*0.5, 0);
    group.add(botShelf);

    // center vertical divider
    const divider = rBox(wall, cabiH - wall*2, wall*0.6, R*0.2, cabinetMat);
    divider.position.set(0, toeH + cabiH*0.5, -fd/2 + wall*0.3 + 0.001*FT);
    group.add(divider);

    /* thin top strip (transition between cabinet top and basin) */
    const topStrip = rBox(fw, 0.008*FT, fd, 0.002*FT,
      mkMat(0xd8d8d6, 0x909090, 0.25, 0.06, 0.16));
    topStrip.position.set(0, toeH + cabiH, 0);
    group.add(topStrip);

    /* ════ TWO CABINET DOORS ════ */
    const dw   = (fw - wall*3 - doorGap) / 2;   // each door width
    const dh   = cabiH - wall*1.5;
    const dBaseY = toeH + wall*0.75;
    const dFaceZ = fd/2 + doorD*0.5;

    [-1, 1].forEach((side, idx) => {
      const cx = side * (dw*0.5 + wall*0.5 + doorGap*0.5);

      // door panel
      const door = rBox(dw, dh, doorD, 0.006*FT, doorMat);
      door.position.set(cx, dBaseY + dh*0.5, dFaceZ);
      group.add(door);

      // door face sheen
      const ds = new THREE.Mesh(
        new THREE.PlaneGeometry(dw*0.88, dh*0.88),
        new THREE.MeshBasicMaterial({color:0xffffff, transparent:true, opacity:0.06, depthWrite:false})
      );
      ds.position.set(cx, dBaseY + dh*0.5, dFaceZ + doorD*0.51);
      group.add(ds);

      // vertical bar handle (near inner edge)
      const hx = cx - side * dw * 0.22;
      addBarHandle(group, hx, dBaseY + dh*0.5, dFaceZ + doorD + 0.010*FT, chromeMat);

      // door gap shadow (center seam)
      const seam = new THREE.Mesh(
        new THREE.PlaneGeometry(doorGap*2, dh),
        new THREE.MeshBasicMaterial({color:0x000000, transparent:true, opacity:0.35, depthWrite:false})
      );
      seam.position.set(side * doorGap*0.5, dBaseY + dh*0.5, dFaceZ + doorD*0.4);
      group.add(seam);
    });

    /* center seam line */
    const seamLine = new THREE.Mesh(
      new THREE.BoxGeometry(doorGap, dh, doorD*0.3),
      mkMat(0x888888, 0x444444, 0.8, 0, 0.12)
    );
    seamLine.position.set(0, dBaseY + dh*0.5, fd/2 + doorD*0.3);
    group.add(seamLine);

    /* ════ BASIN ════ */
    const basinTopY = toeH + cabiH - wall*0.3;
    buildBasin(group, fw, fd, basinTopY, ceramicMat, interiorMat, chromeMat);

    /* ════ FAUCET (single lever, tall, centered at back) ════ */
    const faucetY = toeH + cabiH + 0.008*FT;   // just above basin rim
    const faucetZ = -fd * 0.28;                 // toward back of basin
    buildFaucet(group, 0, faucetY, faucetZ, chromeMat, darkMat);

    /* ════ OVERALL FACE SHEEN ════ */
    const faceSheen = new THREE.Mesh(
      new THREE.PlaneGeometry(fw*0.86, cabiH*0.84),
      new THREE.MeshBasicMaterial({color:0xffffff, transparent:true, opacity:0.05, depthWrite:false})
    );
    faceSheen.position.set(0, toeH + cabiH*0.5, fd/2 + doorD + 0.001*FT);
    group.add(faceSheen);

    /* vertical highlight (glossy cabinet reflection) */
    const stripe = new THREE.Mesh(
      new THREE.PlaneGeometry(fw*0.06, cabiH*0.78),
      new THREE.MeshBasicMaterial({color:0xffffff, transparent:true, opacity:0.09, depthWrite:false})
    );
    stripe.position.set(-fw*0.18, toeH + cabiH*0.5, fd/2 + doorD + 0.002*FT);
    group.add(stripe);

    /* ════ FLOOR SHADOW ════ */
    const ao = new THREE.Mesh(
      new THREE.CircleGeometry(Math.max(fw,fd)*0.58, 48),
      new THREE.MeshBasicMaterial({color:0x000000, transparent:true, opacity:0.12, depthWrite:false})
    );
    ao.rotation.x = -Math.PI/2;
    ao.position.y = 0.001;
    group.add(ao);

    group.traverse(m => {
      if (!m.isMesh) return;
      m.castShadow = true;
      m.receiveShadow = true;
    });

    return group;
  }

  global.PremiumSinkBuilder = { build: buildSink };

})(typeof window !== 'undefined' ? window : global);
