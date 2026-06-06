/* global THREE, RoomRenderer */
(function () {
  'use strict';

  const FT = 0.3048;
  const textureCache = new Map();

  function hexColor(hex) {
    return parseInt(hex.replace('#', ''), 16);
  }

  function loadTexture(url, repeatX, repeatY, callback) {
    if (!url) { callback(null); return; }
    const key = url + '_' + repeatX + '_' + repeatY;
    if (textureCache.has(key)) { callback(textureCache.get(key)); return; }

    const loader = new THREE.TextureLoader();
    loader.load(url, (tex) => {
      tex.wrapS = THREE.RepeatWrapping;
      tex.wrapT = THREE.RepeatWrapping;
      tex.repeat.set(repeatX, repeatY);
      tex.encoding = THREE.sRGBEncoding;
      textureCache.set(key, tex);
      callback(tex);
    }, undefined, () => callback(null));
  }

  function proceduralTexture(type) {
    const size = 256;
    const canvas = document.createElement('canvas');
    canvas.width = size;
    canvas.height = size;
    const ctx = canvas.getContext('2d');

    const patterns = {
      brick: () => {
        ctx.fillStyle = '#8B4513';
        ctx.fillRect(0, 0, size, size);
        for (let y = 0; y < size; y += 16) {
          const offset = (y / 16) % 2 === 0 ? 0 : 20;
          for (let x = -offset; x < size; x += 40) {
            ctx.fillStyle = '#A0522D';
            ctx.fillRect(x + 2, y + 2, 36, 12);
          }
        }
      },
      concrete: () => {
        ctx.fillStyle = '#B0B0B0';
        ctx.fillRect(0, 0, size, size);
        for (let i = 0; i < 800; i++) {
          ctx.fillStyle = `rgba(${160 + Math.random() * 40},${160 + Math.random() * 40},${160 + Math.random() * 40},0.3)`;
          ctx.fillRect(Math.random() * size, Math.random() * size, 2, 2);
        }
      },
      marble: () => {
        const grad = ctx.createLinearGradient(0, 0, size, size);
        grad.addColorStop(0, '#F5F5F5');
        grad.addColorStop(0.5, '#E0E0E0');
        grad.addColorStop(1, '#FAFAFA');
        ctx.fillStyle = grad;
        ctx.fillRect(0, 0, size, size);
        ctx.strokeStyle = 'rgba(200,200,200,0.4)';
        for (let i = 0; i < 8; i++) {
          ctx.beginPath();
          ctx.moveTo(Math.random() * size, 0);
          ctx.bezierCurveTo(Math.random() * size, size * 0.3, Math.random() * size, size * 0.7, Math.random() * size, size);
          ctx.stroke();
        }
      },
      wood: () => {
        ctx.fillStyle = '#8B6914';
        ctx.fillRect(0, 0, size, size);
        for (let x = 0; x < size; x += 4) {
          const shade = 120 + Math.sin(x * 0.1) * 30;
          ctx.fillStyle = `rgb(${shade},${shade * 0.7},${shade * 0.3})`;
          ctx.fillRect(x, 0, 3, size);
        }
      },
      stone: () => {
        ctx.fillStyle = '#9E9E9E';
        ctx.fillRect(0, 0, size, size);
        for (let i = 0; i < 20; i++) {
          const sx = Math.random() * size;
          const sy = Math.random() * size;
          const sw = 30 + Math.random() * 40;
          const sh = 20 + Math.random() * 30;
          ctx.fillStyle = `rgb(${140 + Math.random() * 40},${140 + Math.random() * 40},${140 + Math.random() * 40})`;
          ctx.beginPath();
          ctx.ellipse(sx, sy, sw / 2, sh / 2, Math.random(), 0, Math.PI * 2);
          ctx.fill();
        }
      },
      fabric: () => {
        ctx.fillStyle = '#D7CCC8';
        ctx.fillRect(0, 0, size, size);
        for (let y = 0; y < size; y += 3) {
          ctx.fillStyle = y % 6 === 0 ? '#BCAAA4' : '#D7CCC8';
          ctx.fillRect(0, y, size, 2);
        }
      },
    };

    (patterns[type] || patterns.concrete)();
    const tex = new THREE.CanvasTexture(canvas);
    tex.wrapS = THREE.RepeatWrapping;
    tex.wrapT = THREE.RepeatWrapping;
    tex.encoding = THREE.sRGBEncoding;
    return tex;
  }

  class RoomRenderer {
    constructor() {
      this.scene = new THREE.Scene();
      this.scene.background = new THREE.Color(0x1a1a2e);
      this.scene.fog = new THREE.Fog(0x1a1a2e, 30, 80);

      this.camera = new THREE.PerspectiveCamera(60, 1, 0.1, 200);
      this.renderer = new THREE.WebGLRenderer({ antialias: true, preserveDrawingBuffer: true });
      this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
      this.renderer.shadowMap.enabled = true;
      this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
      this.renderer.outputEncoding = THREE.sRGBEncoding;
      document.body.appendChild(this.renderer.domElement);

      this.roomGroup = new THREE.Group();
      this.scene.add(this.roomGroup);

      this.controls = new THREE.OrbitControls(this.camera, this.renderer.domElement);
      this.controls.enableDamping = true;
      this.controls.dampingFactor = 0.08;
      this.controls.maxPolarAngle = Math.PI * 0.95;
      this.controls.minDistance = 2;
      this.controls.maxDistance = 60;

      this.lights = [];
      this.wallMeshes = {};
      this.cameraMode = 'orbit';
      this.walkVelocity = new THREE.Vector3();
      this.walkKeys = { forward: false, backward: false, left: false, right: false };
      this.clock = new THREE.Clock();
      this.config = null;
      this.roomSize = { w: 0, l: 0, h: 0 };

      this._bindEvents();
      this._animate();
      this._hideLoading();
    }

    _hideLoading() {
      const el = document.getElementById('loading');
      if (el) el.classList.add('hidden');
    }

    _bindEvents() {
      window.addEventListener('resize', () => this._onResize());
      this._onResize();
    }

    _onResize() {
      const w = window.innerWidth;
      const h = window.innerHeight;
      this.camera.aspect = w / h;
      this.camera.updateProjectionMatrix();
      this.renderer.setSize(w, h);
    }

    _clearRoom() {
      while (this.roomGroup.children.length) {
        const child = this.roomGroup.children[0];
        this.roomGroup.remove(child);
        child.traverse((obj) => {
          if (obj.geometry) obj.geometry.dispose();
          if (obj.material) {
            if (Array.isArray(obj.material)) obj.material.forEach(m => m.dispose());
            else obj.material.dispose();
          }
        });
      }
      this.lights.forEach(l => this.scene.remove(l));
      this.lights = [];
      this.wallMeshes = {};
    }

    updateScene(jsonStr) {
      try {
        this.config = typeof jsonStr === 'string' ? JSON.parse(jsonStr) : jsonStr;
        this._clearRoom();
        this._buildRoom();
        this._applyCameraMode(this.cameraMode);
        this._updateWallVisibility();
        this._notifyReady();
      } catch (e) {
        console.error('Scene update error:', e);
      }
    }

    setCameraMode(mode) {
      this.cameraMode = mode;
      this._applyCameraMode(mode);
    }

    setWalkInput(key, active) {
      if (this.walkKeys.hasOwnProperty(key)) {
        this.walkKeys[key] = active;
      }
    }

    _orbitZoom(scale) {
      if (!this.controls.enabled) return;
      const offset = new THREE.Vector3();
      offset.copy(this.camera.position).sub(this.controls.target);
      let distance = offset.length();
      if (distance === 0) return;
      distance = THREE.MathUtils.clamp(
        distance * scale,
        this.controls.minDistance,
        this.controls.maxDistance
      );
      offset.setLength(distance);
      this.camera.position.copy(this.controls.target).add(offset);
      this.controls.update();
      this._updateWallVisibility();
    }

    orbitZoomIn() {
      this._orbitZoom(0.82);
    }

    orbitZoomOut() {
      this._orbitZoom(1.22);
    }

    captureScreenshot() {
      this.renderer.render(this.scene, this.camera);
      return this.renderer.domElement.toDataURL('image/png');
    }

    _notifyReady() {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('onSceneReady');
      }
    }

    _applyCameraMode(mode) {
      if (!this.config) return;
      const { width, length, height } = this.config.room;
      const w = width * FT;
      const l = length * FT;
      const h = height * FT;
      const cx = 0, cz = 0;
      const eyeY = h * 0.4;

      this.controls.enabled = mode === 'orbit' || mode === 'isometric';
      this.controls.minDistance = Math.min(w, l) * 0.4;
      this.controls.maxDistance = Math.max(w, l) * 2.5;

      switch (mode) {
        case 'top':
          this.camera.position.set(cx, h * 2.8, cz);
          this.camera.lookAt(cx, 0, cz);
          break;
        case 'front':
          this.camera.position.set(cx, eyeY, -l * 1.3);
          this.camera.lookAt(cx, eyeY * 0.8, cz);
          break;
        case 'side':
          this.camera.position.set(w * 1.3, eyeY, cz);
          this.camera.lookAt(cx, eyeY * 0.8, cz);
          break;
        case 'isometric':
          this.camera.position.set(w * 0.75, h * 1.1, l * 0.75);
          this.camera.lookAt(cx, h * 0.3, cz);
          break;
        case 'walk':
        case 'firstPerson':
          this.camera.position.set(cx, h * 0.12, cz);
          this.camera.lookAt(cx, h * 0.12, cz - 1);
          break;
        default:
          this.camera.position.set(w * 0.7, h * 0.55, l * 0.7);
          this.camera.lookAt(cx, h * 0.35, cz);
      }
      this.controls.target.set(cx, h * 0.35, cz);
      this.controls.update();
      this._updateWallVisibility();
    }

    _updateWallVisibility() {
      if (!this.wallMeshes || !this.config) return;

      const w = this.roomSize.w;
      const l = this.roomSize.l;
      const dx = this.camera.position.x;
      const dz = this.camera.position.z;

      if (this.cameraMode === 'top') {
        Object.keys(this.wallMeshes).forEach((id) => {
          this.wallMeshes[id].visible = true;
        });
        return;
      }

      const insideRoom =
        Math.abs(dx) < w * 0.45 && Math.abs(dz) < l * 0.45;

      if (this.cameraMode === 'walk' || this.cameraMode === 'firstPerson' || insideRoom) {
        Object.keys(this.wallMeshes).forEach((id) => {
          this.wallMeshes[id].visible = true;
        });
        return;
      }

      let hiddenWall;
      if (this.cameraMode === 'front') hiddenWall = 'front';
      else if (this.cameraMode === 'side') hiddenWall = dx >= 0 ? 'right' : 'left';
      else if (Math.abs(dx) > Math.abs(dz)) {
        hiddenWall = dx > 0 ? 'right' : 'left';
      } else {
        hiddenWall = dz > 0 ? 'back' : 'front';
      }

      Object.keys(this.wallMeshes).forEach((id) => {
        this.wallMeshes[id].visible = id !== hiddenWall;
      });
    }

    _buildRoom() {
      const cfg = this.config;
      const w = cfg.room.width * FT;
      const l = cfg.room.length * FT;
      const h = cfg.room.height * FT;
      this.roomSize = { w, l, h };

      const ambient = new THREE.AmbientLight(0xffffff, 0.35);
      this.scene.add(ambient);
      this.lights.push(ambient);

      const hemi = new THREE.HemisphereLight(0xffffff, 0x444444, 0.4);
      this.scene.add(hemi);
      this.lights.push(hemi);

      this._buildFloor(w, l, cfg.floor);
      this._buildCeiling(w, l, h, cfg.ceiling);
      this._buildWalls(w, l, h, cfg);
      this._buildDoors(cfg.doors, w, l, h);
      this._buildWindows(cfg.windows, w, l, h);
      this._buildCupboards(cfg.cupboards, w, l, h);
      this._buildFurniture(cfg.furniture, w, l);
      this._buildLights(cfg.lights, w, l, h);
    }

    _makeMaterial(color, roughness, metalness, textureUrl, procType, repeatX, repeatY) {
      const mat = new THREE.MeshStandardMaterial({
        color: hexColor(color),
        roughness: roughness,
        metalness: metalness,
        side: THREE.FrontSide,
      });

      if (textureUrl) {
        loadTexture(textureUrl, repeatX || 2, repeatY || 2, (tex) => {
          if (tex) mat.map = tex;
          mat.needsUpdate = true;
        });
      } else if (procType) {
        const tex = proceduralTexture(procType);
        tex.repeat.set(repeatX || 2, repeatY || 2);
        mat.map = tex;
      }
      return mat;
    }

    _buildFloor(w, l, floor) {
      const geo = new THREE.PlaneGeometry(w, l);
      const matProps = this._materialProps(floor.material);
      const mat = this._makeMaterial(
        floor.color, matProps.roughness, matProps.metalness,
        floor.textureDataUrl, null, w / (floor.tileWidth * FT), l / (floor.tileLength * FT)
      );
      const mesh = new THREE.Mesh(geo, mat);
      mesh.rotation.x = -Math.PI / 2;
      mesh.receiveShadow = true;
      this.roomGroup.add(mesh);
    }

    _buildCeiling(w, l, h, ceiling) {
      const geo = new THREE.PlaneGeometry(w, l);
      const matProps = this._ceilingMaterialProps(ceiling.material);
      const mat = this._makeMaterial(
        ceiling.color, matProps.roughness, matProps.metalness,
        ceiling.textureDataUrl, null, 2, 2
      );
      const mesh = new THREE.Mesh(geo, mat);
      mesh.position.y = h;
      mesh.rotation.x = Math.PI / 2;
      this.roomGroup.add(mesh);

      if (ceiling.falseCeilingEnabled && ceiling.falseCeilingType !== 'none') {
        const depth = ceiling.falseCeilingDepth * FT;
        const thickness = ceiling.falseCeilingThickness * FT;
        const dropY = h - depth;

        const falseGeo = new THREE.BoxGeometry(w - 0.4, thickness, l - 0.4);
        const falseMat = this._makeMaterial(ceiling.falseCeilingColor, 0.8, 0.05, null, null, 1, 1);
        const falseMesh = new THREE.Mesh(falseGeo, falseMat);
        falseMesh.position.y = dropY;
        this.roomGroup.add(falseMesh);

        if (ceiling.falseCeilingType === 'cove') {
          const coveGeo = new THREE.TorusGeometry(Math.min(w, l) * 0.3, 0.05, 8, 32);
          const coveMat = new THREE.MeshStandardMaterial({ color: 0xffffff, emissive: 0xfff8e1, emissiveIntensity: 0.5 });
          const cove = new THREE.Mesh(coveGeo, coveMat);
          cove.rotation.x = Math.PI / 2;
          cove.position.y = dropY - 0.02;
          this.roomGroup.add(cove);
        }
      }
    }

    _buildWalls(w, l, h, cfg) {
      const wallDefs = [
        { id: 'front', pos: [0, h / 2, -l / 2], rot: [0, 0, 0], size: [w, h] },
        { id: 'back', pos: [0, h / 2, l / 2], rot: [0, Math.PI, 0], size: [w, h] },
        { id: 'left', pos: [-w / 2, h / 2, 0], rot: [0, Math.PI / 2, 0], size: [l, h] },
        { id: 'right', pos: [w / 2, h / 2, 0], rot: [0, -Math.PI / 2, 0], size: [l, h] },
      ];

      wallDefs.forEach(def => {
        const wallCfg = cfg.walls.find(wl => wl.id === def.id) || cfg.walls[0];
        if (!wallCfg) return;

        const procType = wallCfg.surfaceType === 'texture' ? wallCfg.texture : null;
        const texUrl = wallCfg.surfaceType === 'wallpaper' ? wallCfg.textureDataUrl : null;
        const repeatX = def.size[0] / FT;
        const repeatY = def.size[1] / FT;

        const mat = this._makeMaterial(
          wallCfg.color, 0.85, 0.02, texUrl, procType, repeatX, repeatY
        );

        const openings = this._getWallOpenings(def.id, cfg, w, l, h);
        let mesh;
        if (openings.length === 0) {
          const geo = new THREE.PlaneGeometry(def.size[0], def.size[1]);
          mesh = new THREE.Mesh(geo, mat);
          mesh.position.set(...def.pos);
          mesh.rotation.set(...def.rot);
          mesh.receiveShadow = true;
        } else {
          mesh = this._buildWallWithOpenings(def, mat, openings);
        }
        mesh.userData.wallId = def.id;
        this.wallMeshes[def.id] = mesh;
        this.roomGroup.add(mesh);
      });
    }

    _getWallOpenings(wallId, cfg, w, l, h) {
      const openings = [];
      const addOpening = (item, isDoor) => {
        if (item.wall !== wallId) return;
        const wallLen = (wallId === 'front' || wallId === 'back') ? w : l;
        const xOffset = (item.positionFromEdge * FT) + (item.width * FT / 2) - wallLen / 2;
        openings.push({
          width: item.width * FT,
          height: item.height * FT,
          x: xOffset,
          y: isDoor ? item.height * FT / 2 : ((item.positionFromFloor || 0) * FT) + item.height * FT / 2,
          isDoor,
        });
      };
      cfg.doors.forEach(d => addOpening(d, true));
      cfg.windows.forEach(win => addOpening(win, false));
      return openings;
    }

    _buildWallWithOpenings(def, material, openings) {
      const [wallW, wallH] = def.size;
      const shape = new THREE.Shape();
      shape.moveTo(-wallW / 2, 0);
      shape.lineTo(wallW / 2, 0);
      shape.lineTo(wallW / 2, wallH);
      shape.lineTo(-wallW / 2, wallH);
      shape.lineTo(-wallW / 2, 0);

      openings.forEach(op => {
        const hole = new THREE.Path();
        const left = op.x - op.width / 2;
        const bottom = op.y - op.height / 2;
        hole.moveTo(left, bottom);
        hole.lineTo(left + op.width, bottom);
        hole.lineTo(left + op.width, bottom + op.height);
        hole.lineTo(left, bottom + op.height);
        hole.lineTo(left, bottom);
        shape.holes.push(hole);
      });

      const geo = new THREE.ShapeGeometry(shape);
      const mesh = new THREE.Mesh(geo, material);
      mesh.position.set(def.pos[0], 0, def.pos[2]);
      mesh.rotation.set(...def.rot);
      mesh.receiveShadow = true;
      return mesh;
    }

    _buildDoors(doors, w, l, h) {
      doors.forEach(door => {
        const dw = door.width * FT;
        const dh = door.height * FT;
        const geo = new THREE.BoxGeometry(dw, dh, 0.08);
        const mat = this._makeMaterial(door.color, 0.7, 0.1, door.textureDataUrl, 'wood', 1, 1);
        const mesh = new THREE.Mesh(geo, mat);
        mesh.castShadow = true;

        const pos = this._wallItemPosition(door.wall, door.positionFromEdge, dw, w, l);
        mesh.position.set(pos.x, dh / 2, pos.z);
        if (door.wall === 'left' || door.wall === 'right') mesh.rotation.y = Math.PI / 2;
        mesh.rotation.y += (door.rotation || 0) * Math.PI / 180;
        this.roomGroup.add(mesh);
      });
    }

    _buildWindows(windows, w, l, h) {
      windows.forEach(win => {
        const ww = win.width * FT;
        const wh = win.height * FT;
        const frameGeo = new THREE.BoxGeometry(ww + 0.1, wh + 0.1, 0.06);
        const frameMat = new THREE.MeshStandardMaterial({ color: hexColor(win.frameColor), roughness: 0.5 });
        const frame = new THREE.Mesh(frameGeo, frameMat);

        const glassGeo = new THREE.BoxGeometry(ww, wh, 0.02);
        const glassMat = new THREE.MeshPhysicalMaterial({
          color: hexColor(win.glassColor),
          transparent: true,
          opacity: 0.4,
          roughness: 0.05,
          metalness: 0.1,
          transmission: 0.6,
        });
        const glass = new THREE.Mesh(glassGeo, glassMat);

        const group = new THREE.Group();
        group.add(frame);
        group.add(glass);

        const pos = this._wallItemPosition(win.wall, win.positionFromEdge, ww, w, l);
        group.position.set(pos.x, (win.positionFromFloor * FT) + wh / 2, pos.z);
        if (win.wall === 'left' || win.wall === 'right') group.rotation.y = Math.PI / 2;
        group.rotation.y += (win.rotation || 0) * Math.PI / 180;
        this.roomGroup.add(group);
      });
    }

    _wallItemPosition(wall, fromEdge, itemW, roomW, roomL) {
      const offset = fromEdge * FT + itemW / 2;
      switch (wall) {
        case 'front': return { x: -roomW / 2 + offset, z: -roomL / 2 + 0.05 };
        case 'back': return { x: -roomW / 2 + offset, z: roomL / 2 - 0.05 };
        case 'left': return { x: -roomW / 2 + 0.05, z: -roomL / 2 + offset };
        case 'right': return { x: roomW / 2 - 0.05, z: -roomL / 2 + offset };
        default: return { x: 0, z: 0 };
      }
    }

    _buildCupboards(cupboards, w, l, h) {
      cupboards.forEach((c) => {
        const cw = c.width * FT;
        const ch = c.height * FT;
        const cd = c.depth * FT;
        const group = this._buildWardrobeGroup(cw, ch, cd, c.color, c.textureDataUrl);

        const x = ((c.blueprintX ?? 0.5) - 0.5) * w;
        const z = ((c.blueprintY ?? 0.5) - 0.5) * l;
        group.position.set(x, 0, z);
        group.rotation.y = (c.rotation || 0) * Math.PI / 180;
        this.roomGroup.add(group);
      });
    }

    _buildWardrobeGroup(width, height, depth, color, textureUrl) {
      const group = new THREE.Group();
      const bodyMat = this._makeMaterial(color, 0.55, 0.05, textureUrl, 'wood', 1, 1);
      const trimMat = new THREE.MeshStandardMaterial({
        color: 0x2c2c2c,
        roughness: 0.4,
        metalness: 0.3,
      });

      const body = new THREE.Mesh(new THREE.BoxGeometry(width, height, depth), bodyMat);
      body.position.y = height / 2;
      group.add(body);

      const doorW = width * 0.48;
      const doorGeo = new THREE.BoxGeometry(doorW, height * 0.92, 0.03);
      [-1, 1].forEach((side) => {
        const door = new THREE.Mesh(doorGeo, bodyMat);
        door.position.set(side * width * 0.24, height * 0.5, depth / 2 + 0.02);
        group.add(door);

        const handle = new THREE.Mesh(
          new THREE.BoxGeometry(0.03, 0.12, 0.04),
          trimMat
        );
        handle.position.set(side * width * 0.08, height * 0.45, depth / 2 + 0.05);
        group.add(handle);
      });

      group.traverse((child) => {
        if (child.isMesh) {
          child.castShadow = true;
          child.receiveShadow = true;
        }
      });
      return group;
    }

    _wallMountedPosition(wall, fromEdge, itemW, depth, roomW, roomL) {
      const offset = fromEdge * FT + itemW / 2;
      switch (wall) {
        case 'front': return { x: -roomW / 2 + offset, z: -roomL / 2 };
        case 'back': return { x: -roomW / 2 + offset, z: roomL / 2 };
        case 'left': return { x: -roomW / 2, z: -roomL / 2 + offset };
        case 'right': return { x: roomW / 2, z: -roomL / 2 + offset };
        default: return { x: 0, z: 0 };
      }
    }

    _buildFurniture(furniture, w, l) {
      furniture.forEach((item) => {
        const tex = item.textureDataUrl || null;
        let group;

        switch (item.type) {
          case 'bed':
            group = this._buildBedGroup(item);
            break;
          case 'wardrobe':
          case 'cupboard':
            group = this._buildWardrobeGroup(
              item.width * FT,
              item.height * FT,
              item.depth * FT,
              item.color,
              tex
            );
            break;
          case 'sofa':
            group = this._buildSofaGroup(item, tex);
            break;
          case 'table':
            group = this._buildTableGroup(item);
            break;
          case 'chair':
            group = this._buildChairGroup(item);
            break;
          case 'tvUnit':
            group = this._buildTvUnitGroup(item, tex);
            break;
          default:
            group = this._buildGenericFurniture(item);
        }

        const x = (item.blueprintX - 0.5) * w;
        const z = (item.blueprintY - 0.5) * l;
        group.position.set(x, 0, z);
        group.rotation.y = (item.rotation || 0) * Math.PI / 180;
        this.roomGroup.add(group);
      });
    }

    _buildBedGroup(item) {
      const fw = item.width * FT;
      const fd = item.depth * FT;
      const group = new THREE.Group();
      const frameH = 0.35 * FT;
      const mattressH = 0.45 * FT;
      const woodColor = hexColor(item.color);

      const frameMat = new THREE.MeshStandardMaterial({ color: woodColor, roughness: 0.75 });
      const mattressMat = new THREE.MeshStandardMaterial({ color: 0xf3efe6, roughness: 0.95 });
      const sheetMat = new THREE.MeshStandardMaterial({ color: 0xffffff, roughness: 0.9 });
      const pillowMat = new THREE.MeshStandardMaterial({ color: 0xfafafa, roughness: 0.92 });

      const frame = new THREE.Mesh(new THREE.BoxGeometry(fw, frameH, fd), frameMat);
      frame.position.y = frameH / 2;
      group.add(frame);

      const mattress = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.94, mattressH, fd * 0.94),
        mattressMat
      );
      mattress.position.y = frameH + mattressH / 2;
      group.add(mattress);

      const sheet = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.9, 0.06 * FT, fd * 0.88),
        sheetMat
      );
      sheet.position.y = frameH + mattressH + 0.03 * FT;
      group.add(sheet);

      const headboard = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.96, 2.2 * FT, 0.12 * FT),
        frameMat
      );
      headboard.position.set(0, frameH + 1.1 * FT, -fd / 2 + 0.06 * FT);
      group.add(headboard);

      [-1, 1].forEach((side) => {
        const pillow = new THREE.Mesh(
          new THREE.BoxGeometry(fw * 0.26, 0.14 * FT, fd * 0.2),
          pillowMat
        );
        pillow.position.set(side * fw * 0.2, frameH + mattressH + 0.1 * FT, -fd * 0.28);
        group.add(pillow);
      });

      const blanket = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.88, 0.08 * FT, fd * 0.55),
        new THREE.MeshStandardMaterial({ color: 0xd7ccc8, roughness: 0.95 })
      );
      blanket.position.set(0, frameH + mattressH + 0.05 * FT, fd * 0.12);
      group.add(blanket);

      group.traverse((child) => {
        if (child.isMesh) {
          child.castShadow = true;
          child.receiveShadow = true;
        }
      });
      return group;
    }

    _buildTvUnitGroup(item, textureUrl) {
      const fw = item.width * FT;
      const fh = item.height * FT;
      const fd = item.depth * FT;
      const group = new THREE.Group();
      const mat = this._makeMaterial(item.color, 0.5, 0.1, textureUrl, 'wood', 1, 1);

      const body = new THREE.Mesh(new THREE.BoxGeometry(fw, fh, fd), mat);
      body.position.y = fh / 2;
      group.add(body);

      const screen = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.7, fh * 0.55, 0.04),
        new THREE.MeshStandardMaterial({ color: 0x111111, roughness: 0.2, metalness: 0.5 })
      );
      screen.position.set(0, fh * 0.65, fd / 2 + 0.02);
      group.add(screen);

      group.traverse((c) => { if (c.isMesh) { c.castShadow = true; c.receiveShadow = true; } });
      return group;
    }

    _buildSofaGroup(item, textureUrl) {
      const fw = item.width * FT;
      const fh = item.height * FT;
      const fd = item.depth * FT;
      const group = new THREE.Group();
      const mat = this._makeMaterial(item.color, 0.85, 0.02, textureUrl, 'fabric', 1, 1);

      const base = new THREE.Mesh(new THREE.BoxGeometry(fw, fh * 0.45, fd), mat);
      base.position.y = fh * 0.25;
      group.add(base);

      const back = new THREE.Mesh(new THREE.BoxGeometry(fw, fh * 0.55, fd * 0.2), mat);
      back.position.set(0, fh * 0.55, -fd * 0.4);
      group.add(back);

      group.traverse((c) => { if (c.isMesh) { c.castShadow = true; c.receiveShadow = true; } });
      return group;
    }

    _buildTableGroup(item) {
      const fw = item.width * FT;
      const fh = item.height * FT;
      const fd = item.depth * FT;
      const group = new THREE.Group();
      const mat = this._makeMaterial(item.color, 0.6, 0.1, null, 'wood', 1, 1);

      const top = new THREE.Mesh(new THREE.BoxGeometry(fw, 0.08 * FT, fd), mat);
      top.position.y = fh;
      group.add(top);

      const legGeo = new THREE.BoxGeometry(0.08 * FT, fh, 0.08 * FT);
      [[-1, -1], [-1, 1], [1, -1], [1, 1]].forEach(([sx, sz]) => {
        const leg = new THREE.Mesh(legGeo, mat);
        leg.position.set(sx * fw * 0.42, fh / 2, sz * fd * 0.42);
        group.add(leg);
      });

      group.traverse((c) => { if (c.isMesh) { c.castShadow = true; c.receiveShadow = true; } });
      return group;
    }

    _buildChairGroup(item) {
      const cw = item.width * FT;
      const ch = item.height * FT;
      const cd = item.depth * FT;
      const group = new THREE.Group();
      const fabricMat = this._makeMaterial(item.color, 0.82, 0.04, null, 'fabric', 1, 1);
      const frameMat = this._makeMaterial(item.color, 0.55, 0.12, null, 'wood', 1, 1);

      const seatHeight = ch * 0.42;
      const seatThickness = 0.07 * FT;

      const seat = new THREE.Mesh(
        new THREE.BoxGeometry(cw * 0.88, seatThickness, cd * 0.82),
        fabricMat
      );
      seat.position.y = seatHeight;
      group.add(seat);

      const backrest = new THREE.Mesh(
        new THREE.BoxGeometry(cw * 0.88, ch * 0.42, 0.07 * FT),
        fabricMat
      );
      backrest.position.set(0, seatHeight + ch * 0.18, -cd * 0.36);
      group.add(backrest);

      const legGeo = new THREE.BoxGeometry(0.05 * FT, seatHeight, 0.05 * FT);
      [[-1, -1], [-1, 1], [1, -1], [1, 1]].forEach(([sx, sz]) => {
        const leg = new THREE.Mesh(legGeo, frameMat);
        leg.position.set(sx * cw * 0.36, seatHeight / 2, sz * cd * 0.34);
        group.add(leg);
      });

      const armGeo = new THREE.BoxGeometry(0.06 * FT, ch * 0.22, cd * 0.55);
      [-1, 1].forEach((side) => {
        const arm = new THREE.Mesh(armGeo, frameMat);
        arm.position.set(side * cw * 0.4, seatHeight + ch * 0.08, 0);
        group.add(arm);
      });

      group.traverse((c) => {
        if (c.isMesh) {
          c.castShadow = true;
          c.receiveShadow = true;
        }
      });
      return group;
    }

    _buildGenericFurniture(item) {
      const group = new THREE.Group();
      const mesh = new THREE.Mesh(
        new THREE.BoxGeometry(item.width * FT, item.height * FT, item.depth * FT),
        this._makeMaterial(item.color, 0.7, 0.05, null, 'wood', 1, 1)
      );
      mesh.position.y = (item.height * FT) / 2;
      mesh.castShadow = true;
      mesh.receiveShadow = true;
      group.add(mesh);
      return group;
    }

    _buildLights(lights, w, l, h) {
      lights.forEach(light => {
        if (!light.enabled) return;
        const x = (light.positionX - 0.5) * w;
        const y = light.positionZ * h;
        const z = (light.positionY - 0.5) * l;
        const intensity = light.brightness * 1.5;
        const color = hexColor(light.color);

        let lightObj;
        switch (light.type) {
          case 'spot':
            lightObj = new THREE.SpotLight(color, intensity, 20, Math.PI / 6, 0.3);
            lightObj.castShadow = true;
            break;
          case 'ledStrip':
            lightObj = new THREE.PointLight(color, intensity * 0.8, 15);
            break;
          default:
            lightObj = new THREE.PointLight(color, intensity, 25);
            lightObj.castShadow = true;
        }

        lightObj.position.set(x, y, z);
        if (lightObj.castShadow) {
          lightObj.shadow.mapSize.width = 1024;
          lightObj.shadow.mapSize.height = 1024;
        }
        this.scene.add(lightObj);
        this.lights.push(lightObj);

        const bulbGeo = new THREE.SphereGeometry(0.08, 8, 8);
        const bulbMat = new THREE.MeshBasicMaterial({ color: color });
        const bulb = new THREE.Mesh(bulbGeo, bulbMat);
        bulb.position.set(x, y, z);
        this.roomGroup.add(bulb);
      });
    }

    _materialProps(material) {
      const map = {
        marble: { roughness: 0.15, metalness: 0.1 },
        granite: { roughness: 0.25, metalness: 0.15 },
        wooden: { roughness: 0.7, metalness: 0.02 },
        vinyl: { roughness: 0.4, metalness: 0.05 },
        ceramic: { roughness: 0.35, metalness: 0.08 },
        porcelain: { roughness: 0.2, metalness: 0.12 },
      };
      return map[material] || { roughness: 0.5, metalness: 0.05 };
    }

    _ceilingMaterialProps(material) {
      const map = {
        matte: { roughness: 0.95, metalness: 0 },
        glossy: { roughness: 0.2, metalness: 0.1 },
        pop: { roughness: 0.8, metalness: 0.02 },
        gypsum: { roughness: 0.85, metalness: 0.03 },
      };
      return map[material] || { roughness: 0.9, metalness: 0 };
    }

    _animate() {
      requestAnimationFrame(() => this._animate());
      const delta = this.clock.getDelta();

      if (this.cameraMode === 'walk' || this.cameraMode === 'firstPerson') {
        const speed = 3 * delta;
        const direction = new THREE.Vector3();
        this.camera.getWorldDirection(direction);
        direction.y = 0;
        direction.normalize();

        const right = new THREE.Vector3();
        right.crossVectors(direction, new THREE.Vector3(0, 1, 0));

        if (this.walkKeys.forward) this.camera.position.addScaledVector(direction, speed);
        if (this.walkKeys.backward) this.camera.position.addScaledVector(direction, -speed);
        if (this.walkKeys.left) this.camera.position.addScaledVector(right, -speed);
        if (this.walkKeys.right) this.camera.position.addScaledVector(right, speed);
      }

      this.controls.update();
      this._updateWallVisibility();
      this.renderer.render(this.scene, this.camera);
    }
  }

  function showError(msg) {
    var el = document.getElementById('loading');
    if (el) {
      el.textContent = msg;
      el.classList.add('error');
    }
    console.error(msg);
  }

  function initRenderer() {
    try {
      if (typeof THREE === 'undefined') {
        showError('Three.js failed to load');
        return false;
      }
      if (typeof THREE.OrbitControls === 'undefined') {
        showError('OrbitControls failed to load');
        return false;
      }
      window.RoomRenderer = RoomRenderer;
      window.roomRenderer = new RoomRenderer();
      return true;
    } catch (e) {
      showError('3D init error: ' + e.message);
      return false;
    }
  }

  window.updateRoomScene = function (json) {
    if (!window.roomRenderer && !initRenderer()) return;
    window.roomRenderer.updateScene(json);
  };

  window.setCameraMode = function (mode) {
    if (window.roomRenderer) window.roomRenderer.setCameraMode(mode);
  };

  window.setWalkInput = function (key, active) {
    if (window.roomRenderer) window.roomRenderer.setWalkInput(key, active);
  };

  window.orbitZoomIn = function () {
    if (window.roomRenderer) window.roomRenderer.orbitZoomIn();
  };

  window.orbitZoomOut = function () {
    if (window.roomRenderer) window.roomRenderer.orbitZoomOut();
  };

  window.captureScreenshot = function () {
    if (window.roomRenderer) return window.roomRenderer.captureScreenshot();
    return null;
  };

  initRenderer();
})();
