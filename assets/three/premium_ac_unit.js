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
      emissiveIntensity: eInt ?? 0.16,
      roughness: rough,
      metalness: metal,
      envMapIntensity: 1.4,
    });
  }

  function hexColor(hex) {
    return parseInt(String(hex || '#F5F5F5').replace('#', ''), 16) || 0xf5f5f5;
  }

  function buildPremiumAcUnit(roomRenderer, unit) {
    const uw = unit.width * FT;
    const uh = unit.height * FT;
    const depth = 0.22;
    const group = new THREE.Group();

    const tex = roomRenderer._resolveTextureUrl(unit.textureDataUrl, unit.texturePath);
    const shellColor = hexColor(unit.color);
    const shellEm = new THREE.Color(shellColor).multiplyScalar(0.55).getHex();

    const shellMat = tex
      ? roomRenderer._makeMaterial(unit.color, 0.28, 0.08, tex, null, 1, 1)
      : mkMat(shellColor, shellEm, 0.22, 0.06, 0.20);

    const trimMat = mkMat(
      new THREE.Color(shellColor).multiplyScalar(0.92).getHex(),
      shellEm,
      0.18,
      0.10,
      0.18
    );
    const louverMat = mkMat(0xb8c0c8, 0x606870, 0.42, 0.28, 0.16);
    const chromeMat = mkMat(0xd8dce0, 0x9098a0, 0.08, 0.92, 0.22);
    const darkMat = mkMat(0x1a1a1a, 0x050505, 0.55, 0.40, 0.12);

    const screenMat = new THREE.MeshStandardMaterial({
      color: 0x050a10,
      emissive: 0x0a6a9a,
      emissiveIntensity: 0.75,
      roughness: 0.12,
      metalness: 0.15,
    });
    const ledMat = new THREE.MeshStandardMaterial({
      color: 0x00cfff,
      emissive: 0x00cfff,
      emissiveIntensity: 1.4,
      roughness: 0.1,
    });

    const frontZ = -depth;
    const R = Math.min(uw, uh) * 0.018;

    const topH = uh * 0.14;
    const louverH = uh * 0.30;
    const bodyH = uh - topH - louverH - uh * 0.04;
    const bodyCenterY = -uh * 0.5 + louverH + uh * 0.02 + bodyH * 0.5;
    const bodyTopY = bodyCenterY + bodyH * 0.5;

    const body = rBox(uw * 0.98, bodyH, depth, R, shellMat);
    body.position.set(0, bodyCenterY, -depth * 0.5);
    group.add(body);

    const topPanel = rBox(uw * 0.98, topH, depth * 0.055, R, trimMat);
    topPanel.position.set(0, bodyTopY + topH * 0.5 + 0.001 * FT, frontZ + depth * 0.028);
    group.add(topPanel);

    const displayBezel = rBox(uw * 0.22, uh * 0.055, 0.012, 0.002 * FT, darkMat);
    displayBezel.position.set(uw * 0.30, bodyTopY + topH * 0.42, frontZ + 0.008);
    group.add(displayBezel);

    const display = new THREE.Mesh(
      new THREE.PlaneGeometry(uw * 0.18, uh * 0.042),
      screenMat
    );
    display.position.set(uw * 0.30, bodyTopY + topH * 0.42, frontZ + 0.014);
    group.add(display);

    const brandBar = rBox(uw * 0.14, uh * 0.028, 0.010, 0.001 * FT, chromeMat);
    brandBar.position.set(-uw * 0.34, bodyTopY + topH * 0.40, frontZ + 0.012);
    group.add(brandBar);

    [-0.12, 0.12].forEach((dx) => {
      const led = new THREE.Mesh(new THREE.CircleGeometry(uw * 0.012, 16), ledMat);
      led.position.set(uw * 0.30 + dx * uw, bodyTopY + topH * 0.52, frontZ + 0.012);
      group.add(led);
    });

    const louverBox = rBox(uw * 0.96, louverH, depth * 0.72, R * 0.6, louverMat);
    louverBox.position.set(0, -uh * 0.5 + louverH * 0.5 + uh * 0.02, -depth * 0.42);
    group.add(louverBox);

    for (let i = 0; i < 6; i++) {
      const slat = rBox(uw * 0.90, 0.010, depth * 0.58, 0.001 * FT, louverMat);
      slat.position.set(
        0,
        -uh * 0.5 + uh * 0.06 + i * (louverH * 0.82 / 5),
        frontZ + 0.010
      );
      slat.rotation.x = -0.32;
      group.add(slat);
    }

    const outlet = new THREE.Mesh(
      new THREE.CylinderGeometry(0.018, 0.018, uw * 0.08, 12),
      chromeMat
    );
    outlet.rotation.z = Math.PI / 2;
    outlet.position.set(uw * 0.56, bodyCenterY - bodyH * 0.15, -depth * 0.18);
    group.add(outlet);

    const pipe = new THREE.Mesh(
      new THREE.CylinderGeometry(0.012, 0.012, depth * 0.35, 10),
      darkMat
    );
    pipe.rotation.x = Math.PI / 2;
    pipe.position.set(uw * 0.56, bodyCenterY - bodyH * 0.15, -depth * 0.38);
    group.add(pipe);

    const faceSheen = new THREE.Mesh(
      new THREE.PlaneGeometry(uw * 0.88, bodyH * 0.82),
      new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.045, depthWrite: false })
    );
    faceSheen.position.set(0, bodyCenterY, frontZ + 0.004);
    group.add(faceSheen);

    const topSheen = new THREE.Mesh(
      new THREE.PlaneGeometry(uw * 0.92, topH * 0.82),
      new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.06, depthWrite: false })
    );
    topSheen.rotation.x = -Math.PI / 2;
    topSheen.position.set(0, bodyTopY + topH + 0.0008, frontZ + depth * 0.02);
    group.add(topSheen);

    group.traverse((m) => {
      if (m.isMesh) {
        m.castShadow = true;
        m.receiveShadow = true;
      }
    });

    return group;
  }

  global.PremiumAcUnitBuilder = { build: buildPremiumAcUnit };

})(typeof window !== 'undefined' ? window : global);
