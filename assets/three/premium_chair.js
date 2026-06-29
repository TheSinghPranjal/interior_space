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

  function taperedCylinder(topR, botR, h, seg, material) {
    return new THREE.Mesh(new THREE.CylinderGeometry(topR, botR, h, seg, 3), material);
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

  //----------------------------------------------------------
  // BOX UV
  //----------------------------------------------------------

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

      uv.push(
        (x / size.x) * scale,
        (y / size.y) * scale
      );
    }

    mesh.geometry.setAttribute(
      'uv',
      new THREE.Float32BufferAttribute(uv, 2)
    );
  }

  //----------------------------------------------------------
  // MATERIALS
  //----------------------------------------------------------

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

    // WOOD MATERIAL (Step 8)
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
    }

    return { wood };
  }

  //----------------------------------------------------------
  // CREATE PART
  //----------------------------------------------------------

  function createPart(width, height, depth, material) {
    const mesh = roundedBox(
      width,
      height,
      depth,
      0.003,
      material,
      4
    );

    mesh.castShadow = true;
    mesh.receiveShadow = true;

    return mesh;
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
    mesh.geometry.computeVertexNormals();
  }

  //----------------------------------------------------------
  // MAIN BUILDER
  //----------------------------------------------------------

  function buildPremiumChair(renderer, item, textureUrl) {
    const group = new THREE.Group();

    const { wood } = buildMaterials(renderer, item, textureUrl);

    //----------------------------------------------------------
    // CHAIR DIMENSIONS
    //----------------------------------------------------------

    const width = item.width * FT;
    const depth = item.depth * FT;
    const height = item.height * FT;

    const legSize = 0.04;
    const seatHeight = 0.46;
    const seatThickness = 0.03;

    const apronHeight = 0.08;
    const apronThickness = 0.02;

    const bevel = 0.003;

    //----------------------------------------------------------
    // LEG POSITIONS
    //----------------------------------------------------------

    const legOffsetX = width * 0.42;
    const legOffsetZ = depth * 0.42;

    const frontLegHeight = seatHeight;
    const rearLegHeight = seatHeight;

    //----------------------------------------------------------
    // SEAT
    //----------------------------------------------------------

    const seatWidth = width * 0.92;
    const seatDepth = depth * 0.92;

    const seatTop = seatHeight;
    const seatCenterY = seatTop + seatThickness * 0.5;

    //----------------------------------------------------------
    // APRONS
    //----------------------------------------------------------

    const apronInset = legSize * 0.5;

    const frontBackApronWidth = seatWidth - legSize;

    const sideApronDepth = seatDepth - legSize;

    const apronCenterY = seatHeight - apronHeight * 0.5;

    const frontApronZ = legOffsetZ - apronInset;

    const backApronZ = -legOffsetZ + apronInset;

    const leftApronX = -legOffsetX + apronInset;

    const rightApronX = legOffsetX - apronInset;

    //----------------------------------------------------------
    // BACK POSTS
    //----------------------------------------------------------

    const backPostWidth = legSize;
    const backPostDepth = legSize;

    const backPostVisibleHeight =
      height - seatHeight - seatThickness;

    const backPostCenterY =
      seatHeight +
      seatThickness +
      backPostVisibleHeight * 0.5;

    const backPostZ = -legOffsetZ;

    const backLean = -0.05;

    //----------------------------------------------------------
    // BACK SLATS
    //----------------------------------------------------------

    const slatCount = 3;

    const slatWidth = seatWidth - (legSize * 1.6);

    const slatHeight = 0.055;

    const slatDepth = 0.018;

    const firstSlatY = seatHeight + 0.14;

    const slatGap = 0.085;

    const slatZ = backPostZ + (legSize * 0.45);

    //----------------------------------------------------------
    // FRONT LEFT LEG
    //----------------------------------------------------------

    const frontLeftLeg = createPart(
      legSize,
      frontLegHeight,
      legSize,
      wood
    );

    frontLeftLeg.position.set(
      -legOffsetX,
      frontLegHeight * 0.5,
      legOffsetZ
    );

    group.add(frontLeftLeg);

    //----------------------------------------------------------
    // FRONT RIGHT LEG
    //----------------------------------------------------------

    const frontRightLeg = createPart(
      legSize,
      frontLegHeight,
      legSize,
      wood
    );

    frontRightLeg.position.set(
      legOffsetX,
      frontLegHeight * 0.5,
      legOffsetZ
    );

    group.add(frontRightLeg);

    //----------------------------------------------------------
    // REAR LEFT LEG
    //----------------------------------------------------------

    const rearLeftLeg = createPart(
      legSize,
      rearLegHeight,
      legSize,
      wood
    );

    rearLeftLeg.position.set(
      -legOffsetX,
      rearLegHeight * 0.5,
      -legOffsetZ
    );

    group.add(rearLeftLeg);

    //----------------------------------------------------------
    // REAR RIGHT LEG
    //----------------------------------------------------------

    const rearRightLeg = createPart(
      legSize,
      rearLegHeight,
      legSize,
      wood
    );

    rearRightLeg.position.set(
      legOffsetX,
      rearLegHeight * 0.5,
      -legOffsetZ
    );

    group.add(rearRightLeg);

    [
      frontLeftLeg,
      frontRightLeg,
      rearLeftLeg,
      rearRightLeg,
    ].forEach((leg) => {
      leg.scale.x = 0.985;
      leg.scale.z = 0.985;
      leg.rotation.y = Math.PI * 0.5;
    });

    frontLeftLeg.rotation.z = -0.004;
    frontRightLeg.rotation.z = 0.004;
    rearLeftLeg.rotation.z = -0.003;
    rearRightLeg.rotation.z = 0.003;

    //----------------------------------------------------------
    // SEAT
    //----------------------------------------------------------

    const seat = roundedBox(
      seatWidth,
      seatThickness,
      seatDepth,
      0.008,
      wood,
      12
    );

    seat.castShadow = true;
    seat.receiveShadow = true;

    seat.position.set(
      0,
      seatCenterY,
      0.015
    );

    group.add(seat);

    //----------------------------------------------------------
    // SEAT CROWN
    //----------------------------------------------------------

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
    seat.geometry.computeVertexNormals();

    seat.scale.set(1, 0.98, 1);
    seat.rotation.y += Math.PI;

    //----------------------------------------------------------
    // FRONT APRON
    //----------------------------------------------------------

    const frontApron = createPart(
      frontBackApronWidth,
      apronHeight,
      apronThickness,
      wood
    );

    frontApron.position.set(
      0,
      apronCenterY + 0.002,
      frontApronZ
    );

    group.add(frontApron);

    //----------------------------------------------------------
    // BACK APRON
    //----------------------------------------------------------

    const backApron = createPart(
      frontBackApronWidth,
      apronHeight,
      apronThickness,
      wood
    );

    backApron.position.set(
      0,
      apronCenterY + 0.002,
      backApronZ
    );

    group.add(backApron);

    //----------------------------------------------------------
    // LEFT APRON
    //----------------------------------------------------------

    const leftApron = createPart(
      apronThickness,
      apronHeight,
      sideApronDepth,
      wood
    );

    leftApron.position.set(
      leftApronX,
      apronCenterY + 0.002,
      0
    );

    group.add(leftApron);

    //----------------------------------------------------------
    // RIGHT APRON
    //----------------------------------------------------------

    const rightApron = createPart(
      apronThickness,
      apronHeight,
      sideApronDepth,
      wood
    );

    rightApron.position.set(
      rightApronX,
      apronCenterY + 0.002,
      0
    );

    group.add(rightApron);

    [
      frontApron,
      backApron,
      leftApron,
      rightApron,
    ].forEach((part) => {
      part.geometry.computeVertexNormals();
    });

    //----------------------------------------------------------
    // LEFT BACK POST
    //----------------------------------------------------------

    const leftBackPost = createPart(
      backPostWidth,
      backPostVisibleHeight,
      backPostDepth,
      wood
    );

    leftBackPost.position.set(
      -legOffsetX,
      backPostCenterY,
      backPostZ
    );

    leftBackPost.rotation.x = backLean;

    group.add(leftBackPost);

    //----------------------------------------------------------
    // RIGHT BACK POST
    //----------------------------------------------------------

    const rightBackPost = createPart(
      backPostWidth,
      backPostVisibleHeight,
      backPostDepth,
      wood
    );

    rightBackPost.position.set(
      legOffsetX,
      backPostCenterY,
      backPostZ
    );

    rightBackPost.rotation.x = backLean;

    group.add(rightBackPost);

    [leftBackPost, rightBackPost].forEach((post) => {
      post.scale.x = 0.98;
      post.scale.z = 0.98;
      post.geometry.computeVertexNormals();
    });

    //----------------------------------------------------------
    // SLAT 1
    //----------------------------------------------------------

    const slat1 = roundedBox(
      slatWidth,
      slatHeight,
      slatDepth,
      0.006,
      wood,
      10
    );
    slat1.castShadow = true;
    slat1.receiveShadow = true;

    slat1.position.set(
      0,
      firstSlatY,
      slatZ
    );

    slat1.rotation.x = backLean;
    slat1.rotation.y = 0;

    group.add(slat1);

    //----------------------------------------------------------
    // SLAT 2
    //----------------------------------------------------------

    const slat2 = roundedBox(
      slatWidth,
      slatHeight,
      slatDepth,
      0.006,
      wood,
      10
    );
    slat2.castShadow = true;
    slat2.receiveShadow = true;

    slat2.position.set(
      0,
      firstSlatY + slatGap,
      slatZ
    );

    slat2.rotation.x = backLean;
    slat2.rotation.y = 0;

    group.add(slat2);

    //----------------------------------------------------------
    // SLAT 3
    //----------------------------------------------------------

    const slat3 = roundedBox(
      slatWidth,
      slatHeight,
      slatDepth,
      0.006,
      wood,
      10
    );
    slat3.castShadow = true;
    slat3.receiveShadow = true;

    slat3.position.set(
      0,
      firstSlatY + slatGap * 2,
      slatZ
    );

    slat3.rotation.x = backLean;
    slat3.rotation.y = 0;

    group.add(slat3);

    [slat1, slat2, slat3].forEach((slat) => {
      slat.geometry.computeVertexNormals();
    });

    bowSlat(slat1, slatWidth);
    bowSlat(slat2, slatWidth);
    bowSlat(slat3, slatWidth);

    // UV mapping for wood grain
    applyBoxUV(seat, 2);
    applyBoxUV(frontLeftLeg, 1);
    applyBoxUV(frontRightLeg, 1);
    applyBoxUV(rearLeftLeg, 1);
    applyBoxUV(rearRightLeg, 1);
    applyBoxUV(frontApron, 1);
    applyBoxUV(backApron, 1);
    applyBoxUV(leftApron, 1);
    applyBoxUV(rightApron, 1);
    applyBoxUV(leftBackPost, 1);
    applyBoxUV(rightBackPost, 1);
    applyBoxUV(slat1, 1);
    applyBoxUV(slat2, 1);
    applyBoxUV(slat3, 1);

    if (wood.map) {
      wood.map.rotation = Math.PI * 0.5;
      wood.map.center.set(0.5, 0.5);
      wood.map.needsUpdate = true;
    }

    //----------------------------------------------------------
    // CONTACT SHADOW
    //----------------------------------------------------------
    const shadow = new THREE.Mesh(
      new THREE.CircleGeometry(width * 0.75, 64),
      new THREE.MeshBasicMaterial({
        map: makeRadialShadowTexture(),
        transparent: true,
        opacity: 0.42,
        depthWrite: false,
      })
    );
    shadow.rotation.x = -Math.PI / 2;
    shadow.position.y = 0.001;
    group.add(shadow);

    group.traverse((mesh) => {
      if (!mesh.isMesh) return;
      mesh.castShadow = true;
      mesh.receiveShadow = true;
    });

    return group;
  }

  //----------------------------------------------------------
  // EXPORT
  //----------------------------------------------------------
  global.PremiumChairBuilder = { build: buildPremiumChair };

})(typeof window !== 'undefined' ? window : global);
