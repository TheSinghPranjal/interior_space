/* global THREE */
(function (global) {
  'use strict';

  const FT = 0.3048;

  function randomBetween(a, b) {
    return a + Math.random() * (b - a);
  }

  function createPalmLeaf(length, material) {
    const leaf = new THREE.Mesh(
      new THREE.PlaneGeometry(
        length,
        length * 0.07,
        4,
        1
      ),
      material
    );

    const pos = leaf.geometry.attributes.position;

    for (let i = 0; i < pos.count; i++) {
      const x = pos.getX(i);
      const y = pos.getY(i);

      const t = (x + length * 0.5) / length;

      pos.setXYZ(
        i,
        x,
        y,
        Math.sin(t * Math.PI) * length * 0.02
      );
    }

    pos.needsUpdate = true;
    leaf.geometry.computeVertexNormals();

    return leaf;
  }

  function buildPremiumPottedFlowerPot(renderer, item, textureUrl) {
    const fw = item.width * FT;
    const fh = item.height * FT;
    const fd = item.depth * FT;
    const radius = Math.min(fw, fd) * 0.4;
    const group = new THREE.Group();

    void renderer;
    void textureUrl;

    const soilMat = new THREE.MeshStandardMaterial({
      color: 0x463126,
      roughness: 1,
      metalness: 0,
    });
    const stemMat = new THREE.MeshStandardMaterial({
      color: 0x3c7d2b,
      roughness: 0.95,
      metalness: 0,
    });
    const leafMat = new THREE.MeshStandardMaterial({
      color: 0x3d7f2e,
      roughness: 0.86,
      metalness: 0,
      side: THREE.DoubleSide,
    });

    const potH = fh * 0.28;
    const potTop = radius * 0.95;
    const potBottom = radius * 0.68;

    const potBodyHeight = potH * 0.74;
    const rimHeight = potH * 0.26;

    const ceramicPotMat = new THREE.MeshPhysicalMaterial({
      color: 0xb88767,
      roughness: 0.42,
      metalness: 0.02,
      clearcoat: 0.85,
      clearcoatRoughness: 0.12,
      envMapIntensity: 2.2,
    });

    const potBody = new THREE.Mesh(
      new THREE.CylinderGeometry(
        potTop * 0.98,
        potBottom,
        potBodyHeight,
        32
      ),
      ceramicPotMat
    );
    potBody.position.y = potBodyHeight * 0.5;
    group.add(potBody);

    const rimMat = new THREE.MeshPhysicalMaterial({
      color: 0xf8f8f6,
      roughness: 0.22,
      metalness: 0,
      clearcoat: 1,
      clearcoatRoughness: 0.05,
      envMapIntensity: 2.4,
    });

    const rim = new THREE.Mesh(
      new THREE.CylinderGeometry(
        potTop,
        potTop * 0.97,
        rimHeight,
        32
      ),
      rimMat
    );
    rim.position.y = potBodyHeight + rimHeight * 0.5 - 0.003;
    group.add(rim);

    const soil = new THREE.Mesh(
      new THREE.CylinderGeometry(
        potTop * 0.88,
        potTop * 0.88,
        0.02,
        24
      ),
      soilMat
    );
    soil.position.y = potBodyHeight + rimHeight - 0.01;

    const soilPos = soil.geometry.attributes.position;
    for (let i = 0; i < soilPos.count; i++) {
      let x = soilPos.getX(i);
      let y = soilPos.getY(i);
      const z = soilPos.getZ(i);

      if (y > 0) {
        y += (Math.random() - 0.5) * 0.006;
      }

      soilPos.setXYZ(i, x, y, z);
    }
    soilPos.needsUpdate = true;
    soil.geometry.computeVertexNormals();

    group.add(soil);

    const plantGroup = new THREE.Group();
    plantGroup.position.y = soil.position.y + 0.01;
    group.add(plantGroup);

    const stemMinHeight = fh * 0.42;
    const stemMaxHeight = fh * 0.74;
    const stemRadius = radius * 0.010;
    const clusterRadius = radius * 0.26;
    const stemCount = 45;
    const leafLevels = 3;

    for (let i = 0; i < stemCount; i++) {
      const angle = Math.random() * Math.PI * 2;
      const r = Math.sqrt(Math.random()) * clusterRadius;
      const x = Math.cos(angle) * r;
      const z = Math.sin(angle) * r;

      const h =
        stemMinHeight +
        Math.pow(Math.random(), 1.6) * (stemMaxHeight - stemMinHeight);

      const stem = new THREE.Mesh(
        new THREE.CylinderGeometry(
          stemRadius * 0.65,
          stemRadius,
          h,
          6
        ),
        stemMat
      );

      stem.position.set(x, h * 0.5, z);
      stem.rotation.y = Math.random() * Math.PI * 2;

      stem.castShadow = true;
      stem.receiveShadow = true;

      plantGroup.add(stem);

      for (let l = 0; l < leafLevels; l++) {
        const y =
          h * (0.42 + l * 0.17) +
          randomBetween(-0.01, 0.01);

        [-1, 1].forEach((side) => {
          const leaf = createPalmLeaf(
            randomBetween(fh * 0.12, fh * 0.18),
            leafMat
          );

          leaf.position.set(
            side * 0.012,
            y,
            0
          );

          leaf.rotation.z = side * 0.65;
          leaf.rotation.y = randomBetween(-0.3, 0.3);

          leaf.castShadow = true;
          leaf.receiveShadow = true;

          stem.add(leaf);
        });
      }
    }

    group.traverse((obj) => {
      if (!obj.isMesh) return;
      obj.castShadow = true;
      obj.receiveShadow = true;
      obj.frustumCulled = true;
    });

    group.userData = {
      type: 'plant',
      category: 'decor',
      species: 'ArecaPalm',
      editable: true,
      resizable: true,
      rotatable: true,
      material: 'ceramic',
    };

    const box = new THREE.Box3().setFromObject(group);
    const center = new THREE.Vector3();
    box.getCenter(center);

    group.position.x -= center.x;
    group.position.z -= center.z;
    group.position.y -= box.min.y;

    return group;
  }

  global.PremiumPottedFlowerPotBuilder = {
    build: buildPremiumPottedFlowerPot,
  };
})(typeof window !== 'undefined' ? window : global);
