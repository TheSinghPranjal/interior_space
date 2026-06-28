/* global THREE */
(function (global) {
  'use strict';

  const FT = 0.3048;

  /* ── tiny rounded-box (no external dep) ── */
  function rBox(w, h, d, r, mat) {
    r = Math.min(r, w / 2, h / 2, d / 2);
    const g = new THREE.BoxGeometry(w, h, d, 3, 3, 3);
    const p = g.attributes.position;
    for (let i = 0; i < p.count; i++) {
      let x = p.getX(i), y = p.getY(i), z = p.getZ(i);
      const sx = Math.sign(x), sy = Math.sign(y), sz = Math.sign(z);
      const cx = sx * (w / 2 - r), cy = sy * (h / 2 - r), cz = sz * (d / 2 - r);
      const dx = x - cx, dy = y - cy, dz = z - cz;
      const len = Math.sqrt(dx * dx + dy * dy + dz * dz) || 1;
      p.setXYZ(i, cx + dx / len * r, cy + dy / len * r, cz + dz / len * r);
    }
    p.needsUpdate = true;
    g.computeVertexNormals();
    return new THREE.Mesh(g, mat);
  }

  /* ── materials with emissive so they show even in dark scenes ── */
  function mat(color, emissive, rough, metal) {
    return new THREE.MeshStandardMaterial({
      color:           color,
      emissive:        emissive,
      emissiveIntensity: 0.18,
      roughness:       rough,
      metalness:       metal,
    });
  }

  const C = {
    steel:   0xc8ced2,   // light stainless
    steelE:  0x7a8a8f,   // emissive tint
    dark:    0x2c2c2c,
    darkE:   0x101010,
    trim:    0xa0acb2,
    trimE:   0x606a6e,
    rubber:  0x181818,
    rubberE: 0x080808,
    blue:    0x0d6eaa,
  };

  function steelMat()  { return mat(C.steel,  C.steelE,  0.20, 0.90); }
  function darkMat()   { return mat(C.dark,   C.darkE,   0.55, 0.60); }
  function trimMat()   { return mat(C.trim,   C.trimE,   0.18, 0.92); }
  function rubberMat() { return mat(C.rubber, C.rubberE, 0.95, 0.00); }

  /* ── vertical handle ── */
  function vHandle(group, x, y, z, len, tMat) {
    const r = 0.012 * FT;
    const bar = new THREE.Mesh(new THREE.CylinderGeometry(r, r, len, 14), tMat);
    bar.position.set(x, y, z);
    group.add(bar);
    [-1, 1].forEach(s => {
      const sp = new THREE.Mesh(new THREE.SphereGeometry(r, 10, 8), tMat);
      sp.position.set(x, y + s * len * 0.5, z);
      group.add(sp);
      const br = new THREE.Mesh(new THREE.CylinderGeometry(r * 0.5, r * 0.5, r * 4, 8), tMat);
      br.rotation.z = Math.PI / 2;
      br.position.set(x + r * 2.2, y + s * len * 0.3, z - 0.008 * FT);
      group.add(br);
    });
  }

  /* ── horizontal handle ── */
  function hHandle(group, x, y, z, len, tMat) {
    const r = 0.011 * FT;
    const bar = new THREE.Mesh(new THREE.CylinderGeometry(r, r, len, 12), tMat);
    bar.rotation.z = Math.PI / 2;
    bar.position.set(x, y, z);
    group.add(bar);
    [-1, 1].forEach(s => {
      const sp = new THREE.Mesh(new THREE.SphereGeometry(r, 8, 6), tMat);
      sp.position.set(x + s * len * 0.5, y, z);
      group.add(sp);
      const br = new THREE.Mesh(new THREE.CylinderGeometry(r * 0.5, r * 0.5, r * 3.5, 8), tMat);
      br.position.set(x + s * len * 0.34, y, z - 0.007 * FT);
      group.add(br);
    });
  }

  /* ── dispenser ── */
  function dispenser(group, x, y, z, dMat, tMat) {
    const pw = 0.11 * FT, ph = 0.18 * FT, pd = 0.022 * FT;

    const screenMat = new THREE.MeshStandardMaterial({
      color: 0x050e15, emissive: C.blue, emissiveIntensity: 0.9, roughness: 0.1, metalness: 0,
    });

    // housing recess
    const h = rBox(pw, ph, pd, 0.006 * FT, dMat);
    h.position.set(x, y, z);
    group.add(h);

    // screen
    const sc = new THREE.Mesh(new THREE.PlaneGeometry(pw * 0.78, ph * 0.30), screenMat);
    sc.position.set(x, y + ph * 0.28, z + pd * 0.55);
    group.add(sc);

    // temp readout glow strip
    const glow = new THREE.Mesh(
      new THREE.PlaneGeometry(pw * 0.55, ph * 0.08),
      new THREE.MeshBasicMaterial({ color: 0x00cfff, transparent: true, opacity: 0.55 })
    );
    glow.position.set(x, y + ph * 0.28, z + pd * 0.56);
    group.add(glow);

    // buttons
    [-1, 0, 1].forEach(i => {
      const b = new THREE.Mesh(
        new THREE.CylinderGeometry(0.007 * FT, 0.007 * FT, 0.005 * FT, 10),
        new THREE.MeshStandardMaterial({ color: 0x1a5a7a, emissive: 0x0a3050, emissiveIntensity: 0.4, roughness: 0.3 })
      );
      b.rotation.x = Math.PI / 2;
      b.position.set(x + i * pw * 0.28, y + ph * 0.05, z + pd * 0.56);
      group.add(b);
    });

    // nozzle
    const nz = new THREE.Mesh(new THREE.CylinderGeometry(0.008 * FT, 0.011 * FT, 0.016 * FT, 10), tMat);
    nz.position.set(x, y - ph * 0.20, z + pd * 0.55);
    group.add(nz);

    // drip tray
    const tray = rBox(pw * 0.72, 0.010 * FT, 0.042 * FT, 0.003 * FT, tMat);
    tray.position.set(x, y - ph * 0.41, z + pd * 0.8);
    group.add(tray);
  }

  /* ══════════════════════════════════════════════════════════
     MAIN BUILDER
  ══════════════════════════════════════════════════════════ */
  function buildPremiumFridge(renderer, item, _textureUrl) {
    const fw = item.width  * FT;
    const fh = item.height * FT;
    const fd = item.depth  * FT;

    const group = new THREE.Group();

    const SM  = steelMat();
    const DM  = darkMat();
    const TM  = trimMat();
    const RM  = rubberMat();

    /* Fridge proportions */
    const R      = Math.min(fw, fd) * 0.032;
    const footH  = fh * 0.022;
    const bodyH  = fh - footH;
    const doorD  = 0.052 * FT;   // how far doors stick out from cabinet face
    const wall   = 0.020 * FT;

    /* ── 4 adjustable feet ── */
    [[-1,-1],[-1,1],[1,-1],[1,1]].forEach(([sx,sz]) => {
      const foot = new THREE.Mesh(new THREE.CylinderGeometry(0.015*FT, 0.015*FT, footH, 10), DM);
      foot.position.set(sx*fw*0.40, footH*0.5, sz*fd*0.38);
      group.add(foot);
    });

    /* ── cabinet shell ── */
    const cab = rBox(fw, bodyH, fd, R, SM);
    cab.position.y = footH + bodyH * 0.5;
    group.add(cab);

    // darker back panel
    const back = rBox(fw - wall*2, bodyH - wall, wall, R*0.3, DM);
    back.position.set(0, footH + bodyH*0.5, -fd/2 + wall*0.5);
    group.add(back);

    // top cap slightly brighter
    const topCap = rBox(fw, wall, fd, R, TM);
    topCap.position.y = fh - wall*0.5;
    group.add(topCap);

    // toe kick
    const toe = rBox(fw, footH, fd, R*0.3, DM);
    toe.position.y = footH * 0.5;
    group.add(toe);
    const kick = rBox(fw*0.88, footH*0.5, 0.010*FT, 0.003*FT, TM);
    kick.position.set(0, footH*0.5, fd/2 + 0.002*FT);
    group.add(kick);

    /* ════════════════════════════════
       DOOR ZONES
       Top 62% → 2 French doors
       Bot 38% → 2 pull drawers
    ════════════════════════════════ */
    const topFrac   = 0.62;
    const topH      = bodyH * topFrac;
    const botH      = bodyH * (1 - topFrac);
    const topY      = footH + botH;          // Y where top doors start
    const botY      = footH;                 // Y where drawer zone starts
    const centerGap = 0.008 * FT;
    const edgeGap   = 0.004 * FT;
    const doorW     = (fw - centerGap) / 2 - edgeGap;

    /* shared door SM – slightly lighter emissive for door face */
    const DSM = steelMat();
    DSM.emissiveIntensity = 0.22;

    /* ── LEFT French door ── */
    const lDoor = rBox(doorW, topH - edgeGap, doorD, R*0.55, DSM);
    lDoor.position.set(
      -(doorW/2 + centerGap/2),
      topY + (topH - edgeGap)/2,
      fd/2 + doorD/2
    );
    group.add(lDoor);

    /* ── RIGHT French door ── */
    const rDoor = rBox(doorW, topH - edgeGap, doorD, R*0.55, DSM);
    rDoor.position.set(
      doorW/2 + centerGap/2,
      topY + (topH - edgeGap)/2,
      fd/2 + doorD/2
    );
    group.add(rDoor);

    /* center rubber seal */
    const seal = new THREE.Mesh(
      new THREE.BoxGeometry(centerGap, topH - edgeGap, doorD),
      RM
    );
    seal.position.set(0, topY + (topH-edgeGap)/2, fd/2 + doorD/2);
    group.add(seal);

    /* door-edge silver trim strips */
    [-1,1].forEach(s => {
      const es = rBox(wall*0.55, topH - edgeGap, doorD*0.15, R*0.2, TM);
      es.position.set(s*(fw/2 - wall*0.28), topY + (topH-edgeGap)/2, fd/2 + doorD*0.08);
      group.add(es);
    });

    /* door-top and door-bottom rubber gasket lines */
    [topY, topY + topH - edgeGap].forEach(gy => {
      const g = new THREE.Mesh(new THREE.BoxGeometry(fw, 0.006*FT, doorD*0.8), RM);
      g.position.set(0, gy, fd/2 + doorD/2);
      group.add(g);
    });

    /* ── vertical handles – inner edges of each door ── */
    const hLen = topH * 0.56;
    const hZ   = fd/2 + doorD + 0.015*FT;
    const hY   = topY + (topH-edgeGap)/2;
    // left door handle on its right/inner side
    vHandle(group, -(centerGap/2 + doorW*0.15), hY, hZ, hLen, TM);
    // right door handle on its left/inner side
    vHandle(group,  (centerGap/2 + doorW*0.15), hY, hZ, hLen, TM);

    /* ── water/ice dispenser on LEFT door outer panel ── */
    dispenser(
      group,
      -(centerGap/2 + doorW*0.56),
      topY + topH * 0.62,
      fd/2 + doorD * 0.62,
      DM, TM
    );

    /* brand badge */
    const badge = rBox(fw*0.16, 0.013*FT, 0.004*FT, 0.002*FT, TM);
    badge.position.set(doorW*0.35, topY + topH*0.96, fd/2 + doorD + 0.001*FT);
    group.add(badge);

    /* divider between top and bottom zones */
    const div = new THREE.Mesh(new THREE.BoxGeometry(fw, 0.009*FT, 0.024*FT), RM);
    div.position.set(0, topY, fd/2 + doorD*0.5);
    group.add(div);

    /* ════════════════════════════
       BOTTOM DRAWERS  (2 stacked)
    ════════════════════════════ */
    const nD    = 2;
    const dGap  = 0.007 * FT;
    const dH    = (botH - (nD+1)*dGap) / nD;
    const dD    = doorD * 0.92;
    const dW    = fw - wall;

    for (let i = 0; i < nD; i++) {
      const dy = botY + dGap + i*(dH+dGap) + dH/2;

      const drawer = rBox(dW, dH, dD, R*0.45, DSM);
      drawer.position.set(0, dy, fd/2 + dD/2);
      group.add(drawer);

      // inset groove at bottom of drawer face
      const groove = rBox(dW*0.94, 0.006*FT, dD*0.12, 0.002*FT, DM);
      groove.position.set(0, dy - dH*0.43, fd/2 + dD*0.48);
      group.add(groove);

      // horizontal handle
      hHandle(group, 0, dy + dH*0.04, fd/2 + dD + 0.012*FT, dW*0.40, TM);

      // gap shadow above each drawer gap
      if (i > 0) {
        const gs = new THREE.Mesh(
          new THREE.PlaneGeometry(dW, dGap),
          new THREE.MeshBasicMaterial({color:0x000000, transparent:true, opacity:0.35, depthWrite:false})
        );
        gs.position.set(0, dy - dH/2 - dGap/2, fd/2 + dD*0.6);
        group.add(gs);
      }
    }

    /* drawer-zone side trim */
    [-1,1].forEach(s => {
      const st = rBox(wall*0.5, botH, dD*0.15, R*0.2, TM);
      st.position.set(s*(fw/2 - wall*0.25), botY + botH/2, fd/2 + dD*0.075);
      group.add(st);
    });

    /* ── hinges ── */
    [-1,1].forEach(side => {
      [0.16, 0.84].forEach(f => {
        const hn = new THREE.Mesh(new THREE.BoxGeometry(0.013*FT, 0.036*FT, 0.013*FT), TM);
        hn.position.set(side*(fw/2 - wall*0.5), topY + topH*f, fd/2 - 0.005*FT);
        group.add(hn);
      });
    });

    /* ── face sheen plane (gives stainless look without HDR) ── */
    const sheen = new THREE.Mesh(
      new THREE.PlaneGeometry(fw*0.88, bodyH*0.86),
      new THREE.MeshBasicMaterial({color:0xffffff, transparent:true, opacity:0.055, depthWrite:false})
    );
    sheen.position.set(0, footH + bodyH*0.5, fd/2 + doorD + 0.001*FT);
    group.add(sheen);

    // subtle vertical highlight stripe (center-left) – mimics brushed-steel light reflection
    const stripe = new THREE.Mesh(
      new THREE.PlaneGeometry(fw*0.06, bodyH*0.80),
      new THREE.MeshBasicMaterial({color:0xffffff, transparent:true, opacity:0.09, depthWrite:false})
    );
    stripe.position.set(-fw*0.18, footH + bodyH*0.5, fd/2 + doorD + 0.0015*FT);
    group.add(stripe);

    /* ── floor AO shadow ── */
    const ao = new THREE.Mesh(
      new THREE.CircleGeometry(Math.max(fw,fd)*0.62, 48),
      new THREE.MeshBasicMaterial({color:0x000000, transparent:true, opacity:0.13, depthWrite:false})
    );
    ao.rotation.x = -Math.PI/2;
    ao.position.y = 0.002;
    group.add(ao);

    /* ── cast / receive shadows ── */
    group.traverse(m => {
      if (!m.isMesh) return;
      m.castShadow    = true;
      m.receiveShadow = true;
    });

    return group;
  }

  global.PremiumFridgeBuilder = { build: buildPremiumFridge };

})(typeof window !== 'undefined' ? window : global);
