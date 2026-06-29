/* global THREE */
(function (global) {
  'use strict';

  const FT = 0.3048;

  //----------------------------------------------------------
  // HELPERS
  //----------------------------------------------------------

  function hexColor(hex) {
    if (typeof hex === 'number') return hex;
    return parseInt(String(hex).replace('#', ''), 16) || 0x6a8f5a;
  }

  function roundedBox(width, height, depth, radius, material, seg) {
    radius = Math.min(radius, width / 2, height / 2, depth / 2);
    const s = seg || 8;
    const geometry = new THREE.BoxGeometry(width, height, depth, s, s, s);
    const pos = geometry.attributes.position;
    for (let i = 0; i < pos.count; i++) {
      let x = pos.getX(i), y = pos.getY(i), z = pos.getZ(i);
      const sx = Math.sign(x) || 1, sy = Math.sign(y) || 1, sz = Math.sign(z) || 1;
      const cx = sx * (width / 2 - radius);
      const cy = sy * (height / 2 - radius);
      const cz = sz * (depth / 2 - radius);
      const dx = x - cx, dy = y - cy, dz = z - cz;
      const len = Math.sqrt(dx * dx + dy * dy + dz * dz) || 1;
      pos.setXYZ(i, cx + dx / len * radius, cy + dy / len * radius, cz + dz / len * radius);
    }
    pos.needsUpdate = true;
    geometry.computeVertexNormals();
    return new THREE.Mesh(geometry, material);
  }

  function taperedCylinder(topR, botR, h, seg, material) {
    return new THREE.Mesh(new THREE.CylinderGeometry(topR, botR, h, seg, 3), material);
  }

  function softFabric(mesh) {
    const pos = mesh.geometry.attributes.position;
    if (!pos) return;
    for (let i = 0; i < pos.count; i++) {
      const x = pos.getX(i);
      let y = pos.getY(i);
      const z = pos.getZ(i);
      y += Math.sin(x * 9) * 0.0018 + Math.cos(z * 9) * 0.0018;
      pos.setXYZ(i, x, y, z);
    }
    pos.needsUpdate = true;
    mesh.geometry.computeVertexNormals();
  }

  function makeRadialShadowTexture() {
    const size = 256;
    const canvas = document.createElement('canvas');
    canvas.width = canvas.height = size;
    const ctx = canvas.getContext('2d');
    const grad = ctx.createRadialGradient(
      size / 2, size / 2, size * 0.05, size / 2, size / 2, size * 0.5
    );
    grad.addColorStop(0, 'rgba(0,0,0,0.5)');
    grad.addColorStop(0.55, 'rgba(0,0,0,0.2)');
    grad.addColorStop(1, 'rgba(0,0,0,0)');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, size, size);
    return new THREE.CanvasTexture(canvas);
  }

  //----------------------------------------------------------
  // MATERIALS — fabric cushions + warm wooden frame
  //----------------------------------------------------------

  function buildMaterials(renderer, item, textureUrl) {
    // Cushion fabric — driven by item.color / uploaded texture
    const fabric = renderer._makeMaterial(
      item.color,
      0.95,
      0.0,
      textureUrl,
      textureUrl ? null : 'fabric',
      2,
      2
    );
    if (fabric.roughness !== undefined) {
      fabric.roughness = 0.96;
      fabric.metalness = 0.0;
      fabric.bumpScale = 0.012;
      if (fabric.normalScale) fabric.normalScale.set(0.6, 0.6);
    }

    // Warm walnut wood — frame, legs, arms (independent of cushion colour)
    const wood = renderer._makeMaterial(
      '#6b4327',
      0.55,
      0.04,
      null,
      'wood',
      1,
      1
    );
    if (wood.roughness !== undefined) {
      wood.roughness = 0.5;
      wood.metalness = 0.04;
      wood.envMapIntensity = 1.2;
    }
    if ('clearcoat' in wood) {
      wood.clearcoat = 0.5;
      wood.clearcoatRoughness = 0.16;
    }

    const woodDark = wood.clone();
    if (woodDark.color) woodDark.color = new THREE.Color(0x4a2d18);

    return { fabric, wood, woodDark };
  }

  //----------------------------------------------------------
  // MAIN BUILDER — wooden armchair with cushions (sofa-style)
  //----------------------------------------------------------

  function buildPremiumChair(renderer, item, textureUrl) {
    const cw = item.width * FT;
    const ch = item.height * FT;
    const cd = item.depth * FT;

    const group = new THREE.Group();
    const { fabric, wood, woodDark } = buildMaterials(renderer, item, textureUrl);

    //----------------------------------------------------------
    // KEY DIMENSIONS
    //----------------------------------------------------------
    const legH = ch * 0.26;
    const baseThk = ch * 0.05;
    const baseTopY = legH + baseThk;

    const seatCushThk = ch * 0.14;
    const seatTopY = baseTopY + seatCushThk;

    const backTopY = legH + ch * 0.66;
    const armY = seatTopY + ch * 0.11;

    const radius = Math.min(cw, cd) * 0.05;

    const legX = cw * 0.36;
    const legZ = cd * 0.34;
    const armX = cw * 0.46;
    const postX = cw * 0.40;
    const postZ = -cd * 0.38;

    //==========================================================
    // WOODEN LEGS (tapered, slight splay)
    //==========================================================
    [[-1, 1], [1, 1], [-1, -1], [1, -1]].forEach(([sx, sz]) => {
      const leg = taperedCylinder(0.032 * FT, 0.018 * FT, legH, 18, wood);
      leg.position.set(sx * legX, legH * 0.5, sz * legZ);
      leg.rotation.z = sx * -0.04;
      leg.rotation.x = sz * 0.03;
      group.add(leg);
    });

    //==========================================================
    // WOODEN SEAT FRAME / BASE
    //==========================================================
    const base = roundedBox(cw * 0.86, baseThk, cd * 0.86, radius * 0.7, wood, 6);
    base.position.set(0, legH + baseThk * 0.5, 0);
    group.add(base);

    // front + side aprons for a solid wooden look
    const apronH = ch * 0.06;
    const apronY = legH + baseThk * 0.5 - apronH * 0.2;
    const frontApron = roundedBox(cw * 0.82, apronH, 0.03 * FT, 0.01 * FT, wood, 4);
    frontApron.position.set(0, apronY, cd * 0.41);
    group.add(frontApron);
    const sideApronL = roundedBox(0.03 * FT, apronH, cd * 0.82, 0.01 * FT, wood, 4);
    sideApronL.position.set(-cw * 0.41, apronY, 0);
    group.add(sideApronL);
    const sideApronR = sideApronL.clone();
    sideApronR.position.x = cw * 0.41;
    group.add(sideApronR);

    //==========================================================
    // WOODEN ARMS (handles): horizontal bar + front post
    //==========================================================
    [-1, 1].forEach((side) => {
      // horizontal arm rail (the wooden handle)
      const armBar = roundedBox(0.075 * FT, 0.07 * FT, cd * 0.9, 0.03 * FT, wood, 6);
      armBar.position.set(side * armX, armY, -cd * 0.02);
      group.add(armBar);

      // rounded front cap on the handle
      const cap = new THREE.Mesh(new THREE.SphereGeometry(0.05 * FT, 16, 12), wood);
      cap.scale.set(0.75, 0.7, 1.0);
      cap.position.set(side * armX, armY, cd * 0.43);
      group.add(cap);

      // front vertical support post
      const frontPostH = armY - (legH + baseThk * 0.5);
      const frontPost = roundedBox(0.06 * FT, frontPostH, 0.06 * FT, 0.015 * FT, wood, 4);
      frontPost.position.set(side * armX, legH + baseThk * 0.5 + frontPostH * 0.5, cd * 0.36);
      group.add(frontPost);
    });

    //==========================================================
    // WOODEN BACK FRAME (posts + top rail)
    //==========================================================
    const postH = backTopY - (legH + baseThk * 0.5);
    [-1, 1].forEach((side) => {
      const post = roundedBox(0.07 * FT, postH, 0.06 * FT, 0.015 * FT, wood, 5);
      post.position.set(side * postX, legH + baseThk * 0.5 + postH * 0.5, postZ);
      post.rotation.x = -0.06; // slight backward lean
      group.add(post);
    });

    const topRail = roundedBox(postX * 2 + 0.12 * FT, 0.085 * FT, 0.07 * FT, 0.03 * FT, wood, 6);
    topRail.position.set(0, backTopY, postZ - postH * 0.06);
    group.add(topRail);
    // gentle bow on the crest rail
    (function bow() {
      const p = topRail.geometry.attributes.position;
      const hw = (postX * 2 + 0.12 * FT) * 0.5;
      for (let i = 0; i < p.count; i++) {
        let x = p.getX(i), y = p.getY(i), z = p.getZ(i);
        const t = Math.abs(x) / hw;
        z -= (1 - t * t) * 0.02 * FT;
        p.setXYZ(i, x, y, z);
      }
      p.needsUpdate = true;
      topRail.geometry.computeVertexNormals();
    })();

    //==========================================================
    // FABRIC SEAT CUSHION
    //==========================================================
    const seatCushion = roundedBox(cw * 0.78, seatCushThk, cd * 0.74, radius * 1.2, fabric, 12);
    seatCushion.position.set(0, baseTopY + seatCushThk * 0.5, cd * 0.01);
    seatCushion.scale.y = 1.04;
    // dome the top + waterfall front
    (function domeSeat() {
      const p = seatCushion.geometry.attributes.position;
      const hw = cw * 0.39, hd = cd * 0.37;
      for (let i = 0; i < p.count; i++) {
        let x = p.getX(i), y = p.getY(i), z = p.getZ(i);
        const fx = Math.abs(x) / hw, fz = Math.abs(z) / hd;
        if (y > 0) y += (1 - Math.max(fx, fz)) * 0.012 * FT;
        if (Math.abs(y) < seatCushThk * 0.3 && z > 0) z *= 1.03;
        p.setXYZ(i, x, y, z);
      }
      p.needsUpdate = true;
      seatCushion.geometry.computeVertexNormals();
    })();
    softFabric(seatCushion);
    group.add(seatCushion);

    //==========================================================
    // FABRIC BACK CUSHION
    //==========================================================
    const backCushH = backTopY - seatTopY - 0.02 * FT;
    const backCushion = roundedBox(cw * 0.74, backCushH, ch * 0.12, radius * 1.3, fabric, 12);
    backCushion.position.set(0, seatTopY + backCushH * 0.5, postZ + ch * 0.07);
    backCushion.rotation.x = -0.12;
    // puff the front face
    (function puffBack() {
      const p = backCushion.geometry.attributes.position;
      const hw = cw * 0.37, hh = backCushH * 0.5;
      for (let i = 0; i < p.count; i++) {
        let x = p.getX(i), y = p.getY(i), z = p.getZ(i);
        if (z > 0) {
          const fx = Math.abs(x) / hw, fy = Math.abs(y) / hh;
          z += (1 - Math.max(fx, fy)) * 0.016 * FT;
        }
        p.setXYZ(i, x, y, z);
      }
      p.needsUpdate = true;
      backCushion.geometry.computeVertexNormals();
    })();
    softFabric(backCushion);
    group.add(backCushion);

    // vertical seam dividing the back cushion (tufted look)
    const seam = roundedBox(0.012 * FT, backCushH * 0.86, 0.02 * FT, 0.006 * FT, fabric, 3);
    seam.position.set(0, seatTopY + backCushH * 0.5, postZ + ch * 0.07 + ch * 0.06);
    seam.rotation.x = -0.12;
    group.add(seam);

    //==========================================================
    // CONTACT SHADOW + finishing
    //==========================================================
    const shadow = new THREE.Mesh(
      new THREE.PlaneGeometry(cw * 1.15, cd * 1.15),
      new THREE.MeshBasicMaterial({
        map: makeRadialShadowTexture(),
        transparent: true,
        opacity: 0.45,
        depthWrite: false,
      })
    );
    shadow.rotation.x = -Math.PI / 2;
    shadow.position.set(0, 0.0015 * FT, 0);
    group.add(shadow);

    group.traverse((node) => {
      if (!node.isMesh) return;
      node.castShadow = true;
      node.receiveShadow = true;
    });

    return group;
  }

  //----------------------------------------------------------
  // EXPORT
  //----------------------------------------------------------
  global.PremiumChairBuilder = { build: buildPremiumChair };

})(typeof window !== 'undefined' ? window : global);
