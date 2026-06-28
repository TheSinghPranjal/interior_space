/* global THREE, PremiumCabinetHelpers */
(function (global) {
  'use strict';

  const FT = 0.3048;
  const { createCabinetDoor, createDrawer } = PremiumCabinetHelpers;

  function buildCarcass(renderer, group, item, ctx) {
    const { fw, fh, fd, bodyMat, topMat, shelfMat, trimMat } = ctx;

    bodyMat.roughness = 0.62;
    bodyMat.metalness = 0;
    bodyMat.envMapIntensity = 0.45;

    const panel = 0.03 * FT;
    const toeKickH = fh * 0.06;
    const topThickness = 0.05 * FT;
    const bodyH = fh - toeKickH - topThickness;
    const frontZ = fd / 2 + 0.015 * FT;

    ctx.panel = panel;
    ctx.toeKickH = toeKickH;
    ctx.topThickness = topThickness;
    ctx.bodyH = bodyH;
    ctx.frontZ = frontZ;
    ctx.shelfMat = shelfMat;

    const toeKick = renderer._createRoundedBox(fw, toeKickH, fd * 0.96, panel * 0.4, bodyMat);
    toeKick.position.y = toeKickH * 0.5;
    group.add(toeKick);

    const left = renderer._createRoundedBox(panel, bodyH, fd, panel * 0.5, bodyMat);
    left.position.set(-fw / 2 + panel / 2, toeKickH + bodyH / 2, 0);
    group.add(left);

    const right = left.clone();
    right.position.x = fw / 2 - panel / 2;
    group.add(right);

    const bottom = renderer._createRoundedBox(fw - panel * 2, panel, fd, panel * 0.4, bodyMat);
    bottom.position.set(0, toeKickH + panel / 2, 0);
    group.add(bottom);

    const rail = renderer._createRoundedBox(fw - panel * 2, panel, fd, panel * 0.4, bodyMat);
    rail.position.set(0, toeKickH + bodyH - panel / 2, 0);
    group.add(rail);

    const back = renderer._createRoundedBox(fw - panel * 2, bodyH - panel * 2, panel, panel * 0.3, bodyMat);
    back.position.set(0, toeKickH + bodyH / 2, -fd / 2 + panel / 2);
    group.add(back);

    const top = renderer._createRoundedBox(fw + 0.03 * FT, topThickness, fd + 0.04 * FT, panel, topMat);
    top.position.y = fh - topThickness * 0.5;
    group.add(top);

    const counterShadow = new THREE.Mesh(
      new THREE.PlaneGeometry(fw * 0.98, fd * 0.98),
      new THREE.MeshBasicMaterial({
        color: 0x000000,
        transparent: true,
        opacity: 0.05,
        depthWrite: false,
      })
    );
    counterShadow.rotation.x = -Math.PI / 2;
    counterShadow.position.y = fh - topThickness - 0.003;
    group.add(counterShadow);

    if (bodyMat.map) {
      bodyMat.map.rotation = Math.PI / 2;
      bodyMat.map.center.set(0.5, 0.5);
    }

    group.traverse((mesh) => {
      if (mesh.isMesh) {
        mesh.castShadow = true;
        mesh.receiveShadow = true;
      }
    });
  }

  function addShelfPins(group, ctx, levels) {
    const { fw, fd, toeKickH, bodyH, trimMat } = ctx;
    levels.forEach((level) => {
      [-1, 1].forEach((side) => {
        [-1, 1].forEach((front) => {
          const pin = new THREE.Mesh(
            new THREE.CylinderGeometry(0.0035 * FT, 0.0035 * FT, 0.012 * FT, 8),
            trimMat
          );
          pin.rotation.z = Math.PI / 2;
          pin.position.set(side * (fw * 0.46), toeKickH + bodyH * level, front * (fd * 0.34));
          group.add(pin);
        });
      });
    });
  }

  function buildSingleDoor(group, renderer, ctx) {
    const { fw, bodyH, toeKickH, frontZ, panel, bodyMat, trimMat, shelfMat } = ctx;
    const doorGap = 0.004 * FT;
    const doorWidth = fw - panel * 2 - doorGap * 2;
    const doorHeight = bodyH - panel * 2;
    const doorThickness = 0.022 * FT;

    const door = createCabinetDoor(renderer, doorWidth, doorHeight, doorThickness, bodyMat, trimMat, 'right');
    door.position.set(0, toeKickH + bodyH * 0.5, frontZ);
    group.add(door);

    const shelf = renderer._createRoundedBox(
      fw - panel * 3,
      panel * 0.75,
      ctx.fd - panel * 2,
      panel * 0.25,
      shelfMat
    );
    shelf.position.set(0, toeKickH + bodyH * 0.52, 0);
    group.add(shelf);

    [[-1, -1], [-1, 1], [1, -1], [1, 1]].forEach((c) => {
      const pin = new THREE.Mesh(
        new THREE.CylinderGeometry(0.0035 * FT, 0.0035 * FT, 0.012 * FT, 8),
        trimMat
      );
      pin.rotation.z = Math.PI / 2;
      pin.position.set(c[0] * (fw * 0.43), toeKickH + bodyH * 0.52, c[1] * (ctx.fd * 0.32));
      group.add(pin);
    });

    [0.22, 0.78].forEach((t) => {
      const hinge = new THREE.Mesh(
        new THREE.BoxGeometry(0.012 * FT, 0.05 * FT, 0.018 * FT),
        trimMat
      );
      hinge.position.set(-doorWidth * 0.49, toeKickH + bodyH * t, frontZ - 0.004 * FT);
      group.add(hinge);
    });

    const gapShadow = new THREE.Mesh(
      new THREE.PlaneGeometry(doorWidth, doorHeight),
      new THREE.MeshBasicMaterial({
        color: 0x000000,
        transparent: true,
        opacity: 0.05,
        depthWrite: false,
      })
    );
    gapShadow.position.set(0, toeKickH + bodyH * 0.5, frontZ - 0.01 * FT);
    group.add(gapShadow);

    const inside = new THREE.Mesh(
      new THREE.BoxGeometry(fw - panel * 2, bodyH - panel * 2, ctx.fd - panel * 2),
      new THREE.MeshBasicMaterial({ color: 0x111111, transparent: true, opacity: 0.05 })
    );
    inside.position.set(0, toeKickH + bodyH * 0.5, -panel);
    group.add(inside);
  }

  function buildDoubleDoor(group, renderer, ctx) {
    const { fw, bodyH, toeKickH, frontZ, panel, bodyMat, trimMat, shelfMat, fd } = ctx;
    const doorGap = 0.004 * FT;
    const centerGap = 0.008 * FT;
    const doorWidth = (fw - panel * 2 - centerGap - doorGap * 2) / 2;
    const doorHeight = bodyH - panel * 2;
    const doorThickness = 0.022 * FT;

    const leftDoor = createCabinetDoor(renderer, doorWidth, doorHeight, doorThickness, bodyMat, trimMat, 'left');
    leftDoor.position.set(-doorWidth / 2 - centerGap / 2, toeKickH + bodyH / 2, frontZ);
    group.add(leftDoor);

    const rightDoor = createCabinetDoor(renderer, doorWidth, doorHeight, doorThickness, bodyMat, trimMat, 'right');
    rightDoor.position.set(doorWidth / 2 + centerGap / 2, toeKickH + bodyH / 2, frontZ);
    group.add(rightDoor);

    [0.32, 0.63].forEach((level) => {
      const shelf = renderer._createRoundedBox(
        fw - panel * 3,
        panel * 0.75,
        fd - panel * 2,
        panel * 0.2,
        shelfMat
      );
      shelf.position.set(0, toeKickH + bodyH * level, 0);
      group.add(shelf);
    });

    const divider = renderer._createRoundedBox(panel, bodyH - panel * 2, fd - panel * 2, panel * 0.2, bodyMat);
    divider.position.set(0, toeKickH + bodyH / 2, 0);
    group.add(divider);

    [-1, 1].forEach((side) => {
      [0.2, 0.8].forEach((level) => {
        const hinge = new THREE.Mesh(
          new THREE.BoxGeometry(0.012 * FT, 0.05 * FT, 0.018 * FT),
          trimMat
        );
        hinge.position.set(side * (fw / 2 - panel), toeKickH + bodyH * level, frontZ - 0.004 * FT);
        group.add(hinge);
      });
    });

    const reveal = new THREE.Mesh(
      new THREE.BoxGeometry(centerGap, doorHeight, 0.003 * FT),
      new THREE.MeshBasicMaterial({ color: 0x111111, transparent: true, opacity: 0.25 })
    );
    reveal.position.set(0, toeKickH + bodyH / 2, frontZ + 0.001);
    group.add(reveal);

    const ao = new THREE.Mesh(
      new THREE.BoxGeometry(fw - panel * 2, bodyH - panel * 2, fd - panel * 2),
      new THREE.MeshBasicMaterial({ color: 0x000000, transparent: true, opacity: 0.05 })
    );
    ao.position.set(0, toeKickH + bodyH / 2, -panel);
    group.add(ao);

    addShelfPins(group, ctx, [0.32, 0.63]);
  }

  function buildDrawerUnit(group, renderer, ctx) {
    const { fw, bodyH, toeKickH, frontZ, panel, bodyMat, trimMat, fd } = ctx;
    const drawerCount = 4;
    const drawerGap = 0.012 * FT;
    const drawerFrontThickness = 0.022 * FT;
    const drawerHeight = (bodyH - panel * 2 - drawerGap * (drawerCount - 1)) / drawerCount;
    const drawerDepth = fd - panel * 1.6;

    for (let i = 0; i < drawerCount; i++) {
      const drawer = createDrawer(
        renderer,
        fw - panel * 2,
        drawerHeight,
        drawerDepth,
        drawerFrontThickness,
        bodyMat,
        trimMat
      );
      drawer.position.set(
        0,
        toeKickH + panel + drawerHeight * 0.5 + i * (drawerHeight + drawerGap),
        -panel
      );
      group.add(drawer);
    }

    for (let i = 1; i < drawerCount; i++) {
      const reveal = new THREE.Mesh(
        new THREE.BoxGeometry(fw - panel * 2, 0.003 * FT, 0.006 * FT),
        new THREE.MeshBasicMaterial({ color: 0x111111, transparent: true, opacity: 0.18 })
      );
      reveal.position.set(
        0,
        toeKickH + panel + i * (drawerHeight + drawerGap) - drawerGap * 0.5,
        frontZ
      );
      group.add(reveal);
    }

    [-1, 1].forEach((side) => {
      const rail = renderer._createRoundedBox(panel, bodyH - panel * 2, fd - panel, panel * 0.2, bodyMat);
      rail.position.set(side * (fw / 2 - panel / 2), toeKickH + bodyH / 2, 0);
      group.add(rail);
    });

    const divider = renderer._createRoundedBox(fw - panel * 2, panel, fd - panel, panel * 0.2, bodyMat);
    divider.position.set(0, toeKickH + panel, 0);
    group.add(divider);

    const ao = new THREE.Mesh(
      new THREE.BoxGeometry(fw - panel * 2, bodyH - panel * 2, fd - panel),
      new THREE.MeshBasicMaterial({ color: 0x000000, transparent: true, opacity: 0.05 })
    );
    ao.position.set(0, toeKickH + bodyH / 2, -panel);
    group.add(ao);

    for (let i = 0; i < drawerCount; i++) {
      const stop = renderer._createRoundedBox(fw * 0.15, panel, panel, panel * 0.15, bodyMat);
      stop.position.set(
        0,
        toeKickH + panel + drawerHeight * 0.5 + i * (drawerHeight + drawerGap),
        -fd / 2 + panel
      );
      group.add(stop);
    }
  }

  function buildOpenShelf(group, renderer, ctx) {
    const { fw, bodyH, toeKickH, panel, bodyMat, shelfMat, trimMat, fd } = ctx;
    const usableWidth = fw - panel * 2;
    const usableHeight = bodyH - panel * 2;
    const usableDepth = fd - panel;
    const shelfLevels = [0.26, 0.52, 0.78];

    const backPanel = renderer._createRoundedBox(
      usableWidth,
      usableHeight,
      panel,
      panel * 0.25,
      bodyMat
    );
    backPanel.position.set(0, toeKickH + bodyH * 0.5, -fd / 2 + panel * 0.5);
    group.add(backPanel);

    shelfLevels.forEach((level) => {
      const shelf = renderer._createRoundedBox(usableWidth, panel, usableDepth, panel * 0.25, shelfMat);
      shelf.position.set(0, toeKickH + usableHeight * level, 0);
      group.add(shelf);

      const ao = new THREE.Mesh(
        new THREE.PlaneGeometry(usableWidth * 0.98, usableDepth * 0.98),
        new THREE.MeshBasicMaterial({
          color: 0x000000,
          transparent: true,
          opacity: 0.05,
          depthWrite: false,
        })
      );
      ao.rotation.x = -Math.PI / 2;
      ao.position.set(0, toeKickH + usableHeight * level - 0.002, 0);
      group.add(ao);
    });

    const centerDivider = renderer._createRoundedBox(panel, usableHeight, usableDepth, panel * 0.2, bodyMat);
    centerDivider.position.set(0, toeKickH + bodyH * 0.5, 0);
    group.add(centerDivider);

    addShelfPins(group, ctx, shelfLevels);

    [-1, 1].forEach((side) => {
      const cubbyDivider = renderer._createRoundedBox(panel, usableHeight, usableDepth, panel * 0.2, bodyMat);
      cubbyDivider.position.set(side * usableWidth * 0.25, toeKickH + bodyH * 0.5, 0);
      group.add(cubbyDivider);
    });
  }

  function applyQualityPass(group, ctx) {
    const { fw, fh, fd, toeKickH, topThickness, bodyMat } = ctx;

    group.traverse((mesh) => {
      if (!mesh.isMesh) return;
      const pos = mesh.geometry?.attributes?.position;
      if (!pos) return;

      const box = new THREE.Box3().setFromObject(mesh);
      const sx = Math.max(box.max.x - box.min.x, 0.001);
      const sy = Math.max(box.max.y - box.min.y, 0.001);
      const sz = Math.max(box.max.z - box.min.z, 0.001);

      for (let i = 0; i < pos.count; i++) {
        let x = pos.getX(i);
        let y = pos.getY(i);
        let z = pos.getZ(i);
        const edge = Math.max(Math.abs(x) / (sx * 0.5), Math.abs(y) / (sy * 0.5), Math.abs(z) / (sz * 0.5));
        if (edge > 0.9) {
          x *= 0.998;
          y *= 0.998;
          z *= 0.998;
        }
        pos.setXYZ(i, x, y, z);
      }
      pos.needsUpdate = true;
      mesh.geometry.computeVertexNormals();
    });

    group.traverse((mesh) => {
      if (!mesh.isMesh || mesh.material !== bodyMat) return;
      const pos = mesh.geometry.attributes.position;
      if (!pos) return;
      for (let i = 0; i < pos.count; i++) {
        const x = pos.getX(i);
        let y = pos.getY(i);
        const z = pos.getZ(i);
        y += Math.sin(x * 8) * 0.0007 + Math.cos(z * 5) * 0.0005;
        pos.setXYZ(i, x, y, z);
      }
      pos.needsUpdate = true;
      mesh.geometry.computeVertexNormals();
    });

    group.traverse((mesh) => {
      if (!mesh.isMesh || !mesh.material?.map) return;
      mesh.material.map.rotation = Math.PI / 2;
      mesh.material.map.center.set(0.5, 0.5);
    });

    const baseAO = new THREE.Mesh(
      new THREE.PlaneGeometry(fw * 0.96, fd * 0.96),
      new THREE.MeshBasicMaterial({
        color: 0x000000,
        transparent: true,
        opacity: 0.05,
        depthWrite: false,
      })
    );
    baseAO.rotation.x = -Math.PI / 2;
    baseAO.position.y = toeKickH + 0.003;
    group.add(baseAO);

    const topAO = new THREE.Mesh(
      new THREE.PlaneGeometry(fw * 0.95, fd * 0.95),
      new THREE.MeshBasicMaterial({
        color: 0x000000,
        transparent: true,
        opacity: 0.04,
        depthWrite: false,
      })
    );
    topAO.rotation.x = -Math.PI / 2;
    topAO.position.y = fh - topThickness - 0.002;
    group.add(topAO);

    group.traverse((mesh) => {
      if (!mesh.isMesh || !mesh.userData.isHandle) return;
      const scale = Math.max(1, fw / (3 * FT));
      mesh.scale.y *= scale;
    });

    group.traverse((mesh) => {
      if (!mesh.isMesh) return;
      mesh.rotation.z += (Math.random() - 0.5) * 0.002;
    });

    group.traverse((mesh) => {
      if (!mesh.isMesh) return;
      const mat = mesh.material;
      if (!mat) return;
      if (mat.isMeshStandardMaterial) {
        mat.envMapIntensity = mat.envMapIntensity ?? 0.45;
        mat.metalness = Math.min(mat.metalness ?? 0, 0.95);
        mat.roughness = Math.min(mat.roughness ?? 0.8, 0.85);
      }
    });

    const contactShadow = new THREE.Mesh(
      new THREE.CircleGeometry(Math.max(fw, fd) * 0.58, 40),
      new THREE.MeshBasicMaterial({
        color: 0x000000,
        transparent: true,
        opacity: 0.08,
        depthWrite: false,
      })
    );
    contactShadow.rotation.x = -Math.PI / 2;
    contactShadow.position.y = 0.002;
    group.add(contactShadow);

    group.traverse((mesh) => {
      if (mesh.isMesh) {
        mesh.castShadow = true;
        mesh.receiveShadow = true;
        mesh.renderOrder = 1;
      }
    });
  }

  function buildPremiumStorageUnit(renderer, item) {
    const fw = item.width * FT;
    const fh = item.height * FT;
    const fd = item.depth * FT;
    const style = item.variant || 'singleDoor';
    const group = new THREE.Group();

    const bodyMat = renderer._makePresetMaterial(item);
    const topMat = new THREE.MeshStandardMaterial({
      color: 0xf2f2ef,
      roughness: 0.22,
      metalness: 0.02,
    });
    const trimMat = new THREE.MeshStandardMaterial({
      color: 0x555555,
      roughness: 0.35,
      metalness: 0.85,
    });
    const shelfMat = bodyMat.clone();

    const ctx = { fw, fh, fd, bodyMat, topMat, trimMat, shelfMat };

    buildCarcass(renderer, group, item, ctx);

    if (style === 'openShelf') {
      buildOpenShelf(group, renderer, ctx);
    } else if (style === 'drawerUnit') {
      buildDrawerUnit(group, renderer, ctx);
    } else if (style === 'doubleDoor') {
      buildDoubleDoor(group, renderer, ctx);
    } else {
      buildSingleDoor(group, renderer, ctx);
    }

    bodyMat.roughness = 0.55;
    bodyMat.envMapIntensity = 0.45;
    topMat.roughness = 0.2;
    topMat.envMapIntensity = 0.35;
    trimMat.roughness = 0.25;
    trimMat.metalness = 0.95;
    shelfMat.roughness = 0.6;

    applyQualityPass(group, ctx);

    return group;
  }

  global.PremiumStorageUnitBuilder = {
    build: buildPremiumStorageUnit,
  };
})(typeof window !== 'undefined' ? window : global);
