/* global THREE, PremiumBedBuilder, PremiumPottedFlowerPotBuilder */
(function (global) {
  'use strict';

  const FT = 0.3048;

  function mkMat(color, rough, metal, emissive, eInt) {
    return new THREE.MeshStandardMaterial({
      color,
      emissive: emissive || 0x000000,
      emissiveIntensity: eInt ?? 0.12,
      roughness: rough,
      metalness: metal,
      envMapIntensity: 1.3,
    });
  }

  function addShadows(group) {
    group.traverse((c) => {
      if (c.isMesh) {
        c.castShadow = true;
        c.receiveShadow = true;
      }
    });
    return group;
  }

  function buildBathtubWithWater(renderer, item, textureUrl) {
    const fw = item.width * FT;
    const fd = item.depth * FT;
    const rimH = item.height * FT;
    const group = new THREE.Group();

    const porcelain = renderer._makeMaterial(item.color, 0.1, 0.04, textureUrl, null, 1, 1);
    const innerMat = mkMat(0xf5f5f5, 0.08, 0.04);
    const waterMat = new THREE.MeshStandardMaterial({
      color: 0x4fc3f7,
      roughness: 0.04,
      metalness: 0.12,
      transparent: true,
      opacity: 0.72,
    });
    const chrome = mkMat(0xcfd8dc, 0.12, 0.92, 0x9098a0, 0.18);

    const tubDepth = rimH * 0.74;
    const wallT = fw * 0.08;

    const outer = new THREE.Mesh(new THREE.BoxGeometry(fw, tubDepth, fd), porcelain);
    outer.position.y = tubDepth / 2;
    group.add(outer);

    const inner = new THREE.Mesh(
      new THREE.BoxGeometry(fw - wallT * 2, tubDepth * 0.82, fd - wallT * 2),
      innerMat
    );
    inner.position.y = tubDepth * 0.52;
    group.add(inner);

    const water = new THREE.Mesh(
      new THREE.BoxGeometry(fw - wallT * 2.8, 0.055, fd - wallT * 2.8),
      waterMat
    );
    water.position.y = tubDepth * 0.62;
    group.add(water);

    const ripple = new THREE.Mesh(
      new THREE.PlaneGeometry(fw - wallT * 3.2, fd - wallT * 3.2),
      new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.12, depthWrite: false })
    );
    ripple.rotation.x = -Math.PI / 2;
    ripple.position.y = tubDepth * 0.645;
    group.add(ripple);

    const rim = new THREE.Mesh(new THREE.BoxGeometry(fw, fw * 0.06, fd), porcelain);
    rim.position.y = tubDepth + fw * 0.03;
    group.add(rim);

    const faucet = new THREE.Mesh(new THREE.CylinderGeometry(fw * 0.04, fw * 0.045, rimH * 0.5, 12), chrome);
    faucet.position.set(0, tubDepth + rimH * 0.18, -fd / 2 + fd * 0.14);
    group.add(faucet);

    return addShadows(group);
  }

  function buildBathtubVintage(renderer, item, textureUrl) {
    const fw = item.width * FT;
    const fd = item.depth * FT;
    const rimH = item.height * FT;
    const group = new THREE.Group();

    const enamel = renderer._makeMaterial(item.color, 0.14, 0.05, textureUrl, null, 1, 1);
    const clawMat = mkMat(0x8d6e63, 0.35, 0.55, 0x3e2723, 0.1);
    const chrome = mkMat(0xdfe3e8, 0.1, 0.9, 0x9098a0, 0.2);

    const tubR = fw * 0.42;
    const tub = new THREE.Mesh(
      new THREE.CylinderGeometry(tubR, tubR * 0.92, rimH * 0.55, 32, 1, false, 0, Math.PI),
      enamel
    );
    tub.rotation.z = Math.PI / 2;
    tub.rotation.y = Math.PI / 2;
    tub.position.y = rimH * 0.32;
    group.add(tub);

    const rimTorus = new THREE.Mesh(
      new THREE.TorusGeometry(tubR * 0.98, fw * 0.035, 12, 40, Math.PI),
      enamel
    );
    rimTorus.rotation.z = Math.PI / 2;
    rimTorus.rotation.y = Math.PI / 2;
    rimTorus.position.y = rimH * 0.58;
    group.add(rimTorus);

    [[-1, -1], [-1, 1], [1, -1], [1, 1]].forEach(([sx, sz]) => {
      const leg = new THREE.Mesh(new THREE.CylinderGeometry(fw * 0.045, fw * 0.055, rimH * 0.28, 10), clawMat);
      leg.position.set(sx * tubR * 0.72, rimH * 0.14, sz * fd * 0.28);
      group.add(leg);
      const foot = new THREE.Mesh(new THREE.SphereGeometry(fw * 0.05, 12, 10), clawMat);
      foot.position.set(sx * tubR * 0.72, 0.02, sz * fd * 0.28);
      group.add(foot);
    });

    const faucet = new THREE.Mesh(new THREE.CylinderGeometry(fw * 0.025, fw * 0.03, rimH * 0.42, 10), chrome);
    faucet.position.set(0, rimH * 0.62, -fd * 0.22);
    group.add(faucet);

    return addShadows(group);
  }

  function buildPottedPlant(renderer, item, textureUrl) {
    if (typeof PremiumPottedFlowerPotBuilder !== 'undefined') {
      return PremiumPottedFlowerPotBuilder.build(renderer, item, textureUrl);
    }
    return _simplePlant(item, 0x43a047, 0xbf360c);
  }

  function buildIndoorPlant(renderer, item, textureUrl) {
    const group = new THREE.Group();
    const potMat = renderer._makeMaterial(item.color, 0.55, 0.08, textureUrl, null, 1, 1);
    const leafMat = mkMat(0x388e3c, 0.82, 0.02, 0x1b5e20, 0.08);

    const fw = item.width * FT;
    const fh = item.height * FT;
    const potH = fh * 0.22;
    const pot = new THREE.Mesh(new THREE.CylinderGeometry(fw * 0.38, fw * 0.32, potH, 16), potMat);
    pot.position.y = potH / 2;
    group.add(pot);

    for (let i = 0; i < 14; i++) {
      const angle = (i / 14) * Math.PI * 2;
      const leaf = new THREE.Mesh(new THREE.BoxGeometry(fw * 0.08, fh * 0.42, fw * 0.02), leafMat);
      leaf.position.set(Math.cos(angle) * fw * 0.22, potH + fh * 0.28, Math.sin(angle) * fw * 0.22);
      leaf.rotation.y = angle;
      leaf.rotation.z = 0.35;
      group.add(leaf);
    }

    return addShadows(group);
  }

  function buildMonstera(renderer, item, textureUrl) {
    const group = new THREE.Group();
    const potMat = renderer._makeMaterial(item.color, 0.5, 0.06, textureUrl, null, 1, 1);
    const leafMat = mkMat(0x2e7d32, 0.75, 0.02, 0x1b5e20, 0.1);

    const fw = item.width * FT;
    const fh = item.height * FT;
    const potH = fh * 0.18;
    const pot = new THREE.Mesh(new THREE.CylinderGeometry(fw * 0.42, fw * 0.34, potH, 20), potMat);
    pot.position.y = potH / 2;
    group.add(pot);

    const leafShapes = [
      { x: 0, z: 0, ry: 0, sx: 1.1 },
      { x: 0.12, z: 0.08, ry: 0.6, sx: 0.9 },
      { x: -0.14, z: 0.05, ry: -0.5, sx: 0.95 },
      { x: 0.05, z: -0.12, ry: 2.4, sx: 0.85 },
      { x: -0.08, z: -0.1, ry: -2.2, sx: 0.88 },
    ];

    leafShapes.forEach((s, i) => {
      const w = fw * 0.55 * s.sx;
      const h = fh * 0.38;
      const leaf = new THREE.Mesh(new THREE.PlaneGeometry(w, h), leafMat);
      leaf.position.set(s.x * fw, potH + fh * (0.32 + i * 0.08), s.z * fw);
      leaf.rotation.y = s.ry;
      leaf.rotation.x = -0.25;
      group.add(leaf);
      const split = new THREE.Mesh(
        new THREE.PlaneGeometry(w * 0.08, h * 0.85),
        new THREE.MeshBasicMaterial({ color: 0x1b5e20, transparent: true, opacity: 0.35 })
      );
      split.position.copy(leaf.position);
      split.rotation.copy(leaf.rotation);
      split.position.y += 0.002;
      group.add(split);
    });

    return addShadows(group);
  }

  function _simplePlant(item, leafColor, potColor) {
    const group = new THREE.Group();
    const fw = item.width * FT;
    const fh = item.height * FT;
    const potMat = mkMat(potColor, 0.6, 0.05);
    const leafMat = mkMat(leafColor, 0.85, 0.02);
    const pot = new THREE.Mesh(new THREE.CylinderGeometry(fw * 0.35, fw * 0.3, fh * 0.2, 14), potMat);
    pot.position.y = fh * 0.1;
    group.add(pot);
    const bush = new THREE.Mesh(new THREE.SphereGeometry(fw * 0.42, 14, 12), leafMat);
    bush.position.y = fh * 0.45;
    group.add(bush);
    return addShadows(group);
  }

  function buildLuxuryBed(renderer, item, textureUrl) {
    if (typeof PremiumBedBuilder !== 'undefined') {
      return PremiumBedBuilder.build(renderer, item, textureUrl);
    }
    const group = new THREE.Group();
    const fw = item.width * FT;
    const fd = item.depth * FT;
    const frameMat = renderer._makeMaterial(item.color, 0.85, 0.05, textureUrl, 'fabric', 2, 2);
    const base = new THREE.Mesh(new THREE.BoxGeometry(fw, 0.34 * FT, fd), frameMat);
    base.position.y = 0.17 * FT;
    group.add(base);
    return addShadows(group);
  }

  function buildCatalogItem(renderer, item, textureUrl) {
    const id = item.premiumCatalogId;
    switch (id) {
      case 'bathtubWithWater':
        return buildBathtubWithWater(renderer, item, textureUrl);
      case 'bathtubVintage':
        return buildBathtubVintage(renderer, item, textureUrl);
      case 'pottedPlant':
        return buildPottedPlant(renderer, item, textureUrl);
      case 'indoorPlant':
        return buildIndoorPlant(renderer, item, textureUrl);
      case 'monstera':
        return buildMonstera(renderer, item, textureUrl);
      case 'luxuryBed':
        return buildLuxuryBed(renderer, item, textureUrl);
      default:
        return null;
    }
  }

  global.PremiumCatalogBuilder = { build: buildCatalogItem };

})(typeof window !== 'undefined' ? window : global);
