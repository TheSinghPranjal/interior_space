/* global THREE */
(function (global) {
  'use strict';

  const FT = 0.3048;

  function createRoundedBox(width, height, depth, radius, material) {
    radius = Math.min(radius, width * 0.45, height * 0.45, depth * 0.45);

    const shape = new THREE.Shape();
    shape.moveTo(-width / 2 + radius, -height / 2);
    shape.lineTo(width / 2 - radius, -height / 2);
    shape.quadraticCurveTo(width / 2, -height / 2, width / 2, -height / 2 + radius);
    shape.lineTo(width / 2, height / 2 - radius);
    shape.quadraticCurveTo(width / 2, height / 2, width / 2 - radius, height / 2);
    shape.lineTo(-width / 2 + radius, height / 2);
    shape.quadraticCurveTo(-width / 2, height / 2, -width / 2, height / 2 - radius);
    shape.lineTo(-width / 2, -height / 2 + radius);
    shape.quadraticCurveTo(-width / 2, -height / 2, -width / 2 + radius, -height / 2);

    const geometry = new THREE.ExtrudeGeometry(shape, {
      depth: depth,
      bevelEnabled: true,
      bevelSegments: 8,
      steps: 1,
      bevelSize: radius * 0.45,
      bevelThickness: radius * 0.45,
      curveSegments: 18,
    });

    geometry.center();
    return new THREE.Mesh(geometry, material);
  }

  function deformVertices(mesh, fn) {
    const pos = mesh.geometry.attributes.position;
    if (!pos) return;
    for (let i = 0; i < pos.count; i++) {
      let x = pos.getX(i);
      let y = pos.getY(i);
      let z = pos.getZ(i);
      const out = fn(x, y, z, i);
      if (out) {
        x = out.x !== undefined ? out.x : x;
        y = out.y !== undefined ? out.y : y;
        z = out.z !== undefined ? out.z : z;
      }
      pos.setXYZ(i, x, y, z);
    }
    pos.needsUpdate = true;
    mesh.geometry.computeVertexNormals();
  }

  function applyFabricBulge(meshes) {
    meshes.forEach((mesh) => {
      deformVertices(mesh, (x, y, z) => ({
        z: z + Math.sin(x * 6) * Math.cos(y * 3) * 0.004,
      }));
    });
  }

  function buildPremiumBed(renderer, item, textureUrl) {
    const fw = item.width * FT;
    const fd = item.depth * FT;
    const group = new THREE.Group();

    const frameHeight = 0.34 * FT;
    const railWidth = 0.18 * FT;
    const radius = Math.min(fw, fd) * 0.035;

    const frameMat = renderer._makeMaterial(
      item.color,
      0.92,
      0.03,
      textureUrl,
      textureUrl ? null : 'fabric',
      2,
      2
    );

    // Base platform
    const base = createRoundedBox(fw, frameHeight, fd, radius, frameMat);
    base.position.y = frameHeight / 2;
    group.add(base);

    // Side rails
    const leftRail = createRoundedBox(railWidth, frameHeight, fd, radius, frameMat);
    leftRail.position.set(-fw / 2 + railWidth / 2, frameHeight / 2, 0);
    group.add(leftRail);

    const rightRail = leftRail.clone();
    rightRail.position.x = fw / 2 - railWidth / 2;
    group.add(rightRail);

    // Foot rail
    const footRail = createRoundedBox(fw, frameHeight, railWidth, radius, frameMat);
    footRail.position.set(0, frameHeight / 2, fd / 2 - railWidth / 2);
    group.add(footRail);

    // Wooden legs
    const legMat = new THREE.MeshStandardMaterial({
      color: 0x7a5535,
      roughness: 0.82,
      metalness: 0.02,
    });
    const legRadius = 0.05 * FT;
    const legHeight = 0.18 * FT;
    [[-1, -1], [1, -1], [-1, 1], [1, 1]].forEach((c) => {
      const leg = new THREE.Mesh(
        new THREE.CylinderGeometry(legRadius, legRadius * 0.9, legHeight, 18),
        legMat
      );
      leg.position.set(
        c[0] * (fw / 2 - legRadius * 3),
        legHeight / 2,
        c[1] * (fd / 2 - legRadius * 3)
      );
      group.add(leg);
    });

    // Mattress
    const mattressHeight = 0.42 * FT;
    const mattressMat = new THREE.MeshStandardMaterial({
      color: 0xf7f4ef,
      roughness: 0.98,
      metalness: 0,
    });
    const mattress = createRoundedBox(
      fw - railWidth * 1.4,
      mattressHeight,
      fd - railWidth * 1.3,
      radius * 1.4,
      mattressMat
    );
    mattress.position.y = frameHeight + mattressHeight / 2 + 0.015 * FT;
    group.add(mattress);

    deformVertices(mattress, (x, y, z) => {
      const edge = Math.abs(x) / (fw * 0.5) + Math.abs(z) / (fd * 0.5);
      if (edge > 1.2) {
        return {
          y: y + 0.005 * Math.sin(x * 12) + 0.004 * Math.cos(z * 10),
        };
      }
      return null;
    });

    deformVertices(mattress, (x, y, z) => ({
      y: y + Math.sin(x * 18) * 0.003 + Math.cos(z * 18) * 0.003,
    }));

    // Headboard
    const headboardHeight = 2.35 * FT;
    const headboardThickness = 0.18 * FT;
    const headboard = createRoundedBox(
      fw * 1.02,
      headboardHeight,
      headboardThickness,
      radius * 1.3,
      frameMat
    );
    headboard.position.set(0, headboardHeight * 0.5 + frameHeight, -fd / 2 + headboardThickness / 2);
    group.add(headboard);

    const panel = createRoundedBox(
      fw * 0.9,
      headboardHeight * 0.82,
      0.05 * FT,
      radius,
      frameMat
    );
    panel.position.set(
      0,
      headboardHeight * 0.5 + frameHeight,
      -fd / 2 + headboardThickness + 0.015 * FT
    );
    group.add(panel);

    const channelCount = 6;
    for (let i = 0; i < channelCount; i++) {
      const strip = createRoundedBox(
        fw * 0.11,
        headboardHeight * 0.75,
        0.018 * FT,
        radius * 0.6,
        frameMat
      );
      strip.position.set(
        -fw * 0.34 + i * (fw * 0.135),
        headboardHeight * 0.5 + frameHeight,
        -fd / 2 + headboardThickness + 0.04 * FT
      );
      group.add(strip);
    }

    const wingWidth = 0.08 * FT;
    const leftWing = createRoundedBox(
      wingWidth,
      headboardHeight,
      headboardThickness * 1.1,
      radius,
      frameMat
    );
    leftWing.position.set(-fw / 2, headboardHeight * 0.5 + frameHeight, -fd / 2 + headboardThickness / 2);
    group.add(leftWing);

    const rightWing = leftWing.clone();
    rightWing.position.x = fw / 2;
    group.add(rightWing);

    applyFabricBulge([headboard, panel]);

    // Luxury duvet
    const duvetHeight = 0.18 * FT;
    const duvetMat = new THREE.MeshStandardMaterial({
      color: 0xf7f7f5,
      roughness: 0.99,
      metalness: 0,
      envMapIntensity: 0.2,
    });
    const duvet = createRoundedBox(
      fw * 0.97,
      duvetHeight,
      fd * 0.74,
      radius * 1.7,
      duvetMat
    );
    duvet.position.set(
      0,
      frameHeight + mattressHeight + duvetHeight * 0.45,
      fd * 0.08
    );
    group.add(duvet);

    deformVertices(duvet, (x, y, z) => {
      const nx = Math.abs(x) / (fw * 0.5);
      const nz = Math.abs(z) / (fd * 0.5);
      return {
        y: y + 0.015 + Math.cos(nx * Math.PI) * 0.02 + Math.cos(nz * Math.PI) * 0.015,
      };
    });

    duvet.scale.set(1.03, 1, 1.02);

    deformVertices(duvet, (x, y, z) => ({
      y: y + Math.sin(x * 12) * 0.005 + Math.cos(z * 8) * 0.004 + Math.sin((x + z) * 14) * 0.003,
    }));

    deformVertices(duvet, (x, y, z) => {
      if (z < 0) {
        return { y: y + 0.018 * Math.exp(z * 5) };
      }
      return null;
    });

    duvet.rotation.x = -0.01;
    duvet.scale.set(1.05, 1, 1.03);
    duvet.rotation.x = -0.015;

    deformVertices(duvet, (x, y, z) => {
      const d = Math.sqrt(x * x + z * z);
      return { y: y - Math.max(0, d * 0.004) };
    });

    const border = createRoundedBox(
      fw * 0.96,
      0.012 * FT,
      fd * 0.72,
      radius * 0.6,
      new THREE.MeshStandardMaterial({ color: 0xe9e9e7, roughness: 0.96 })
    );
    border.position.copy(duvet.position);
    border.position.y += 0.015 * FT;
    group.add(border);

    // Premium pillows
    const pillowMat = new THREE.MeshStandardMaterial({
      color: 0xfbfbf9,
      roughness: 0.98,
      metalness: 0,
      envMapIntensity: 0.15,
    });
    const pillowWidth = fw * 0.28;
    const pillowHeight = 0.18 * FT;
    const pillowDepth = fd * 0.18;
    const pillowY = frameHeight + mattressHeight + pillowHeight * 0.6;
    const pillowZ = -fd * 0.28;
    const pillows = [];

    [-1, 1].forEach((side) => {
      const pillow = createRoundedBox(
        pillowWidth,
        pillowHeight,
        pillowDepth,
        radius * 1.7,
        pillowMat
      );
      pillow.position.set(side * fw * 0.19, pillowY, pillowZ);
      pillow.rotation.x = -0.18;
      pillow.rotation.z = side * 0.05;
      pillows.push(pillow);
      group.add(pillow);
    });

    pillows.forEach((pillow) => {
      deformVertices(pillow, (x, y, z) => ({
        y: y + 0.015 + Math.cos(x * 12) * 0.012 + Math.cos(z * 12) * 0.01,
      }));
      deformVertices(pillow, (x, y, z) => {
        if (y < 0) return { y: y * 0.65 };
        return null;
      });
      deformVertices(pillow, (x, y, z) => ({
        y: y + Math.sin(x * 18) * 0.003 + Math.cos(z * 15) * 0.003,
      }));
      deformVertices(pillow, (x, y, z) => {
        const r = Math.sqrt(x * x + z * z);
        return { y: y - Math.exp(-r * 15) * 0.018 };
      });
      pillow.rotation.x += (Math.random() - 0.5) * 0.03;
      pillow.rotation.z += (Math.random() - 0.5) * 0.03;
    });

    pillows.forEach((p) => {
      p.position.z -= 0.03 * FT;
    });

    [-1, 1].forEach((side) => {
      const deco = createRoundedBox(
        pillowWidth * 0.65,
        pillowHeight * 0.75,
        pillowDepth * 0.65,
        radius * 1.6,
        pillowMat
      );
      deco.position.set(side * fw * 0.12, pillowY + 0.03 * FT, pillowZ + 0.1 * FT);
      deco.rotation.x = -0.1;
      deco.rotation.z = side * 0.12;
      group.add(deco);
    });

    // Mattress piping & stitching
    const piping = createRoundedBox(
      fw * 0.93,
      0.025 * FT,
      fd * 0.93,
      radius,
      new THREE.MeshStandardMaterial({ color: 0xffffff, roughness: 0.92 })
    );
    piping.position.y = frameHeight + mattressHeight - 0.015 * FT;
    group.add(piping);

    const stitchMat = new THREE.MeshStandardMaterial({ color: 0xe9e4dc, roughness: 0.96 });
    const stitchThickness = 0.01 * FT;
    const leftStitch = new THREE.Mesh(
      new THREE.BoxGeometry(stitchThickness, mattressHeight * 0.92, fd * 0.88),
      stitchMat
    );
    leftStitch.position.set(-(fw * 0.47), frameHeight + mattressHeight / 2, 0);
    group.add(leftStitch);

    const rightStitch = leftStitch.clone();
    rightStitch.position.x *= -1;
    group.add(rightStitch);

    const frontStitch = new THREE.Mesh(
      new THREE.BoxGeometry(fw * 0.9, mattressHeight * 0.92, stitchThickness),
      stitchMat
    );
    frontStitch.position.set(0, frameHeight + mattressHeight / 2, fd * 0.44);
    group.add(frontStitch);

    // Shadow gap & ambient occlusion
    const gap = new THREE.Mesh(
      new THREE.BoxGeometry(fw * 0.94, 0.01 * FT, fd * 0.94),
      new THREE.MeshBasicMaterial({ color: 0x111111, transparent: true, opacity: 0.18 })
    );
    gap.position.y = frameHeight + 0.01 * FT;
    group.add(gap);

    const ao = new THREE.Mesh(
      new THREE.PlaneGeometry(fw * 0.94, fd * 0.94),
      new THREE.MeshBasicMaterial({ color: 0x000000, transparent: true, opacity: 0.08 })
    );
    ao.rotation.x = -Math.PI / 2;
    ao.position.y = frameHeight + 0.005;
    group.add(ao);

    const shadow = new THREE.Mesh(
      new THREE.PlaneGeometry(fw * 1.15, fd * 1.15),
      new THREE.MeshBasicMaterial({
        color: 0x000000,
        transparent: true,
        opacity: 0.14,
        depthWrite: false,
      })
    );
    shadow.rotation.x = -Math.PI / 2;
    shadow.position.y = 0.002;
    group.add(shadow);

    // Subtle fabric noise on upholstered meshes
    group.traverse((mesh) => {
      if (!mesh.isMesh) return;
      const pos = mesh.geometry.attributes.position;
      if (!pos || mesh.material === legMat) return;
      for (let i = 0; i < pos.count; i++) {
        const x = pos.getX(i);
        const y = pos.getY(i) + (Math.random() - 0.5) * 0.0008;
        const z = pos.getZ(i);
        pos.setXYZ(i, x, y, z);
      }
      pos.needsUpdate = true;
    });

    // Material quality & shadows
    group.traverse((obj) => {
      if (!obj.isMesh) return;
      if (obj.material && obj.material.isMeshStandardMaterial) {
        obj.material.roughness = Math.min(obj.material.roughness ?? 0.9, 0.96);
        obj.material.metalness = 0;
        if (obj.material.envMapIntensity === undefined) {
          obj.material.envMapIntensity = 0.35;
        }
      }
      obj.castShadow = true;
      obj.receiveShadow = true;
      obj.renderOrder = 1;
    });

    return group;
  }

  global.PremiumBedBuilder = {
    build: buildPremiumBed,
    createRoundedBox: createRoundedBox,
  };
})(typeof window !== 'undefined' ? window : global);
