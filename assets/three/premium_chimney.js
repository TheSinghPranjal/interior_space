/* global THREE */
(function (global) {
  'use strict';

  const FT = 0.3048;

  function rBox(w, h, d, r, mat) {
    r = Math.min(r, w / 2, h / 2, d / 2);
    const g = new THREE.BoxGeometry(w, h, d, 4, 4, 4);
    const p = g.attributes.position;
    for (let i = 0; i < p.count; i++) {
      let x = p.getX(i), y = p.getY(i), z = p.getZ(i);
      const sx = Math.sign(x) || 1, sy = Math.sign(y) || 1, sz = Math.sign(z) || 1;
      const cx = sx * (w / 2 - r), cy = sy * (h / 2 - r), cz = sz * (d / 2 - r);
      const dx = x - cx, dy = y - cy, dz = z - cz;
      const len = Math.sqrt(dx * dx + dy * dy + dz * dz) || 1;
      p.setXYZ(i, cx + dx / len * r, cy + dy / len * r, cz + dz / len * r);
    }
    p.needsUpdate = true;
    g.computeVertexNormals();
    return new THREE.Mesh(g, mat);
  }

  function mkMat(color, emissive, rough, metal, eInt) {
    return new THREE.MeshStandardMaterial({
      color,
      emissive,
      emissiveIntensity: eInt ?? 0.14,
      roughness: rough,
      metalness: metal,
      envMapIntensity: 1.5,
    });
  }

  function makeFilterMeshTexture() {
    const size = 128;
    const canvas = document.createElement('canvas');
    canvas.width = canvas.height = size;
    const ctx = canvas.getContext('2d');
    ctx.fillStyle = '#707880';
    ctx.fillRect(0, 0, size, size);
    ctx.strokeStyle = '#4e545c';
    ctx.lineWidth = 1;
    for (let x = 0; x <= size; x += 5) {
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, size);
      ctx.stroke();
    }
    for (let y = 0; y <= size; y += 8) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(size, y);
      ctx.stroke();
    }
    const tex = new THREE.CanvasTexture(canvas);
    tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
    tex.repeat.set(5, 4);
    return tex;
  }

  function createPart(w, h, d, material) {
    const mesh = rBox(w, h, d, 0.004 * FT, material);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    return mesh;
  }

  function applyBoxUV(mesh) {
    mesh.geometry.computeBoundingBox();
    mesh.geometry.computeVertexNormals();
  }

  function createHoodGeometry(topW, bottomW, topD, bottomD, height) {
    const geometry = new THREE.BufferGeometry();

    const hwTop = topW * 0.5;
    const hdTop = topD * 0.5;

    const hwBottom = bottomW * 0.5;
    const hdBottom = bottomD * 0.5;

    const vertices = [
      // Top
      -hwTop, height, -hdTop,
       hwTop, height, -hdTop,
       hwTop, height,  hdTop,
      -hwTop, height,  hdTop,

      // Bottom
      -hwBottom, 0, -hdBottom,
       hwBottom, 0, -hdBottom,
       hwBottom, 0,  hdBottom,
      -hwBottom, 0,  hdBottom,
    ];

    const indices = [
      // top
      0, 1, 2,
      0, 2, 3,

      // front
      3, 2, 6,
      3, 6, 7,

      // right
      2, 1, 5,
      2, 5, 6,

      // back
      1, 0, 4,
      1, 4, 5,

      // left
      0, 3, 7,
      0, 7, 4,

      // bottom
      4, 7, 6,
      4, 6, 5,
    ];

    geometry.setAttribute('position', new THREE.Float32BufferAttribute(vertices, 3));
    geometry.setIndex(indices);
    geometry.computeVertexNormals();

    return geometry;
  }

  function buildPremiumChimney(renderer, item) {
    const fw = item.width * FT;
    const fh = item.height * FT;
    const fd = item.depth * FT;

    const group = new THREE.Group();
    group.name = 'PremiumChimney';

    const parts = [];
    const glassParts = [];
    const steelParts = [];

    //----------------------------------------------------------
    // BUILD ORDER
    //----------------------------------------------------------
    // Materials
    // Dimensions
    // Hood
    // Chimney
    // Bottom Frame
    // Filters
    // Buttons
    // Lights
    // Shadow
    // Optimization

    //----------------------------------------------------------
    // MATERIALS
    //----------------------------------------------------------
    const blackBodyMat = new THREE.MeshPhysicalMaterial({
      color: 0x141414,
      roughness: 0.22,
      metalness: 0.65,
      clearcoat: 1,
      clearcoatRoughness: 0.08,
      envMapIntensity: 2.5,
    });

    const stainlessMat = new THREE.MeshPhysicalMaterial({
      color: 0xcfd2d4,
      roughness: 0.35,
      metalness: 0.9,
      envMapIntensity: 2.2,
    });

    const glassMat = new THREE.MeshPhysicalMaterial({
      color: 0x111111,
      transparent: true,
      opacity: 0.96,
      roughness: 0.02,
      metalness: 0.1,
      transmission: 0.08,
      clearcoat: 1,
      clearcoatRoughness: 0.02,
    });

    const buttonMat = new THREE.MeshStandardMaterial({
      color: 0x3d3d3d,
      roughness: 0.45,
      metalness: 0.7,
    });

    const lightRingMat = new THREE.MeshStandardMaterial({
      color: 0xd9d9d9,
      roughness: 0.2,
      metalness: 0.9,
    });

    const ledMat = new THREE.MeshStandardMaterial({
      color: 0xffffff,
      emissive: 0xfff2dd,
      emissiveIntensity: 1.5,
    });

    //----------------------------------------------------------
    // MAIN DIMENSIONS
    //----------------------------------------------------------
    const hoodHeight = fh * 0.34;
    const hoodTopWidth = fw * 0.48;
    const hoodBottomWidth = fw * 0.98;
    const hoodDepthTop = fd * 0.34;
    const hoodDepthBottom = fd * 0.96;
    const chimneyWidth = fw * 0.24;
    const chimneyDepth = fd * 0.22;
    const chimneyHeight = fh * 0.66;

    const radius = 0.004 * FT;

    //----------------------------------------------------------
    // FLUE
    //----------------------------------------------------------
    const flueOuterWidth = chimneyWidth;
    const flueOuterDepth = chimneyDepth;
    const flueHeight = chimneyHeight;
    const flueRadius = radius;
    const flueTopMargin = 0.02;

    //----------------------------------------------------------
    // FILTER AREA
    //----------------------------------------------------------
    const bottomWidth = hoodBottomWidth * 0.94;
    const bottomDepth = hoodDepthBottom * 0.92;
    const frameThickness = 0.020;
    const frameHeight = 0.020;
    const recessDepth = 0.018;
    const filterWidth = bottomWidth * 0.82;
    const filterDepth = bottomDepth * 0.74;

    //----------------------------------------------------------
    // LIGHTS & PANEL
    //----------------------------------------------------------
    const lightRadius = 0.028;
    const lightRingRadius = 0.034;
    const lightOffsetX = hoodBottomWidth * 0.27;
    const lightOffsetZ = hoodDepthBottom * 0.26;
    const panelWidth = hoodBottomWidth * 0.34;
    const panelHeight = 0.028;
    const panelDepth = 0.010;

    //----------------------------------------------------------
    // MAIN HOOD
    //----------------------------------------------------------
    const hood = new THREE.Mesh(
      createHoodGeometry(
        hoodTopWidth,
        hoodBottomWidth,
        hoodDepthTop,
        hoodDepthBottom,
        hoodHeight
      ),
      blackBodyMat
    );
    hood.name = 'MainHood';
    hood.castShadow = true;
    hood.receiveShadow = true;
    hood.position.set(0, 0, 0);
    parts.push(hood);

    //----------------------------------------------------------
    // FRONT FASCIA
    //----------------------------------------------------------
    const fasciaHeight = hoodHeight * 0.18;
    const fascia = createPart(
      hoodBottomWidth,
      fasciaHeight,
      0.018,
      glassMat
    );
    fascia.name = 'FrontFascia';
    fascia.position.set(
      0,
      fasciaHeight * 0.5 + 0.01,
      hoodDepthBottom * 0.5 - 0.01
    );
    glassParts.push(fascia);

    const collar = createPart(
      chimneyWidth * 1.25,
      0.018,
      chimneyDepth * 1.25,
      blackBodyMat
    );
    collar.name = 'TopCollar';
    collar.position.set(0, hoodHeight - 0.009, 0);
    parts.push(collar);

    const sheen = new THREE.Mesh(
      new THREE.PlaneGeometry(hoodBottomWidth * 0.82, hoodHeight * 0.55),
      new THREE.MeshBasicMaterial({
        color: 0xffffff,
        transparent: true,
        opacity: 0.05,
        depthWrite: false,
      })
    );
    sheen.name = 'FrontSheen';
    sheen.position.set(0, hoodHeight * 0.45, hoodDepthBottom * 0.51);
    glassParts.push(sheen);

    //----------------------------------------------------------
    // MAIN FLUE
    //----------------------------------------------------------
    const flue = createPart(
      flueOuterWidth,
      flueHeight,
      flueOuterDepth,
      blackBodyMat
    );
    flue.name = 'Flue';
    flue.position.set(0, hoodHeight + flueHeight * 0.5, 0);
    parts.push(flue);

    //----------------------------------------------------------
    // FLUE FRONT PANEL
    //----------------------------------------------------------
    const flueFront = createPart(
      flueOuterWidth * 0.94,
      flueHeight * 0.96,
      0.006,
      glassMat
    );
    flueFront.name = 'FlueFront';
    flueFront.position.set(
      0,
      hoodHeight + flueHeight * 0.5,
      flueOuterDepth * 0.5 + 0.003
    );
    glassParts.push(flueFront);

    const flueLeftTrim = createPart(
      0.004,
      flueHeight,
      flueOuterDepth,
      stainlessMat
    );
    flueLeftTrim.name = 'FlueLeftTrim';
    flueLeftTrim.position.set(
      -flueOuterWidth * 0.5,
      hoodHeight + flueHeight * 0.5,
      0
    );
    steelParts.push(flueLeftTrim);

    const flueRightTrim = createPart(
      0.004,
      flueHeight,
      flueOuterDepth,
      stainlessMat
    );
    flueRightTrim.name = 'FlueRightTrim';
    flueRightTrim.position.set(
      flueOuterWidth * 0.5,
      hoodHeight + flueHeight * 0.5,
      0
    );
    steelParts.push(flueRightTrim);

    //----------------------------------------------------------
    // FLUE CAP
    //----------------------------------------------------------
    const flueCap = createPart(
      flueOuterWidth + 0.01,
      0.012,
      flueOuterDepth + 0.01,
      blackBodyMat
    );
    flueCap.name = 'FlueCap';
    flueCap.position.set(0, hoodHeight + flueHeight + 0.006, 0);
    parts.push(flueCap);

    const flueReflection = new THREE.Mesh(
      new THREE.PlaneGeometry(flueOuterWidth * 0.75, flueHeight * 0.82),
      new THREE.MeshBasicMaterial({
        color: 0xffffff,
        transparent: true,
        opacity: 0.04,
        depthWrite: false,
      })
    );
    flueReflection.name = 'FlueReflection';
    flueReflection.position.set(
      0,
      hoodHeight + flueHeight * 0.5,
      flueOuterDepth * 0.5 + 0.004
    );
    glassParts.push(flueReflection);

    //----------------------------------------------------------
    // BOTTOM FRAME
    //----------------------------------------------------------
    [
      { w: bottomWidth, d: frameThickness, x: 0, z: bottomDepth / 2 - frameThickness / 2 },
      { w: bottomWidth, d: frameThickness, x: 0, z: -bottomDepth / 2 + frameThickness / 2 },
      { w: frameThickness, d: bottomDepth, x: -bottomWidth / 2 + frameThickness / 2, z: 0 },
      { w: frameThickness, d: bottomDepth, x: bottomWidth / 2 - frameThickness / 2, z: 0 },
    ].forEach((side, i) => {
      const strip = createPart(side.w, frameHeight, side.d, stainlessMat);
      strip.name = 'BottomFrame' + (i + 1);
      strip.position.set(side.x, frameHeight * 0.5, side.z);
      parts.push(strip);
    });

    //----------------------------------------------------------
    // FILTER RECESS
    //----------------------------------------------------------
    const recess = createPart(
      filterWidth + 0.02,
      recessDepth,
      filterDepth + 0.02,
      stainlessMat
    );
    recess.name = 'FilterRecess';
    recess.position.set(0, frameHeight + recessDepth * 0.5, 0);
    parts.push(recess);

    //----------------------------------------------------------
    // FILTER
    //----------------------------------------------------------
    const filterMaterial = new THREE.MeshStandardMaterial({
      map: makeFilterMeshTexture(),
      color: 0x90969c,
      roughness: 0.55,
      metalness: 0.72,
    });
    const filter = new THREE.Mesh(
      new THREE.PlaneGeometry(filterWidth, filterDepth),
      filterMaterial
    );
    filter.rotation.x = -Math.PI / 2;
    filter.position.set(0, frameHeight + 0.002, 0);
    filter.name = 'FilterMesh';
    filter.castShadow = true;
    filter.receiveShadow = true;

    //----------------------------------------------------------
    // FILTER BORDER
    //----------------------------------------------------------
    const border = createPart(
      filterWidth + 0.01,
      0.006,
      filterDepth + 0.01,
      stainlessMat
    );
    border.name = 'FilterBorder';
    border.position.set(0, frameHeight + 0.004, 0);
    parts.push(border);

    //----------------------------------------------------------
    // HANDLE
    //----------------------------------------------------------
    const handle = createPart(
      filterWidth * 0.10,
      0.008,
      0.020,
      buttonMat
    );
    handle.name = 'FilterHandle';
    handle.position.set(0, frameHeight + 0.006, filterDepth * 0.36);
    parts.push(handle);

    //----------------------------------------------------------
    // TOUCH PANEL
    //----------------------------------------------------------
    const controlPanel = createPart(
      panelWidth,
      panelHeight,
      panelDepth,
      glassMat
    );
    controlPanel.name = 'TouchPanel';
    controlPanel.position.set(
      0,
      hoodHeight * 0.12,
      hoodDepthBottom * 0.48
    );
    glassParts.push(controlPanel);

    //----------------------------------------------------------
    // TOUCH BUTTONS
    //----------------------------------------------------------
    const buttonSpacing = panelWidth / 6;
    for (let i = 0; i < 5; i++) {
      const button = new THREE.Mesh(
        new THREE.CylinderGeometry(0.006, 0.006, 0.003, 24),
        buttonMat
      );
      button.name = 'TouchButton' + (i + 1);
      button.rotation.x = Math.PI / 2;
      button.position.set(
        (-2 + i) * buttonSpacing,
        hoodHeight * 0.12,
        hoodDepthBottom * 0.487
      );
      parts.push(button);
    }

    //----------------------------------------------------------
    // LED RINGS
    //----------------------------------------------------------
    [-1, 1].forEach((side, index) => {
      const ring = new THREE.Mesh(
        new THREE.CylinderGeometry(lightRingRadius, lightRingRadius, 0.006, 40),
        stainlessMat
      );
      ring.name = 'LEDRing' + (index + 1);
      ring.position.set(side * lightOffsetX, 0.004, lightOffsetZ);
      parts.push(ring);
    });

    //----------------------------------------------------------
    // LED BULBS
    //----------------------------------------------------------
    [-1, 1].forEach((side, index) => {
      const bulb = new THREE.Mesh(
        new THREE.CylinderGeometry(lightRadius, lightRadius, 0.003, 36),
        ledMat
      );
      bulb.name = 'LEDBulb' + (index + 1);
      bulb.position.set(side * lightOffsetX, 0.002, lightOffsetZ);
      parts.push(bulb);
    });

    //----------------------------------------------------------
    // SIDE TRIMS
    //----------------------------------------------------------
    const trimWidth = 0.008;
    const trimDepth = hoodDepthBottom;
    const trimHeight = hoodHeight;

    const leftTrim = createPart(trimWidth, trimHeight, trimDepth, stainlessMat);
    leftTrim.name = 'LeftTrim';
    leftTrim.position.set(
      -hoodBottomWidth * 0.5 + trimWidth * 0.5,
      hoodHeight * 0.5,
      0
    );
    parts.push(leftTrim);

    const rightTrim = createPart(trimWidth, trimHeight, trimDepth, stainlessMat);
    rightTrim.name = 'RightTrim';
    rightTrim.position.set(
      hoodBottomWidth * 0.5 - trimWidth * 0.5,
      hoodHeight * 0.5,
      0
    );
    parts.push(rightTrim);

    //----------------------------------------------------------
    // FRONT EDGE STRIP
    //----------------------------------------------------------
    const frontEdge = createPart(
      hoodBottomWidth,
      0.008,
      0.010,
      stainlessMat
    );
    frontEdge.name = 'FrontEdgeStrip';
    frontEdge.position.set(0, 0.004, hoodDepthBottom * 0.5);
    parts.push(frontEdge);

    const topTrim = createPart(
      chimneyWidth + 0.02,
      0.006,
      chimneyDepth + 0.02,
      stainlessMat
    );
    topTrim.name = 'TopTrim';
    topTrim.position.set(0, hoodHeight + 0.006, 0);
    parts.push(topTrim);

    // Piano-black body finish
    blackBodyMat.roughness = 0.08;
    blackBodyMat.metalness = 0.82;
    blackBodyMat.clearcoat = 1;
    blackBodyMat.clearcoatRoughness = 0.03;
    blackBodyMat.envMapIntensity = 3.0;

    // Brighter stainless reflections
    stainlessMat.roughness = 0.18;
    stainlessMat.metalness = 1;
    stainlessMat.envMapIntensity = 3;

    parts.forEach((mesh) => {
      if (!mesh.geometry) return;
      mesh.geometry.computeVertexNormals();
    });

    parts.forEach(applyBoxUV);

    parts.forEach((mesh) => group.add(mesh));
    glassParts.forEach((mesh) => group.add(mesh));
    steelParts.forEach((mesh) => group.add(mesh));
    group.add(filter);

    [-1, 1].forEach((side) => {
      const glow = new THREE.Mesh(
        new THREE.CircleGeometry(lightRadius * 1.4, 32),
        new THREE.MeshBasicMaterial({
          color: 0xfff6e8,
          transparent: true,
          opacity: 0.15,
          depthWrite: false,
        })
      );
      glow.rotation.x = -Math.PI / 2;
      glow.position.set(side * lightOffsetX, 0.001, lightOffsetZ);
      group.add(glow);
    });

    const indicatorSpacing = panelWidth / 6;
    for (let i = 0; i < 5; i++) {
      const led = new THREE.Mesh(
        new THREE.SphereGeometry(0.0025, 12, 12),
        new THREE.MeshBasicMaterial({ color: 0x66ccff })
      );
      led.name = 'IndicatorLED' + (i + 1);
      led.position.set(
        (-2 + i) * indicatorSpacing,
        hoodHeight * 0.145,
        hoodDepthBottom * 0.492
      );
      group.add(led);
    }

    const reflection = new THREE.Mesh(
      new THREE.PlaneGeometry(hoodBottomWidth * 0.7, hoodHeight * 0.55),
      new THREE.MeshBasicMaterial({
        color: 0xffffff,
        transparent: true,
        opacity: 0.035,
        depthWrite: false,
      })
    );
    reflection.name = 'GlossReflection';
    reflection.position.set(0, hoodHeight * 0.45, hoodDepthBottom * 0.505);
    group.add(reflection);

    group.traverse((mesh) => {
      if (!mesh.isMesh) return;
      mesh.castShadow = true;
      mesh.receiveShadow = true;
      mesh.frustumCulled = true;
    });

    group.userData = {
      type: 'kitchenChimney',
      category: 'kitchen',
      editable: true,
      resizable: true,
      rotatable: true,
      material: 'lightGray',
      setColor(color) {
        parts.forEach((mesh) => {
          if (mesh.material && mesh.material.color) {
            mesh.material.color.set(color);
          }
        });
      },
      setTexture(texture) {
        parts.forEach((mesh) => {
          if (mesh.material && mesh.material.map !== undefined) {
            mesh.material.map = texture;
            mesh.material.needsUpdate = true;
          }
        });
      },
    };

    return group;
  }

  global.PremiumChimneyBuilder = { build: buildPremiumChimney };

})(typeof window !== 'undefined' ? window : global);
