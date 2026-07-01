/* global THREE */
(function (global) {
  'use strict';

  const FT = 0.3048;

  function randomBetween(a, b) {
    return a + Math.random() * (b - a);
  }

  function applyFrondColorVariation(frond) {
    frond.traverse((obj) => {
      if (!obj.isMesh) return;

      obj.material = obj.material.clone();

      obj.material.color.offsetHSL(
        randomBetween(-0.01, 0.015),
        randomBetween(-0.10, 0.08),
        randomBetween(-0.12, 0.08)
      );

      if (typeof obj.material.roughness === 'number') {
        obj.material.roughness = randomBetween(0.78, 0.90);
      }
    });
  }

  function applyWindVariation(frond) {
    frond.rotation.z += randomBetween(-0.08, 0.08);
    frond.rotation.y += randomBetween(-0.10, 0.10);
    frond.rotation.x += randomBetween(-0.05, 0.05);
  }

  function finalizeFrondPlacement(frond, plantGroup) {
    plantGroup.add(frond);
    applyWindVariation(frond);
    applyFrondColorVariation(frond);
  }

  //----------------------------------------------------------
  // PALM FROND
  //----------------------------------------------------------

  function createPalmFrond(length, material) {
    const group = new THREE.Group();

    // Center vein
    const vein = new THREE.Mesh(
      new THREE.CylinderGeometry(
        0.0015,
        0.0022,
        length,
        6
      ),
      material
    );

    //----------------------------------------------------------
    // CURVED VEIN
    //----------------------------------------------------------

    const veinPos = vein.geometry.attributes.position;

    for (let i = 0; i < veinPos.count; i++) {
      let x = veinPos.getX(i);
      let y = veinPos.getY(i);
      let z = veinPos.getZ(i);

      const t = y / length;

      z += Math.sin(t * Math.PI) * length * 0.045;

      x += Math.sin(t * Math.PI * 0.5) * length * 0.01;

      veinPos.setXYZ(i, x, y, z);
    }

    veinPos.needsUpdate = true;
    vein.geometry.computeVertexNormals();

    vein.position.y = length * 0.5;

    group.add(vein);

    //----------------------------------------------------------
    // FROND TWIST
    //----------------------------------------------------------

    group.rotation.y = randomBetween(-0.25, 0.25);

    //----------------------------------------------------------
    // LEAFLETS
    //----------------------------------------------------------

    const leafletCount = 40;

    for (let i = 0; i < leafletCount; i++) {
      const t = i / (leafletCount - 1);

      const y =
        t * length +
        randomBetween(-0.004, 0.004);

      const centerWeight = 1 - Math.abs(t - 0.5) * 2;

      const leafletLength =
        length *
        (0.07 +
          centerWeight * 0.18 +
          randomBetween(-0.015, 0.015));

      [-1, 1].forEach((side) => {
        const leaflet = new THREE.Mesh(
          new THREE.PlaneGeometry(
            leafletLength,
            leafletLength * 0.055,
            4,
            1
          ),
          material
        );

        leaflet.position.set(
          side * leafletLength * 0.28,
          y,
          0
        );

        leaflet.position.y -= Math.pow(t, 2) * 0.02;

        const pos = leaflet.geometry.attributes.position;

        for (let j = 0; j < pos.count; j++) {
          let x = pos.getX(j);
          let ly = pos.getY(j);

          const lt = (x + leafletLength * 0.5) / leafletLength;

          const scale = 1.0 - lt * 0.75;

          ly *= scale;

          pos.setXY(j, x, ly);
        }

        pos.needsUpdate = true;
        leaflet.geometry.computeVertexNormals();

        const p = leaflet.geometry.attributes.position;

        for (let j = 0; j < p.count; j++) {
          let x = p.getX(j);
          let ly = p.getY(j);
          let z = p.getZ(j);

          const lt = (x + leafletLength * 0.5) / leafletLength;

          z += Math.sin(lt * Math.PI) * leafletLength * 0.03;

          p.setXYZ(j, x, ly, z);
        }

        p.needsUpdate = true;
        leaflet.geometry.computeVertexNormals();

        const droop = Math.pow(t, 1.6);

        leaflet.rotation.z =
          side *
          randomBetween(0.75, 1.0);

        leaflet.rotation.y =
          side * randomBetween(0.20, 0.35);

        leaflet.rotation.x =
          -droop *
          randomBetween(0.25, 0.45);

        leaflet.scale.set(
          randomBetween(0.9, 1.15),
          randomBetween(0.85, 1.1),
          1
        );

        if (Math.random() > 0.06) {
          group.add(leaflet);
        }
      });
    }

    return group;
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
    const stemMat = new THREE.MeshPhysicalMaterial({
      color: 0x3c7d2b,
      roughness: 0.95,
      metalness: 0,
      clearcoat: 0.05,
    });
    const leafMat = new THREE.MeshPhysicalMaterial({
      color: 0x3d7f2e,
      roughness: 0.86,
      metalness: 0,
      side: THREE.DoubleSide,
      clearcoat: 0.08,
      transparent: true,
      opacity: 0.98,
      depthWrite: true,
    });
    if ('transmission' in leafMat) {
      leafMat.transmission = 0.04;
    }

    const potH = fh * 0.28;
    const potTop = radius * 0.95;
    const potBottom = radius * 0.68;

    const potBodyHeight = potH * 0.74;
    const rimHeight = potH * 0.26;

    //----------------------------------------------------------
    // CERAMIC POT
    //----------------------------------------------------------

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
        48
      ),
      ceramicPotMat
    );
    potBody.position.y = potBodyHeight * 0.5;
    group.add(potBody);

    //----------------------------------------------------------
    // CERAMIC RIM
    //----------------------------------------------------------

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
        48
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
        40
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

    //----------------------------------------------------------
    // PALM STEMS
    //----------------------------------------------------------

    const stemMinHeight = fh * 0.42;
    const stemMaxHeight = fh * 0.74;
    const stemRadius = radius * 0.010;
    const clusterRadius = radius * 0.46;

    //----------------------------------------------------------
    // STEM DENSITY
    //----------------------------------------------------------

    const stemCount = 85;

    //----------------------------------------------------------
    // DENSE CANOPY
    //----------------------------------------------------------

    const innerFronds = 24;
    const middleFronds = 34;
    const outerFronds = 30;

    //----------------------------------------------------------
    // STEMS
    //----------------------------------------------------------

    const stems = [];

    for (let i = 0; i < stemCount; i++) {
      const angle = Math.random() * Math.PI * 2;
      const r = Math.sqrt(Math.random()) * clusterRadius;
      const x = Math.cos(angle) * r;
      const z = Math.sin(angle) * r;

      const h = randomBetween(stemMinHeight, stemMaxHeight);

      const stem = new THREE.Mesh(
        new THREE.CylinderGeometry(
          stemRadius * 0.65,
          stemRadius,
          h,
          8
        ),
        stemMat
      );

      stem.position.set(x, h * 0.5, z);

      stem.rotation.z = (Math.random() - 0.5) * 0.15;
      stem.rotation.x = (Math.random() - 0.5) * 0.12;

      stem.material = stemMat.clone();
      stem.material.color.offsetHSL(0, 0, randomBetween(-0.05, 0.05));

      stem.castShadow = true;
      stem.receiveShadow = true;

      plantGroup.add(stem);

      stems.push({
        mesh: stem,
        height: h,
      });
    }

    stems.forEach((s) => {
      const scale = randomBetween(0.9, 1.12);
      s.mesh.scale.set(scale, 1, scale);
    });

    for (let i = 0; i < 18; i++) {
      const h = randomBetween(fh * 0.45, fh * 0.62);

      const stem = new THREE.Mesh(
        new THREE.CylinderGeometry(
          stemRadius * 0.6,
          stemRadius,
          h,
          8
        ),
        stemMat
      );

      stem.position.set(
        randomBetween(-0.02, 0.02),
        h * 0.5,
        randomBetween(-0.02, 0.02)
      );

      stem.material = stemMat.clone();
      stem.material.color.offsetHSL(0, 0, randomBetween(-0.05, 0.05));

      stem.castShadow = true;
      stem.receiveShadow = true;

      plantGroup.add(stem);

      stems.push({
        mesh: stem,
        height: h,
      });
    }

    //----------------------------------------------------------
    // INNER FRONDS
    //----------------------------------------------------------

    for (let i = 0; i < innerFronds; i++) {
      const stem = stems[Math.floor(Math.random() * stems.length)];

      const frond = createPalmFrond(
        randomBetween(fh * 0.34, fh * 0.42),
        leafMat
      );

      frond.position.copy(stem.mesh.position);
      frond.position.y = stem.height * 0.82;
      frond.rotation.y = Math.random() * Math.PI * 2;
      frond.rotation.x = randomBetween(-0.18, -0.05);
      frond.rotation.z = randomBetween(-0.15, 0.15);

      finalizeFrondPlacement(frond, plantGroup);
    }

    //----------------------------------------------------------
    // MIDDLE FRONDS
    //----------------------------------------------------------

    for (let i = 0; i < middleFronds; i++) {
      const stem = stems[Math.floor(Math.random() * stems.length)];

      const frond = createPalmFrond(
        randomBetween(fh * 0.42, fh * 0.55),
        leafMat
      );

      frond.position.copy(stem.mesh.position);
      frond.position.y = stem.height * 0.74;
      frond.rotation.y = Math.random() * Math.PI * 2;
      frond.rotation.x = randomBetween(-0.45, -0.25);
      frond.rotation.z = randomBetween(-0.35, 0.35);

      finalizeFrondPlacement(frond, plantGroup);
    }

    //----------------------------------------------------------
    // OUTER FRONDS
    //----------------------------------------------------------

    for (let i = 0; i < outerFronds; i++) {
      const stem = stems[Math.floor(Math.random() * stems.length)];

      const frond = createPalmFrond(
        randomBetween(fh * 0.52, fh * 0.66),
        leafMat
      );

      frond.position.copy(stem.mesh.position);
      frond.position.y = stem.height * 0.66;
      frond.rotation.y = Math.random() * Math.PI * 2;
      frond.rotation.x = randomBetween(-0.95, -0.60);
      frond.rotation.z = randomBetween(-0.55, 0.55);

      finalizeFrondPlacement(frond, plantGroup);
    }

    //----------------------------------------------------------
    // HANGING FRONDS
    //----------------------------------------------------------

    for (let i = 0; i < 18; i++) {
      const stem = stems[Math.floor(Math.random() * stems.length)];

      const frond = createPalmFrond(
        randomBetween(fh * 0.58, fh * 0.72),
        leafMat
      );

      frond.position.copy(stem.mesh.position);
      frond.position.y = stem.height * 0.58;
      frond.rotation.x = randomBetween(-1.25, -0.95);
      frond.rotation.y = Math.random() * Math.PI * 2;
      frond.rotation.z = randomBetween(-0.8, 0.8);

      finalizeFrondPlacement(frond, plantGroup);
    }

    //----------------------------------------------------------
    // FILL GAPS
    //----------------------------------------------------------

    for (let i = 0; i < 25; i++) {
      const stem = stems[Math.floor(Math.random() * stems.length)];

      const frond = createPalmFrond(
        randomBetween(fh * 0.38, fh * 0.50),
        leafMat
      );

      frond.position.copy(stem.mesh.position);
      frond.position.y = stem.height * 0.70;
      frond.rotation.y = Math.random() * Math.PI * 2;
      frond.rotation.x = randomBetween(-0.45, -0.25);
      frond.scale.set(0.75, 0.75, 0.75);

      finalizeFrondPlacement(frond, plantGroup);
    }

    //----------------------------------------------------------
    // TOP SHOOTS
    //----------------------------------------------------------

    for (let i = 0; i < 18; i++) {
      const frond = createPalmFrond(
        randomBetween(fh * 0.18, fh * 0.26),
        leafMat
      );

      frond.position.set(
        randomBetween(-0.015, 0.015),
        randomBetween(fh * 0.42, fh * 0.52),
        randomBetween(-0.015, 0.015)
      );

      frond.rotation.x = randomBetween(-0.05, 0.12);
      frond.rotation.y = Math.random() * Math.PI * 2;

      finalizeFrondPlacement(frond, plantGroup);
    }

    plantGroup.rotation.y = randomBetween(0, Math.PI * 2);

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
