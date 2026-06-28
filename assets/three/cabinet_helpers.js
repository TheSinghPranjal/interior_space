/* global THREE */
(function (global) {
  'use strict';

  const FT = 0.3048;

  function createBarGeometry(radius, length) {
    if (typeof THREE.CapsuleGeometry !== 'undefined') {
      return new THREE.CapsuleGeometry(radius, length, 6, 14);
    }
    return new THREE.CylinderGeometry(radius, radius, length + radius * 2, 12);
  }

  function createHandle(renderer, opts) {
    const {
      length = 0.18 * FT,
      radius = 0.008 * FT,
      finish = 'steel',
      type = 'bar',
      vertical = true,
    } = opts || {};

    const group = new THREE.Group();

    let color = 0xd6d6d6;
    let roughness = 0.24;
    let metalness = 0.9;

    switch (finish) {
      case 'black':
        color = 0x222222;
        roughness = 0.42;
        metalness = 0.82;
        break;
      case 'gold':
        color = 0xc8a648;
        roughness = 0.18;
        metalness = 1;
        break;
      default:
        break;
    }

    const mat = new THREE.MeshStandardMaterial({
      color,
      roughness,
      metalness,
      envMapIntensity: 0.9,
    });

    if (type === 'knob') {
      const knob = new THREE.Mesh(new THREE.SphereGeometry(radius * 2.1, 20, 20), mat);
      knob.position.z = radius * 2;
      knob.userData.isHandle = true;
      group.add(knob);
    } else if (type === 'finger') {
      const pull = renderer._createRoundedBox(length, radius * 2.3, radius * 3, radius, mat);
      pull.userData.isHandle = true;
      group.add(pull);
    } else {
      const bar = new THREE.Mesh(createBarGeometry(radius, length), mat);
      bar.userData.isHandle = true;
      if (vertical) {
        bar.rotation.x = Math.PI / 2;
      } else {
        bar.rotation.z = Math.PI / 2;
      }
      group.add(bar);

      [-1, 1].forEach((side) => {
        const mount = new THREE.Mesh(
          new THREE.CylinderGeometry(radius * 0.45, radius * 0.45, radius * 3, 10),
          mat
        );
        mount.rotation.x = Math.PI / 2;
        if (vertical) {
          mount.position.y = side * length * 0.32;
        } else {
          mount.position.x = side * length * 0.32;
        }
        group.add(mount);
      });
    }

    const shadow = new THREE.Mesh(
      new THREE.PlaneGeometry(vertical ? radius * 6 : length * 0.8, vertical ? length * 0.8 : radius * 6),
      new THREE.MeshBasicMaterial({
        color: 0x000000,
        transparent: true,
        opacity: 0.08,
        depthWrite: false,
      })
    );
    shadow.position.z = -radius;
    group.add(shadow);

    group.traverse((mesh) => {
      if (mesh.isMesh) {
        mesh.castShadow = true;
        mesh.receiveShadow = true;
      }
    });

    return group;
  }

  function deformDoorFace(door, width, height) {
    const pos = door.geometry.attributes.position;
    if (!pos) return;
    for (let i = 0; i < pos.count; i++) {
      let x = pos.getX(i);
      let y = pos.getY(i);
      let z = pos.getZ(i);
      const edge = Math.max(Math.abs(x) / (width * 0.5), Math.abs(y) / (height * 0.5));
      if (edge > 0.82) {
        z -= 0.0015;
      }
      pos.setXYZ(i, x, y, z);
    }
    pos.needsUpdate = true;
    door.geometry.computeVertexNormals();
  }

  function createCabinetDoor(renderer, width, height, thickness, material, handleMaterial, hingeSide) {
    const group = new THREE.Group();
    const radius = Math.min(width, height) * 0.05;

    const door = renderer._createRoundedBox(width, height, thickness, radius, material);
    door.position.z = -0.003;
    group.add(door);
    deformDoorFace(door, width, height);

    const handleLength = Math.min(height, width) * 0.24;
    const handle = new THREE.Mesh(createBarGeometry(0.008 * FT, handleLength), handleMaterial);
    handle.rotation.z = Math.PI / 2;
    handle.userData.isHandle = true;
    const hx = hingeSide === 'left' ? width * 0.32 : -width * 0.32;
    handle.position.set(hx, 0, thickness * 0.9);
    group.add(handle);

    [-1, 1].forEach((side) => {
      const mount = new THREE.Mesh(
        new THREE.CylinderGeometry(0.0035 * FT, 0.0035 * FT, 0.012 * FT, 8),
        handleMaterial
      );
      mount.rotation.x = Math.PI / 2;
      mount.position.set(hx, side * handleLength * 0.33, thickness * 0.55);
      group.add(mount);
    });

    const shadow = new THREE.Mesh(
      new THREE.PlaneGeometry(handleLength * 0.9, 0.018 * FT),
      new THREE.MeshBasicMaterial({
        color: 0x000000,
        transparent: true,
        opacity: 0.08,
        depthWrite: false,
      })
    );
    shadow.position.set(hx, 0, thickness * 0.25);
    group.add(shadow);

    const gap = new THREE.Mesh(
      new THREE.BoxGeometry(width, height, 0.0015 * FT),
      new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.02 })
    );
    gap.position.z = -0.004;
    group.add(gap);

    if (material.map) {
      material.map.rotation = Math.PI / 2;
      material.map.center.set(0.5, 0.5);
    }

    group.traverse((mesh) => {
      if (mesh.isMesh) {
        mesh.castShadow = true;
        mesh.receiveShadow = true;
      }
    });

    return group;
  }

  function createDrawer(renderer, width, height, depth, frontThickness, bodyMaterial, handleMaterial) {
    const group = new THREE.Group();
    const radius = Math.min(width, height) * 0.05;

    const front = renderer._createRoundedBox(width, height, frontThickness, radius, bodyMaterial);
    front.position.z = depth * 0.5 - 0.003 * FT;
    group.add(front);
    deformDoorFace(front, width, height);

    const box = renderer._createRoundedBox(width * 0.96, height * 0.92, depth, radius * 0.5, bodyMaterial);
    box.position.z = -depth * 0.02;
    group.add(box);

    const handleLength = width * 0.24;
    const handle = new THREE.Mesh(createBarGeometry(0.008 * FT, handleLength), handleMaterial);
    handle.rotation.z = Math.PI / 2;
    handle.userData.isHandle = true;
    handle.position.set(0, 0, depth * 0.5 + frontThickness * 0.75);
    group.add(handle);

    [-1, 1].forEach((side) => {
      const mount = new THREE.Mesh(
        new THREE.CylinderGeometry(0.0035 * FT, 0.0035 * FT, 0.012 * FT, 8),
        handleMaterial
      );
      mount.rotation.x = Math.PI / 2;
      mount.position.set(side * handleLength * 0.33, 0, depth * 0.5 + frontThickness * 0.35);
      group.add(mount);
    });

    const shadow = new THREE.Mesh(
      new THREE.PlaneGeometry(handleLength * 0.85, 0.018 * FT),
      new THREE.MeshBasicMaterial({
        color: 0x000000,
        transparent: true,
        opacity: 0.08,
        depthWrite: false,
      })
    );
    shadow.position.set(0, 0, depth * 0.5 + frontThickness * 0.18);
    group.add(shadow);

    const gap = new THREE.Mesh(
      new THREE.BoxGeometry(width, height, 0.0015 * FT),
      new THREE.MeshBasicMaterial({ color: 0xffffff, transparent: true, opacity: 0.02 })
    );
    gap.position.z = depth * 0.5 - 0.004 * FT;
    group.add(gap);

    if (bodyMaterial.map) {
      bodyMaterial.map.rotation = Math.PI / 2;
      bodyMaterial.map.center.set(0.5, 0.5);
    }

    group.traverse((mesh) => {
      if (mesh.isMesh) {
        mesh.castShadow = true;
        mesh.receiveShadow = true;
      }
    });

    return group;
  }

  global.PremiumCabinetHelpers = {
    FT,
    createHandle,
    createCabinetDoor,
    createDrawer,
  };
})(typeof window !== 'undefined' ? window : global);
