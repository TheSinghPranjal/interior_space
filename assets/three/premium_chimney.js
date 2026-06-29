/* global THREE */
(function (global) {
  'use strict';

  const FT = 0.3048;

  function rBox(w, h, d, r, mat) {
    r = Math.min(r, w / 2, h / 2, d / 2);
    const g = new THREE.BoxGeometry(w, h, d, 4, 4, 4);
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
      color,
      emissive,
      emissiveIntensity: eInt ?? 0.14,
      roughness: rough,
      metalness: metal,
      envMapIntensity: 1.5,
    });
  }

  function makeFilterMeshTexture() {
    const size = 128;
    const canvas = document.createElement('canvas');
    canvas.width = canvas.height = size;
    const ctx = canvas.getContext('2d');
    ctx.fillStyle = '#707880';
    ctx.fillRect(0, 0, size, size);
    ctx.strokeStyle = '#4e545c';
    ctx.lineWidth = 1;
    for (let x = 0; x <= size; x += 5) {
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, size);
      ctx.stroke();
    }
    for (let y = 0; y <= size; y += 8) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(size, y);
      ctx.stroke();
    }
    const tex = new THREE.CanvasTexture(canvas);
    tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
    tex.repeat.set(5, 4);
    return tex;
  }

  function buildPremiumChimney(renderer, item) {
    const fw = item.width * FT;
    const fh = item.height * FT;
    const fd = item.depth * FT;
    const depthScale = Math.max(0.55, fd / fw);

    const group = new THREE.Group();
    group.name = 'PremiumChimney';

    const bodyColor = 0xc4c8cc;
    const bodyEmissive = 0x686e76;

    const bodyMat = mkMat(bodyColor, bodyEmissive, 0.32, 0.18);
    const panelMat = mkMat(0x7a8088, 0x404850, 0.45, 0.25);
    const buttonMat = mkMat(0x4a5058, 0x202428, 0.55, 0.35);
    const filterFrameMat = mkMat(0x5c626a, 0x303840, 0.42, 0.40);
    const latchMat = mkMat(0x2e343a, 0x101418, 0.65, 0.20);
    const lightMat = new THREE.MeshStandardMaterial({
      color: 0xffffff,
      emissive: 0xfff4e8,
      emissiveIntensity: 1.1,
      roughness: 0.35,
      metalness: 0.0,
    });
    const lightRingMat = mkMat(0xd8dce0, 0x909498, 0.25, 0.55, 0.08);

    const hoodH = fh * 0.54;
    const flueH = fh * 0.46;
    const flueW = fw * 0.24;
    const flueD = fd * 0.42;
    const hoodTopR = fw * 0.17;
    const hoodBotR = fw * 0.47;

    const bodyParts = [];

    // Hood canopy — tapered pyramid
    const hood = new THREE.Mesh(
      new THREE.CylinderGeometry(hoodTopR, hoodBotR, hoodH, 4, 1, false),
      bodyMat
    );
    hood.name = 'HoodCanopy';
    hood.rotation.y = Math.PI / 4;
    hood.scale.set(1, 1, depthScale);
    hood.position.set(0, hoodH * 0.5, fd * 0.02);
    bodyParts.push(hood);

    // Front vertical lip (control fascia)
    const lipH = hoodH * 0.30;
    const frontLip = rBox(fw * 0.86, lipH, fd * 0.14, 0.004 * FT, bodyMat);
    frontLip.name = 'FrontLip';
    frontLip.position.set(0, lipH * 0.5 + hoodH * 0.03, fd * 0.36);
    bodyParts.push(frontLip);

    // Top transition collar
    const collar = rBox(flueW * 1.35, 0.028 * FT, flueD * 1.25, 0.004 * FT, bodyMat);
    collar.name = 'TopCollar';
    collar.position.set(0, hoodH - 0.012 * FT, fd * 0.02);
    bodyParts.push(collar);

    // Flue duct
    const flue = rBox(flueW, flueH, flueD, 0.006 * FT, bodyMat);
    flue.name = 'Flue';
    flue.position.set(0, hoodH + flueH * 0.5, fd * 0.02);
    bodyParts.push(flue);

    // Control panel
    const panelW = fw * 0.34;
    const panel = rBox(panelW, 0.038 * FT, 0.014 * FT, 0.002 * FT, panelMat);
    panel.name = 'ControlPanel';
    panel.position.set(0, lipH * 0.58 + hoodH * 0.03, fd * 0.44);
    bodyParts.push(panel);

    // Control buttons
    [-1.5, -0.5, 0.5, 1.5].forEach((slot, i) => {
      const btn = new THREE.Mesh(
        new THREE.CylinderGeometry(0.011 * FT, 0.011 * FT, 0.006 * FT, 16),
        buttonMat
      );
      btn.name = 'Button' + (i + 1);
      btn.rotation.x = Math.PI / 2;
      btn.position.set(slot * panelW * 0.18, lipH * 0.58 + hoodH * 0.03, fd * 0.449);
      bodyParts.push(btn);
    });

    // Bottom outer rim
    const rimT = 0.022 * FT;
    const rimW = fw * 0.94;
    const rimD = fd * 0.88;
    const filterW = fw * 0.62;
    const filterD = fd * 0.52;

    [
      { w: rimW, h: rimT, d: rimT, x: 0, z: rimD * 0.5 - rimT * 0.5 },
      { w: rimW, h: rimT, d: rimT, x: 0, z: -(rimD * 0.5 - rimT * 0.5) },
      { w: rimT, h: rimT, d: rimD, x: -(rimW * 0.5 - rimT * 0.5), z: 0 },
      { w: rimT, h: rimT, d: rimD, x: rimW * 0.5 - rimT * 0.5, z: 0 },
    ].forEach((s, i) => {
      const strip = rBox(s.w, s.h, s.d, 0.002 * FT, bodyMat);
      strip.name = 'BottomRim' + (i + 1);
      strip.position.set(s.x, rimT * 0.5, s.z);
      bodyParts.push(strip);
    });

    // Filter recess frame
    const recessDepth = 0.028 * FT;
    const recess = rBox(filterW + 0.016 * FT, recessDepth, filterD + 0.016 * FT, 0.003 * FT, filterFrameMat);
    recess.name = 'FilterRecess';
    recess.position.set(0, rimT + recessDepth * 0.5, fd * 0.04);
    bodyParts.push(recess);

    // Mesh filter grille
    const filterMeshMat = new THREE.MeshStandardMaterial({
      map: makeFilterMeshTexture(),
      color: 0x9098a0,
      roughness: 0.55,
      metalness: 0.65,
      envMapIntensity: 1.2,
    });
    const filter = new THREE.Mesh(
      new THREE.PlaneGeometry(filterW, filterD),
      filterMeshMat
    );
    filter.name = 'FilterGrille';
    filter.rotation.x = -Math.PI / 2;
    filter.position.set(0, rimT + 0.004 * FT, fd * 0.04);

    // Filter latch
    const latch = rBox(filterW * 0.16, 0.012 * FT, 0.018 * FT, 0.002 * FT, latchMat);
    latch.name = 'FilterLatch';
    latch.position.set(0, rimT + 0.008 * FT, fd * 0.04 + filterD * 0.42);

    // Underside LED lights
    const lightR = 0.034 * FT;
    [-1, 1].forEach((side, i) => {
      const ring = new THREE.Mesh(
        new THREE.CylinderGeometry(lightR, lightR, 0.008 * FT, 24),
        lightRingMat
      );
      ring.name = 'LightRing' + (i + 1);
      ring.position.set(side * fw * 0.30, rimT + 0.006 * FT, fd * 0.28);

      const bulb = new THREE.Mesh(
        new THREE.CylinderGeometry(lightR * 0.72, lightR * 0.72, 0.004 * FT, 20),
        lightMat
      );
      bulb.name = 'Light' + (i + 1);
      bulb.position.set(side * fw * 0.30, rimT + 0.003 * FT, fd * 0.28);

      bodyParts.push(ring);
      bodyParts.push(bulb);
    });

    // Front face sheen
    const sheen = new THREE.Mesh(
      new THREE.PlaneGeometry(fw * 0.72, hoodH * 0.62),
      new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.06, depthWrite: false })
    );
    sheen.name = 'FrontSheen';
    sheen.position.set(0, hoodH * 0.42, fd * 0.43);

    bodyParts.forEach((mesh) => {
      mesh.castShadow = true;
      mesh.receiveShadow = true;
      mesh.frustumCulled = true;
      group.add(mesh);
    });

    filter.castShadow = true;
    filter.receiveShadow = true;
    latch.castShadow = true;
    group.add(filter);
    group.add(latch);
    group.add(sheen);

    group.userData = {
      type: 'kitchenChimney',
      category: 'kitchen',
      editable: true,
      resizable: true,
      rotatable: true,
      material: 'lightGray',
      setColor(color) {
        bodyParts.forEach((mesh) => {
          if (mesh.material && mesh.material.color) {
            mesh.material.color.set(color);
          }
        });
      },
      setTexture(texture) {
        bodyParts.forEach((mesh) => {
          if (mesh.material && mesh.material.map !== undefined) {
            mesh.material.map = texture;
            mesh.material.needsUpdate = true;
          }
        });
      },
    };

    return group;
  }

  global.PremiumChimneyBuilder = { build: buildPremiumChimney };

})(typeof window !== 'undefined' ? window : global);
