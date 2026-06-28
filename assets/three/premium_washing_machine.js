/* global THREE */
(function (global) {
  'use strict';

  const FT = 0.3048;

  /* ── rounded box ── */
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

  /* ── materials with emissive (visible in dark scenes) ── */
  function mkMat(color, emissive, rough, metal, eInt) {
    return new THREE.MeshStandardMaterial({
      color, emissive, emissiveIntensity: eInt ?? 0.18,
      roughness: rough, metalness: metal,
    });
  }

  const OFF_WHITE = 0xf0eeea, OFF_WHITE_E = 0xa09e9a;
  const LGRAY     = 0xd0cdc8, LGRAY_E     = 0x808078;
  const CHROME    = 0xd4d8dc, CHROME_E    = 0x909498;
  const DARK      = 0x1e1e1e, DARK_E      = 0x080808;
  const DRUM_C    = 0x8a9198, DRUM_E      = 0x404548;
  const SCREEN_E  = 0x0d5f92;

  const BM  = () => mkMat(OFF_WHITE, OFF_WHITE_E, 0.30, 0.05, 0.22);
  const CM  = () => mkMat(CHROME,    CHROME_E,    0.10, 0.95, 0.22);
  const DM  = () => mkMat(DARK,      DARK_E,      0.55, 0.55, 0.15);
  const DrM = () => mkMat(DRUM_C,    DRUM_E,      0.18, 0.90, 0.22);
  const RM  = () => mkMat(0x151515,  0x050505,    0.96, 0.00, 0.10);
  const BGM = () => mkMat(0x111111,  0x060606,    0.05, 0.70, 0.14);

  function buildPremiumWashingMachine(renderer, item, _textureUrl) {
    const fw = item.width  * FT;
    const fd = item.depth  * FT;
    const fh = item.height * FT;
    const group = new THREE.Group();

    const bm  = BM(), cm = CM(), dm = DM(), drm = DrM(), rm = RM(), bgm = BGM();
    const pm  = mkMat(LGRAY, LGRAY_E, 0.28, 0.06, 0.20);

    const screenMat = new THREE.MeshStandardMaterial({
      color: 0x050e18, emissive: SCREEN_E, emissiveIntensity: 0.80,
      roughness: 0.08, metalness: 0.10,
    });
    const ledMat = new THREE.MeshStandardMaterial({
      color: 0x00cfff, emissive: 0x00cfff, emissiveIntensity: 1.6, roughness: 0.1,
    });

    /* ── dims ── */
    const R       = Math.min(fw, fd) * 0.032;
    const footH   = 0.018 * FT;
    const plinthH = footH + 0.014 * FT;
    const bodyH   = fh - plinthH;
    const topH    = bodyH * 0.195;
    const mainH   = bodyH - topH;
    const wall    = 0.018 * FT;

    /* door circle dims */
    const doorR   = Math.min(fw, mainH) * 0.370;
    const doorCY  = plinthH + mainH * 0.52;
    const doorCZ  = fd * 0.5 + 0.002 * FT;   // sit flush on front face
    const drumR   = doorR * 0.68;
    const drumD   = fd * 0.40;
    const cpY     = plinthH + mainH + topH * 0.5;

    /* ── feet ── */
    [[-1,-1],[-1,1],[1,-1],[1,1]].forEach(([sx,sz]) => {
      const f = new THREE.Mesh(new THREE.CylinderGeometry(0.014*FT,0.014*FT,footH,14), dm);
      f.position.set(sx*fw*0.41, footH*0.5, sz*fd*0.41);
      group.add(f);
    });

    /* ── plinth ── */
    const plinth = rBox(fw, plinthH, fd, R*0.5, dm);
    plinth.position.y = plinthH*0.5;
    group.add(plinth);

    /* ── body ── */
    const body = rBox(fw, bodyH, fd, R, bm);
    body.position.y = plinthH + bodyH*0.5;
    group.add(body);

    const topCap = rBox(fw, wall, fd, R, pm);
    topCap.position.y = fh - wall*0.5;
    group.add(topCap);

    const back = rBox(fw-wall*2, bodyH-wall, wall*0.8, R*0.3, dm);
    back.position.set(0, plinthH+bodyH*0.5, -fd/2+wall*0.4);
    group.add(back);

    /* ════════════════════════════════
       CONTROL PANEL
    ════════════════════════════════ */
    const cp = rBox(fw*0.97, topH, wall*1.5, R*0.5, bgm);
    cp.position.set(0, cpY, fd/2+wall*0.25);
    group.add(cp);

    /* chrome accent lines */
    [cpY-topH*0.5, cpY+topH*0.5].forEach(y => {
      const a = rBox(fw*0.97, 0.006*FT, 0.008*FT, 0.002*FT, cm);
      a.position.set(0, y, fd/2+wall*0.55);
      group.add(a);
    });

    /* detergent drawer */
    const dw = fw*0.22, dh = topH*0.44, dd = 0.020*FT;
    const dx = -fw*0.31;
    const dHousing = rBox(dw*1.08, dh*1.12, wall*1.1, 0.005*FT, dm);
    dHousing.position.set(dx, cpY, fd/2+wall*0.12);
    group.add(dHousing);
    const drawer = rBox(dw, dh, dd, 0.005*FT, bm);
    drawer.position.set(dx, cpY, fd/2+wall*0.72);
    group.add(drawer);
    const dhandle = rBox(dw*0.52, dh*0.17, 0.014*FT, 0.003*FT, cm);
    dhandle.position.set(dx, cpY, fd/2+wall*1.16);
    group.add(dhandle);

    /* knob */
    const kx = -fw*0.04, kr = fw*0.060;
    const knob = new THREE.Mesh(new THREE.CylinderGeometry(kr, kr, 0.026*FT, 60), cm);
    knob.rotation.x = Math.PI/2;
    knob.position.set(kx, cpY, fd/2+wall*0.88);
    group.add(knob);
    const knobBezel = new THREE.Mesh(new THREE.TorusGeometry(kr*1.02, 0.005*FT, 14, 60), cm);
    knobBezel.rotation.x = Math.PI/2;
    knobBezel.position.set(kx, cpY, fd/2+wall*0.98);
    group.add(knobBezel);
    const knobCap = new THREE.Mesh(new THREE.CylinderGeometry(kr*0.63,kr*0.63,0.016*FT,44), bgm);
    knobCap.rotation.x = Math.PI/2;
    knobCap.position.set(kx, cpY, fd/2+wall*1.06);
    group.add(knobCap);
    const ind = new THREE.Mesh(new THREE.BoxGeometry(0.004*FT,kr*0.38,0.003*FT),
      mkMat(0xffffff,0xffffff,0.2,0,0.5));
    ind.position.set(kx, cpY+kr*0.42, fd/2+wall*1.14);
    group.add(ind);
    for (let i=0;i<32;i++){
      const a=(i/32)*Math.PI*2;
      const gr=new THREE.Mesh(new THREE.BoxGeometry(0.003*FT,0.009*FT,0.022*FT),cm);
      gr.position.set(kx+Math.cos(a)*kr*0.97, cpY+Math.sin(a)*kr*0.97, fd/2+wall*0.88);
      gr.rotation.z=a; group.add(gr);
    }
    for (let i=0;i<12;i++){
      const a=Math.PI*0.75+(i/11)*Math.PI*1.5;
      const t=new THREE.Mesh(new THREE.BoxGeometry(0.003*FT,0.013*FT,0.002*FT),
        mkMat(0xcccccc,0x888888,0.3,0,0.18));
      t.position.set(kx+Math.cos(a)*kr*1.50, cpY+Math.sin(a)*kr*1.50, fd/2+wall*0.84);
      t.rotation.z=a; group.add(t);
    }

    /* screen */
    const sw=fw*0.25, sh=topH*0.50, sx=fw*0.185;
    const sHousing=rBox(sw*1.10, sh*1.16, wall*0.85, 0.006*FT, dm);
    sHousing.position.set(sx, cpY, fd/2+wall*0.48);
    group.add(sHousing);
    const screen=rBox(sw, sh, 0.004*FT, 0.004*FT, screenMat);
    screen.position.set(sx, cpY, fd/2+wall*0.96);
    group.add(screen);
    const tempGlow=new THREE.Mesh(new THREE.PlaneGeometry(sw*0.28,sh*0.52),
      new THREE.MeshBasicMaterial({color:0x00cfff,transparent:true,opacity:0.50}));
    tempGlow.position.set(sx+sw*0.20, cpY, fd/2+wall*1.00);
    group.add(tempGlow);
    for(let i=0;i<5;i++){
      const led=new THREE.Mesh(new THREE.CircleGeometry(0.0036*FT,10),ledMat);
      led.position.set(sx-sw*0.36+i*0.036*FT, cpY+sh*0.37, fd/2+wall*1.00);
      group.add(led);
    }

    /* buttons */
    for(let i=0;i<3;i++){
      const btn=new THREE.Mesh(new THREE.CylinderGeometry(0.016*FT,0.016*FT,0.009*FT,18),
        mkMat(0xe8e6e2,0x909090,0.28,0.06,0.18));
      btn.rotation.x=Math.PI/2;
      btn.position.set(fw*0.375, cpY+(i-1)*topH*0.27, fd/2+wall*0.88);
      group.add(btn);
    }

    /* ════════════════════════════════
       DOOR  — all circular geometry
    ════════════════════════════════ */

    /* dark square recess behind door */
    const recess = rBox(doorR*2.30, doorR*2.30, wall*1.0, 0.010*FT, dm);
    recess.position.set(0, doorCY, fd/2+wall*0.10);
    group.add(recess);

    /* ① outer chrome bezel ring — TorusGeometry default is in XY plane = faces +Z = correct */
    const outerRing = new THREE.Mesh(
      new THREE.TorusGeometry(doorR, 0.034*FT, 24, 120), cm);
    outerRing.position.set(0, doorCY, doorCZ);
    group.add(outerRing);

    /* ② mid dark ring */
    const midRing = new THREE.Mesh(
      new THREE.TorusGeometry(doorR*0.884, 0.016*FT, 16, 80), bgm);
    midRing.position.set(0, doorCY, doorCZ - 0.006*FT);
    group.add(midRing);

    /* ③ rubber gasket ring */
    const gasket = new THREE.Mesh(
      new THREE.TorusGeometry(doorR*0.745, 0.026*FT, 18, 80), rm);
    gasket.position.set(0, doorCY, doorCZ - 0.028*FT);
    group.add(gasket);

    /* ④ drum back (dark circle) */
    const drumBack = new THREE.Mesh(new THREE.CircleGeometry(drumR, 80), dm);
    drumBack.position.set(0, doorCY, doorCZ - drumD);
    group.add(drumBack);

    /* ⑤ drum cylinder — CylinderGeometry is along Y axis, rotate to align with Z */
    const drum = new THREE.Mesh(
      new THREE.CylinderGeometry(drumR, drumR, drumD, 80, 2, true), drm);
    drum.rotation.x = Math.PI/2;   // cylinder: Y→Z so it goes into the machine
    drum.position.set(0, doorCY, doorCZ - drumD*0.5);
    group.add(drum);

    /* drum holes */
    for(let ring=0;ring<5;ring++){
      const hr=drumR*(0.22+ring*0.14);
      const count=16+ring*6;
      for(let i=0;i<count;i++){
        const a=(i/count)*Math.PI*2;
        const hole=new THREE.Mesh(new THREE.CircleGeometry(0.0032*FT,8),dm);
        hole.position.set(Math.cos(a)*hr, doorCY+Math.sin(a)*hr, doorCZ-drumD+0.001);
        group.add(hole);
      }
    }

    /* drum paddles */
    for(let i=0;i<3;i++){
      const a=(i/3)*Math.PI*2;
      const paddle=rBox(drumR*0.18, 0.015*FT, drumD*0.78, 0.004*FT,
        mkMat(0x3a3f45,0x1a1f22,0.58,0.05,0.15));
      paddle.rotation.z=a;
      paddle.position.set(Math.cos(a)*drumR*0.53, doorCY+Math.sin(a)*drumR*0.53, doorCZ-drumD*0.44);
      group.add(paddle);
    }

    /* ⑥ glass disc (flat circle — NOT a sphere) */
    const glassMat = new THREE.MeshStandardMaterial({
      color: 0x1a2830,
      emissive: 0x0a1418,
      emissiveIntensity: 0.25,
      roughness: 0.02,
      metalness: 0.10,
      transparent: true,
      opacity: 0.72,
      side: THREE.DoubleSide,
    });
    const glassDisc = new THREE.Mesh(new THREE.CircleGeometry(doorR*0.700, 80), glassMat);
    glassDisc.position.set(0, doorCY, doorCZ - 0.002*FT);
    group.add(glassDisc);

    /* ⑦ glass highlight (crescent top-left) */
    const hlMat = new THREE.MeshBasicMaterial({color:0xffffff,transparent:true,opacity:0.10,depthWrite:false});
    const hl = new THREE.Mesh(new THREE.CircleGeometry(doorR*0.20, 32), hlMat);
    hl.position.set(-doorR*0.30, doorCY+doorR*0.30, doorCZ+0.002*FT);
    group.add(hl);

    /* reflection band across middle of glass */
    const refMat = new THREE.MeshBasicMaterial({color:0xffffff,transparent:true,opacity:0.05,depthWrite:false});
    const ref = new THREE.Mesh(new THREE.PlaneGeometry(doorR*1.3, doorR*0.28), refMat);
    ref.position.set(0, doorCY, doorCZ+0.003*FT);
    group.add(ref);

    /* ── door pull handle — horizontal chrome bar below door center ── */
    const hBarLen = doorR * 1.10;
    const hBarR   = 0.013 * FT;
    const hBarY   = doorCY - doorR * 0.78;
    const hBarZ   = doorCZ + 0.030 * FT;

    // main bar
    const hBar = new THREE.Mesh(
      new THREE.CylinderGeometry(hBarR, hBarR, hBarLen, 16),
      cm);
    hBar.rotation.z = Math.PI / 2;   // lay it horizontally
    hBar.position.set(0, hBarY, hBarZ);
    group.add(hBar);

    // end caps
    [-1,1].forEach(s => {
      const cap = new THREE.Mesh(new THREE.SphereGeometry(hBarR, 12, 10), cm);
      cap.position.set(s * hBarLen * 0.5, hBarY, hBarZ);
      group.add(cap);

      // mounting bracket
      const brkt = new THREE.Mesh(
        new THREE.CylinderGeometry(hBarR*0.55, hBarR*0.55, 0.022*FT, 10),
        cm);
      brkt.position.set(s * hBarLen * 0.42, hBarY, hBarZ - 0.015*FT);
      group.add(brkt);
    });

    /* ── hinge & latch ── */
    const hinge=rBox(0.018*FT,0.082*FT,0.018*FT,0.004*FT,cm);
    hinge.position.set(-doorR*1.05, doorCY, fd/2);
    group.add(hinge);
    const latch=rBox(0.011*FT,0.046*FT,0.009*FT,0.003*FT,cm);
    latch.position.set(doorR*1.05, doorCY, fd/2);
    group.add(latch);

    /* ── filter panel (bottom right) ── */
    const fp=rBox(fw*0.17, plinthH*0.54, 0.008*FT, 0.004*FT, pm);
    fp.position.set(fw*0.30, plinthH*0.5, fd/2+0.003*FT);
    group.add(fp);
    const fph=rBox(fw*0.09, 0.006*FT, 0.006*FT, 0.002*FT, cm);
    fph.position.set(fw*0.30, plinthH*0.62, fd/2+0.008*FT);
    group.add(fph);

    /* ── side grooves ── */
    [-1,1].forEach(side=>{
      for(let i=0;i<3;i++){
        const g=rBox(0.003*FT, bodyH*0.25, 0.003*FT, 0.001*FT, dm);
        g.position.set(side*(fw/2-0.002*FT), plinthH+bodyH*(0.22+i*0.26), 0);
        group.add(g);
      }
    });

    /* ── face sheen ── */
    const sheen=new THREE.Mesh(new THREE.PlaneGeometry(fw*0.84,bodyH*0.82),
      new THREE.MeshBasicMaterial({color:0xffffff,transparent:true,opacity:0.055,depthWrite:false}));
    sheen.position.set(0, plinthH+bodyH*0.5, fd/2+wall*1.6+0.001*FT);
    group.add(sheen);

    /* ── floor shadow ── */
    const ao=new THREE.Mesh(new THREE.CircleGeometry(Math.max(fw,fd)*0.60,48),
      new THREE.MeshBasicMaterial({color:0x000000,transparent:true,opacity:0.12,depthWrite:false}));
    ao.rotation.x=-Math.PI/2; ao.position.y=0.002;
    group.add(ao);

    group.traverse(m=>{
      if(!m.isMesh) return;
      m.castShadow=true; m.receiveShadow=true;
    });

    return group;
  }

  global.PremiumWashingMachineBuilder = { build: buildPremiumWashingMachine };

})(typeof window !== 'undefined' ? window : global);
