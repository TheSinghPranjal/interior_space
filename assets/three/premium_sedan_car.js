/* global THREE */
(function (global) {
  'use strict';

  const FT = 0.3048;

  function hexColor(hex) {
    if (typeof hex === 'number') return hex;
    return parseInt(String(hex).replace('#', ''), 16) || 0x1e3a5f;
  }

  function mkMat(color, rough, metal, emissive, eInt) {
    return new THREE.MeshStandardMaterial({
      color,
      emissive: emissive || 0x000000,
      emissiveIntensity: eInt ?? 0.08,
      roughness: rough,
      metalness: metal,
      envMapIntensity: 1.35,
    });
  }

  function addShadows(group) {
    group.traverse((c) => {
      if (c.isMesh) {
        c.castShadow = true;
        c.receiveShadow = true;
      }
    });
    return group;
  }

  function finishFromPreset(preset) {
    switch (preset) {
      case 'metallic':
        return { rough: 0.18, metal: 0.82 };
      case 'glossy':
        return { rough: 0.12, metal: 0.35 };
      case 'black':
        return { rough: 0.22, metal: 0.55 };
      case 'white':
        return { rough: 0.14, metal: 0.18 };
      case 'whiteMatte':
        return { rough: 0.72, metal: 0.05 };
      default:
        return { rough: 0.16, metal: 0.42 };
    }
  }

  function buildWheel(radius, width, tireMat, rimMat) {
    const wheel = new THREE.Group();
    const tire = new THREE.Mesh(
      new THREE.CylinderGeometry(radius, radius, width, 24),
      tireMat
    );
    tire.rotation.z = Math.PI / 2;
    wheel.add(tire);

    const rim = new THREE.Mesh(
      new THREE.CylinderGeometry(radius * 0.62, radius * 0.62, width * 1.04, 18),
      rimMat
    );
    rim.rotation.z = Math.PI / 2;
    wheel.add(rim);

    const hub = new THREE.Mesh(
      new THREE.CylinderGeometry(radius * 0.18, radius * 0.18, width * 1.08, 12),
      rimMat
    );
    hub.rotation.z = Math.PI / 2;
    wheel.add(hub);

    for (let i = 0; i < 5; i++) {
      const spoke = new THREE.Mesh(
        new THREE.BoxGeometry(radius * 0.08, radius * 0.55, width * 0.92),
        rimMat
      );
      spoke.rotation.z = (i / 5) * Math.PI * 2;
      spoke.position.y = radius * 0.22;
      wheel.add(spoke);
    }

    return wheel;
  }

  function buildSedan(renderer, item, textureUrl) {
    const fw = item.width * FT;
    const fh = item.height * FT;
    const fd = item.depth * FT;
    const group = new THREE.Group();

    const finish = finishFromPreset(item.materialPreset);
    const paintColor = hexColor(item.color);
    const paint = renderer._makeMaterial(
      item.color,
      finish.rough,
      finish.metal,
      textureUrl,
      null,
      1,
      1
    );
    const glass = new THREE.MeshPhysicalMaterial({
      color: 0x9ecbff,
      roughness: 0.04,
      metalness: 0.08,
      transparent: true,
      opacity: 0.42,
      transmission: 0.35,
      envMapIntensity: 1.4,
    });
    const darkGlass = glass.clone();
    darkGlass.opacity = 0.55;
    darkGlass.color = new THREE.Color(0x1a2530);

    const chrome = mkMat(0xdfe3e8, 0.12, 0.92, 0x9098a0, 0.15);
    const blackTrim = mkMat(0x111111, 0.45, 0.35);
    const rubber = mkMat(0x1a1a1a, 0.92, 0.02);
    const headlight = mkMat(0xf5f8ff, 0.08, 0.05, 0xffffff, 0.55);
    const taillight = mkMat(0xff1744, 0.2, 0.08, 0xff0033, 0.75);
    const amber = mkMat(0xffb300, 0.25, 0.05, 0xff9100, 0.35);
    const dashMat = mkMat(0x263238, 0.78, 0.08);
    const seatMat = mkMat(0x37474f, 0.88, 0.02);

    const wheelR = fh * 0.16;
    const wheelW = fw * 0.08;
    const tireMat = rubber;
    const rimMat = mkMat(0xb0bec5, 0.18, 0.88, 0x78909c, 0.12);
    const groundClear = wheelR * 0.92;

    // Lower body / side sills
    const lowerH = fh * 0.28;
    const lower = new THREE.Mesh(
      new THREE.BoxGeometry(fw * 0.96, lowerH, fd * 0.98),
      paint
    );
    lower.position.y = groundClear + lowerH / 2;
    group.add(lower);

    // Main cabin / shoulder line
    const cabinH = fh * 0.34;
    const cabin = new THREE.Mesh(
      new THREE.BoxGeometry(fw * 0.88, cabinH, fd * 0.52),
      paint
    );
    cabin.position.set(0, groundClear + lowerH + cabinH / 2 - fh * 0.02, -fd * 0.04);
    group.add(cabin);

    // Hood
    const hood = new THREE.Mesh(
      new THREE.BoxGeometry(fw * 0.86, fh * 0.12, fd * 0.28),
      paint
    );
    hood.position.set(0, groundClear + lowerH + fh * 0.06, fd * 0.31);
    hood.rotation.x = -0.08;
    group.add(hood);

    // Trunk deck
    const trunk = new THREE.Mesh(
      new THREE.BoxGeometry(fw * 0.86, fh * 0.11, fd * 0.24),
      paint
    );
    trunk.position.set(0, groundClear + lowerH + fh * 0.05, -fd * 0.34);
    trunk.rotation.x = 0.06;
    group.add(trunk);

    // Roof
    const roof = new THREE.Mesh(
      new THREE.BoxGeometry(fw * 0.78, fh * 0.08, fd * 0.38),
      paint
    );
    roof.position.set(0, groundClear + lowerH + cabinH + fh * 0.02, -fd * 0.05);
    group.add(roof);

    // Sunroof glass
    const sunroof = new THREE.Mesh(
      new THREE.BoxGeometry(fw * 0.42, fh * 0.025, fd * 0.22),
      darkGlass
    );
    sunroof.position.set(0, groundClear + lowerH + cabinH + fh * 0.055, -fd * 0.02);
    group.add(sunroof);

    // Front bumper
    const frontBumper = new THREE.Mesh(
      new THREE.BoxGeometry(fw * 0.92, fh * 0.12, fd * 0.06),
      blackTrim
    );
    frontBumper.position.set(0, groundClear + fh * 0.08, fd * 0.48);
    group.add(frontBumper);

    // Rear bumper
    const rearBumper = new THREE.Mesh(
      new THREE.BoxGeometry(fw * 0.92, fh * 0.12, fd * 0.06),
      blackTrim
    );
    rearBumper.position.set(0, groundClear + fh * 0.08, -fd * 0.48);
    group.add(rearBumper);

    // Front grille
    const grille = new THREE.Mesh(
      new THREE.BoxGeometry(fw * 0.48, fh * 0.14, fd * 0.025),
      blackTrim
    );
    grille.position.set(0, groundClear + lowerH * 0.55, fd * 0.495);
    group.add(grille);

    // Headlights
    [-1, 1].forEach((side) => {
      const head = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.14, fh * 0.08, fd * 0.04),
        headlight
      );
      head.position.set(side * fw * 0.34, groundClear + lowerH * 0.62, fd * 0.47);
      group.add(head);

      const drl = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.1, fh * 0.025, fd * 0.02),
        amber
      );
      drl.position.set(side * fw * 0.34, groundClear + lowerH * 0.42, fd * 0.485);
      group.add(drl);
    });

    // Taillights
    [-1, 1].forEach((side) => {
      const tail = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.16, fh * 0.09, fd * 0.035),
        taillight
      );
      tail.position.set(side * fw * 0.34, groundClear + lowerH * 0.58, -fd * 0.475);
      group.add(tail);
    });

    // Windshield
    const windshield = new THREE.Mesh(
      new THREE.BoxGeometry(fw * 0.76, fh * 0.22, fd * 0.04),
      glass
    );
    windshield.position.set(0, groundClear + lowerH + cabinH * 0.72, fd * 0.18);
    windshield.rotation.x = -0.42;
    group.add(windshield);

    // Rear windshield
    const rearGlass = new THREE.Mesh(
      new THREE.BoxGeometry(fw * 0.72, fh * 0.18, fd * 0.035),
      glass
    );
    rearGlass.position.set(0, groundClear + lowerH + cabinH * 0.68, -fd * 0.24);
    rearGlass.rotation.x = 0.38;
    group.add(rearGlass);

    // Side windows + door seams
    [-1, 1].forEach((side) => {
      const frontWin = new THREE.Mesh(
        new THREE.BoxGeometry(fd * 0.04, fh * 0.16, fd * 0.18),
        glass
      );
      frontWin.position.set(side * fw * 0.44, groundClear + lowerH + cabinH * 0.62, fd * 0.06);
      group.add(frontWin);

      const rearWin = new THREE.Mesh(
        new THREE.BoxGeometry(fd * 0.04, fh * 0.14, fd * 0.16),
        glass
      );
      rearWin.position.set(side * fw * 0.44, groundClear + lowerH + cabinH * 0.6, -fd * 0.12);
      group.add(rearWin);

      // Door lines
      [fd * 0.08, -fd * 0.04].forEach((z) => {
        const seam = new THREE.Mesh(
          new THREE.BoxGeometry(fd * 0.008, fh * 0.24, fd * 0.003),
          blackTrim
        );
        seam.position.set(side * fw * 0.455, groundClear + lowerH + cabinH * 0.45, z);
        group.add(seam);
      });

      // Door handles
      const handle = new THREE.Mesh(
        new THREE.BoxGeometry(fd * 0.03, fh * 0.025, fd * 0.08),
        chrome
      );
      handle.position.set(side * fw * 0.47, groundClear + lowerH + cabinH * 0.35, fd * 0.02);
      group.add(handle);

      // Mirror
      const mirrorArm = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.04, fh * 0.025, fd * 0.06),
        paint
      );
      mirrorArm.position.set(side * fw * 0.5, groundClear + lowerH + cabinH * 0.72, fd * 0.12);
      group.add(mirrorArm);
      const mirrorGlass = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.05, fh * 0.05, fd * 0.03),
        darkGlass
      );
      mirrorGlass.position.set(side * fw * 0.52, groundClear + lowerH + cabinH * 0.72, fd * 0.12);
      group.add(mirrorGlass);
    });

    // Dashboard (visible through windshield)
    const dashboard = new THREE.Mesh(
      new THREE.BoxGeometry(fw * 0.68, fh * 0.12, fd * 0.12),
      dashMat
    );
    dashboard.position.set(0, groundClear + lowerH + fh * 0.18, fd * 0.12);
    dashboard.rotation.x = -0.25;
    group.add(dashboard);

    const steering = new THREE.Mesh(
      new THREE.TorusGeometry(fw * 0.05, fw * 0.008, 8, 20),
      blackTrim
    );
    steering.rotation.y = Math.PI / 2;
    steering.rotation.x = -0.35;
    steering.position.set(-fw * 0.14, groundClear + lowerH + fh * 0.24, fd * 0.1);
    group.add(steering);

    // Front seats silhouette
    [-1, 1].forEach((side) => {
      const seat = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.18, fh * 0.16, fd * 0.12),
        seatMat
      );
      seat.position.set(side * fw * 0.16, groundClear + lowerH + fh * 0.12, fd * 0.02);
      group.add(seat);
    });

    // Wheels
    const wheelPositions = [
      [fw * 0.38, fd * 0.3],
      [-fw * 0.38, fd * 0.3],
      [fw * 0.38, -fd * 0.3],
      [-fw * 0.38, -fd * 0.3],
    ];
    wheelPositions.forEach(([x, z]) => {
      const wheel = buildWheel(wheelR, wheelW, tireMat, rimMat);
      wheel.position.set(x, wheelR, z);
      group.add(wheel);
    });

    // Wheel arches (subtle fenders)
    wheelPositions.forEach(([x, z]) => {
      const arch = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.22, fh * 0.08, fd * 0.18),
        paint
      );
      arch.position.set(x, groundClear + lowerH + fh * 0.02, z);
      group.add(arch);
    });

    // Exhaust pipes
    [-1, 1].forEach((side) => {
      const exhaust = new THREE.Mesh(
        new THREE.CylinderGeometry(fw * 0.025, fw * 0.028, fd * 0.08, 12),
        chrome
      );
      exhaust.rotation.x = Math.PI / 2;
      exhaust.position.set(side * fw * 0.18, groundClear + fh * 0.06, -fd * 0.49);
      group.add(exhaust);
    });

    // Underbody shadow plate
    const shadow = new THREE.Mesh(
      new THREE.BoxGeometry(fw * 0.9, fh * 0.02, fd * 0.88),
      mkMat(0x000000, 1, 0, 0, 0)
    );
    shadow.position.y = fh * 0.01;
    shadow.material.transparent = true;
    shadow.material.opacity = 0.18;
    group.add(shadow);

    return addShadows(group);
  }

  global.PremiumSedanCarBuilder = {
    build: buildSedan,
  };
})(typeof window !== 'undefined' ? window : global);
