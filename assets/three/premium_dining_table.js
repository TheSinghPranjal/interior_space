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

  function applyWoodGrain(topMat) {
    if (topMat.map) {
      topMat.map.rotation = Math.PI / 2;
      topMat.map.center.set(0.5, 0.5);
    }
  }

  function buildDiningChair(renderer, width, height, depth, frameMat, fabricMat) {
    const group = new THREE.Group();
    const seatH = height * 0.48;
    const legH = seatH;
    const legRadius = width * 0.03;

    const seat = renderer._createRoundedBox(
      width,
      height * 0.11,
      depth,
      width * 0.08,
      fabricMat
    );
    seat.position.y = legH;
    seat.scale.set(1.02, 1, 1.02);
    group.add(seat);

    const back = renderer._createRoundedBox(
      width,
      height * 0.55,
      depth * 0.1,
      width * 0.08,
      fabricMat
    );
    back.position.set(0, legH + height * 0.28, -depth * 0.45);
    back.rotation.x = -0.08;
    group.add(back);

    [[-1, -1], [-1, 1], [1, -1], [1, 1]].forEach((c) => {
      const leg = new THREE.Mesh(
        new THREE.CylinderGeometry(legRadius * 0.45, legRadius, legH, 12),
        frameMat
      );
      leg.position.set(c[0] * (width * 0.38), legH * 0.5, c[1] * (depth * 0.36));
      group.add(leg);
    });

    const frame = renderer._createRoundedBox(
      width * 0.92,
      height * 0.035,
      depth * 0.92,
      width * 0.05,
      frameMat
    );
    frame.position.y = legH - height * 0.03;
    group.add(frame);

    [-1, 1].forEach((side) => {
      const support = new THREE.Mesh(
        new THREE.CylinderGeometry(legRadius * 0.65, legRadius * 0.8, height * 0.42, 8),
        frameMat
      );
      support.position.set(side * width * 0.34, legH + height * 0.18, -depth * 0.39);
      support.rotation.x = -0.08;
      group.add(support);
    });

    const stitch = renderer._createRoundedBox(
      width * 0.88,
      0.004 * FT,
      depth * 0.88,
      width * 0.03,
      new THREE.MeshStandardMaterial({ color: 0xe8dfd5, roughness: 0.95 })
    );
    stitch.position.y = legH + height * 0.045;
    group.add(stitch);

    for (let i = -1; i <= 1; i++) {
      const vStitch = new THREE.Mesh(
        new THREE.BoxGeometry(0.003 * FT, height * 0.42, 0.004 * FT),
        new THREE.MeshStandardMaterial({ color: 0xd8d0c6, roughness: 0.96 })
      );
      vStitch.position.set(i * width * 0.18, height * 0.62, -depth * 0.4);
      group.add(vStitch);
    }

    [seat, back].forEach((mesh) => {
      deformVertices(mesh, (x, y, z) => ({
        y: y + Math.sin(x * 18) * 0.0025 + Math.cos(z * 16) * 0.002,
      }));
    });

    deformVertices(seat, (x, y, z) => ({
      y: y + Math.cos(x * 18) * 0.003 + Math.cos(z * 16) * 0.003,
    }));

    deformVertices(seat, (x, y, z) => {
      const r = Math.sqrt(x * x + z * z);
      return { y: y - Math.exp(-r * 18) * 0.008 };
    });

    deformVertices(back, (x, y, z) => ({
      z: z - Math.sin(y * 3) * 0.015,
    }));

    deformVertices(back, (x, y, z) => ({
      z: z + Math.sin(y * 7) * 0.004 + Math.cos(x * 12) * 0.002,
    }));

    group.rotation.x = -0.015;

    group.traverse((obj) => {
      if (obj.isMesh) {
        obj.castShadow = true;
        obj.receiveShadow = true;
      }
    });

    return group;
  }

  function pullChairsTowardTable(chairs) {
    chairs.forEach((chair) => {
      const dir = new THREE.Vector3();
      dir.subVectors(new THREE.Vector3(0, 0, 0), chair.position);
      dir.y = 0;
      dir.normalize();
      chair.position.add(dir.multiplyScalar(0.05 * FT));
    });
  }

  function addChairVariations(chairs) {
    chairs.forEach((chair) => {
      chair.rotation.y += (Math.random() - 0.5) * 0.05;
      chair.position.x += (Math.random() - 0.5) * 0.01 * FT;
      chair.position.z += (Math.random() - 0.5) * 0.01 * FT;
    });
  }

  function addChairShadows(chairs, chairWidth) {
    chairs.forEach((chair) => {
      const shadow = new THREE.Mesh(
        new THREE.CircleGeometry(chairWidth * 0.55, 24),
        new THREE.MeshBasicMaterial({
          color: 0x000000,
          transparent: true,
          opacity: 0.08,
          depthWrite: false,
        })
      );
      shadow.rotation.x = -Math.PI / 2;
      shadow.position.y = 0.003;
      chair.add(shadow);
    });
  }

  function placeRectangularChairs(group, chairs, fw, fd, chairWidth, chairDepth, chairGap) {
    const count = chairs.length;
    const frontX3 = [-fw * 0.28, 0, fw * 0.28];
    const frontX2 = [-fw * 0.2, fw * 0.2];

    if (count >= 8) {
      frontX3.forEach((x, i) => {
        const chair = chairs[i];
        chair.position.set(x, 0, fd / 2 + chairDepth * 0.65 + chairGap);
        chair.rotation.y = Math.PI;
        group.add(chair);
      });
      frontX3.forEach((x, i) => {
        const chair = chairs[i + 3];
        chair.position.set(x, 0, -fd / 2 - chairDepth * 0.65 - chairGap);
        group.add(chair);
      });
      const leftChair = chairs[6];
      leftChair.position.set(-fw / 2 - chairWidth * 0.72 - chairGap, 0, 0);
      leftChair.rotation.y = Math.PI / 2;
      group.add(leftChair);
      const rightChair = chairs[7];
      rightChair.position.set(fw / 2 + chairWidth * 0.72 + chairGap, 0, 0);
      rightChair.rotation.y = -Math.PI / 2;
      group.add(rightChair);
    } else if (count === 6) {
      frontX2.forEach((x, i) => {
        const chair = chairs[i];
        chair.position.set(x, 0, fd / 2 + chairDepth * 0.65 + chairGap);
        chair.rotation.y = Math.PI;
        group.add(chair);
      });
      frontX2.forEach((x, i) => {
        const chair = chairs[i + 2];
        chair.position.set(x, 0, -fd / 2 - chairDepth * 0.65 - chairGap);
        group.add(chair);
      });
      chairs[4].position.set(-fw / 2 - chairWidth * 0.72 - chairGap, 0, 0);
      chairs[4].rotation.y = Math.PI / 2;
      group.add(chairs[4]);
      chairs[5].position.set(fw / 2 + chairWidth * 0.72 + chairGap, 0, 0);
      chairs[5].rotation.y = -Math.PI / 2;
      group.add(chairs[5]);
    } else {
      const sides = [
        { x: 0, z: fd / 2 + chairDepth * 0.65 + chairGap, rot: Math.PI },
        { x: 0, z: -fd / 2 - chairDepth * 0.65 - chairGap, rot: 0 },
        { x: -fw / 2 - chairWidth * 0.72 - chairGap, z: 0, rot: Math.PI / 2 },
        { x: fw / 2 + chairWidth * 0.72 + chairGap, z: 0, rot: -Math.PI / 2 },
      ];
      sides.forEach((side, i) => {
        const chair = chairs[i];
        chair.position.set(side.x, 0, side.z);
        chair.rotation.y = side.rot;
        group.add(chair);
      });
    }
  }

  function placeRoundChairs(group, chairs, tableRadius, chairWidth, chairDepth, chairGap) {
    const count = chairs.length;
    for (let i = 0; i < count; i++) {
      const angle = (i / count) * Math.PI * 2;
      const dist = tableRadius + chairDepth * 0.65 + chairGap;
      const chair = chairs[i];
      chair.position.set(Math.cos(angle) * dist, 0, Math.sin(angle) * dist);
      chair.rotation.y = -angle + Math.PI / 2;
      group.add(chair);
    }
  }

  function buildRectangularTable(group, renderer, fw, fd, tableH, topMat, legMat) {
    const topThickness = 0.1 * FT;
    const cornerRadius = Math.min(fw, fd) * 0.08;
    const pedestalHeight = tableH - topThickness;

    const top = renderer._createRoundedBox(fw, topThickness, fd, cornerRadius, topMat);
    top.position.y = tableH - topThickness * 0.5;
    group.add(top);

    const underTop = renderer._createRoundedBox(
      fw * 0.94,
      topThickness * 0.45,
      fd * 0.94,
      cornerRadius * 0.8,
      topMat
    );
    underTop.position.y = tableH - topThickness - topThickness * 0.18;
    group.add(underTop);

    const edgeHeight = topThickness * 0.35;
    const edge = renderer._createRoundedBox(
      fw * 0.985,
      edgeHeight,
      fd * 0.985,
      cornerRadius,
      topMat
    );
    edge.position.y = tableH - topThickness + edgeHeight * 0.5;
    group.add(edge);

    const lip = renderer._createRoundedBox(
      fw * 0.92,
      0.018 * FT,
      fd * 0.92,
      cornerRadius * 0.6,
      topMat
    );
    lip.position.y = tableH - topThickness - 0.01 * FT;
    group.add(lip);

    const centerColumn = renderer._createRoundedBox(
      fw * 0.22,
      pedestalHeight * 0.78,
      fd * 0.28,
      cornerRadius,
      legMat
    );
    centerColumn.position.y = pedestalHeight * 0.39;
    group.add(centerColumn);

    const lowerColumn = renderer._createRoundedBox(
      fw * 0.28,
      pedestalHeight * 0.14,
      fd * 0.36,
      cornerRadius,
      legMat
    );
    lowerColumn.position.y = pedestalHeight * 0.08;
    group.add(lowerColumn);

    const base = renderer._createRoundedBox(
      fw * 0.55,
      0.05 * FT,
      fd * 0.3,
      cornerRadius,
      legMat
    );
    base.position.y = 0.025 * FT;
    group.add(base);

    deformVertices(top, (x, y, z) => {
      const edgeFactor = Math.max(Math.abs(x) / (fw * 0.5), Math.abs(z) / (fd * 0.5));
      if (edgeFactor > 0.82) {
        return { y: y - (edgeFactor - 0.82) * 0.008 };
      }
      return null;
    });

    deformVertices(top, (x, y, z) => ({
      y: y + Math.sin(x * 8) * 0.0015 + Math.cos(z * 5) * 0.0012,
    }));

    return { top, topThickness };
  }

  function buildRoundTable(group, renderer, tableRadius, tableH, topMat, legMat) {
    const topThickness = 0.1 * FT;
    const pedestalHeight = tableH - topThickness;

    const top = new THREE.Mesh(
      new THREE.CylinderGeometry(tableRadius, tableRadius * 0.98, topThickness, 48),
      topMat
    );
    top.position.y = tableH - topThickness * 0.5;
    group.add(top);

    const edge = new THREE.Mesh(
      new THREE.TorusGeometry(tableRadius * 0.98, topThickness * 0.18, 12, 48),
      topMat
    );
    edge.rotation.x = Math.PI / 2;
    edge.position.y = tableH - topThickness * 0.85;
    group.add(edge);

    const centerColumn = new THREE.Mesh(
      new THREE.CylinderGeometry(tableRadius * 0.11, tableRadius * 0.14, pedestalHeight * 0.78, 24),
      legMat
    );
    centerColumn.position.y = pedestalHeight * 0.39;
    group.add(centerColumn);

    const lowerColumn = new THREE.Mesh(
      new THREE.CylinderGeometry(tableRadius * 0.14, tableRadius * 0.18, pedestalHeight * 0.14, 24),
      legMat
    );
    lowerColumn.position.y = pedestalHeight * 0.08;
    group.add(lowerColumn);

    const base = new THREE.Mesh(
      new THREE.CylinderGeometry(tableRadius * 0.28, tableRadius * 0.32, 0.05 * FT, 32),
      legMat
    );
    base.position.y = 0.025 * FT;
    group.add(base);

    return { top, topThickness };
  }

  function addCenterpiece(group, tableH) {
    const vase = new THREE.Mesh(
      new THREE.CylinderGeometry(0.08 * FT, 0.1 * FT, 0.3 * FT, 20),
      new THREE.MeshStandardMaterial({ color: 0xf2f2f2, roughness: 0.25 })
    );
    vase.position.y = tableH + 0.15 * FT;
    group.add(vase);

    for (let i = 0; i < 8; i++) {
      const leaf = new THREE.Mesh(
        new THREE.SphereGeometry(0.04 * FT, 8, 6),
        new THREE.MeshStandardMaterial({ color: 0x4caf50, roughness: 0.82 })
      );
      leaf.scale.set(1.4, 0.25, 0.8);
      const angle = (i / 8) * Math.PI * 2;
      leaf.position.set(
        Math.cos(angle) * 0.07 * FT,
        tableH + 0.32 * FT,
        Math.sin(angle) * 0.07 * FT
      );
      leaf.rotation.y = angle;
      group.add(leaf);
    }
  }

  function buildPremiumDiningTable(renderer, item) {
    const fw = item.width * FT;
    const fd = item.depth * FT;
    const tableH = item.height * FT;
    const isRound = item.variant === 'round';
    const tex = item.textureDataUrl || null;
    const group = new THREE.Group();

    const preset = renderer._furniturePresetMaterial(item);
    const topMat = renderer._makeMaterial(
      preset.color,
      preset.roughness,
      preset.metalness,
      preset.textureUrl,
      preset.textureUrl ? null : preset.procType || 'wood',
      2,
      2
    );
    const legMat = renderer._makeMaterial(
      preset.color,
      0.58,
      preset.metalness * 0.5,
      null,
      preset.procType || 'wood',
      2,
      2
    );

    applyWoodGrain(topMat);

    let tableRadius;
    if (isRound) {
      tableRadius = Math.max(fw, fd) / 2;
      buildRoundTable(group, renderer, tableRadius, tableH, topMat, legMat);
    } else {
      buildRectangularTable(group, renderer, fw, fd, tableH, topMat, legMat);
    }

    topMat.roughness = 0.42;
    topMat.metalness = 0.03;
    topMat.envMapIntensity = 0.65;
    legMat.roughness = 0.58;
    legMat.envMapIntensity = 0.45;

    const span = isRound ? Math.max(fw, fd) : fw;
    let chairCount;
    if (span < 5 * FT) chairCount = 4;
    else if (span < 7 * FT) chairCount = 6;
    else chairCount = 8;

    const chairWidth = (isRound ? Math.max(fw, fd) : fw) * 0.12;
    const chairDepth = (isRound ? Math.max(fw, fd) : fd) * 0.16;
    const chairHeight = tableH * 1.05;
    const chairGap = 0.12 * FT;

    const chairWood = renderer._makeMaterial(
      item.color,
      0.62,
      0.08,
      tex,
      tex ? null : 'wood',
      2,
      2
    );
    chairWood.roughness = 0.62;
    chairWood.envMapIntensity = 0.45;

    const chairFabric = new THREE.MeshStandardMaterial({
      color: 0xb4a79d,
      roughness: 0.95,
      metalness: 0,
      envMapIntensity: 0.2,
    });

    const chairs = [];
    for (let i = 0; i < chairCount; i++) {
      chairs.push(buildDiningChair(renderer, chairWidth, chairHeight, chairDepth, chairWood, chairFabric));
    }

    if (isRound) {
      placeRoundChairs(group, chairs, tableRadius, chairWidth, chairDepth, chairGap);
    } else {
      placeRectangularChairs(group, chairs, fw, fd, chairWidth, chairDepth, chairGap);
    }

    pullChairsTowardTable(chairs);
    addChairVariations(chairs);
    addChairShadows(chairs, chairWidth);

    addCenterpiece(group, tableH);

    const shadow = new THREE.Mesh(
      new THREE.CircleGeometry(Math.max(fw, fd) * 0.6, 48),
      new THREE.MeshBasicMaterial({
        color: 0x000000,
        transparent: true,
        opacity: 0.08,
        depthWrite: false,
      })
    );
    shadow.rotation.x = -Math.PI / 2;
    shadow.position.y = 0.003;
    group.add(shadow);

    group.traverse((mesh) => {
      if (mesh.isMesh) {
        mesh.castShadow = true;
        mesh.receiveShadow = true;
      }
    });

    return group;
  }

  global.PremiumDiningTableBuilder = {
    build: buildPremiumDiningTable,
  };
})(typeof window !== 'undefined' ? window : global);
