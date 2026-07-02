/* global THREE, RoomRenderer */
(function () {
  'use strict';

  const FT = 0.3048;
  const textureCache = new Map();

  function hexColor(hex) {
    return parseInt(hex.replace('#', ''), 16);
  }

  function loadTexture(url, repeatX, repeatY, callback, clamp) {
    if (!url) { callback(null); return; }
    const useClamp = clamp === true;
    const key = url + '_' + repeatX + '_' + repeatY + '_' + (useClamp ? 'clamp' : 'repeat');
    if (textureCache.has(key)) { callback(textureCache.get(key)); return; }

    const loader = new THREE.TextureLoader();
    loader.load(url, (tex) => {
      if (useClamp) {
        tex.wrapS = THREE.ClampToEdgeWrapping;
        tex.wrapT = THREE.ClampToEdgeWrapping;
      } else {
        tex.wrapS = THREE.RepeatWrapping;
        tex.wrapT = THREE.RepeatWrapping;
      }
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
        ctx.fillStyle = '#909090';
        ctx.fillRect(0, 0, size, size);
        for (let x = 0; x < size; x += 4) {
          const shade = 130 + Math.sin(x * 0.12) * 35 + Math.sin(x * 0.04) * 15;
          ctx.fillStyle = `rgb(${shade},${shade},${shade})`;
          ctx.fillRect(x, 0, 3, size);
        }
      },
      metal: () => {
        ctx.fillStyle = '#B0BEC5';
        ctx.fillRect(0, 0, size, size);
        for (let y = 0; y < size; y += 2) {
          ctx.fillStyle = y % 4 === 0 ? '#ECEFF1' : '#78909C';
          ctx.fillRect(0, y, size, 1);
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
      if (THREE.ACESFilmicToneMapping !== undefined) {
        this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
        this.renderer.toneMappingExposure = 1.1;
      }
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
      this.fanRotors = [];
      this.wallMeshes = {};
      this._materialCache = new Map();
      this._cachedMaterials = new Set();
      this.isApartmentMode = false;
      this.cameraMode = 'orbit';
      this.walkVelocity = new THREE.Vector3();
      this.walkKeys = { forward: false, backward: false, left: false, right: false };
      this.clock = new THREE.Clock();
      this.config = null;
      this.roomSize = { w: 0, l: 0, h: 0 };
      this._apartmentPremium = false;

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
            const mats = Array.isArray(obj.material) ? obj.material : [obj.material];
            mats.forEach((m) => {
              if (!this._cachedMaterials.has(m)) m.dispose();
            });
          }
        });
      }
      this.lights.forEach(l => this.scene.remove(l));
      this.lights = [];
      this.fanRotors = [];
      this.wallMeshes = {};
    }

    _applyPerformanceSettings() {
      const apartment = this.config && this.config.mode === 'apartment';
      this.isApartmentMode = apartment;
      this.renderer.shadowMap.enabled = !apartment;
      this.renderer.setPixelRatio(
        Math.min(window.devicePixelRatio, apartment ? 1.5 : 2)
      );
    }

    updateScene(jsonStr) {
      try {
        this.config = typeof jsonStr === 'string' ? JSON.parse(jsonStr) : jsonStr;
        this._cachedMaterials.forEach((m) => m.dispose());
        this._cachedMaterials.clear();
        this._materialCache.clear();
        textureCache.clear();
        this._clearRoom();
        this._apartmentPremium = false;
        this._applyPerformanceSettings();
        if (this.config.mode === 'apartment') {
          this._buildApartment();
        } else {
          this._buildRoom();
        }
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

    captureExportViews() {
      const previousMode = this.cameraMode || 'orbit';
      const captureMode = (mode) => {
        this.setCameraMode(mode);
        this.renderer.render(this.scene, this.camera);
        return this.renderer.domElement.toDataURL('image/png');
      };

      const views = {
        front: captureMode('front'),
        top: captureMode('top'),
      };

      this.setCameraMode(previousMode);
      return JSON.stringify(views);
    }

    _notifyReady() {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('onSceneReady');
      }
    }

    _applyCameraMode(mode) {
      if (!this.config) return;
      let width, length, height;
      if (this.config.mode === 'apartment') {
        width = this.config.apartment.width;
        length = this.config.apartment.length;
        height = (this.roomSize.h || 10) / FT;
      } else {
        ({ width, length, height } = this.config.room);
      }
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
          const mesh = this.wallMeshes[id];
          if (mesh) mesh.visible = true;
        });
        return;
      }

      const insideRoom =
        Math.abs(dx) < w * 0.45 && Math.abs(dz) < l * 0.45;

      if (insideRoom) {
        Object.keys(this.wallMeshes).forEach((id) => {
          const mesh = this.wallMeshes[id];
          if (mesh) mesh.visible = true;
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
        const mesh = this.wallMeshes[id];
        if (!mesh) return;
        mesh.visible = id !== hiddenWall;
      });
    }

    _resolveTextureUrl(inlineUrl, texturePath) {
      if (inlineUrl) return inlineUrl;
      const shared = this.config && this.config.sharedTextures;
      if (shared && texturePath && shared[texturePath]) return shared[texturePath];
      return null;
    }

    _isPremiumFurniture() {
      return !!(this._apartmentPremium || (this.config && this.config.premiumFurniture));
    }

    _usesIdenticalPremiumGeometry(type) {
      return ['sofa'].indexOf(type) >= 0;
    }

    _hasDedicatedPremiumBuilder(type) {
      return [
        'bed', 'chair', 'table', 'diningTable', 'flowerPot',
        'storageUnit', 'fridge', 'washingMachine', 'shoeRack',
        'sink', 'kitchenChimney', 'car',
      ].indexOf(type) >= 0;
    }

    _cloneMaterial(mat) {
      if (!mat || !mat.clone) return mat;
      const c = mat.clone();
      if (mat.map) c.map = mat.map;
      if (mat.normalMap) c.normalMap = mat.normalMap;
      if (mat.roughnessMap) c.roughnessMap = mat.roughnessMap;
      if (mat.metalnessMap) c.metalnessMap = mat.metalnessMap;
      if (mat.aoMap) c.aoMap = mat.aoMap;
      if (mat.emissiveMap) c.emissiveMap = mat.emissiveMap;
      return c;
    }

    _applyPremiumFurnitureFinish(group) {
      group.traverse((child) => {
        if (!child.isMesh || !child.material) return;
        const sourceMats = Array.isArray(child.material) ? child.material : [child.material];
        const mats = sourceMats.map((mat) => {
          if (!mat) return mat;
          const c = this._cloneMaterial(mat);
          const isFabricLike = typeof c.roughness === 'number' && c.roughness >= 0.72;
          if (isFabricLike) {
            c.roughness = Math.max(0.78, c.roughness * 0.97);
            if ('envMapIntensity' in c) {
              c.envMapIntensity = Math.max(c.envMapIntensity || 1, 1.15);
            }
          } else {
            if (typeof c.roughness === 'number') {
              c.roughness = Math.max(0.08, c.roughness * 0.88);
            }
            if (typeof c.metalness === 'number') {
              c.metalness = Math.min(0.35, c.metalness + 0.08);
            }
            if ('envMapIntensity' in c) {
              c.envMapIntensity = Math.max(c.envMapIntensity || 1, 1.5);
            }
          }
          c.needsUpdate = true;
          return c;
        });
        child.material = Array.isArray(child.material) ? mats : mats[0];
      });
    }

    _addSceneLights() {
      const ambient = new THREE.AmbientLight(0xffffff, 0.45);
      this.scene.add(ambient);
      this.lights.push(ambient);

      const hemi = new THREE.HemisphereLight(0xffffff, 0x444444, 0.55);
      this.scene.add(hemi);
      this.lights.push(hemi);

      const dir = new THREE.DirectionalLight(0xffffff, 2.8);
      dir.position.set(5, 12, 8);
      dir.castShadow = true;
      dir.shadow.mapSize.set(2048, 2048);
      dir.shadow.bias = -0.0002;
      this.scene.add(dir);
      this.lights.push(dir);
    }

    _buildRoomContents(cfg, targetGroup, opts = {}) {
      const savedGroup = this.roomGroup;
      const savedWallMeshes = this.wallMeshes;
      const savedConfig = this.config;
      const lightweight = opts.lightweight || false;
      const premiumFurniture = opts.premiumFurniture === true ||
        cfg.premiumFurniture === true ||
        this._apartmentPremium;

      const sharedTextures = (savedConfig && savedConfig.sharedTextures) ||
        cfg.sharedTextures ||
        null;

      this.roomGroup = targetGroup;
      this.wallMeshes = {};
      this.config = Object.assign({}, cfg, {
        premiumFurniture: premiumFurniture,
        sharedTextures: sharedTextures,
      });

      const layout = this._resolveRoomLayout(cfg);
      const { w, l, h } = layout;

      if (layout.polygon) {
        this._buildPolygonFloor(layout.polygon, cfg.floor);
        if (!lightweight) this._buildPolygonCeiling(layout.polygon, h, cfg.ceiling);
        if (this._shouldUseRectangularWalls(layout)) {
          this._buildWalls(w, l, h, cfg, layout);
        } else {
          this._buildPolygonWalls(layout, h, cfg);
        }
      } else {
        this._buildFloor(w, l, cfg.floor);
        if (!lightweight) this._buildCeiling(w, l, h, cfg.ceiling);
        this._buildWalls(w, l, h, cfg, layout);
      }

      if (this.config.showWallDimensionLabels !== false) {
        this._buildWallLabels(layout, h);
      }
      this._buildDoors(cfg.doors, layout);
      this._buildWindows(cfg.windows, layout);
      this._buildCurtains(cfg.curtains || [], layout);
      this._buildAcUnits(cfg.acUnits || [], layout);
      this._buildWallTvUnits(cfg.wallTvUnits || [], layout);
      this._buildCupboards(cfg.cupboards, w, l, h);
      this._buildStairs(cfg.stairs || [], w, l);
      this._buildFurniture(cfg.furniture, w, l);
      if (!lightweight) {
        this._buildLights(cfg.lights, w, l, h);
        this._buildFans(cfg.fans || [], w, l, h);
      } else {
        this._buildFans(cfg.fans || [], w, l, h, { animate: false });
      }

      if (lightweight) {
        targetGroup.traverse((obj) => {
          if (obj.isMesh) {
            obj.castShadow = false;
            obj.receiveShadow = false;
          }
        });
      }

      this.roomGroup = savedGroup;
      this.wallMeshes = savedWallMeshes;
      this.config = savedConfig;

      return { w, l, h };
    }

    _resolveRoomLayout(cfg) {
      const room = cfg.room;
      const h = room.height * FT;
      const wallLengths = room.wallLengths || {
        front: room.width,
        back: room.width,
        left: room.length,
        right: room.length,
      };
      const w = (room.effectiveWidth ?? room.width) * FT;
      const l = (room.effectiveLength ?? room.length) * FT;
      let polygon = null;
      if (room.floorPolygon && room.floorPolygon.length >= 3 &&
          (room.shapeMode === 'polygon' || room.useCustomWallLengths)) {
        polygon = this._centerPolygon(room.floorPolygon);
      }
      return {
        w, l, h, wallLengths, polygon,
        useCustom: !!room.useCustomWallLengths,
        shapeMode: room.shapeMode || 'rectangular',
      };
    }

    /** Quadrilateral floor edges: FL→FR front, FR→BR right, BR→BL back, BL→FL left. */
    _quadEdgeWallId(edgeIndex) {
      return ['front', 'right', 'back', 'left'][edgeIndex];
    }

    _usesQuadWallIdMapping(cfg, layout) {
      const poly = layout.polygon;
      if (!poly || poly.length !== 4) return false;
      if (layout.shapeMode === 'polygon') return false;
      return !!(layout.useCustom || (cfg.room && cfg.room.useCustomWallLengths));
    }

    _wallCfgForPolygonEdge(cfg, edgeIndex, layout) {
      if (this._usesQuadWallIdMapping(cfg, layout)) {
        const wallId = this._quadEdgeWallId(edgeIndex);
        return cfg.walls.find(w => w.id === wallId)
          || cfg.walls.find(w => w.wallIndex === edgeIndex)
          || cfg.walls[edgeIndex]
          || cfg.walls[0];
      }
      return cfg.walls[edgeIndex]
        || cfg.walls.find(w => w.wallIndex === edgeIndex)
        || cfg.walls[0];
    }

    _polygonWallMeshId(wallCfg, edgeIndex, layout, cfg) {
      const roomCfg = cfg || this.config;
      if (this._usesQuadWallIdMapping(roomCfg, layout) && wallCfg && wallCfg.id) {
        return wallCfg.id;
      }
      const idx = wallCfg && wallCfg.wallIndex != null ? wallCfg.wallIndex : edgeIndex;
      return `wall_${idx}`;
    }

    _shouldUseRectangularWalls(layout) {
      if (!layout.polygon || layout.polygon.length !== 4) return false;
      if (layout.shapeMode === 'polygon') return false;
      if (!layout.useCustom) return false;
      const wl = layout.wallLengths || {};
      const front = wl.front || 0;
      const back = wl.back || 0;
      const left = wl.left || 0;
      const right = wl.right || 0;
      return Math.abs(front - back) < 0.05 && Math.abs(left - right) < 0.05;
    }

    _centerPolygon(floorPolygon) {
      const pts = floorPolygon.map(p => ({ x: p.x * FT, z: p.y * FT }));
      const cx = pts.reduce((s, p) => s + p.x, 0) / pts.length;
      const cz = pts.reduce((s, p) => s + p.z, 0) / pts.length;
      return pts.map(p => ({ x: p.x - cx, z: p.z - cz }));
    }

    _buildPolygonFloor(polygon, floor) {
      const shape = new THREE.Shape();
      shape.moveTo(polygon[0].x, polygon[0].z);
      for (let i = 1; i < polygon.length; i++) shape.lineTo(polygon[i].x, polygon[i].z);
      shape.lineTo(polygon[0].x, polygon[0].z);
      const geo = new THREE.ShapeGeometry(shape);
      geo.rotateX(-Math.PI / 2);
      const matProps = this._materialProps(floor.material);
      const mat = this._makeMaterial(
        floor.color, matProps.roughness, matProps.metalness,
        this._resolveTextureUrl(floor.textureDataUrl, floor.texturePath), null, 2, 2
      );
      const mesh = new THREE.Mesh(geo, mat);
      mesh.receiveShadow = true;
      this.roomGroup.add(mesh);
    }

    _buildPolygonCeiling(polygon, h, ceiling) {
      const shape = new THREE.Shape();
      shape.moveTo(polygon[0].x, polygon[0].z);
      for (let i = 1; i < polygon.length; i++) shape.lineTo(polygon[i].x, polygon[i].z);
      shape.lineTo(polygon[0].x, polygon[0].z);
      const geo = new THREE.ShapeGeometry(shape);
      geo.rotateX(Math.PI / 2);
      const matProps = this._ceilingMaterialProps(ceiling.material);
      const mat = this._makeMaterial(
        ceiling.color, matProps.roughness, matProps.metalness,
        this._resolveTextureUrl(ceiling.textureDataUrl, ceiling.texturePath), null, 2, 2
      );
      const mesh = new THREE.Mesh(geo, mat);
      mesh.position.y = h;
      this.roomGroup.add(mesh);
    }

    _buildPolygonWalls(layout, h, cfg) {
      const poly = layout.polygon;
      for (let i = 0; i < poly.length; i++) {
        try {
        const a = poly[i];
        const b = poly[(i + 1) % poly.length];
        const dx = b.x - a.x;
        const dz = b.z - a.z;
        const len = Math.sqrt(dx * dx + dz * dz);
        if (len < 0.001) continue;
        const wallCfg = this._wallCfgForPolygonEdge(cfg, i, layout);
        if (!wallCfg) continue;
        const id = this._polygonWallMeshId(wallCfg, i, layout, cfg);
        const procType = wallCfg.surfaceType === 'texture' ? wallCfg.texture : null;
        const texUrl = wallCfg.surfaceType === 'wallpaper'
          ? this._resolveTextureUrl(wallCfg.textureDataUrl, wallCfg.wallpaperPath)
          : null;
        const sizeXFt = len / FT;
        const sizeYFt = h / FT;
        const { repeatX, repeatY, clamp } = this._wallTextureRepeat(wallCfg, sizeXFt * (this._wallVisibility(wallCfg).fraction), sizeYFt);
        const mat = this._makeMaterial(
          wallCfg.color, 0.85, 0.02, texUrl, procType, repeatX, repeatY, clamp
        );
        const barrierType = wallCfg.barrierType || 'solid';
        let mesh;
        if (barrierType !== 'solid') {
          mesh = this._buildPolygonWallBarrierGroup(
            poly[i], poly[(i + 1) % poly.length], wallCfg, h, id
          );
        } else {
          mesh = this._buildPolygonWallSegment(
            poly[i], poly[(i + 1) % poly.length], wallCfg, h, mat, id
          );
        }
        if (!mesh) continue;
        this.wallMeshes[id] = mesh;
        this.roomGroup.add(mesh);
        } catch (err) {
          console.error('Polygon wall build failed:', i, err);
        }
      }
    }

    _buildWallLabels(layout, h) {
      const wallOrder = [
        { id: 'front', label: 'Front' },
        { id: 'back', label: 'Back' },
        { id: 'left', label: 'Left' },
        { id: 'right', label: 'Right' },
      ];
      wallOrder.forEach(({ id, label }) => {
        const lenFt = layout.wallLengths[id];
        if (!lenFt) return;
        const wallCfg = this.config.walls && this.config.walls.find(w => w.id === id);
        if (wallCfg && this._wallVisibility(wallCfg).fraction <= 0.001) return;
        const canvas = document.createElement('canvas');
        canvas.width = 256;
        canvas.height = 64;
        const ctx = canvas.getContext('2d');
        ctx.fillStyle = 'rgba(255,255,255,0.92)';
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        ctx.fillStyle = '#1A2421';
        ctx.font = 'bold 22px sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText(`${label}: ${lenFt.toFixed(1)} ft`, 128, 38);
        const tex = new THREE.CanvasTexture(canvas);
        const mat = new THREE.MeshBasicMaterial({ map: tex, transparent: true });
        const mesh = new THREE.Mesh(new THREE.PlaneGeometry(1.2, 0.3), mat);
        const pos = this._wallLabelPosition(id, layout, h);
        mesh.position.set(pos.x, pos.y, pos.z);
        mesh.rotation.y = pos.rotY;
        this.roomGroup.add(mesh);
      });
    }

    _wallLabelPosition(wallId, layout, h) {
      if (layout.polygon) {
        const idx = { front: 0, right: 1, back: 2, left: 3 }[wallId];
        if (idx == null) return { x: 0, y: h * 0.55, z: 0, rotY: 0 };
        const a = layout.polygon[idx];
        const b = layout.polygon[(idx + 1) % layout.polygon.length];
        const dx = b.x - a.x;
        const dz = b.z - a.z;
        const len = Math.sqrt(dx * dx + dz * dz) || 1;
        const inset = 0.35;
        return {
          x: (a.x + b.x) / 2 + (-dz / len) * inset,
          y: h * 0.55,
          z: (a.z + b.z) / 2 + (dx / len) * inset,
          rotY: Math.atan2(-dz, dx),
        };
      }
      const { w, l } = layout;
      switch (wallId) {
        case 'front': return { x: 0, y: h * 0.55, z: -l / 2 + 0.35, rotY: 0 };
        case 'back': return { x: 0, y: h * 0.55, z: l / 2 - 0.35, rotY: Math.PI };
        case 'left': return { x: -w / 2 + 0.35, y: h * 0.55, z: 0, rotY: Math.PI / 2 };
        case 'right': return { x: w / 2 - 0.35, y: h * 0.55, z: 0, rotY: -Math.PI / 2 };
        default: return { x: 0, y: h * 0.55, z: 0, rotY: 0 };
      }
    }

    _buildRoom() {
      const cfg = this.config;
      const w = cfg.room.width * FT;
      const l = cfg.room.length * FT;
      const h = cfg.room.height * FT;
      this.roomSize = { w, l, h };

      this._addSceneLights();
      this._buildRoomContents(cfg, this.roomGroup);
    }

    _buildApartment() {
      const apt = this.config.apartment;
      const aptW = apt.width * FT;
      const aptL = apt.length * FT;
      let maxH = 3 * FT;

      this._apartmentPremium = !!this.config.premiumFurniture;
      this._addSceneLights();

      const baseMat = new THREE.MeshStandardMaterial({
        color: 0xE8E0D5,
        roughness: 0.9,
        metalness: 0,
      });
      const base = new THREE.Mesh(new THREE.PlaneGeometry(aptW, aptL), baseMat);
      base.rotation.x = -Math.PI / 2;
      base.position.y = -0.01;
      base.receiveShadow = false;
      this.roomGroup.add(base);

      const gridHelper = new THREE.GridHelper(Math.max(aptW, aptL), 12, 0x888888, 0xcccccc);
      gridHelper.position.y = 0.001;
      this.roomGroup.add(gridHelper);

      const lightweight = this.config.performanceMode !== false;
      const placements = this.config.placements || [];

      placements.forEach((placement, index) => {
        try {
          const cfg = placement.room;
          if (!cfg || !cfg.room) return;

          const subGroup = new THREE.Group();
          subGroup.name = placement.name || ('Room_' + (index + 1));
          const dims = this._buildRoomContents(cfg, subGroup, {
            lightweight: lightweight,
            premiumFurniture: this._apartmentPremium,
          });
          maxH = Math.max(maxH, dims.h);

          const wx = (placement.blueprintX - 0.5) * aptW;
          const wz = (placement.blueprintY - 0.5) * aptL;
          subGroup.position.set(wx, 0, wz);
          subGroup.rotation.y = (placement.rotation || 0) * Math.PI / 180;
          this.roomGroup.add(subGroup);
        } catch (err) {
          console.error('Apartment room build failed for placement', index, placement && placement.name, err);
        }
      });

      this.roomSize = { w: aptW, l: aptL, h: maxH };
      this.wallMeshes = {};
    }

    _wallTextureRepeat(wallCfg, sizeXFt, sizeYFt) {
      if (wallCfg.surfaceType === 'wallpaper' &&
          (wallCfg.textureDataUrl || wallCfg.wallpaperPath) &&
          !wallCfg.tileWallpaper) {
        return { repeatX: 1, repeatY: 1, clamp: true };
      }
      return { repeatX: sizeXFt, repeatY: sizeYFt, clamp: false };
    }

    _wallVisibility(wallCfg) {
      const fraction = wallCfg.visibleFraction != null ? wallCfg.visibleFraction : 1;
      const align = wallCfg.visibleAlign || 'start';
      return {
        fraction: Math.max(0, Math.min(1, fraction)),
        align,
      };
    }

    _buildVisibleWallMesh(wallCfg, fullWidth, fullHeight, id, basePos, baseRot, mat) {
      const { fraction, align } = this._wallVisibility(wallCfg);
      if (fraction <= 0.001) return null;

      const visW = fullWidth * fraction;
      const visH = fullHeight;

      let alongOffset = 0;
      if (align === 'center') alongOffset = (fullWidth - visW) / 2;
      else if (align === 'end') alongOffset = fullWidth - visW;

      const geo = new THREE.PlaneGeometry(visW, visH);
      const mesh = new THREE.Mesh(geo, mat);

      const pos = [basePos[0], basePos[1], basePos[2]];
      switch (id) {
        case 'front':
          pos[0] = basePos[0] - fullWidth / 2 + alongOffset + visW / 2;
          break;
        case 'back':
          pos[0] = basePos[0] + fullWidth / 2 - alongOffset - visW / 2;
          break;
        case 'left':
          pos[2] = basePos[2] - fullWidth / 2 + alongOffset + visW / 2;
          break;
        case 'right':
          pos[2] = basePos[2] + fullWidth / 2 - alongOffset - visW / 2;
          break;
      }

      mesh.position.set(pos[0], pos[1], pos[2]);
      mesh.rotation.set(baseRot[0], baseRot[1], baseRot[2]);
      mesh.userData.wallId = id;
      return mesh;
    }

    _wallSegmentAlongOffset(fullWidth, fraction, align) {
      const visW = fullWidth * fraction;
      let alongOffset = 0;
      if (align === 'center') alongOffset = (fullWidth - visW) / 2;
      else if (align === 'end') alongOffset = fullWidth - visW;
      return { visW, alongOffset };
    }

    _populateFenceGroup(group, width, height, color) {
      const woodMat = this._makeMaterial(color, 0.78, 0.08, null, 'wood', 1, 1);
      const postH = height * 0.86;
      const postR = 0.035;
      const spacing = Math.max(0.65, width / Math.max(2, Math.floor(width / 0.75)));
      const count = Math.max(2, Math.round(width / spacing) + 1);
      const step = width / (count - 1);

      for (let i = 0; i < count; i++) {
        const x = -width / 2 + i * step;
        const post = new THREE.Mesh(
          new THREE.CylinderGeometry(postR, postR * 1.08, postH, 8),
          woodMat
        );
        post.position.set(x, postH / 2, 0);
        group.add(post);
      }

      [postH * 0.18, postH * 0.52, postH * 0.86].forEach((y) => {
        const rail = new THREE.Mesh(new THREE.BoxGeometry(width, 0.045, 0.045), woodMat);
        rail.position.set(0, y, 0);
        group.add(rail);
      });

      for (let i = 0; i < count - 1; i++) {
        const segStart = -width / 2 + i * step;
        const pickets = 3;
        for (let j = 1; j < pickets; j++) {
          const x = segStart + (j / pickets) * step;
          const picket = new THREE.Mesh(
            new THREE.BoxGeometry(0.028, postH * 0.72, 0.022),
            woodMat
          );
          picket.position.set(x, postH * 0.36, 0);
          group.add(picket);
        }
      }
    }

    _populateBalconyRailingGroup(group, width, height, color) {
      const railMat = this._makeMaterial(color, 0.32, 0.55, null, 'metal', 1, 1);
      const railH = Math.min(height * 0.38, 3.5 * FT);
      const baseY = 0.06;
      const spacing = Math.max(0.16, width / Math.max(2, Math.floor(width / 0.18)));
      const count = Math.max(2, Math.round(width / spacing) + 1);
      const step = width / (count - 1);

      const bottomRail = new THREE.Mesh(new THREE.BoxGeometry(width, 0.04, 0.05), railMat);
      bottomRail.position.set(0, baseY, 0);
      group.add(bottomRail);

      const topRail = new THREE.Mesh(new THREE.BoxGeometry(width, 0.06, 0.09), railMat);
      topRail.position.set(0, baseY + railH, 0);
      group.add(topRail);

      for (let i = 0; i < count; i++) {
        const x = -width / 2 + i * step;
        const bal = new THREE.Mesh(
          new THREE.BoxGeometry(0.022, railH - 0.12, 0.022),
          railMat
        );
        bal.position.set(x, baseY + railH * 0.48, 0);
        group.add(bal);
      }

      [-1, 1].forEach((side) => {
        const post = new THREE.Mesh(
          new THREE.BoxGeometry(0.05, railH + 0.1, 0.05),
          railMat
        );
        post.position.set(side * width / 2, baseY + railH * 0.48, 0);
        group.add(post);
      });
    }

    _buildWallBarrierGroup(wallCfg, fullWidth, fullHeight, id, basePos, baseRot) {
      const barrierType = wallCfg.barrierType || 'solid';
      if (barrierType === 'solid') return null;

      const { fraction, align } = this._wallVisibility(wallCfg);
      if (fraction <= 0.001) return null;

      const { visW, alongOffset } = this._wallSegmentAlongOffset(fullWidth, fraction, align);
      const group = new THREE.Group();

      if (barrierType === 'fence') {
        this._populateFenceGroup(group, visW, fullHeight, wallCfg.color);
      } else if (barrierType === 'balconyRailing') {
        this._populateBalconyRailingGroup(group, visW, fullHeight, wallCfg.color);
      } else {
        return null;
      }

      const pos = [basePos[0], basePos[1], basePos[2]];
      switch (id) {
        case 'front':
          pos[0] = basePos[0] - fullWidth / 2 + alongOffset + visW / 2;
          break;
        case 'back':
          pos[0] = basePos[0] + fullWidth / 2 - alongOffset - visW / 2;
          break;
        case 'left':
          pos[2] = basePos[2] - fullWidth / 2 + alongOffset + visW / 2;
          break;
        case 'right':
          pos[2] = basePos[2] + fullWidth / 2 - alongOffset - visW / 2;
          break;
      }

      group.position.set(pos[0], 0, pos[2]);
      group.rotation.set(baseRot[0], baseRot[1], baseRot[2]);
      group.userData.wallId = id;
      group.traverse((c) => {
        if (c.isMesh) {
          c.castShadow = true;
          c.receiveShadow = true;
        }
      });
      return group;
    }

    _buildPolygonWallBarrierGroup(a, b, wallCfg, h, id) {
      const barrierType = wallCfg.barrierType || 'solid';
      if (barrierType === 'solid') return null;

      const { fraction, align } = this._wallVisibility(wallCfg);
      if (fraction <= 0.001) return null;

      const dx = b.x - a.x;
      const dz = b.z - a.z;
      const len = Math.sqrt(dx * dx + dz * dz);
      if (len < 0.001) return null;

      const visLen = len * fraction;
      const skip = len - visLen;

      let startX = a.x;
      let startZ = a.z;
      if (align === 'center') {
        startX = a.x + (dx * skip / 2) / len;
        startZ = a.z + (dz * skip / 2) / len;
      } else if (align === 'end') {
        startX = a.x + (dx * skip) / len;
        startZ = a.z + (dz * skip) / len;
      }

      const midX = startX + (dx / len) * visLen / 2;
      const midZ = startZ + (dz / len) * visLen / 2;
      const inset = 0.04;
      const group = new THREE.Group();

      if (barrierType === 'fence') {
        this._populateFenceGroup(group, visLen, h, wallCfg.color);
      } else if (barrierType === 'balconyRailing') {
        this._populateBalconyRailingGroup(group, visLen, h, wallCfg.color);
      } else {
        return null;
      }

      group.position.set(
        midX + (-dz / len) * inset,
        0,
        midZ + (dx / len) * inset
      );
      group.rotation.y = Math.atan2(-dz, dx);
      group.userData.wallId = id;
      group.traverse((c) => {
        if (c.isMesh) {
          c.castShadow = true;
          c.receiveShadow = true;
        }
      });
      return group;
    }

    _buildPolygonWallSegment(a, b, wallCfg, h, mat, id) {
      const { fraction, align } = this._wallVisibility(wallCfg);
      if (fraction <= 0.001) return null;

      const dx = b.x - a.x;
      const dz = b.z - a.z;
      const len = Math.sqrt(dx * dx + dz * dz);
      if (len < 0.001) return null;

      const visLen = len * fraction;
      const skip = len - visLen;

      let startX = a.x;
      let startZ = a.z;
      if (align === 'center') {
        startX = a.x + (dx * skip / 2) / len;
        startZ = a.z + (dz * skip / 2) / len;
      } else if (align === 'end') {
        startX = a.x + (dx * skip) / len;
        startZ = a.z + (dz * skip) / len;
      }

      const midX = startX + (dx / len) * visLen / 2;
      const midZ = startZ + (dz / len) * visLen / 2;
      const inset = 0.04;

      const geo = new THREE.PlaneGeometry(visLen, h);
      const mesh = new THREE.Mesh(geo, mat);
      mesh.position.set(
        midX + (-dz / len) * inset,
        h / 2,
        midZ + (dx / len) * inset
      );
      mesh.rotation.y = Math.atan2(-dz, dx);
      mesh.userData.wallId = id;
      mesh.receiveShadow = true;
      return mesh;
    }

    _makeMaterial(color, roughness, metalness, textureUrl, procType, repeatX, repeatY, clamp) {
      const useClamp = clamp === true;
      const key = [color, roughness, metalness, textureUrl || '', procType || '', repeatX, repeatY, useClamp ? 'c' : 'r'].join('|');
      if (this._materialCache.has(key)) {
        return this._materialCache.get(key);
      }

      const mat = new THREE.MeshStandardMaterial({
        color: hexColor(color),
        roughness: roughness,
        metalness: metalness,
        side: THREE.FrontSide,
      });

      if (textureUrl) {
        loadTexture(textureUrl, repeatX || 1, repeatY || 1, (tex) => {
          if (tex) mat.map = tex;
          mat.needsUpdate = true;
        }, useClamp);
      } else if (procType) {
        const tex = proceduralTexture(procType);
        tex.repeat.set(repeatX || 2, repeatY || 2);
        mat.map = tex;
      }

      this._materialCache.set(key, mat);
      this._cachedMaterials.add(mat);
      return mat;
    }

    _buildFloor(w, l, floor) {
      const geo = new THREE.PlaneGeometry(w, l);
      const matProps = this._materialProps(floor.material);
      const mat = this._makeMaterial(
        floor.color, matProps.roughness, matProps.metalness,
        this._resolveTextureUrl(floor.textureDataUrl, floor.texturePath), null, w / (floor.tileWidth * FT), l / (floor.tileLength * FT)
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
        this._resolveTextureUrl(ceiling.textureDataUrl, ceiling.texturePath), null, 2, 2
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

    _buildWalls(w, l, h, cfg, layout) {
      const wallLengths = (layout && layout.wallLengths) || {
        front: w / FT, back: w / FT, left: l / FT, right: l / FT,
      };
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
        const texUrl = wallCfg.surfaceType === 'wallpaper'
          ? this._resolveTextureUrl(wallCfg.textureDataUrl, wallCfg.wallpaperPath)
          : null;
        const sizeXFt = def.size[0] / FT;
        const sizeYFt = def.size[1] / FT;
        const { repeatX, repeatY, clamp } = this._wallTextureRepeat(wallCfg, sizeXFt, sizeYFt);

        const mat = this._makeMaterial(
          wallCfg.color, 0.85, 0.02, texUrl, procType, repeatX, repeatY, clamp
        );

        const barrierType = wallCfg.barrierType || 'solid';
        if (barrierType !== 'solid') {
          const barrier = this._buildWallBarrierGroup(
            wallCfg, def.size[0], def.size[1], def.id, def.pos, def.rot
          );
          if (barrier) {
            this.wallMeshes[def.id] = barrier;
            this.roomGroup.add(barrier);
          }
          return;
        }

        const mesh = this._buildVisibleWallMesh(
          wallCfg, def.size[0], def.size[1], def.id, def.pos, def.rot, mat
        );
        if (!mesh) return;
        mesh.receiveShadow = true;
        this.wallMeshes[def.id] = mesh;
        this.roomGroup.add(mesh);
      });
    }

    _wallItemPositionFromLayout(wall, fromEdge, itemW, layout) {
      const wallLenFt = layout.wallLengths[wall] || (wall === 'front' || wall === 'back' ? layout.w / FT : layout.l / FT);
      const wallLen = wallLenFt * FT;
      const w = layout.w;
      const l = layout.l;
      const offset = fromEdge * FT + itemW / 2;
      switch (wall) {
        case 'front': return { x: -w / 2 + offset, z: -l / 2 + 0.05 };
        case 'back': return { x: -w / 2 + offset, z: l / 2 - 0.05 };
        case 'left': return { x: -w / 2 + 0.05, z: -l / 2 + offset };
        case 'right': return { x: w / 2 - 0.05, z: -l / 2 + offset };
        default: return { x: 0, z: 0 };
      }
    }

    _doorMaterialProps(material) {
      switch (material) {
        case 'glass':
          return {
            roughness: 0.04,
            metalness: 0.25,
            proc: null,
            transparent: true,
            opacity: 0.4,
          };
        case 'metal':
          return { roughness: 0.28, metalness: 0.9, proc: 'metal' };
        case 'laminate':
          return { roughness: 0.42, metalness: 0.06, proc: 'fabric' };
        case 'wood':
        default:
          return { roughness: 0.72, metalness: 0.05, proc: 'wood' };
      }
    }

    _buildDoorMaterial(door, repeatX, repeatY) {
      const doorTex = this._resolveTextureUrl(door.textureDataUrl, door.texturePath);
      const props = this._doorMaterialProps(door.material);
      const color = hexColor(door.color);

      if (props.transparent) {
        const mat = new THREE.MeshStandardMaterial({
          color,
          roughness: props.roughness,
          metalness: props.metalness,
          transparent: true,
          opacity: props.opacity,
          side: THREE.DoubleSide,
          depthWrite: false,
        });
        if (doorTex) {
          loadTexture(doorTex, repeatX, repeatY, (tex) => {
            if (tex) {
              mat.map = tex;
              mat.needsUpdate = true;
            }
          });
        }
        return mat;
      }

      const proc = doorTex ? null : props.proc;
      return this._makeMaterial(
        door.color,
        props.roughness,
        props.metalness,
        doorTex,
        proc,
        repeatX,
        repeatY
      );
    }

    _buildDoors(doors, layout) {
      doors.forEach(door => {
        const dw = door.width * FT;
        const dh = door.height * FT;
        const group = new THREE.Group();
        const geo = new THREE.BoxGeometry(dw, dh, 0.08);
        const mat = this._buildDoorMaterial(door, Math.max(dw / FT, 1), Math.max(dh / FT, 1));
        const mesh = new THREE.Mesh(geo, mat);
        mesh.castShadow = false;
        mesh.receiveShadow = true;
        group.add(mesh);

        const knobMat = new THREE.MeshStandardMaterial({
          color: 0xB8860B,
          roughness: 0.25,
          metalness: 0.85,
        });
        const knob = new THREE.Mesh(new THREE.SphereGeometry(0.045, 12, 12), knobMat);
        knob.position.set(dw * 0.38, -dh * 0.05, 0.06);
        group.add(knob);

        const pos = this._wallItemPositionFromLayout(door.wall, door.positionFromEdge, dw, layout);
        group.position.set(pos.x, dh / 2, pos.z);
        if (door.wall === 'left' || door.wall === 'right') group.rotation.y = Math.PI / 2;
        group.rotation.y += (door.rotation || 0) * Math.PI / 180;
        this.roomGroup.add(group);
      });
    }

    _buildWindows(windows, layout) {
      windows.forEach(win => {
        const ww = win.width * FT;
        const wh = win.height * FT;
        const frameW = 0.06;
        const frameD = 0.08;
        const frameColor = hexColor(win.frameColor);
        const frameMat = new THREE.MeshStandardMaterial({
          color: frameColor,
          roughness: 0.45,
          metalness: 0.15,
        });

        const group = new THREE.Group();

        const addFrameBar = (geo, px, py, pz) => {
          const mesh = new THREE.Mesh(geo, frameMat);
          mesh.position.set(px, py, pz);
          mesh.castShadow = true;
          mesh.receiveShadow = true;
          group.add(mesh);
        };

        addFrameBar(new THREE.BoxGeometry(ww + frameW * 2, frameW, frameD), 0, wh / 2 + frameW / 2, 0);
        addFrameBar(new THREE.BoxGeometry(ww + frameW * 2, frameW, frameD), 0, -wh / 2 - frameW / 2, 0);
        addFrameBar(new THREE.BoxGeometry(frameW, wh, frameD), -ww / 2 - frameW / 2, 0, 0);
        addFrameBar(new THREE.BoxGeometry(frameW, wh, frameD), ww / 2 + frameW / 2, 0, 0);
        addFrameBar(new THREE.BoxGeometry(ww, frameW * 0.7, frameD * 0.85), 0, 0, 0.005);
        addFrameBar(new THREE.BoxGeometry(frameW * 0.7, wh, frameD * 0.85), 0, 0, 0.005);

        const sill = new THREE.Mesh(new THREE.BoxGeometry(ww + 0.16, 0.05, 0.12), frameMat);
        sill.position.set(0, -wh / 2 - frameW - 0.025, 0.04);
        sill.castShadow = true;
        group.add(sill);

        const glassHex = hexColor(win.glassColor);
        const glassMat = new THREE.MeshStandardMaterial({
          color: glassHex,
          transparent: true,
          opacity: 0.55,
          roughness: 0.05,
          metalness: 0.1,
          side: THREE.DoubleSide,
          depthWrite: false,
        });
        const glass = new THREE.Mesh(
          new THREE.BoxGeometry(ww - frameW * 0.4, wh - frameW * 0.4, 0.018),
          glassMat
        );
        glass.castShadow = false;
        glass.receiveShadow = false;
        group.add(glass);

        const sky = new THREE.Mesh(
          new THREE.PlaneGeometry(ww - frameW, wh - frameW),
          new THREE.MeshBasicMaterial({ color: 0x87CEEB, transparent: true, opacity: 0.35 })
        );
        sky.position.z = -0.02;
        group.add(sky);

        const pos = this._wallItemPositionFromLayout(win.wall, win.positionFromEdge, ww, layout);
        group.position.set(pos.x, (win.positionFromFloor * FT) + wh / 2, pos.z);
        if (win.wall === 'left' || win.wall === 'right') group.rotation.y = Math.PI / 2;
        group.rotation.y += (win.rotation || 0) * Math.PI / 180;
        this.roomGroup.add(group);
      });
    }

    _wallItemRotation(wall) {
      switch (wall) {
        case 'front': return Math.PI;
        case 'back': return 0;
        case 'left': return -Math.PI / 2;
        case 'right': return Math.PI / 2;
        default: return 0;
      }
    }

    _buildStandardAcUnitGroup(unit) {
      const uw = unit.width * FT;
      const uh = unit.height * FT;
      const depth = 0.22;
      const group = new THREE.Group();

      const bodyMat = this._makeMaterial(
        unit.color, 0.35, 0.12,
        this._resolveTextureUrl(unit.textureDataUrl, unit.texturePath),
        null, 1, 1
      );
      const trimMat = new THREE.MeshStandardMaterial({
        color: new THREE.Color(hexColor(unit.color)).multiplyScalar(0.88),
        roughness: 0.4,
        metalness: 0.08,
      });
      const louverMat = new THREE.MeshStandardMaterial({
        color: 0xB0BEC5,
        roughness: 0.55,
        metalness: 0.2,
      });

      // Wall plane at z=0; unit extends into the room (-Z).
      const frontZ = -depth;
      const topH = uh * 0.12;
      const louverH = uh * 0.28;
      const bodyH = uh - topH - louverH - uh * 0.04;
      const bodyCenterY = -uh * 0.5 + louverH + uh * 0.02 + bodyH * 0.5;
      const bodyTopY = bodyCenterY + bodyH * 0.5;
      const topCapDepth = depth * 0.05;

      const body = new THREE.Mesh(new THREE.BoxGeometry(uw, bodyH, depth), bodyMat);
      body.position.set(0, bodyCenterY, -depth / 2);
      body.castShadow = true;
      body.receiveShadow = true;
      group.add(body);

      const topCap = new THREE.Mesh(
        new THREE.BoxGeometry(uw * 0.98, topH, topCapDepth),
        trimMat
      );
      topCap.position.set(0, bodyTopY + topH / 2 + 0.001 * FT, frontZ + topCapDepth / 2 + 0.002);
      topCap.castShadow = true;
      group.add(topCap);

      const display = new THREE.Mesh(
        new THREE.BoxGeometry(uw * 0.18, uh * 0.06, 0.012),
        new THREE.MeshStandardMaterial({ color: 0x263238, roughness: 0.3, metalness: 0.4 })
      );
      display.position.set(uw * 0.32, bodyTopY + topH * 0.35, frontZ + 0.008);
      group.add(display);

      const brandBar = new THREE.Mesh(
        new THREE.BoxGeometry(uw * 0.12, uh * 0.04, 0.012),
        new THREE.MeshStandardMaterial({ color: 0x78909C, roughness: 0.5, metalness: 0.15 })
      );
      brandBar.position.set(-uw * 0.38, bodyTopY + topH * 0.35, frontZ + 0.008);
      group.add(brandBar);

      const louver = new THREE.Mesh(
        new THREE.BoxGeometry(uw * 0.96, louverH, depth * 0.75),
        louverMat
      );
      louver.position.set(0, -uh * 0.5 + louverH * 0.5 + uh * 0.02, -depth * 0.42);
      louver.castShadow = true;
      group.add(louver);

      for (let i = 0; i < 5; i++) {
        const slat = new THREE.Mesh(
          new THREE.BoxGeometry(uw * 0.9, 0.012, depth * 0.55),
          louverMat
        );
        slat.position.set(
          0,
          -uh * 0.5 + uh * 0.06 + i * (louverH * 0.82 / 4),
          frontZ + 0.008
        );
        slat.rotation.x = -0.35;
        group.add(slat);
      }

      group.traverse((c) => { if (c.isMesh) { c.castShadow = true; c.receiveShadow = true; } });
      return group;
    }

    _buildAcUnits(units, layout) {
      units.forEach((unit) => {
        const uw = unit.width * FT;
        const uh = unit.height * FT;
        const group = this._isPremiumFurniture()
          ? PremiumAcUnitBuilder.build(this, unit)
          : this._buildStandardAcUnitGroup(unit);

        const pos = this._wallItemPositionFromLayout(unit.wall, unit.positionFromEdge, uw, layout);
        group.position.set(pos.x, (unit.positionFromFloor * FT) + uh / 2, pos.z);
        group.rotation.y = this._wallItemRotation(unit.wall) + (unit.rotation || 0) * Math.PI / 180;
        this.roomGroup.add(group);
      });
    }

    _buildCurtains(curtains, layout) {
      curtains.forEach((curtain) => {
        const cw = curtain.width * FT;
        const ch = curtain.height * FT;
        const group = new THREE.Group();
        const fabricMat = new THREE.MeshStandardMaterial({
          color: hexColor(curtain.color),
          roughness: 0.92,
          metalness: 0.02,
          side: THREE.DoubleSide,
        });
        const rodMat = new THREE.MeshStandardMaterial({ color: 0x8D6E63, roughness: 0.4, metalness: 0.35 });
        const isOpen = curtain.state !== 'closed';

        const rod = new THREE.Mesh(new THREE.CylinderGeometry(0.025, 0.025, cw + 0.12, 8), rodMat);
        rod.rotation.z = Math.PI / 2;
        rod.position.y = ch / 2 + 0.04;
        group.add(rod);

        const panelW = isOpen ? cw * 0.22 : cw * 0.48;
        const panelOffset = isOpen ? cw * 0.36 : cw * 0.24;
        [-1, 1].forEach((side) => {
          const panel = new THREE.Mesh(new THREE.BoxGeometry(panelW, ch, 0.025), fabricMat);
          panel.position.set(side * panelOffset, 0, isOpen ? side * 0.06 : 0.02);
          if (isOpen) panel.rotation.y = side * 0.55;
          panel.castShadow = false;
          group.add(panel);
          const fold = new THREE.Mesh(new THREE.BoxGeometry(panelW * 0.85, ch * 0.92, 0.012), fabricMat);
          fold.position.copy(panel.position);
          fold.position.z += 0.015;
          fold.rotation.copy(panel.rotation);
          group.add(fold);
        });

        const pos = this._wallItemPositionFromLayout(curtain.wall, curtain.positionFromEdge, cw, layout);
        group.position.set(pos.x, (curtain.positionFromFloor * FT) + ch / 2, pos.z);
        if (curtain.wall === 'left' || curtain.wall === 'right') group.rotation.y = Math.PI / 2;
        group.rotation.y += (curtain.rotation || 0) * Math.PI / 180;
        this.roomGroup.add(group);
      });
    }

    _buildWallTvUnits(units, layout) {
      units.forEach((unit) => {
        const uw = unit.width * FT;
        const uh = unit.height * FT;
        const group = new THREE.Group();
        const bodyMat = this._makeMaterial(unit.color, 0.5, 0.1, this._resolveTextureUrl(unit.textureDataUrl, unit.texturePath), this._resolveTextureUrl(unit.textureDataUrl, unit.texturePath) ? null : 'wood', 1, 1);

        const body = new THREE.Mesh(new THREE.BoxGeometry(uw, uh, 0.08), bodyMat);
        body.position.z = 0.04;
        body.castShadow = false;
        body.receiveShadow = false;
        group.add(body);

        const screen = new THREE.Mesh(
          new THREE.BoxGeometry(uw * 0.82, uh * 0.72, 0.02),
          new THREE.MeshStandardMaterial({ color: 0x111111, roughness: 0.2, metalness: 0.5 })
        );
        screen.position.set(0, uh * 0.06, 0.09);
        screen.castShadow = false;
        screen.receiveShadow = false;
        group.add(screen);

        const pos = this._wallItemPositionFromLayout(unit.wall, unit.positionFromEdge, uw, layout);
        group.position.set(pos.x, ((unit.positionFromFloor || 0) * FT) + uh / 2, pos.z);
        if (unit.wall === 'left' || unit.wall === 'right') group.rotation.y = Math.PI / 2;
        group.rotation.y += (unit.rotation || 0) * Math.PI / 180;
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
        group.rotation.y = -(c.rotation || 0) * Math.PI / 180;
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

    _buildStairs(stairs, w, l) {
      if (!stairs || !stairs.length) return;

      stairs.forEach((stair) => {
        try {
          const group = new THREE.Group();
          const fw = stair.width * FT;
          const totalH = stair.height * FT;
          const totalD = stair.depth * FT;
          const n = Math.max(2, Math.min(30, parseInt(stair.stepCount, 10) || 10));
          const rise = totalH / n;
          const tread = totalD / n;
          const tex = this._resolveTextureUrl(stair.textureDataUrl, stair.texturePath);
          const finish = this._stairFinishProps(stair.materialPreset);
          const treadMat = this._makeMaterial(
            stair.color,
            finish.rough,
            finish.metal,
            tex,
            finish.proc,
            1,
            1
          );
          const riserMat = this._cloneMaterial(treadMat);
          if (riserMat.color) riserMat.color.multiplyScalar(0.92);
          const railMat = new THREE.MeshStandardMaterial({
            color: 0xb0bec5,
            roughness: 0.18,
            metalness: 0.82,
            envMapIntensity: 1.2,
          });
          const glassRail = new THREE.MeshStandardMaterial({
            color: 0xdfe7ef,
            roughness: 0.08,
            metalness: 0.15,
            transparent: true,
            opacity: 0.55,
          });

          for (let i = 0; i < n; i++) {
            const yBase = i * rise;
            const zCenter = totalD / 2 - tread * (i + 0.5);

            const riser = new THREE.Mesh(
              new THREE.BoxGeometry(fw * 0.94, rise * 0.96, tread * 0.07),
              riserMat
            );
            riser.position.set(0, yBase + rise * 0.48, zCenter - tread * 0.46);
            group.add(riser);

            const treadMesh = new THREE.Mesh(
              new THREE.BoxGeometry(fw * 0.94, rise * 0.09, tread * 0.96),
              treadMat
            );
            treadMesh.position.set(0, yBase + rise - rise * 0.045, zCenter);
            group.add(treadMesh);

            const nosing = new THREE.Mesh(
              new THREE.BoxGeometry(fw * 0.94, rise * 0.045, tread * 0.08),
              treadMat
            );
            nosing.position.set(0, yBase + rise - rise * 0.02, zCenter + tread * 0.44);
            group.add(nosing);
          }

          [-1, 1].forEach((side) => {
            const stringer = new THREE.Mesh(
              new THREE.BoxGeometry(0.07, totalH * 1.02, Math.sqrt(totalH * totalH + totalD * totalD)),
              treadMat
            );
            stringer.rotation.x = -Math.atan2(totalH, totalD);
            stringer.position.set(side * fw * 0.47, totalH / 2, 0);
            group.add(stringer);
          });

          const buildRail = (side, useGlass) => {
            const railX = side * fw * 0.44;
            const mat = useGlass ? glassRail : railMat;
            for (let i = 0; i <= n; i++) {
              const postH = 0.75 + (i / n) * 0.35;
              const post = new THREE.Mesh(
                new THREE.CylinderGeometry(0.022, 0.026, postH, 10),
                mat
              );
              post.position.set(
                railX,
                i * rise + postH / 2,
                totalD / 2 - tread * i
              );
              group.add(post);
            }
            const railLen = Math.sqrt(totalH * totalH + totalD * totalD) * 1.02;
            const handrail = new THREE.Mesh(
              new THREE.CylinderGeometry(0.032, 0.032, railLen, 12),
              mat
            );
            handrail.rotation.x = Math.atan2(totalH, totalD);
            handrail.position.set(railX, totalH / 2 + 0.78, 0);
            group.add(handrail);

            for (let i = 0; i < n; i++) {
              const bal = new THREE.Mesh(
                new THREE.CylinderGeometry(0.012, 0.012, 0.42 + (i / n) * 0.12, 8),
                mat
              );
              bal.position.set(
                railX,
                i * rise + 0.55,
                totalD / 2 - tread * (i + 0.5)
              );
              group.add(bal);
            }
          };

          if (stair.showLeftRailing !== false) buildRail(-1, false);
          if (stair.showRightRailing !== false) buildRail(1, stair.materialPreset === 'glass');

          const x = (stair.blueprintX - 0.5) * w;
          const z = (stair.blueprintY - 0.5) * l;
          group.position.set(x, 0, z);
          group.rotation.y = -(stair.rotation || 0) * Math.PI / 180;
          group.traverse((c) => {
            if (c.isMesh) {
              c.castShadow = true;
              c.receiveShadow = true;
            }
          });
          this.roomGroup.add(group);
        } catch (err) {
          console.error('Stair build failed:', stair.id, err);
        }
      });
    }

    _stairFinishProps(preset) {
      switch (preset) {
        case 'marble':
          return { rough: 0.16, metal: 0.08, proc: null };
        case 'carpet':
          return { rough: 0.94, metal: 0.0, proc: 'fabric' };
        case 'metallic':
          return { rough: 0.2, metal: 0.78, proc: null };
        case 'glossy':
          return { rough: 0.12, metal: 0.32, proc: null };
        default:
          return { rough: 0.62, metal: 0.04, proc: 'wood' };
      }
    }

    _buildFurniture(furniture, w, l) {
      furniture.forEach((item) => {
        try {
        const tex = this._resolveTextureUrl(item.textureDataUrl, item.texturePath);
        let group;

        if (item.premiumCatalogId && typeof PremiumCatalogBuilder !== 'undefined') {
          group = PremiumCatalogBuilder.build(this, item, tex);
          if (!group) {
            console.warn('Premium catalog build returned null:', item.premiumCatalogId);
          }
        }

        if (!group) switch (item.type) {
          case 'bed':
            group = this._buildBedGroup(item, tex);
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
            group = this._buildTableGroup(item, tex);
            break;
          case 'chair':
            group = this._buildChairGroup(item, tex);
            break;
          case 'tvUnit':
            group = this._buildTvUnitGroup(item, tex);
            break;
          case 'sink':
            group = this._buildSinkGroup(item, tex);
            break;
          case 'toilet':
            group = this._buildToiletGroup(item, tex);
            break;
          case 'washingMachine':
            group = this._buildWashingMachineGroup(item, tex);
            break;
          case 'bathtub':
            group = this._buildBathtubGroup(item, tex);
            break;
          case 'flowerPot':
            group = this._buildFlowerPotGroup(item, tex);
            break;
          case 'fridge':
            group = this._buildFridgeGroup(item, tex);
            break;
          case 'shoeRack':
            group = this._buildShoeRackGroup(item, tex);
            break;
          case 'diningTable':
            group = this._buildDiningTableGroup(item);
            break;
          case 'storageUnit':
            group = this._buildStorageUnitGroup(item);
            break;
          case 'kitchenChimney':
            group = this._buildKitchenChimneyGroup(item);
            break;
          case 'car':
            group = this._buildCarGroup(item, tex);
            break;
          default:
            group = this._buildGenericFurniture(item);
        }

        const x = (item.blueprintX - 0.5) * w;
        const z = (item.blueprintY - 0.5) * l;
        const y = (item.heightFromFloor || 0) * FT;
        group.position.set(x, y, z);
        group.rotation.y = -(item.rotation || 0) * Math.PI / 180;
        if (
          this._isPremiumFurniture()
          && !this._hasDedicatedPremiumBuilder(item.type)
          && !this._usesIdenticalPremiumGeometry(item.type)
        ) {
          this._applyPremiumFurnitureFinish(group);
        }
        this.roomGroup.add(group);
        } catch (err) {
          console.error('Furniture build failed:', item.type, item.id, err);
        }
      });
    }

    _buildBedGroup(item, textureUrl) {
      if (this._isPremiumFurniture()) {
        return PremiumBedBuilder.build(this, item, textureUrl);
      }
      return this._buildStandardBedGroup(item, textureUrl);
    }

    _buildCarGroup(item, textureUrl) {
      if (this._isPremiumFurniture()) {
        if (typeof PremiumSedanCarBuilder !== 'undefined') {
          return PremiumSedanCarBuilder.build(this, item, textureUrl);
        }
        if (typeof PremiumCatalogBuilder !== 'undefined') {
          return PremiumCatalogBuilder.build(this, item, textureUrl);
        }
      }
      const fw = item.width * FT;
      const fd = item.depth * FT;
      const fh = item.height * FT;
      const group = new THREE.Group();
      const body = new THREE.Mesh(
        new THREE.BoxGeometry(fw, fh * 0.45, fd),
        this._makeMaterial(item.color, 0.35, 0.2, textureUrl, null, 1, 1)
      );
      body.position.y = fh * 0.22;
      group.add(body);
      return group;
    }

    _buildStandardBedGroup(item, textureUrl) {
      const fw = item.width * FT;
      const fd = item.depth * FT;
      const group = new THREE.Group();
      const frameH = 0.35 * FT;
      const mattressH = 0.45 * FT;
      const frameMat = this._makeMaterial(item.color, 0.75, 0.05, textureUrl, textureUrl ? null : 'wood', 1, 1);
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

    _buildSinkGroup(item, textureUrl) {
      if (this._isPremiumFurniture()) {
        return PremiumSinkBuilder.build(this, item, textureUrl);
      }
      return this._buildStandardSinkGroup(item, textureUrl);
    }

    _buildStandardSinkGroup(item, textureUrl) {
      const fw = item.width * FT;
      const fd = item.depth * FT;
      const counterH = 0.9 * FT;
      const group = new THREE.Group();
      const cabinetMat = this._makeMaterial(item.color, 0.55, 0.05, textureUrl, textureUrl ? null : 'wood', 1, 1);
      const counterMat = new THREE.MeshStandardMaterial({
        color: 0xECEFF1,
        roughness: 0.18,
        metalness: 0.08,
      });
      const basinMat = new THREE.MeshStandardMaterial({
        color: 0xFFFFFF,
        roughness: 0.08,
        metalness: 0.04,
      });
      const chrome = new THREE.MeshStandardMaterial({
        color: 0xCFD8DC,
        roughness: 0.15,
        metalness: 0.92,
      });

      const cabinetH = 2.4 * FT;
      const cabinet = new THREE.Mesh(new THREE.BoxGeometry(fw, cabinetH, fd), cabinetMat);
      cabinet.position.y = cabinetH / 2;
      group.add(cabinet);

      const counter = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 1.02, counterH, fd * 1.04),
        counterMat
      );
      counter.position.y = cabinetH + counterH / 2;
      group.add(counter);

      const basinOuter = new THREE.Mesh(
        new THREE.CylinderGeometry(fw * 0.28, fw * 0.22, 0.28 * FT, 32),
        basinMat
      );
      basinOuter.position.set(0, cabinetH + counterH * 0.55, fd * 0.05);
      group.add(basinOuter);

      const basinInner = new THREE.Mesh(
        new THREE.CylinderGeometry(fw * 0.22, fw * 0.18, 0.22 * FT, 32),
        new THREE.MeshStandardMaterial({ color: 0xE3F2FD, roughness: 0.05, metalness: 0.1 })
      );
      basinInner.position.set(0, cabinetH + counterH * 0.62, fd * 0.05);
      group.add(basinInner);

      const drain = new THREE.Mesh(
        new THREE.CylinderGeometry(0.02, 0.02, 0.015, 12),
        chrome
      );
      drain.position.set(0, cabinetH + counterH * 0.48, fd * 0.05);
      group.add(drain);

      const faucetStem = new THREE.Mesh(
        new THREE.CylinderGeometry(0.018, 0.022, 0.32 * FT, 12),
        chrome
      );
      faucetStem.position.set(0, cabinetH + counterH + 0.14 * FT, -fd * 0.32);
      group.add(faucetStem);

      const spout = new THREE.Mesh(
        new THREE.BoxGeometry(0.035, 0.035, fd * 0.28),
        chrome
      );
      spout.position.set(0, cabinetH + counterH + 0.26 * FT, -fd * 0.18);
      group.add(spout);

      [-1, 1].forEach((side) => {
        const handle = new THREE.Mesh(
          new THREE.CylinderGeometry(0.012, 0.012, 0.08 * FT, 8),
          chrome
        );
        handle.position.set(side * fw * 0.14, cabinetH + counterH + 0.1 * FT, -fd * 0.34);
        group.add(handle);
      });

      const backsplash = new THREE.Mesh(
        new THREE.BoxGeometry(fw, 0.45 * FT, 0.04),
        counterMat
      );
      backsplash.position.set(0, cabinetH + counterH + 0.18 * FT, -fd / 2 + 0.02);
      group.add(backsplash);

      group.traverse((c) => { if (c.isMesh) { c.castShadow = true; c.receiveShadow = true; } });
      return group;
    }

    _buildToiletGroup(item, textureUrl) {
      const fw = item.width * FT;
      const fd = item.depth * FT;
      const group = new THREE.Group();
      const porcelain = this._makeMaterial(item.color, 0.1, 0.02, textureUrl, textureUrl ? null : null, 1, 1);
      const seatMat = new THREE.MeshStandardMaterial({
        color: 0xF5F5F5,
        roughness: 0.45,
        metalness: 0.01,
      });

      const tank = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.58, 0.55 * FT, fd * 0.2),
        porcelain
      );
      tank.position.set(0, 0.72 * FT, -fd * 0.36);
      group.add(tank);

      const tankLid = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.54, 0.04, fd * 0.16),
        porcelain
      );
      tankLid.position.set(0, 1.0 * FT, -fd * 0.36);
      group.add(tankLid);

      const bowl = new THREE.Mesh(
        new THREE.SphereGeometry(fw * 0.36, 32, 20, 0, Math.PI * 2, 0, Math.PI * 0.55),
        porcelain
      );
      bowl.scale.set(1.05, 0.55, 1.35);
      bowl.position.set(0, 0.18 * FT, fd * 0.08);
      group.add(bowl);

      const bowlBase = new THREE.Mesh(
        new THREE.CylinderGeometry(fw * 0.2, fw * 0.24, 0.16 * FT, 24),
        porcelain
      );
      bowlBase.position.set(0, 0.08 * FT, fd * 0.06);
      group.add(bowlBase);

      const rim = new THREE.Mesh(
        new THREE.TorusGeometry(fw * 0.31, 0.022, 10, 36),
        porcelain
      );
      rim.rotation.x = Math.PI / 2;
      rim.scale.set(1, 1.25, 1);
      rim.position.set(0, 0.36 * FT, fd * 0.06);
      group.add(rim);

      const seat = new THREE.Mesh(
        new THREE.TorusGeometry(fw * 0.27, 0.038, 10, 36),
        seatMat
      );
      seat.rotation.x = Math.PI / 2;
      seat.scale.set(1, 1.22, 1);
      seat.position.set(0, 0.41 * FT, fd * 0.04);
      group.add(seat);

      const seatInner = new THREE.Mesh(
        new THREE.CylinderGeometry(fw * 0.2, fw * 0.18, 0.04, 24),
        new THREE.MeshStandardMaterial({ color: 0xFFFFFF, roughness: 0.12 })
      );
      seatInner.position.set(0, 0.39 * FT, fd * 0.04);
      group.add(seatInner);

      const lid = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.54, 0.035, fd * 0.36),
        seatMat
      );
      lid.position.set(0, 0.52 * FT, -fd * 0.06);
      group.add(lid);

      group.traverse((c) => { if (c.isMesh) { c.castShadow = true; c.receiveShadow = true; } });
      return group;
    }

    _buildWashingMachineGroup(item, textureUrl) {
      if (this._isPremiumFurniture()) {
        return PremiumWashingMachineBuilder.build(this, item, textureUrl);
      }
      return this._buildStandardWashingMachineGroup(item, textureUrl);
    }

    _buildStandardWashingMachineGroup(item, textureUrl) {
      const fw = item.width * FT;
      const fd = item.depth * FT;
      const fh = item.height * FT;
      const group = new THREE.Group();

      const bodyMat = this._makeMaterial(item.color, 0.35, 0.12, textureUrl, textureUrl ? null : null, 1, 1);
      const darkMat = new THREE.MeshStandardMaterial({
        color: 0x37474F,
        roughness: 0.4,
        metalness: 0.25,
      });
      const chromeMat = new THREE.MeshStandardMaterial({
        color: 0xB0BEC5,
        roughness: 0.18,
        metalness: 0.88,
      });
      const glassMat = new THREE.MeshStandardMaterial({
        color: 0x263238,
        roughness: 0.05,
        metalness: 0.35,
        transparent: true,
        opacity: 0.72,
      });
      const drumMat = new THREE.MeshStandardMaterial({
        color: 0x90A4AE,
        roughness: 0.25,
        metalness: 0.65,
      });

      const plinthH = 0.08 * FT;
      const bodyH = fh - plinthH;
      const plinth = new THREE.Mesh(new THREE.BoxGeometry(fw, plinthH, fd), darkMat);
      plinth.position.y = plinthH / 2;
      group.add(plinth);

      const body = new THREE.Mesh(new THREE.BoxGeometry(fw * 0.96, bodyH * 0.96, fd * 0.96), bodyMat);
      body.position.y = plinthH + bodyH * 0.48;
      group.add(body);

      const frontFaceZ = fd * 0.48;
      const topPanelDepth = fd * 0.025;
      const topPanel = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.94, bodyH * 0.14, topPanelDepth),
        darkMat
      );
      topPanel.position.set(0, plinthH + bodyH * 0.91, frontFaceZ + topPanelDepth * 0.5 + 0.002 * FT);
      group.add(topPanel);

      const drawerDepth = fd * 0.05;
      const drawer = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.22, bodyH * 0.05, drawerDepth),
        bodyMat
      );
      drawer.position.set(-fw * 0.28, plinthH + bodyH * 0.84, frontFaceZ + drawerDepth * 0.5 + 0.002 * FT);
      group.add(drawer);

      const dial = new THREE.Mesh(
        new THREE.CylinderGeometry(fw * 0.055, fw * 0.055, 0.025, 20),
        chromeMat
      );
      dial.rotation.x = Math.PI / 2;
      dial.position.set(fw * 0.28, plinthH + bodyH * 0.84, frontFaceZ + 0.015 * FT);
      group.add(dial);

      const doorRadius = Math.min(fw, bodyH) * 0.31;
      const doorY = plinthH + bodyH * 0.42;
      const doorZ = fd * 0.47;

      const doorRing = new THREE.Mesh(
        new THREE.TorusGeometry(doorRadius, fw * 0.035, 12, 40),
        chromeMat
      );
      doorRing.position.set(0, doorY, doorZ);
      group.add(doorRing);

      const doorGlass = new THREE.Mesh(
        new THREE.CircleGeometry(doorRadius * 0.88, 40),
        glassMat
      );
      doorGlass.position.set(0, doorY, doorZ + 0.008);
      group.add(doorGlass);

      const drum = new THREE.Mesh(
        new THREE.CylinderGeometry(doorRadius * 0.62, doorRadius * 0.62, fw * 0.28, 28, 1, true),
        drumMat
      );
      drum.rotation.z = Math.PI / 2;
      drum.position.set(0, doorY, doorZ - fw * 0.12);
      group.add(drum);

      for (let i = 0; i < 6; i++) {
        const paddle = new THREE.Mesh(
          new THREE.BoxGeometry(doorRadius * 0.12, doorRadius * 0.06, fw * 0.22),
          drumMat
        );
        const angle = (i / 6) * Math.PI * 2;
        paddle.position.set(
          Math.cos(angle) * doorRadius * 0.45,
          doorY + Math.sin(angle) * doorRadius * 0.45,
          doorZ - fw * 0.12
        );
        paddle.rotation.z = angle;
        group.add(paddle);
      }

      const handle = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.14, fw * 0.025, fd * 0.025),
        chromeMat
      );
      handle.position.set(doorRadius * 0.55, doorY, doorZ + 0.02);
      group.add(handle);

      group.traverse((c) => { if (c.isMesh) { c.castShadow = true; c.receiveShadow = true; } });
      return group;
    }

    _buildBathtubGroup(item, textureUrl) {
      const fw = item.width * FT;
      const fd = item.depth * FT;
      const rimH = item.height * FT;
      const group = new THREE.Group();

      const porcelain = this._makeMaterial(item.color, 0.12, 0.03, textureUrl, textureUrl ? null : null, 1, 1);
      const innerMat = new THREE.MeshStandardMaterial({
        color: 0xF5F5F5,
        roughness: 0.08,
        metalness: 0.04,
      });
      const waterMat = new THREE.MeshStandardMaterial({
        color: 0x81D4FA,
        roughness: 0.05,
        metalness: 0.08,
        transparent: true,
        opacity: 0.55,
      });
      const chrome = new THREE.MeshStandardMaterial({
        color: 0xCFD8DC,
        roughness: 0.15,
        metalness: 0.92,
      });

      const tubDepth = rimH * 0.72;
      const wallT = fw * 0.08;

      const outerShell = new THREE.Mesh(
        new THREE.BoxGeometry(fw, tubDepth, fd),
        porcelain
      );
      outerShell.position.y = tubDepth / 2;
      group.add(outerShell);

      const innerCavity = new THREE.Mesh(
        new THREE.BoxGeometry(fw - wallT * 2, tubDepth * 0.82, fd - wallT * 2),
        innerMat
      );
      innerCavity.position.y = tubDepth * 0.52;
      group.add(innerCavity);

      const floorCurve = new THREE.Mesh(
        new THREE.CylinderGeometry(fw * 0.38, fw * 0.38, fd - wallT * 2.4, 32, 1, false, 0, Math.PI),
        innerMat
      );
      floorCurve.rotation.z = Math.PI / 2;
      floorCurve.rotation.y = Math.PI / 2;
      floorCurve.position.y = tubDepth * 0.22;
      group.add(floorCurve);

      const water = new THREE.Mesh(
        new THREE.BoxGeometry(fw - wallT * 2.6, 0.04, fd - wallT * 2.6),
        waterMat
      );
      water.position.y = tubDepth * 0.58;
      group.add(water);

      const rimThickness = fw * 0.06;
      const rimDefs = [
        { sx: fw, sy: rimThickness, sz: fd, px: 0, py: tubDepth + rimThickness / 2, pz: 0 },
        { sx: fw - wallT, sy: rimThickness * 0.85, sz: rimThickness, px: 0, py: tubDepth + rimThickness / 2, pz: fd / 2 - rimThickness / 2 },
        { sx: fw - wallT, sy: rimThickness * 0.85, sz: rimThickness, px: 0, py: tubDepth + rimThickness / 2, pz: -fd / 2 + rimThickness / 2 },
        { sx: rimThickness, sy: rimThickness * 0.85, sz: fd - wallT, px: fw / 2 - rimThickness / 2, py: tubDepth + rimThickness / 2, pz: 0 },
        { sx: rimThickness, sy: rimThickness * 0.85, sz: fd - wallT, px: -fw / 2 + rimThickness / 2, py: tubDepth + rimThickness / 2, pz: 0 },
      ];
      rimDefs.forEach(({ sx, sy, sz, px, py, pz }) => {
        const rim = new THREE.Mesh(new THREE.BoxGeometry(sx, sy, sz), porcelain);
        rim.position.set(px, py, pz);
        group.add(rim);
      });

      const faucetZ = -fd / 2 + fd * 0.12;
      const faucetBase = new THREE.Mesh(
        new THREE.CylinderGeometry(fw * 0.045, fw * 0.05, rimH * 0.55, 12),
        chrome
      );
      faucetBase.position.set(0, tubDepth + rimH * 0.22, faucetZ);
      group.add(faucetBase);

      const spout = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.04, fw * 0.035, fd * 0.14),
        chrome
      );
      spout.position.set(0, tubDepth + rimH * 0.38, faucetZ + fd * 0.05);
      group.add(spout);

      const showerHead = new THREE.Mesh(
        new THREE.CylinderGeometry(fw * 0.07, fw * 0.07, 0.025, 16),
        chrome
      );
      showerHead.rotation.x = Math.PI / 2;
      showerHead.position.set(0, tubDepth + rimH * 0.48, faucetZ + fd * 0.12);
      group.add(showerHead);

      const showerPipe = new THREE.Mesh(
        new THREE.CylinderGeometry(fw * 0.018, fw * 0.018, rimH * 0.45, 8),
        chrome
      );
      showerPipe.position.set(0, tubDepth + rimH * 0.62, faucetZ + fd * 0.1);
      group.add(showerPipe);

      [-1, 1].forEach((side) => {
        const handle = new THREE.Mesh(
          new THREE.CylinderGeometry(fw * 0.022, fw * 0.022, rimH * 0.08, 10),
          chrome
        );
        handle.rotation.z = Math.PI / 2;
        handle.position.set(side * fw * 0.14, tubDepth + rimH * 0.28, faucetZ);
        group.add(handle);
      });

      const feetY = 0.05;
      [[-1, -1], [-1, 1], [1, -1], [1, 1]].forEach(([sx, sz]) => {
        const foot = new THREE.Mesh(
          new THREE.CylinderGeometry(fw * 0.045, fw * 0.05, feetY, 10),
          chrome
        );
        foot.position.set(sx * fw * 0.38, feetY / 2, sz * fd * 0.42);
        group.add(foot);
      });

      group.traverse((c) => { if (c.isMesh) { c.castShadow = true; c.receiveShadow = true; } });
      return group;
    }

    _buildFlowerPotGroup(item, textureUrl) {
      if (this._isPremiumFurniture()) {
        return PremiumFlowerPotBuilder.build(this, item, textureUrl);
      }
      return this._buildStandardFlowerPotGroup(item, textureUrl);
    }

    _buildStandardFlowerPotGroup(item, textureUrl) {
      const fw = item.width * FT;
      const fh = item.height * FT;
      const fd = item.depth * FT;
      const radius = Math.min(fw, fd) * 0.42;
      const group = new THREE.Group();

      const potMat = this._makeMaterial(item.color, 0.82, 0.04, textureUrl, textureUrl ? null : null, 1, 1);
      const soilMat = new THREE.MeshStandardMaterial({
        color: 0x4E342E,
        roughness: 0.95,
        metalness: 0.01,
      });
      const stemMat = new THREE.MeshStandardMaterial({
        color: 0x388E3C,
        roughness: 0.75,
        metalness: 0.02,
      });
      const leafMat = new THREE.MeshStandardMaterial({
        color: 0x43A047,
        roughness: 0.7,
        metalness: 0.02,
        side: THREE.DoubleSide,
      });
      const flowerColors = [0xE91E63, 0xFFEB3B, 0xFF7043, 0xAB47BC];

      const saucerH = fh * 0.04;
      const saucer = new THREE.Mesh(
        new THREE.CylinderGeometry(radius * 1.08, radius * 1.02, saucerH, 24),
        potMat
      );
      saucer.position.y = saucerH / 2;
      group.add(saucer);

      const potH = fh * 0.55;
      const pot = new THREE.Mesh(
        new THREE.CylinderGeometry(radius * 0.95, radius * 0.72, potH, 28),
        potMat
      );
      pot.position.y = saucerH + potH / 2;
      group.add(pot);

      const rim = new THREE.Mesh(
        new THREE.TorusGeometry(radius * 0.95, radius * 0.06, 10, 28),
        potMat
      );
      rim.rotation.x = Math.PI / 2;
      rim.position.y = saucerH + potH - radius * 0.02;
      group.add(rim);

      const soilY = saucerH + potH - fh * 0.04;
      const soil = new THREE.Mesh(
        new THREE.CylinderGeometry(radius * 0.82, radius * 0.82, fh * 0.06, 24),
        soilMat
      );
      soil.position.y = soilY;
      group.add(soil);

      const plantBase = saucerH + potH;
      const stemSpecs = [
        { x: 0, z: 0, h: fh * 0.38, leanX: 0, leanZ: 0 },
        { x: radius * 0.22, z: radius * 0.08, h: fh * 0.3, leanX: 0.12, leanZ: 0.05 },
        { x: -radius * 0.18, z: radius * 0.15, h: fh * 0.28, leanX: -0.1, leanZ: 0.08 },
        { x: radius * 0.05, z: -radius * 0.2, h: fh * 0.32, leanX: 0.04, leanZ: -0.11 },
      ];

      stemSpecs.forEach((spec, i) => {
        const stem = new THREE.Mesh(
          new THREE.CylinderGeometry(radius * 0.035, radius * 0.05, spec.h, 8),
          stemMat
        );
        stem.position.set(spec.x, plantBase + spec.h / 2, spec.z);
        stem.rotation.x = spec.leanX;
        stem.rotation.z = spec.leanZ;
        group.add(stem);

        const tipY = plantBase + spec.h;
        const tipX = spec.x + Math.sin(spec.leanZ) * spec.h * 0.15;
        const tipZ = spec.z + Math.sin(spec.leanX) * spec.h * 0.15;

        const flowerMat = new THREE.MeshStandardMaterial({
          color: flowerColors[i % flowerColors.length],
          roughness: 0.55,
          metalness: 0.05,
        });
        const bloom = new THREE.Mesh(
          new THREE.SphereGeometry(radius * 0.16, 12, 12),
          flowerMat
        );
        bloom.position.set(tipX, tipY + radius * 0.1, tipZ);
        group.add(bloom);

        const center = new THREE.Mesh(
          new THREE.SphereGeometry(radius * 0.06, 8, 8),
          new THREE.MeshStandardMaterial({ color: 0xFFF176, roughness: 0.6 })
        );
        center.position.set(tipX, tipY + radius * 0.1, tipZ + radius * 0.02);
        group.add(center);

        [-1, 1].forEach((side) => {
          const leaf = new THREE.Mesh(
            new THREE.SphereGeometry(radius * 0.12, 8, 6),
            leafMat
          );
          leaf.scale.set(1.6, 0.35, 0.9);
          leaf.position.set(
            spec.x + side * radius * 0.14,
            plantBase + spec.h * 0.45,
            spec.z + side * radius * 0.06
          );
          leaf.rotation.y = side * 0.6;
          group.add(leaf);
        });
      });

      group.traverse((c) => { if (c.isMesh) { c.castShadow = true; c.receiveShadow = true; } });
      return group;
    }

    _buildFridgeGroup(item, textureUrl) {
      if (this._isPremiumFurniture()) {
        return PremiumFridgeBuilder.build(this, item, textureUrl);
      }
      return this._buildStandardFridgeGroup(item, textureUrl);
    }

    _buildStandardFridgeGroup(item, textureUrl) {
      const fw = item.width * FT;
      const fh = item.height * FT;
      const fd = item.depth * FT;
      const group = new THREE.Group();

      const bodyMat = this._makeMaterial(item.color, 0.28, 0.35, textureUrl, textureUrl ? null : null, 1, 1);
      const trimMat = new THREE.MeshStandardMaterial({
        color: new THREE.Color(hexColor(item.color)).multiplyScalar(0.88),
        roughness: 0.35,
        metalness: 0.45,
      });
      const handleMat = new THREE.MeshStandardMaterial({
        color: 0xB0BEC5,
        roughness: 0.2,
        metalness: 0.88,
      });
      const darkMat = new THREE.MeshStandardMaterial({
        color: 0x263238,
        roughness: 0.15,
        metalness: 0.5,
      });

      const footH = fh * 0.025;
      [[-1, -1], [-1, 1], [1, -1], [1, 1]].forEach(([sx, sz]) => {
        const foot = new THREE.Mesh(
          new THREE.BoxGeometry(fw * 0.08, footH, fd * 0.08),
          trimMat
        );
        foot.position.set(sx * fw * 0.42, footH / 2, sz * fd * 0.42);
        group.add(foot);
      });

      const bodyH = fh - footH;
      const body = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.96, bodyH * 0.96, fd * 0.96),
        bodyMat
      );
      body.position.y = footH + bodyH / 2;
      group.add(body);

      const doorInset = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.92, bodyH * 0.92, fd * 0.04),
        trimMat
      );
      doorInset.position.set(0, footH + bodyH / 2, fd * 0.47);
      group.add(doorInset);

      const freezerH = bodyH * 0.28;
      const freezerLine = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.94, fh * 0.012, fd * 0.05),
        darkMat
      );
      freezerLine.position.set(0, footH + bodyH - freezerH, fd * 0.475);
      group.add(freezerLine);

      const handleW = fw * 0.045;
      const handleD = fd * 0.035;
      const upperHandle = new THREE.Mesh(
        new THREE.BoxGeometry(handleW, bodyH * 0.22, handleD),
        handleMat
      );
      upperHandle.position.set(fw * 0.38, footH + bodyH * 0.72, fd * 0.5);
      group.add(upperHandle);

      const lowerHandle = new THREE.Mesh(
        new THREE.BoxGeometry(handleW, bodyH * 0.28, handleD),
        handleMat
      );
      lowerHandle.position.set(fw * 0.38, footH + bodyH * 0.38, fd * 0.5);
      group.add(lowerHandle);

      const dispenser = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.18, bodyH * 0.08, fd * 0.06),
        darkMat
      );
      dispenser.position.set(-fw * 0.28, footH + bodyH * 0.62, fd * 0.49);
      group.add(dispenser);

      const waterPad = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.12, bodyH * 0.04, fd * 0.02),
        new THREE.MeshStandardMaterial({ color: 0x455A64, roughness: 0.4, metalness: 0.3 })
      );
      waterPad.position.set(-fw * 0.28, footH + bodyH * 0.58, fd * 0.51);
      group.add(waterPad);

      const brandBar = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.2, bodyH * 0.025, fd * 0.01),
        handleMat
      );
      brandBar.position.set(0, footH + bodyH * 0.92, fd * 0.485);
      group.add(brandBar);

      group.traverse((c) => { if (c.isMesh) { c.castShadow = true; c.receiveShadow = true; } });
      return group;
    }

    _buildShoeRackGroup(item, textureUrl) {
      if (this._isPremiumFurniture()) {
        return PremiumShoeRackBuilder.build(this, item, textureUrl);
      }
      return this._buildStandardShoeRackGroup(item, textureUrl);
    }

    _buildStandardShoeRackGroup(item, textureUrl) {
      const fw = item.width * FT;
      const fh = item.height * FT;
      const fd = item.depth * FT;
      const group = new THREE.Group();

      const frameMat = this._makeMaterial(item.color, 0.62, 0.06, textureUrl, textureUrl ? null : 'wood', 1, 1);
      const shelfMat = this._makeMaterial(item.color, 0.58, 0.05, textureUrl, textureUrl ? null : 'wood', 1, 1);
      const shoeMat = new THREE.MeshStandardMaterial({ color: 0x5D4037, roughness: 0.82, metalness: 0.02 });
      const shoeMat2 = new THREE.MeshStandardMaterial({ color: 0x37474F, roughness: 0.78, metalness: 0.04 });

      const postW = Math.max(0.035 * FT, fw * 0.045);
      const legH = Math.max(0.06 * FT, fh * 0.07);
      const bodyH = fh - legH;
      const shelfTh = 0.022 * FT;
      const shelfCount = Math.max(3, Math.min(5, Math.round(bodyH / (0.55 * FT))));
      const tilt = 0.14;
      const innerW = fw - postW * 2.4;
      const innerD = fd - postW * 1.2;
      const frontZ = fd / 2 - postW * 0.35;

      const addPost = (x, z) => {
        const post = new THREE.Mesh(new THREE.BoxGeometry(postW, fh, postW), frameMat);
        post.position.set(x, fh / 2, z);
        group.add(post);
      };
      addPost(-fw / 2 + postW / 2, -fd / 2 + postW / 2);
      addPost(fw / 2 - postW / 2, -fd / 2 + postW / 2);
      addPost(-fw / 2 + postW / 2, fd / 2 - postW / 2);
      addPost(fw / 2 - postW / 2, fd / 2 - postW / 2);

      const topRail = new THREE.Mesh(new THREE.BoxGeometry(fw * 0.94, postW * 0.75, postW * 0.75), frameMat);
      topRail.position.y = fh - postW * 0.55;
      group.add(topRail);

      const back = new THREE.Mesh(new THREE.BoxGeometry(fw * 0.9, bodyH * 0.94, 0.018 * FT), frameMat);
      back.position.set(0, legH + bodyH / 2, -fd / 2 + 0.02 * FT);
      group.add(back);

      const addShelf = (y, tilted) => {
        const shelf = new THREE.Mesh(new THREE.BoxGeometry(innerW, shelfTh, innerD), shelfMat);
        shelf.position.set(0, y, 0);
        if (tilted) shelf.rotation.x = -tilt;
        group.add(shelf);

        const lip = new THREE.Mesh(new THREE.BoxGeometry(innerW, shelfTh * 0.85, 0.018 * FT), frameMat);
        const lipZ = tilted ? frontZ - innerD * 0.5 * Math.sin(tilt) : frontZ;
        const lipY = tilted ? y - innerD * 0.42 * Math.sin(tilt) : y + shelfTh * 0.5;
        lip.position.set(0, lipY, lipZ);
        group.add(lip);
      };

      for (let i = 0; i < shelfCount; i++) {
        const t = (i + 1) / (shelfCount + 1);
        const shelfY = legH + bodyH * t;
        addShelf(shelfY, i < shelfCount - 1);
      }

      const bottomShelf = new THREE.Mesh(new THREE.BoxGeometry(innerW, shelfTh, innerD * 0.96), shelfMat);
      bottomShelf.position.set(0, legH + shelfTh / 2, 0);
      group.add(bottomShelf);

      const shoeLayouts = [
        { x: -innerW * 0.28, z: innerD * 0.08, w: innerW * 0.22, d: innerD * 0.55, h: 0.07 * FT, mat: shoeMat },
        { x: innerW * 0.02, z: innerD * 0.12, w: innerW * 0.24, d: innerD * 0.5, h: 0.075 * FT, mat: shoeMat2 },
        { x: innerW * 0.3, z: innerD * 0.06, w: innerW * 0.2, d: innerD * 0.48, h: 0.065 * FT, mat: shoeMat },
      ];
      const midShelfY = legH + bodyH * 0.5;
      shoeLayouts.forEach((s) => {
        const shoe = new THREE.Mesh(new THREE.BoxGeometry(s.w, s.h, s.d), s.mat);
        shoe.position.set(s.x, midShelfY + shelfTh + s.h / 2, s.z - innerD * 0.08);
        shoe.rotation.x = -tilt * 0.35;
        group.add(shoe);
      });

      group.traverse((c) => { if (c.isMesh) { c.castShadow = true; c.receiveShadow = true; } });
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

    _createRoundedBox(width, height, depth, radius, material) {
      const shape = new THREE.Shape();
      const w = width;
      const h = height;
      const r = Math.min(radius, w * 0.25, h * 0.25);

      shape.moveTo(-w / 2 + r, -h / 2);
      shape.lineTo(w / 2 - r, -h / 2);
      shape.quadraticCurveTo(w / 2, -h / 2, w / 2, -h / 2 + r);
      shape.lineTo(w / 2, h / 2 - r);
      shape.quadraticCurveTo(w / 2, h / 2, w / 2 - r, h / 2);
      shape.lineTo(-w / 2 + r, h / 2);
      shape.quadraticCurveTo(-w / 2, h / 2, -w / 2, h / 2 - r);
      shape.lineTo(-w / 2, -h / 2 + r);
      shape.quadraticCurveTo(-w / 2, -h / 2, -w / 2 + r, -h / 2);

      const geometry = new THREE.ExtrudeGeometry(shape, {
        depth: depth,
        bevelEnabled: true,
        bevelSize: r * 0.4,
        bevelThickness: r * 0.45,
        bevelSegments: 8,
        curveSegments: 16,
      });

      geometry.center();
      return new THREE.Mesh(geometry, material);
    }

    _buildSofaGroup(item, textureUrl) {
      return this._buildStandardSofaGroup(item, textureUrl);
    }

    _buildStandardSofaGroup(item, textureUrl) {
      const fw = item.width * FT;
      const fh = item.height * FT;
      const fd = item.depth * FT;
      const group = new THREE.Group();

      const mat = this._cloneMaterial(this._makeMaterial(
        item.color,
        0.92,
        0.03,
        textureUrl,
        textureUrl ? null : 'fabric',
        3,
        3
      ));
      mat.roughness = 0.95;
      mat.metalness = 0.0;
      if (mat.bumpScale !== undefined) mat.bumpScale = 0.015;
      if (mat.normalScale) mat.normalScale.set(0.6, 0.6);

      const armWidth = fw * 0.15;
      const seatHeight = fh * 0.28;
      const cushionHeight = fh * 0.20;
      const backHeight = fh * 0.52;
      const radius = Math.min(fw, fd) * 0.045;

      const frame = this._createRoundedBox(
        fw - armWidth * 0.4,
        seatHeight,
        fd * 0.95,
        radius,
        mat
      );
      frame.position.y = seatHeight * 0.5;
      group.add(frame);

      const leftArm = this._createRoundedBox(armWidth, fh * 0.65, fd, radius, mat);
      leftArm.position.set(-fw / 2 + armWidth / 2, fh * 0.33, 0);
      group.add(leftArm);

      const rightArm = leftArm.clone();
      rightArm.position.x = fw / 2 - armWidth / 2;
      group.add(rightArm);

      const back = this._createRoundedBox(
        fw - armWidth * 1.4,
        backHeight,
        fd * 0.12,
        radius,
        mat
      );
      back.position.set(0, fh * 0.47, -fd * 0.42);
      group.add(back);

      const seatCount = 3;
      const innerW = fw - armWidth * 2.2;
      const seatWidth = innerW / seatCount;

      for (let i = 0; i < seatCount; i++) {
        const cx = -innerW / 2 + seatWidth * (i + 0.5);
        const cushion = this._createRoundedBox(
          seatWidth * 0.96,
          cushionHeight,
          fd * 0.90,
          radius * 1.2,
          mat
        );
        cushion.position.set(cx, seatHeight + cushionHeight * 0.45, 0);
        cushion.scale.y = 1.05;
        group.add(cushion);
      }

      for (let i = 0; i < seatCount; i++) {
        const cx = -innerW / 2 + seatWidth * (i + 0.5);
        const cushion = this._createRoundedBox(
          seatWidth * 0.91,
          fh * 0.33,
          fd * 0.14,
          radius * 1.4,
          mat
        );
        cushion.position.set(cx, fh * 0.56, -fd * 0.28);
        cushion.rotation.x = -0.06;
        group.add(cushion);
      }

      group.children.forEach((mesh) => {
        if (!mesh.geometry || !mesh.geometry.attributes.position) return;
        const pos = mesh.geometry.attributes.position;
        for (let i = 0; i < pos.count; i++) {
          const x = pos.getX(i);
          let y = pos.getY(i);
          const z = pos.getZ(i);
          y += Math.sin(x * 8) * 0.002;
          y += Math.cos(z * 8) * 0.002;
          pos.setXYZ(i, x, y, z);
        }
        pos.needsUpdate = true;
        mesh.geometry.computeVertexNormals();
      });

      group.traverse((obj) => {
        if (obj.isMesh) {
          obj.castShadow = true;
          obj.receiveShadow = true;
        }
      });

      return group;
    }

    _furniturePresetMaterial(item) {
      const preset = item.materialPreset || 'wood';
      const tex = this._resolveTextureUrl(item.textureDataUrl, item.texturePath);
      const color = item.color;
      switch (preset) {
        case 'whiteMatte':
          return { color: '#F5F5F5', roughness: 0.92, metalness: 0.02, procType: null, textureUrl: tex };
        case 'glossy':
          return { color, roughness: 0.12, metalness: 0.25, procType: null, textureUrl: tex };
        case 'metallic':
          return { color: color || '#78909C', roughness: 0.22, metalness: 0.88, procType: 'metal', textureUrl: tex };
        case 'stainlessSteel':
          return { color: '#B0BEC5', roughness: 0.18, metalness: 0.92, procType: 'metal', textureUrl: tex };
        case 'black':
          return { color: '#212121', roughness: 0.35, metalness: 0.55, procType: 'metal', textureUrl: tex };
        case 'white':
          return { color: '#FAFAFA', roughness: 0.28, metalness: 0.15, procType: null, textureUrl: tex };
        default:
          return { color, roughness: 0.62, metalness: 0.05, procType: 'wood', textureUrl: tex };
      }
    }

    _makePresetMaterial(item) {
      const p = this._furniturePresetMaterial(item);
      return this._makeMaterial(p.color, p.roughness, p.metalness, p.textureUrl, p.procType, 1, 1);
    }

    _buildDiningTableGroup(item) {
      if (this._isPremiumFurniture()) {
        return PremiumDiningTableBuilder.build(this, item);
      }
      return this._buildStandardDiningTableGroup(item);
    }

    _buildStandardDiningTableGroup(item) {
      const fw = item.width * FT;
      const fd = item.depth * FT;
      const tableH = item.height * FT;
      const isRound = item.variant === 'round';
      const tex = this._resolveTextureUrl(item.textureDataUrl, item.texturePath);
      const group = new THREE.Group();
      const topMat = this._makeMaterial(item.color, 0.52, 0.08, tex, 'wood', 1, 1);
      const legMat = this._makeMaterial(item.color, 0.58, 0.1, null, 'wood', 1, 1);
      const topThickness = 0.08 * FT;
      const legH = tableH - topThickness;

      if (isRound) {
        const radius = Math.max(fw, fd) / 2;
        const top = new THREE.Mesh(
          new THREE.CylinderGeometry(radius, radius, topThickness, 36),
          topMat
        );
        top.position.y = legH + topThickness / 2;
        group.add(top);

        const pedestal = new THREE.Mesh(
          new THREE.CylinderGeometry(radius * 0.14, radius * 0.2, legH, 20),
          legMat
        );
        pedestal.position.y = legH / 2;
        group.add(pedestal);
      } else {
        const top = new THREE.Mesh(new THREE.BoxGeometry(fw, topThickness, fd), topMat);
        top.position.y = legH + topThickness / 2;
        group.add(top);

        [[-1, -1], [-1, 1], [1, -1], [1, 1]].forEach(([sx, sz]) => {
          const leg = new THREE.Mesh(new THREE.BoxGeometry(0.07 * FT, legH, 0.07 * FT), legMat);
          leg.position.set(sx * fw * 0.4, legH / 2, sz * fd * 0.4);
          group.add(leg);
        });
      }

      group.traverse((c) => { if (c.isMesh) { c.castShadow = true; c.receiveShadow = true; } });
      return group;
    }

    _buildStorageUnitGroup(item) {
      if (this._isPremiumFurniture()) {
        return PremiumStorageUnitBuilder.build(this, item);
      }
      return this._buildStandardStorageUnitGroup(item);
    }

    _buildStandardStorageUnitGroup(item) {
      const fw = item.width * FT;
      const fh = item.height * FT;
      const fd = item.depth * FT;
      const style = item.variant || 'singleDoor';
      const group = new THREE.Group();
      const bodyMat = this._makePresetMaterial(item);
      const trimMat = new THREE.MeshStandardMaterial({ color: 0x37474F, roughness: 0.35, metalness: 0.75 });
      const shelfMat = new THREE.MeshStandardMaterial({ color: 0xD7CCC8, roughness: 0.85, metalness: 0.02 });
      const toeKickH = fh * 0.06;
      const bodyH = fh - toeKickH;

      const toeKick = new THREE.Mesh(new THREE.BoxGeometry(fw, toeKickH, fd * 0.98), trimMat);
      toeKick.position.y = toeKickH / 2;
      group.add(toeKick);

      const carcass = new THREE.Mesh(new THREE.BoxGeometry(fw * 0.98, bodyH, fd), bodyMat);
      carcass.position.y = toeKickH + bodyH / 2;
      group.add(carcass);

      const counterTop = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 1.02, 0.04 * FT, fd * 1.04),
        new THREE.MeshStandardMaterial({ color: 0xECEFF1, roughness: 0.25, metalness: 0.08 })
      );
      counterTop.position.y = fh + 0.02 * FT;
      group.add(counterTop);

      const addHandle = (x, y, z) => {
        const handle = new THREE.Mesh(new THREE.BoxGeometry(0.02 * FT, 0.1 * FT, 0.04 * FT), trimMat);
        handle.position.set(x, y, z);
        group.add(handle);
      };

      const frontZ = fd / 2 + 0.015 * FT;
      if (style === 'openShelf') {
        const openBack = new THREE.Mesh(
          new THREE.BoxGeometry(fw * 0.92, bodyH * 0.92, 0.03 * FT),
          bodyMat
        );
        openBack.position.set(0, toeKickH + bodyH / 2, -fd / 2 + 0.04 * FT);
        group.add(openBack);
        [0.33, 0.66].forEach((t) => {
          const shelf = new THREE.Mesh(
            new THREE.BoxGeometry(fw * 0.9, 0.025 * FT, fd * 0.85),
            shelfMat
          );
          shelf.position.set(0, toeKickH + bodyH * t, 0);
          group.add(shelf);
        });
        const sideL = new THREE.Mesh(new THREE.BoxGeometry(0.04 * FT, bodyH * 0.92, fd * 0.88), bodyMat);
        sideL.position.set(-fw / 2 + 0.03 * FT, toeKickH + bodyH / 2, 0);
        group.add(sideL);
        const sideR = sideL.clone();
        sideR.position.x = fw / 2 - 0.03 * FT;
        group.add(sideR);
      } else if (style === 'drawerUnit') {
        const drawerCount = 4;
        const drawerH = bodyH / drawerCount;
        for (let i = 0; i < drawerCount; i++) {
          const dy = toeKickH + drawerH * i + drawerH / 2;
          const drawer = new THREE.Mesh(
            new THREE.BoxGeometry(fw * 0.9, drawerH * 0.88, 0.03 * FT),
            bodyMat
          );
          drawer.position.set(0, dy, frontZ);
          group.add(drawer);
          const groove = new THREE.Mesh(
            new THREE.BoxGeometry(fw * 0.86, 0.008 * FT, 0.01 * FT),
            trimMat
          );
          groove.position.set(0, toeKickH + drawerH * (i + 1), frontZ + 0.01 * FT);
          group.add(groove);
          addHandle(fw * 0.32, dy, frontZ + 0.03 * FT);
        }
      } else if (style === 'doubleDoor') {
        [-1, 1].forEach((side) => {
          const door = new THREE.Mesh(
            new THREE.BoxGeometry(fw * 0.44, bodyH * 0.9, 0.03 * FT),
            bodyMat
          );
          door.position.set(side * fw * 0.22, toeKickH + bodyH / 2, frontZ);
          group.add(door);
          addHandle(side * fw * 0.08, toeKickH + bodyH * 0.52, frontZ + 0.03 * FT);
        });
      } else {
        const door = new THREE.Mesh(
          new THREE.BoxGeometry(fw * 0.88, bodyH * 0.9, 0.03 * FT),
          bodyMat
        );
        door.position.set(0, toeKickH + bodyH / 2, frontZ);
        group.add(door);
        addHandle(fw * 0.35, toeKickH + bodyH * 0.52, frontZ + 0.03 * FT);
      }

      group.traverse((c) => { if (c.isMesh) { c.castShadow = true; c.receiveShadow = true; } });
      return group;
    }

    _buildKitchenChimneyGroup(item) {
      if (this._isPremiumFurniture()) {
        return PremiumChimneyBuilder.build(this, item);
      }
      return this._buildStandardKitchenChimneyGroup(item);
    }

    _buildStandardKitchenChimneyGroup(item) {
      const fw = item.width * FT;
      const fh = item.height * FT;
      const fd = item.depth * FT;
      const style = item.variant || 'wallMounted';
      const group = new THREE.Group();
      const preset = this._furniturePresetMaterial(item);
      const bodyMat = this._makeMaterial(preset.color, preset.roughness, preset.metalness, preset.textureUrl, preset.procType, 1, 1);
      const glassMat = new THREE.MeshStandardMaterial({
        color: 0x90A4AE,
        roughness: 0.05,
        metalness: 0.1,
        transparent: true,
        opacity: 0.45,
      });
      const darkMat = new THREE.MeshStandardMaterial({ color: 0x263238, roughness: 0.4, metalness: 0.5 });
      const lightMat = new THREE.MeshStandardMaterial({
        color: 0xFFF8E1,
        emissive: 0xFFF8E1,
        emissiveIntensity: 0.55,
        roughness: 0.8,
      });

      const hoodH = fh * 0.55;
      const ductH = fh * 0.45;
      const hoodBottom = hoodH * 0.35;

      const hood = new THREE.Mesh(
        new THREE.CylinderGeometry(fw * 0.08, fw * 0.48, hoodH, 4, 1, false),
        bodyMat
      );
      hood.rotation.y = Math.PI / 4;
      hood.position.y = hoodBottom + hoodH / 2;
      group.add(hood);

      const hoodPanel = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.92, hoodH * 0.35, fd * 0.75),
        bodyMat
      );
      hoodPanel.position.set(0, hoodBottom + hoodH * 0.2, fd * 0.08);
      group.add(hoodPanel);

      if (style === 'glass') {
        const glassFront = new THREE.Mesh(
          new THREE.BoxGeometry(fw * 0.78, hoodH * 0.42, 0.02 * FT),
          glassMat
        );
        glassFront.position.set(0, hoodBottom + hoodH * 0.22, fd * 0.36);
        group.add(glassFront);
        [-1, 1].forEach((side) => {
          const glassSide = new THREE.Mesh(
            new THREE.BoxGeometry(0.02 * FT, hoodH * 0.42, fd * 0.55),
            glassMat
          );
          glassSide.position.set(side * fw * 0.38, hoodBottom + hoodH * 0.22, fd * 0.12);
          group.add(glassSide);
        });
      }

      const duct = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.32, ductH, fd * 0.28),
        bodyMat
      );
      duct.position.y = hoodBottom + hoodH + ductH / 2;
      group.add(duct);

      const controlStrip = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.55, 0.04 * FT, 0.03 * FT),
        darkMat
      );
      controlStrip.position.set(0, hoodBottom + hoodH * 0.08, fd * 0.38);
      group.add(controlStrip);

      const lightBar = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.7, 0.025 * FT, 0.02 * FT),
        lightMat
      );
      lightBar.position.set(0, hoodBottom + 0.04 * FT, fd * 0.32);
      group.add(lightBar);

      if (style === 'stainlessSteel') {
        group.traverse((c) => {
          if (c.isMesh && c.material !== glassMat && c.material !== lightMat && c.material !== darkMat) {
            c.material = bodyMat;
          }
        });
      }

      const filter = new THREE.Mesh(
        new THREE.BoxGeometry(fw * 0.6, 0.02 * FT, fd * 0.45),
        darkMat
      );
      filter.position.set(0, hoodBottom + 0.02 * FT, 0);
      group.add(filter);

      group.traverse((c) => { if (c.isMesh) { c.castShadow = true; c.receiveShadow = true; } });
      return group;
    }

    _buildTableGroup(item, textureUrl) {
      if (this._isPremiumFurniture()) {
        return PremiumTableBuilder.build(this, item, textureUrl);
      }
      return this._buildStandardTableGroup(item, textureUrl);
    }

    _buildStandardTableGroup(item, textureUrl) {
      const fw = item.width * FT;
      const fh = item.height * FT;
      const fd = item.depth * FT;
      const group = new THREE.Group();
      const mat = this._makeMaterial(item.color, 0.6, 0.1, textureUrl, textureUrl ? null : 'wood', 1, 1);

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

    _buildChairGroup(item, textureUrl) {
      if (this._isPremiumFurniture()) {
        return PremiumChairBuilder.build(this, item, textureUrl);
      }
      return this._buildStandardChairGroup(item, textureUrl);
    }

    _buildStandardChairGroup(item, textureUrl) {
      const cw = item.width * FT;
      const ch = item.height * FT;
      const cd = item.depth * FT;
      const group = new THREE.Group();
      const fabricMat = this._makeMaterial(item.color, 0.82, 0.04, textureUrl, textureUrl ? null : 'fabric', 1, 1);
      const frameMat = this._makeMaterial(item.color, 0.55, 0.12, textureUrl, textureUrl ? null : 'wood', 1, 1);

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

    _buildFans(fans, w, l, h, opts = {}) {
      const animate = opts.animate !== false;
      fans.forEach((fan) => {
        const x = (fan.positionX - 0.5) * w;
        const z = (fan.positionY - 0.5) * l;
        const mountY = Math.min(h, Math.max(h * 0.85, (fan.height || 0.95) * h));
        const fanColor = hexColor(fan.color);

        const group = new THREE.Group();
        group.position.set(x, mountY, z);

        const mountMat = new THREE.MeshStandardMaterial({
          color: fanColor,
          roughness: 0.45,
          metalness: 0.25,
        });
        const bladeMat = new THREE.MeshStandardMaterial({
          color: fanColor,
          roughness: 0.55,
          metalness: 0.08,
          side: THREE.DoubleSide,
        });
        const darkMat = new THREE.MeshStandardMaterial({
          color: 0x455A64,
          roughness: 0.5,
          metalness: 0.2,
        });

        const canopy = new THREE.Mesh(new THREE.CylinderGeometry(0.12, 0.14, 0.06, 16), mountMat);
        canopy.position.y = 0.03;
        group.add(canopy);

        const downrod = new THREE.Mesh(new THREE.CylinderGeometry(0.025, 0.025, 0.35, 8), darkMat);
        downrod.position.y = -0.14;
        group.add(downrod);

        const motor = new THREE.Mesh(new THREE.CylinderGeometry(0.14, 0.16, 0.12, 16), mountMat);
        motor.position.y = -0.35;
        group.add(motor);

        const rotor = new THREE.Group();
        rotor.position.y = -0.38;

        const hub = new THREE.Mesh(new THREE.CylinderGeometry(0.05, 0.05, 0.04, 12), darkMat);
        rotor.add(hub);

        const bladeLen = 0.55;
        const bladeW = 0.14;
        for (let i = 0; i < 3; i++) {
          const bladeGroup = new THREE.Group();
          bladeGroup.rotation.y = (i * Math.PI * 2) / 3;
          const blade = new THREE.Mesh(
            new THREE.BoxGeometry(bladeLen, 0.02, bladeW),
            bladeMat
          );
          blade.position.x = bladeLen * 0.48;
          bladeGroup.add(blade);
          rotor.add(bladeGroup);
        }

        group.add(rotor);
        group.traverse((obj) => {
          if (obj.isMesh) obj.castShadow = false;
        });
        if (animate) this.fanRotors.push(rotor);
        this.roomGroup.add(group);
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

      if (this.fanRotors && this.fanRotors.length) {
        this.fanRotors.forEach((rotor) => {
          rotor.rotation.y += delta * 2.4;
        });
      }

      this.controls.update();
      if (!this.isApartmentMode) this._updateWallVisibility();
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

  window.captureExportViews = function () {
    if (window.roomRenderer) return window.roomRenderer.captureExportViews();
    return null;
  };

  initRenderer();
})();
