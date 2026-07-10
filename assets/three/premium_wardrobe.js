/* global THREE, PremiumCabinetHelpers */
(function (global) {
  'use strict';

  const FT = 0.3048;
  const { createCabinetDoor } = PremiumCabinetHelpers;

  function buildCarcass(renderer, group, ctx) {
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

  function buildTripleDoor(group, renderer, ctx) {
    const { fw, bodyH, toeKickH, frontZ, panel, bodyMat, trimMat, shelfMat, fd } = ctx;
    const doorGap = 0.004 * FT;
    const centerGap = 0.008 * FT;
    const doorWidth = (fw - panel * 2 - centerGap * 2 - doorGap * 2) / 3;
    const doorHeight = bodyH - panel * 2;
    const doorThickness = 0.022 * FT;

    const leftDoor = createCabinetDoor(renderer, doorWidth, doorHeight, doorThickness, bodyMat, trimMat, 'left');
    leftDoor.position.set(-doorWidth - centerGap, toeKickH + bodyH / 2, frontZ);
    group.add(leftDoor);

    const centerDoor = createCabinetDoor(renderer, doorWidth, doorHeight, doorThickness, bodyMat, trimMat, 'right');
    centerDoor.position.set(0, toeKickH + bodyH / 2, frontZ);
    group.add(centerDoor);

    const rightDoor = createCabinetDoor(renderer, doorWidth, doorHeight, doorThickness, bodyMat, trimMat, 'right');
    rightDoor.position.set(doorWidth + centerGap, toeKickH + bodyH / 2, frontZ);
    group.add(rightDoor);

    [0.34, 0.67].forEach((level) => {
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

    [-1, 0, 1].forEach((slot) => {
      const divider = renderer._createRoundedBox(panel, bodyH - panel * 2, fd - panel * 2, panel * 0.2, bodyMat);
      divider.position.set(slot * (doorWidth + centerGap * 0.5), toeKickH + bodyH / 2, 0);
      group.add(divider);
    });

    const ao = new THREE.Mesh(
      new THREE.BoxGeometry(fw - panel * 2, bodyH - panel * 2, fd - panel * 2),
      new THREE.MeshBasicMaterial({ color: 0x000000, transparent: true, opacity: 0.05 })
    );
    ao.position.set(0, toeKickH + bodyH / 2, -panel);
    group.add(ao);
  }

  function buildPremiumWardrobe(renderer, item, textureUrl) {
    const fw = item.width * FT;
    const fh = item.height * FT;
    const fd = item.depth * FT;
    const group = new THREE.Group();

    const resolvedTex = textureUrl
      || renderer._resolveTextureUrl(item.textureDataUrl, item.texturePath);
    const bodyMat = renderer._makeMaterial(
      item.color,
      0.62,
      0.05,
      resolvedTex,
      resolvedTex ? null : 'wood',
      2,
      2
    );
    const shelfMat = bodyMat.clone();
    if (bodyMat.map) shelfMat.map = bodyMat.map;

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

    const ctx = { fw, fh, fd, bodyMat, topMat, trimMat, shelfMat };
    buildCarcass(renderer, group, ctx);
    buildTripleDoor(group, renderer, ctx);

    bodyMat.roughness = 0.55;
    bodyMat.envMapIntensity = 0.45;
    shelfMat.roughness = 0.6;

    group.traverse((mesh) => {
      if (mesh.isMesh) {
        mesh.castShadow = true;
        mesh.receiveShadow = true;
        mesh.renderOrder = 1;
      }
    });

    return group;
  }

  global.PremiumWardrobeBuilder = {
    build: buildPremiumWardrobe,
  };
})(typeof window !== 'undefined' ? window : global);
