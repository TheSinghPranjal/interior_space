/* global THREE */
(function (global) {
  'use strict';

  const FT = 0.3048;

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

  function buildPremiumFlowerPot(renderer, item, textureUrl) {
    const fw = item.width * FT;
    const fh = item.height * FT;
    const fd = item.depth * FT;
    const radius = Math.min(fw, fd) * 0.42;
    const group = new THREE.Group();

    const potMat = renderer._makeMaterial(
      item.color,
      0.82,
      0.04,
      textureUrl,
      textureUrl ? null : null,
      1,
      1
    );
    const soilMat = new THREE.MeshStandardMaterial({
      color: 0x4e342e,
      roughness: 0.95,
      metalness: 0.01,
    });

    const potHeight = fh * 0.3;
    const potRadiusTop = radius * 0.92;
    const potRadiusBottom = radius * 0.72;

    const pot = new THREE.Mesh(
      new THREE.CylinderGeometry(potRadiusTop, potRadiusBottom, potHeight, 48, 4, false),
      potMat
    );
    pot.position.y = potHeight * 0.5;
    group.add(pot);

    const rim = new THREE.Mesh(
      new THREE.TorusGeometry(potRadiusTop, radius * 0.08, 18, 48),
      potMat
    );
    rim.rotation.x = Math.PI / 2;
    rim.position.y = potHeight;
    group.add(rim);

    const saucer = new THREE.Mesh(
      new THREE.CylinderGeometry(radius * 1.05, radius * 1.12, fh * 0.035, 48),
      potMat
    );
    saucer.position.y = fh * 0.018;
    group.add(saucer);

    const soil = new THREE.Mesh(
      new THREE.CylinderGeometry(radius * 0.8, radius * 0.8, fh * 0.05, 32),
      soilMat
    );
    soil.position.y = potHeight - fh * 0.03;
    group.add(soil);

    deformVertices(soil, (x, y, z) => ({
      y: y + Math.random() * 0.01,
    }));

    const trunkHeight = fh * 0.62;
    const trunkRadius = radius * 0.08;
    const trunkMat = new THREE.MeshStandardMaterial({
      color: 0x6d5c41,
      roughness: 0.96,
      metalness: 0.02,
      bumpScale: 0.01,
    });

    const createTrunkPath = (offset) => {
      const points = [];
      const turns = 5;
      for (let i = 0; i <= 60; i++) {
        const t = i / 60;
        const angle = t * Math.PI * 2 * turns + offset;
        points.push(
          new THREE.Vector3(
            Math.cos(angle) * trunkRadius * 0.65,
            t * trunkHeight,
            Math.sin(angle) * trunkRadius * 0.65
          )
        );
      }
      return new THREE.CatmullRomCurve3(points);
    };

    const tube1 = new THREE.Mesh(
      new THREE.TubeGeometry(createTrunkPath(0), 80, trunkRadius * 0.42, 12, false),
      trunkMat
    );
    const tube2 = new THREE.Mesh(
      new THREE.TubeGeometry(createTrunkPath(Math.PI), 80, trunkRadius * 0.42, 12, false),
      trunkMat
    );
    tube1.position.y = potHeight;
    tube2.position.y = potHeight;
    group.add(tube1);
    group.add(tube2);

    const root = new THREE.Mesh(
      new THREE.CylinderGeometry(trunkRadius * 1.4, trunkRadius * 1.0, fh * 0.05, 16),
      trunkMat
    );
    root.position.y = potHeight + fh * 0.02;
    group.add(root);

    const branchBase = new THREE.Mesh(
      new THREE.SphereGeometry(trunkRadius * 1.2, 18, 18),
      trunkMat
    );
    branchBase.position.y = potHeight + trunkHeight;
    group.add(branchBase);

    const leafGeometry = new THREE.SphereGeometry(radius * 0.1, 8, 6);
    leafGeometry.scale(1.7, 0.28, 1.0);

    const leafMaterial = new THREE.MeshStandardMaterial({
      color: 0x2e7d32,
      roughness: 0.88,
      metalness: 0,
      side: THREE.DoubleSide,
    });

    const createLeafCluster = (cx, cy, cz, clusterRadius, count) => {
      const cluster = new THREE.Group();
      for (let i = 0; i < count; i++) {
        const leaf = new THREE.Mesh(leafGeometry, leafMaterial);
        const theta = Math.random() * Math.PI * 2;
        const phi = Math.random() * Math.PI;
        const r = clusterRadius * (0.25 + Math.random() * 0.75);
        leaf.position.set(
          Math.cos(theta) * Math.sin(phi) * r,
          Math.cos(phi) * r,
          Math.sin(theta) * Math.sin(phi) * r
        );
        leaf.rotation.x = Math.random() * Math.PI;
        leaf.rotation.y = Math.random() * Math.PI;
        leaf.rotation.z = Math.random() * Math.PI;
        leaf.scale.multiplyScalar(0.75 + Math.random() * 0.55);
        cluster.add(leaf);
      }
      cluster.position.set(cx, cy, cz);
      group.add(cluster);
    };

    const canopyY = potHeight + trunkHeight + radius * 0.1;

    createLeafCluster(0, canopyY, 0, radius * 1.15, 110);
    createLeafCluster(radius * 0.35, canopyY - radius * 0.18, radius * 0.18, radius * 0.95, 80);
    createLeafCluster(-radius * 0.35, canopyY - radius * 0.15, -radius * 0.12, radius * 0.95, 80);
    createLeafCluster(0, canopyY + radius * 0.28, 0, radius * 0.75, 60);

    for (let i = 0; i < 45; i++) {
      const leaf = new THREE.Mesh(leafGeometry, leafMaterial);
      const angle = Math.random() * Math.PI * 2;
      const r = radius * 1.05;
      leaf.position.set(
        Math.cos(angle) * r,
        canopyY - radius * 0.55 + Math.random() * radius * 0.25,
        Math.sin(angle) * r
      );
      leaf.rotation.z = Math.PI / 2;
      leaf.rotation.y = angle;
      group.add(leaf);
    }

    group.traverse((mesh) => {
      if (!mesh.isMesh) return;
      if (mesh.material !== leafMaterial) return;
      mesh.material = mesh.material.clone();
      const hsl = {};
      mesh.material.color.getHSL(hsl);
      mesh.material.color.setHSL(hsl.h, 0.65, 0.3 + Math.random() * 0.1);
    });

    group.traverse((mesh) => {
      if (!mesh.isMesh) return;
      if (mesh.geometry !== leafGeometry) return;
      mesh.rotation.x += (Math.random() - 0.5) * 0.35;
      mesh.rotation.z += (Math.random() - 0.5) * 0.35;
    });

    group.traverse((c) => {
      if (c.isMesh) {
        c.castShadow = true;
        c.receiveShadow = true;
      }
    });

    return group;
  }

  global.PremiumFlowerPotBuilder = {
    build: buildPremiumFlowerPot,
  };
})(typeof window !== 'undefined' ? window : global);
