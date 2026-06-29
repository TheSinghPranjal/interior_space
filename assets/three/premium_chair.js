/* global THREE */
(function (global) {
  'use strict';

  const FT = 0.3048;

  //----------------------------------------------------------
  // HELPERS
  //----------------------------------------------------------

  function hexColor(hex) {
    if (typeof hex === 'number') return hex;
    return parseInt(String(hex).replace('#', ''), 16) || 0x6a8f5a;
  }

  function roundedBox(width, height, depth, radius, material, seg) {
    radius = Math.min(radius, width / 2, height / 2, depth / 2);
    const s = seg || 8;
    const geometry = new THREE.BoxGeometry(width, height, depth, s, s, s);
    const pos = geometry.attributes.position;
    for (let i = 0; i < pos.count; i++) {
      let x = pos.getX(i), y = pos.getY(i), z = pos.getZ(i);
      const sx = Math.sign(x) || 1, sy = Math.sign(y) || 1, sz = Math.sign(z) || 1;
      const cx = sx * (width / 2 - radius);
      const cy = sy * (height / 2 - radius);
      const cz = sz * (depth / 2 - radius);
      const dx = x - cx, dy = y - cy, dz = z - cz;
      const len = Math.sqrt(dx * dx + dy * dy + dz * dz) || 1;
      pos.setXYZ(i, cx + dx / len * radius, cy + dy / len * radius, cz + dz / len * radius);
    }
    pos.needsUpdate = true;
    geometry.computeVertexNormals();
    return new THREE.Mesh(geometry, material);
  }

  function makeRadialShadowTexture() {
    const size = 256;
    const canvas = document.createElement('canvas');
    canvas.width = canvas.height = size;
    const ctx = canvas.getContext('2d');
    const grad = ctx.createRadialGradient(
      size / 2, size / 2, size * 0.05, size / 2, size / 2, size * 0.5
    );
    grad.addColorStop(0, 'rgba(0,0,0,0.5)');
    grad.addColorStop(0.55, 'rgba(0,0,0,0.2)');
    grad.addColorStop(1, 'rgba(0,0,0,0)');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, size, size);
    return new THREE.CanvasTexture(canvas);
  }

  function applyBoxUV(mesh, scale) {
    scale = scale || 1;
    mesh.geometry.computeBoundingBox();

    const box = mesh.geometry.boundingBox;
    const size = new THREE.Vector3();
    box.getSize(size);

    const uv = [];
    const pos = mesh.geometry.attributes.position;

    for (let i = 0; i < pos.count; i++) {
      const x = pos.getX(i);
      const y = pos.getY(i);
      uv.push((x / size.x) * scale, (y / size.y) * scale);
    }

    mesh.geometry.setAttribute('uv', new THREE.Float32BufferAttribute(uv, 2));
  }

  function buildMaterials(renderer, item, textureUrl) {
    const wood = renderer._makeMaterial(
      textureUrl ? '#ffffff' : '#8b5a35',
      0.72,
      0.0,
      textureUrl,
      textureUrl ? null : 'wood',
      1,
      1
    );

    wood.roughness = 0.48;
    wood.metalness = 0.0;
    wood.envMapIntensity = 2.0;

    if ('clearcoat' in wood) {
      wood.clearcoat = 0.28;
      wood.clearcoatRoughness = 0.18;
    }

    if (wood.normalScale) {
      wood.normalScale.set(1.0, 1.0);
    }

    if (wood.map && renderer.renderer) {
      wood.map.anisotropy = renderer.renderer.capabilities.getMaxAnisotropy();
      wood.map.wrapS = THREE.RepeatWrapping;
      wood.map.wrapT = THREE.RepeatWrapping;
      wood.map.rotation = Math.PI * 0.5;
      wood.map.center.set(0.5, 0.5);
      wood.map.needsUpdate = true;
    }

    return { wood };
  }

  function createPart(w, h, d, material) {
    return roundedBox(w, h, d, 0.003, material, 4);
  }

  function bowSlat(mesh, slatWidth) {
    const p = mesh.geometry.attributes.position;
    const halfWidth = slatWidth * 0.5;

    for (let i = 0; i < p.count; i++) {
      let x = p.getX(i);
      let y = p.getY(i);
      let z = p.getZ(i);

      if (z > 0) {
        const t = Math.abs(x) / halfWidth;
        z += (1 - t * t) * 0.004;
      }

      p.setXYZ(i, x, y, z);
    }

    p.needsUpdate = true;
  }

  function sculptSeatCrown(seat, seatWidth, seatDepth) {
    const seatPos = seat.geometry.attributes.position;
    const halfW = seatWidth * 0.5;
    const halfD = seatDepth * 0.5;

    for (let i = 0; i < seatPos.count; i++) {
      let x = seatPos.getX(i);
      let y = seatPos.getY(i);
      let z = seatPos.getZ(i);

      if (y > 0) {
        const fx = Math.abs(x) / halfW;
        const fz = Math.abs(z) / halfD;
        const influence = 1 - Math.max(fx, fz);
        y += influence * 0.004;
      }

      seatPos.setXYZ(i, x, y, z);
    }

    for (let i = 0; i < seatPos.count; i++) {
      let x = seatPos.getX(i);
      let y = seatPos.getY(i);
      let z = seatPos.getZ(i);

      if (z > 0) {
        z *= 1.015;
      }

      seatPos.setXYZ(i, x, y, z);
    }

    seatPos.needsUpdate = true;
  }

  //----------------------------------------------------------
  // MAIN BUILDER
  //----------------------------------------------------------

  function buildPremiumChair(renderer, item, textureUrl) {
    const group = new THREE.Group();
    group.name = 'PremiumChair';

    //----------------------------------------------------------
    // BUILD ORDER
    // 1. Materials
    // 2. Dimensions
    // 3. Legs
    // 4. Seat
    // 5. Aprons
    // 6. Back Posts
    // 7. Back Slats
    // 8. Contact Shadow
    // 9. Optimize Meshes
    // 10. Return Group
    //----------------------------------------------------------

    // 1. Materials
    const { wood } = buildMaterials(renderer, item, textureUrl);

    // 2. Dimensions
    const width = item.width * FT;
    const depth = item.depth * FT;
    const height = item.height * FT;

    const legSize = 0.04;
    const seatHeight = 0.46;
    const seatThickness = 0.03;
    const apronHeight = 0.08;
    const apronThickness = 0.02;
    const bevel = 0.008;

    const legOffsetX = width * 0.42;
    const legOffsetZ = depth * 0.42;
    const frontLegHeight = seatHeight;
    const rearLegHeight = seatHeight;

    const seatWidth = width * 0.92;
    const seatDepth = depth * 0.92;
    const seatCenterY = seatHeight + seatThickness * 0.5;

    const apronInset = legSize * 0.5;
    const frontBackApronWidth = seatWidth - legSize;
    const sideApronDepth = seatDepth - legSize;
    const apronCenterY = seatHeight - apronHeight * 0.5;
    const frontApronZ = legOffsetZ - apronInset;
    const backApronZ = -legOffsetZ + apronInset;
    const leftApronX = -legOffsetX + apronInset;
    const rightApronX = legOffsetX - apronInset;

    const backPostWidth = legSize;
    const backPostDepth = legSize;
    const backPostVisibleHeight = height - seatHeight - seatThickness;
    const backPostCenterY = seatHeight + seatThickness + backPostVisibleHeight * 0.5;
    const backPostZ = -legOffsetZ;
    const backLean = -0.05;

    const slatWidth = seatWidth - legSize * 1.6;
    const slatHeight = 0.055;
    const slatDepth = 0.018;
    const firstSlatY = seatHeight + 0.14;
    const slatGap = 0.085;
    const slatZ = backPostZ + legSize * 0.45;
    const topBarHeight = slatHeight * 1.15;
    const topBarDepth = slatDepth * 1.25;
    const topBarY = height - topBarHeight * 0.5 - 0.008;

    // 3. Legs
    const frontLeftLeg = createPart(legSize, frontLegHeight, legSize, wood);
    frontLeftLeg.name = 'FrontLeftLeg';
    frontLeftLeg.position.set(-legOffsetX, frontLegHeight * 0.5, legOffsetZ);

    const frontRightLeg = createPart(legSize, frontLegHeight, legSize, wood);
    frontRightLeg.name = 'FrontRightLeg';
    frontRightLeg.position.set(legOffsetX, frontLegHeight * 0.5, legOffsetZ);

    const rearLeftLeg = createPart(legSize, rearLegHeight, legSize, wood);
    rearLeftLeg.name = 'RearLeftLeg';
    rearLeftLeg.position.set(-legOffsetX, rearLegHeight * 0.5, -legOffsetZ);

    const rearRightLeg = createPart(legSize, rearLegHeight, legSize, wood);
    rearRightLeg.name = 'RearRightLeg';
    rearRightLeg.position.set(legOffsetX, rearLegHeight * 0.5, -legOffsetZ);

    [frontLeftLeg, frontRightLeg, rearLeftLeg, rearRightLeg].forEach((leg) => {
      leg.scale.x = 0.985;
      leg.scale.z = 0.985;
      leg.rotation.y = Math.PI * 0.5;
    });
    frontLeftLeg.rotation.z = -0.004;
    frontRightLeg.rotation.z = 0.004;
    rearLeftLeg.rotation.z = -0.003;
    rearRightLeg.rotation.z = 0.003;

    // 4. Seat
    const seat = roundedBox(seatWidth, seatThickness, seatDepth, bevel, wood, 12);
    seat.name = 'Seat';
    seat.position.set(0, seatCenterY, 0.015);
    sculptSeatCrown(seat, seatWidth, seatDepth);
    seat.scale.set(1, 0.98, 1);
    seat.rotation.y += Math.PI;

    // 5. Aprons
    const frontApron = createPart(frontBackApronWidth, apronHeight, apronThickness, wood);
    frontApron.name = 'FrontApron';
    frontApron.position.set(0, apronCenterY + 0.002, frontApronZ);

    const backApron = createPart(frontBackApronWidth, apronHeight, apronThickness, wood);
    backApron.name = 'BackApron';
    backApron.position.set(0, apronCenterY + 0.002, backApronZ);

    const leftApron = createPart(apronThickness, apronHeight, sideApronDepth, wood);
    leftApron.name = 'LeftApron';
    leftApron.position.set(leftApronX, apronCenterY + 0.002, 0);

    const rightApron = createPart(apronThickness, apronHeight, sideApronDepth, wood);
    rightApron.name = 'RightApron';
    rightApron.position.set(rightApronX, apronCenterY + 0.002, 0);

    // 6. Back Posts
    const leftBackPost = createPart(backPostWidth, backPostVisibleHeight, backPostDepth, wood);
    leftBackPost.name = 'LeftBackPost';
    leftBackPost.position.set(-legOffsetX, backPostCenterY, backPostZ);
    leftBackPost.rotation.x = backLean;
    leftBackPost.scale.x = 0.98;
    leftBackPost.scale.z = 0.98;

    const rightBackPost = createPart(backPostWidth, backPostVisibleHeight, backPostDepth, wood);
    rightBackPost.name = 'RightBackPost';
    rightBackPost.position.set(legOffsetX, backPostCenterY, backPostZ);
    rightBackPost.rotation.x = backLean;
    rightBackPost.scale.x = 0.98;
    rightBackPost.scale.z = 0.98;

    // 7. Back Slats + Top Bar
    const slat0 = roundedBox(slatWidth, slatHeight, slatDepth, 0.006, wood, 10);
    slat0.name = 'Slat0';
    slat0.position.set(0, firstSlatY, slatZ);
    slat0.rotation.x = backLean;

    const slat1 = roundedBox(slatWidth, slatHeight, slatDepth, 0.006, wood, 10);
    slat1.name = 'Slat1';
    slat1.position.set(0, firstSlatY + slatGap, slatZ);
    slat1.rotation.x = backLean;

    const slat2 = roundedBox(slatWidth, slatHeight, slatDepth, 0.006, wood, 10);
    slat2.name = 'Slat2';
    slat2.position.set(0, firstSlatY + slatGap * 2, slatZ);
    slat2.rotation.x = backLean;

    const slat3 = roundedBox(slatWidth, slatHeight, slatDepth, 0.006, wood, 10);
    slat3.name = 'Slat3';
    slat3.position.set(0, firstSlatY + slatGap * 3, slatZ);
    slat3.rotation.x = backLean;

    const topBar = roundedBox(slatWidth, topBarHeight, topBarDepth, 0.008, wood, 10);
    topBar.name = 'TopBar';
    topBar.position.set(0, topBarY, slatZ);
    topBar.rotation.x = backLean;

    bowSlat(slat0, slatWidth);
    bowSlat(slat1, slatWidth);
    bowSlat(slat2, slatWidth);
    bowSlat(slat3, slatWidth);
    bowSlat(topBar, slatWidth);

    const parts = [
      seat,
      frontLeftLeg,
      frontRightLeg,
      rearLeftLeg,
      rearRightLeg,
      frontApron,
      backApron,
      leftApron,
      rightApron,
      leftBackPost,
      rightBackPost,
      slat0,
      slat1,
      slat2,
      slat3,
      topBar,
    ];

    // 9. Optimize meshes (single pass)
    parts.forEach((mesh) => {
      mesh.castShadow = true;
      mesh.receiveShadow = true;
      mesh.material = wood;
      applyBoxUV(mesh, mesh.name === 'Seat' ? 2 : 1);
      mesh.geometry.computeVertexNormals();
      mesh.frustumCulled = true;
      mesh.updateMatrix();
      mesh.matrixAutoUpdate = false;
      group.add(mesh);
    });

    // Center the chair on its bounding box
    const centerBox = new THREE.Box3().setFromObject(group);
    const center = new THREE.Vector3();
    centerBox.getCenter(center);
    group.position.sub(center);

    group.updateMatrixWorld(true);

    // Move onto the floor
    const floorBox = new THREE.Box3().setFromObject(group);
    group.position.y -= floorBox.min.y;

    // Metadata for editing
    group.userData = {
      type: 'chair',
      category: 'dining',
      editable: true,
      resizable: true,
      rotatable: true,
      material: 'wood',
      setColor(color) {
        parts.forEach((mesh) => {
          mesh.material.color.set(color);
        });
      },
      setTexture(texture) {
        parts.forEach((mesh) => {
          mesh.material.map = texture;
          mesh.material.needsUpdate = true;
        });
      },
    };

    // 8. Contact Shadow (not in parts array)
    const shadow = new THREE.Mesh(
      new THREE.CircleGeometry(width * 0.75, 64),
      new THREE.MeshBasicMaterial({
        map: makeRadialShadowTexture(),
        transparent: true,
        opacity: 0.42,
        depthWrite: false,
      })
    );
    shadow.name = 'ContactShadow';
    shadow.rotation.x = -Math.PI / 2;
    shadow.position.y = 0.001;
    shadow.frustumCulled = true;
    group.add(shadow);

    group.updateMatrixWorld(true);

    return group;
  }

  global.PremiumChairBuilder = { build: buildPremiumChair };

})(typeof window !== 'undefined' ? window : global);
