/* global THREE */
(function (global) {
  'use strict';

  const FT = 0.3048;

  function rBox(w, h, d, r, mat) {
    r = Math.min(r, w / 2, h / 2, d / 2);
    const g = new THREE.BoxGeometry(w, h, d, 3, 3, 3);
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

  function mkMat(color, emissive, rough, metal, eInt) {
    return new THREE.MeshStandardMaterial({
      color, emissive, emissiveIntensity: eInt ?? 0.18,
      roughness: rough, metalness: metal,
    });
  }

  const WALNUT    = 0x3d1f0d, WALNUT_E  = 0x1a0a04;
  const WALNUT_MID= 0x4a2510, WALNUT_ME = 0x200e05;
  const WALNUT_LT = 0x5c2e12, WALNUT_LE = 0x2a1208;
  const FRAME     = 0x2a1208, FRAME_E   = 0x0d0603;
  const GOLD      = 0xc8a96e, GOLD_E    = 0x7a6030;
  const MARBLE    = 0x3a3530, MARBLE_E  = 0x1a1510;
  const MARBLE_VN = 0x4a4540;

  function walnutMat()   { return mkMat(WALNUT,     WALNUT_E,  0.75, 0.02, 0.20); }
  function walnutMidMat(){ return mkMat(WALNUT_MID, WALNUT_ME, 0.72, 0.02, 0.18); }
  function walnutLtMat() { return mkMat(WALNUT_LT,  WALNUT_LE, 0.70, 0.02, 0.16); }
  function frameMat()    { return mkMat(FRAME,       FRAME_E,   0.80, 0.01, 0.18); }
  function goldMat()     { return mkMat(GOLD,        GOLD_E,    0.28, 0.72, 0.22); }
  function marbleMat()   { return mkMat(MARBLE,      MARBLE_E,  0.20, 0.05, 0.18); }

  function addCupHandle(group, x, y, z, width, gm) {
    const r  = 0.008 * FT;
    const hw = width * 0.5;
    const bow= 0.018 * FT;
    const bar = new THREE.Mesh(new THREE.CylinderGeometry(r, r, width, 14), gm);
    bar.rotation.z = Math.PI / 2;
    bar.position.set(x, y, z);
    group.add(bar);
    [-1, 1].forEach(s => {
      const post = new THREE.Mesh(new THREE.CylinderGeometry(r*0.7, r*0.7, bow, 10), gm);
      post.rotation.x = Math.PI / 2;
      post.position.set(x + s*hw*0.72, y, z - bow*0.5);
      group.add(post);
      const cap = new THREE.Mesh(new THREE.SphereGeometry(r*0.9, 10, 8), gm);
      cap.position.set(x + s*hw*0.72, y, z - bow);
      group.add(cap);
    });
    [-1, 1].forEach(s => {
      const ec = new THREE.Mesh(new THREE.SphereGeometry(r, 10, 8), gm);
      ec.position.set(x + s*hw*0.5, y, z);
      group.add(ec);
    });
  }

  function addInsetPanel(group, x, y, z, w, h, depth, framM, panM) {
    const border = 0.018 * FT;
    const pw = w - border*2;
    const ph = h - border*2;
    const frame = rBox(w, h, depth, 0.004*FT, framM);
    frame.position.set(x, y, z);
    group.add(frame);
    const panel = rBox(pw, ph, depth*0.6, 0.003*FT, panM);
    panel.position.set(x, y, z - depth*0.22);
    group.add(panel);
    const beadH = new THREE.Mesh(new THREE.BoxGeometry(pw, 0.004*FT, depth*0.3), framM);
    beadH.position.set(x, y + ph*0.5 + 0.002*FT, z - depth*0.08);
    group.add(beadH);
    const beadHb = new THREE.Mesh(new THREE.BoxGeometry(pw, 0.004*FT, depth*0.3), framM);
    beadHb.position.set(x, y - ph*0.5 - 0.002*FT, z - depth*0.08);
    group.add(beadHb);
    const beadV = new THREE.Mesh(new THREE.BoxGeometry(0.004*FT, ph, depth*0.3), framM);
    beadV.position.set(x - pw*0.5 - 0.002*FT, y, z - depth*0.08);
    group.add(beadV);
    const beadVr = new THREE.Mesh(new THREE.BoxGeometry(0.004*FT, ph, depth*0.3), framM);
    beadVr.position.set(x + pw*0.5 + 0.002*FT, y, z - depth*0.08);
    group.add(beadVr);
  }

  function buildPremiumShoeRack(renderer, item, _textureUrl) {
    const fw = item.width  * FT;
    const fh = item.height * FT;
    const fd = item.depth  * FT;
    const group = new THREE.Group();

    const WM  = walnutMat();
    const WMM = walnutMidMat();
    const WLM = walnutLtMat();
    const FM  = frameMat();
    const GM  = goldMat();
    const MM  = marbleMat();

    const R       = Math.min(fw, fd) * 0.020;
    const wall    = 0.018 * FT;
    const footH   = fh * 0.065;
    const bodyH   = fh - footH;
    const topSlabH= fh * 0.055;
    const cabinetH= bodyH - topSlabH;
    const drawerZoneH = cabinetH * 0.22;
    const doorZoneH   = cabinetH * 0.78;
    const nCols       = 3;
    const colW        = fw / nCols;
    const doorD       = 0.030 * FT;
    const gapSeam     = 0.006 * FT;

    /* feet */
    const footW = fw * 0.08;
    const footD = fd * 0.12;
    [[-1,-1],[-1,1],[1,-1],[1,1]].forEach(([sx,sz]) => {
      const post = rBox(footW, footH, footD, 0.004*FT, WM);
      post.position.set(sx*(fw/2 - footW*0.55), footH*0.5, sz*(fd/2 - footD*0.55));
      group.add(post);
      const notch = rBox(footW*1.18, footH*0.12, footD*1.18, 0.003*FT, FM);
      notch.position.set(sx*(fw/2 - footW*0.55), footH*0.90, sz*(fd/2 - footD*0.55));
      group.add(notch);
    });
    const botRail = rBox(fw - footW*2, footH*0.28, footD*0.55, 0.003*FT, FM);
    botRail.position.set(0, footH*0.14, fd/2 - footD*0.55);
    group.add(botRail);

    /* shell */
    const leftPanel = rBox(wall, cabinetH, fd, R, WM);
    leftPanel.position.set(-fw/2 + wall*0.5, footH + cabinetH*0.5, 0);
    group.add(leftPanel);
    const rightPanel = rBox(wall, cabinetH, fd, R, WM);
    rightPanel.position.set(fw/2 - wall*0.5, footH + cabinetH*0.5, 0);
    group.add(rightPanel);
    const backPanel = rBox(fw - wall*2, cabinetH, wall*0.6, R*0.3, FM);
    backPanel.position.set(0, footH + cabinetH*0.5, -fd/2 + wall*0.3);
    group.add(backPanel);
    const topRail = rBox(fw, wall, fd, R, WM);
    topRail.position.set(0, footH + cabinetH - wall*0.5, 0);
    group.add(topRail);
    const botShelf = rBox(fw - wall*2, wall, fd - wall, R*0.3, WMM);
    botShelf.position.set(0, footH + wall*0.5, 0);
    group.add(botShelf);
    const divider = rBox(fw - wall*2, wall*1.2, fd - wall, R*0.3, FM);
    divider.position.set(0, footH + doorZoneH + wall*0.6, 0);
    group.add(divider);
    for (let i = 1; i < nCols; i++) {
      const dvx = -fw/2 + i*colW;
      const vDiv = rBox(wall, cabinetH, fd - wall, R*0.2, FM);
      vDiv.position.set(dvx, footH + cabinetH*0.5, 0);
      group.add(vDiv);
    }

    /* drawers */
    const drawerBaseY = footH + doorZoneH + wall;
    const drawerH     = drawerZoneH - wall*2.5;
    const drawerD     = doorD;
    for (let col = 0; col < nCols; col++) {
      const cx = -fw/2 + col*colW + colW/2;
      const dw = colW - wall*1.5 - gapSeam;
      addInsetPanel(group, cx, drawerBaseY + drawerH*0.5, fd/2 + drawerD*0.5, dw, drawerH, drawerD, WM, WLM);
      addCupHandle(group, cx, drawerBaseY + drawerH*0.5, fd/2 + drawerD + 0.010*FT, colW * 0.38, GM);
      const gapShadow = new THREE.Mesh(
        new THREE.PlaneGeometry(dw, 0.004*FT),
        new THREE.MeshBasicMaterial({color:0x000000, transparent:true, opacity:0.40, depthWrite:false}));
      gapShadow.position.set(cx, drawerBaseY + drawerH + gapSeam*0.5, fd/2 + drawerD*0.3);
      group.add(gapShadow);
    }

    /* doors */
    const doorBaseY = footH;
    const doorH     = doorZoneH - wall*0.5;
    for (let col = 0; col < nCols; col++) {
      const cx = -fw/2 + col*colW + colW/2;
      const dw = colW - wall*1.5 - gapSeam;
      const topPanelH    = doorH * 0.30;
      const botPanelH    = doorH * 0.62;
      const panelBorderV = doorH * 0.025;
      const door = rBox(dw, doorH, doorD, 0.005*FT, WM);
      door.position.set(cx, doorBaseY + doorH*0.5, fd/2 + doorD*0.5);
      group.add(door);
      addInsetPanel(group, cx, doorBaseY + doorH - panelBorderV - topPanelH*0.5, fd/2 + doorD*0.55, dw * 0.82, topPanelH, doorD * 0.45, FM, WLM);
      addInsetPanel(group, cx, doorBaseY + panelBorderV + botPanelH*0.5, fd/2 + doorD*0.55, dw * 0.82, botPanelH, doorD * 0.45, FM, WLM);
      addCupHandle(group, cx, doorBaseY + doorH - panelBorderV - topPanelH - 0.028*FT, fd/2 + doorD + 0.010*FT, colW * 0.38, GM);
      if (col < nCols-1) {
        const colShadow = new THREE.Mesh(
          new THREE.PlaneGeometry(gapSeam*1.5, doorH),
          new THREE.MeshBasicMaterial({color:0x000000, transparent:true, opacity:0.35, depthWrite:false}));
        colShadow.position.set(cx + colW*0.5, doorBaseY + doorH*0.5, fd/2 + doorD*0.8);
        group.add(colShadow);
      }
    }

    /* ════ MARBLE SLAB — no overhang, flush with cabinet, NO angled veins ════ */
    const slabY = footH + cabinetH;
    // Slab exactly matches cabinet width/depth — no overhang to prevent sticking out
    const slabW = fw;
    const slabD = fd;

    const slab = rBox(slabW, topSlabH, slabD, 0.006*FT, MM);
    slab.position.set(0, slabY + topSlabH*0.5, 0);
    group.add(slab);

    // Veins: ONLY straight horizontal lines (rotation.y = 0), clipped to slab width
    // No rotation so they never poke outside the slab boundary
    const veinMat = mkMat(MARBLE_VN, 0x606050, 0.18, 0.04, 0.12);
    [
      { x: -slabW*0.25, len: slabW*0.35, z:  slabD*0.10 },
      { x:  slabW*0.08, len: slabW*0.28, z: -slabD*0.05 },
      { x:  slabW*0.30, len: slabW*0.20, z:  slabD*0.20 },
      { x: -slabW*0.05, len: slabW*0.42, z: -slabD*0.15 },
      { x: -slabW*0.38, len: slabW*0.18, z:  slabD*0.05 },
    ].forEach(v => {
      // Clamp so vein never exceeds slab boundary
      const maxLen = slabW - Math.abs(v.x)*2 - 0.010*FT;
      const safeLen = Math.min(v.len, maxLen);
      if (safeLen <= 0) return;
      const vein = new THREE.Mesh(
        new THREE.BoxGeometry(safeLen, topSlabH*1.01, 0.005*FT),
        veinMat
      );
      // NO rotation.y — veins run straight left-right only
      vein.position.set(v.x, slabY + topSlabH*0.5, v.z);
      group.add(vein);
    });

    // Front edge highlight
    const edgeMat = mkMat(0x4a4540, 0x252015, 0.22, 0.06, 0.16);
    const frontEdge = rBox(slabW, topSlabH, 0.006*FT, 0.002*FT, edgeMat);
    frontEdge.position.set(0, slabY + topSlabH*0.5, slabD/2);
    group.add(frontEdge);

    // Top sheen (rotated flat, no Y offset issues)
    const sheenTop = new THREE.Mesh(
      new THREE.PlaneGeometry(slabW*0.86, slabD*0.78),
      new THREE.MeshBasicMaterial({color:0xffffff, transparent:true, opacity:0.06, depthWrite:false}));
    sheenTop.rotation.x = -Math.PI/2;
    sheenTop.position.set(0, slabY + topSlabH + 0.001*FT, 0);
    group.add(sheenTop);

    /* mouldings */
    const mould = rBox(fw, wall*0.9, wall*1.2, 0.003*FT, FM);
    mould.position.set(0, footH + cabinetH - wall, fd/2 + wall*0.2);
    group.add(mould);
    const mouldBot = rBox(fw, wall*0.8, wall*1.2, 0.003*FT, FM);
    mouldBot.position.set(0, footH + wall*0.4, fd/2 + wall*0.2);
    group.add(mouldBot);

    /* face sheen */
    const faceSheen = new THREE.Mesh(
      new THREE.PlaneGeometry(fw*0.88, cabinetH*0.86),
      new THREE.MeshBasicMaterial({color:0xffffff, transparent:true, opacity:0.025, depthWrite:false}));
    faceSheen.position.set(0, footH + cabinetH*0.5, fd/2 + doorD + 0.001*FT);
    group.add(faceSheen);

    /* floor shadow */
    const ao = new THREE.Mesh(
      new THREE.CircleGeometry(Math.max(fw,fd)*0.58, 48),
      new THREE.MeshBasicMaterial({color:0x000000, transparent:true, opacity:0.14, depthWrite:false}));
    ao.rotation.x = -Math.PI/2;
    ao.position.y = 0.002;
    group.add(ao);

    group.traverse(m => {
      if (!m.isMesh) return;
      m.castShadow = true;
      m.receiveShadow = true;
    });

    return group;
  }

  global.PremiumShoeRackBuilder = { build: buildPremiumShoeRack };

})(typeof window !== 'undefined' ? window : global);
