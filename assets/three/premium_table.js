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

  function isLightFinish(item) {
    const preset = item.materialPreset || '';
    if (preset === 'whiteMatte' || preset === 'white') return true;
    const hex = (item.color || '#795548').replace('#', '');
    if (hex.length < 6) return false;
    const r = parseInt(hex.slice(0, 2), 16);
    const g = parseInt(hex.slice(2, 4), 16);
    const b = parseInt(hex.slice(4, 6), 16);
    return (r + g + b) / 3 > 200;
  }

  function buildPremiumTable(renderer, item, textureUrl) {
    const fw = item.width * FT;
    const fh = item.height * FT;
    const fd = item.depth * FT;
    const group = new THREE.Group();

    const bodyMat = renderer._makeMaterial(
      item.color,
      0.88,
      0.03,
      textureUrl,
      textureUrl ? null : 'wood',
      2,
      2
    );

    const handleMat = new THREE.MeshStandardMaterial({
      color: 0xd5d5d5,
      roughness: 0.35,
      metalness: 0.7,
    });

    const topOverhang = 0.03 * FT;
    const topThickness = 0.09 * FT;
    const panelThickness = 0.08 * FT;
    const cornerRadius = Math.min(fw, fd) * 0.07;
    const cabinetWidth = fw * 0.34;
    const cabinetBodyHeight = fh - topThickness;
    const cabinetCenterX = fw / 2 - cabinetWidth / 2;

    const topWidth = fw + topOverhang * 2;
    const topDepth = fd + topOverhang;

    const top = renderer._createRoundedBox(
      topWidth,
      topThickness,
      topDepth,
      cornerRadius,
      bodyMat
    );
    top.position.y = fh - topThickness * 0.5;
    group.add(top);

    const leftPanel = renderer._createRoundedBox(
      panelThickness,
      cabinetBodyHeight,
      fd,
      panelThickness * 0.35,
      bodyMat
    );
    leftPanel.position.set(-fw / 2 + panelThickness / 2, cabinetBodyHeight / 2, 0);
    group.add(leftPanel);

    const bottomCurve = renderer._createRoundedBox(
      panelThickness,
      0.04 * FT,
      fd * 0.94,
      0.02 * FT,
      bodyMat
    );
    bottomCurve.position.set(-fw / 2 + panelThickness / 2, 0.02 * FT, 0);
    group.add(bottomCurve);

    const back = renderer._createRoundedBox(
      fw * 0.55,
      0.1 * FT,
      panelThickness,
      panelThickness * 0.35,
      bodyMat
    );
    back.position.set(-fw * 0.12, fh * 0.68, -fd / 2 + panelThickness / 2);
    group.add(back);

    const cabinet = renderer._createRoundedBox(
      cabinetWidth,
      cabinetBodyHeight,
      fd,
      panelThickness * 0.35,
      bodyMat
    );
    cabinet.position.set(cabinetCenterX, cabinetBodyHeight / 2, 0);
    group.add(cabinet);

    const base = renderer._createRoundedBox(
      cabinetWidth * 0.96,
      0.03 * FT,
      fd * 0.92,
      panelThickness * 0.25,
      bodyMat
    );
    base.position.set(cabinetCenterX, 0.015 * FT, 0);
    group.add(base);

    const underFrame = renderer._createRoundedBox(
      fw * 0.92,
      0.035 * FT,
      fd * 0.92,
      0.015 * FT,
      bodyMat
    );
    underFrame.position.y = fh - topThickness - 0.018 * FT;
    group.add(underFrame);

    const rail = renderer._createRoundedBox(
      fw * 0.58,
      0.05 * FT,
      0.05 * FT,
      0.015 * FT,
      bodyMat
    );
    rail.position.set(-fw * 0.08, fh * 0.62, -fd / 2 + 0.03 * FT);
    group.add(rail);

    const drawerGap = 0.015 * FT;
    const drawerHeight = cabinetBodyHeight / 3 - drawerGap;
    const drawerDepth = fd * 0.94;
    const drawerWidth = cabinetWidth * 0.92;
    const drawers = [];
    const handles = [];

    for (let i = 0; i < 3; i++) {
      const drawerY =
        fh - topThickness - drawerHeight * 0.5 - i * (drawerHeight + drawerGap);

      const drawer = renderer._createRoundedBox(
        drawerWidth,
        drawerHeight,
        0.05 * FT,
        panelThickness * 0.28,
        bodyMat
      );
      drawer.position.set(cabinetCenterX, drawerY, fd / 2 - 0.025 * FT - 0.015 * FT);
      group.add(drawer);
      drawers.push(drawer);

      deformVertices(drawer, (x, y, z) => {
        const edge = Math.max(
          Math.abs(x) / (drawerWidth * 0.5),
          Math.abs(y) / (drawerHeight * 0.5)
        );
        if (edge > 0.82) {
          return { z: z - 0.002 };
        }
        return null;
      });

      deformVertices(drawer, (x, y, z) => ({
        z: z + Math.sin(x * 8) * 0.001,
      }));

      if (i >= 1) {
        const gap = new THREE.Mesh(
          new THREE.BoxGeometry(drawerWidth, 0.004 * FT, 0.01 * FT),
          new THREE.MeshBasicMaterial({ color: 0x222222, transparent: true, opacity: 0.22 })
        );
        gap.position.set(
          cabinetCenterX,
          fh - topThickness - i * (drawerHeight + drawerGap) + drawerGap * 0.5,
          fd / 2 + 0.002
        );
        group.add(gap);
      }

      const handle = renderer._createRoundedBox(
        drawerWidth * 0.26,
        0.018 * FT,
        0.03 * FT,
        0.01 * FT,
        handleMat
      );
      handle.scale.set(1, 1.15, 1.3);
      handle.position.set(cabinetCenterX, drawerY, fd / 2 + 0.04 * FT);
      group.add(handle);
      handles.push(handle);

      const handleShadow = new THREE.Mesh(
        new THREE.PlaneGeometry(drawerWidth * 0.18, 0.03 * FT),
        new THREE.MeshBasicMaterial({
          color: 0x000000,
          transparent: true,
          opacity: 0.08,
          depthWrite: false,
        })
      );
      handleShadow.position.copy(handle.position);
      handleShadow.position.z -= 0.008;
      group.add(handleShadow);

      [-1, 1].forEach((side) => {
        const mount = new THREE.Mesh(
          new THREE.CylinderGeometry(0.004 * FT, 0.004 * FT, 0.015 * FT, 8),
          handleMat
        );
        mount.rotation.x = Math.PI / 2;
        mount.position.set(
          cabinetCenterX + side * drawerWidth * 0.08,
          drawerY,
          fd / 2 + 0.022 * FT
        );
        group.add(mount);
      });
    }

    const groove = new THREE.Mesh(
      new THREE.BoxGeometry(0.003 * FT, fh, fd * 0.95),
      new THREE.MeshBasicMaterial({ color: 0x222222, transparent: true, opacity: 0.18 })
    );
    groove.position.set(fw / 2 - cabinetWidth, fh * 0.5, 0);
    group.add(groove);

    const innerShadow = new THREE.Mesh(
      new THREE.PlaneGeometry(fw * 0.52, fh * 0.72),
      new THREE.MeshBasicMaterial({
        color: 0x000000,
        transparent: true,
        opacity: 0.06,
        depthWrite: false,
      })
    );
    innerShadow.position.set(-fw * 0.12, fh * 0.48, -fd / 2 + 0.005);
    group.add(innerShadow);

    const ao = new THREE.Mesh(
      new THREE.PlaneGeometry(fw * 0.96, fd * 0.96),
      new THREE.MeshBasicMaterial({
        color: 0x000000,
        transparent: true,
        opacity: 0.05,
        depthWrite: false,
      })
    );
    ao.rotation.x = -Math.PI / 2;
    ao.position.y = fh - topThickness - 0.005;
    group.add(ao);

    const cabinetShadow = new THREE.Mesh(
      new THREE.PlaneGeometry(cabinetWidth * 0.95, fd * 0.92),
      new THREE.MeshBasicMaterial({
        color: 0x000000,
        transparent: true,
        opacity: 0.08,
        depthWrite: false,
      })
    );
    cabinetShadow.rotation.x = -Math.PI / 2;
    cabinetShadow.position.set(cabinetCenterX, 0.002, 0);
    group.add(cabinetShadow);

    const floorShadow = new THREE.Mesh(
      new THREE.PlaneGeometry(fw * 1.05, fd * 1.05),
      new THREE.MeshBasicMaterial({
        color: 0x000000,
        transparent: true,
        opacity: 0.07,
        depthWrite: false,
      })
    );
    floorShadow.rotation.x = -Math.PI / 2;
    floorShadow.position.y = 0.002;
    group.add(floorShadow);

    deformVertices(top, (x, y, z) => {
      const edge = Math.max(Math.abs(x) / (topWidth * 0.5), Math.abs(z) / (topDepth * 0.5));
      if (edge > 0.82) {
        return { y: y - 0.004 };
      }
      return null;
    });

    deformVertices(top, (x, y, z) => ({
      y: y + Math.sin(x * 10) * 0.0008 + Math.cos(z * 7) * 0.0006,
    }));

    if (isLightFinish(item)) {
      bodyMat.roughness = 0.74;
      bodyMat.metalness = 0;
      bodyMat.envMapIntensity = 0.18;
    } else {
      bodyMat.roughness = 0.52;
      bodyMat.metalness = 0;
      bodyMat.envMapIntensity = 0.45;
    }

    group.traverse((mesh) => {
      if (!mesh.isMesh) return;
      mesh.castShadow = true;
      mesh.receiveShadow = true;
      if (mesh.material && mesh.material.isMeshStandardMaterial) {
        if (mesh.material.envMapIntensity === undefined) {
          mesh.material.envMapIntensity = 0.3;
        }
        if (mesh.material.roughness === undefined) {
          mesh.material.roughness = 0.8;
        }
        if (mesh.material.metalness === undefined) {
          mesh.material.metalness = 0;
        }
      }
    });

    return group;
  }

  global.PremiumTableBuilder = {
    build: buildPremiumTable,
  };
})(typeof window !== 'undefined' ? window : global);
