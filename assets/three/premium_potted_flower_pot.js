/* global THREE */
(function (global) {
  'use strict';

  const FT = 0.3048;

  function randomBetween(a, b) {
    return a + Math.random() * (b - a);
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

    vein.position.y = length * 0.5;

    const vp = vein.geometry.attributes.position;
    for (let i = 0; i < vp.count; i++) {
      let x = vp.getX(i);
      let y = vp.getY(i);
      let z = vp.getZ(i);

      const t = y / length;

      z += Math.sin(t * Math.PI) * length * 0.035;

      vp.setXYZ(i, x, y, z);
    }
    vp.needsUpdate = true;
    vein.geometry.computeVertexNormals();

    group.add(vein);

    //----------------------------------------------------------
    // LEAFLETS
    //----------------------------------------------------------

    const leafletCount = 34;

    for (let i = 0; i < leafletCount; i++) {
      const t = i / (leafletCount - 1);

      const y = t * length;

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

        leaflet.rotation.z = side * randomBetween(0.70, 0.95);
        leaflet.rotation.y = side * randomBetween(0.20, 0.35);
        leaflet.rotation.x = randomBetween(-0.08, 0.08);

        group.add(leaflet);
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

    const potMat = renderer._makeMaterial(
      item.color,
      0.78,
      0.05,
      textureUrl,
      textureUrl ? null : null,
      1,
      1
    );
    const soilMat = new THREE.MeshStandardMaterial({
      color: 0x4e342e,
      roughness: 0.96,
      metalness: 0.0,
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
    });

    const potH = fh * 0.28;
    const potTop = radius * 0.95;
    const potBottom = radius * 0.68;

    const potBodyHeight = potH * 0.74;
    const rimHeight = potH * 0.26;

    const potBody = new THREE.Mesh(
      new THREE.CylinderGeometry(
        potTop * 0.98,
        potBottom,
        potBodyHeight,
        48
      ),
      renderer._makeMaterial('#b98769', 0.92, 0, null, null, 1, 1)
    );
    potBody.position.y = potBodyHeight * 0.5;
    group.add(potBody);

    const rim = new THREE.Mesh(
      new THREE.CylinderGeometry(
        potTop,
        potTop * 0.97,
        rimHeight,
        48
      ),
      renderer._makeMaterial('#efefef', 0.32, 0, null, null, 1, 1)
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
    group.add(soil);

    const plantGroup = new THREE.Group();
    plantGroup.position.y = soil.position.y + 0.01;
    group.add(plantGroup);

    //----------------------------------------------------------
    // PALM STEMS
    //----------------------------------------------------------

    const stemCount = 60;
    const stemMinHeight = fh * 0.42;
    const stemMaxHeight = fh * 0.74;
    const stemRadius = radius * 0.010;
    const clusterRadius = radius * 0.30;

    //----------------------------------------------------------
    // FRONDS
    //----------------------------------------------------------

    const frondCount = 58;
    const frondMin = fh * 0.34;
    const frondMax = fh * 0.52;

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
    // CREATE FRONDS
    //----------------------------------------------------------

    for (let i = 0; i < frondCount; i++) {
      const stem = stems[Math.floor(Math.random() * stems.length)];

      const length = randomBetween(frondMin, frondMax);

      const frond = createPalmFrond(length, leafMat);

      frond.position.copy(stem.mesh.position);

      frond.position.y = stem.height * 0.72;

      plantGroup.add(frond);

      frond.rotation.y = Math.random() * Math.PI * 2;

      frond.rotation.x = randomBetween(-0.6, -0.15);

      frond.rotation.z = randomBetween(-0.45, 0.45);

      const s = randomBetween(0.8, 1.25);

      frond.scale.set(s, s, s);

      frond.traverse((obj) => {
        if (!obj.isMesh) return;

        obj.material = obj.material.clone();

        obj.material.color.offsetHSL(
          randomBetween(-0.02, 0.02),
          randomBetween(-0.05, 0.05),
          randomBetween(-0.08, 0.04)
        );
      });

      frond.rotation.x -= randomBetween(0.15, 0.45);
    }

    group.traverse((obj) => {
      if (obj.isMesh) {
        obj.castShadow = true;
        obj.receiveShadow = true;
      }
    });

    return group;
  }

  global.PremiumPottedFlowerPotBuilder = {
    build: buildPremiumPottedFlowerPot,
  };
})(typeof window !== 'undefined' ? window : global);
