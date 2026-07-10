/* global THREE */
(function (global) {
  'use strict';

  const FT = 0.3048;
  const DEFAULT_EYE_HEIGHT_FT = 5;
  const DEFAULT_WALK_SPEED_FT = 6;
  const DEFAULT_RUN_SPEED_FT = 12;
  const WALL_CLEARANCE = 0.3 * FT;
  const PLAYER_RADIUS = 0.25 * FT;
  const FOV_DEFAULT = 60;
  const FOV_MIN = 40;
  const FOV_MAX = 75;
  const PITCH_MIN = THREE.MathUtils.degToRad(-70);
  const PITCH_MAX = THREE.MathUtils.degToRad(70);
  const ACCEL_TIME = 0.06;
  const MAX_DELTA = 1 / 45;
  const FOV_RESET_MS = 400;
  const MODE_TRANSITION_MS = 600;

  function easeInOutCubic(t) {
    return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
  }

  function clamp(v, min, max) {
    return Math.max(min, Math.min(max, v));
  }

  function rotatePoint(x, z, rotY) {
    const c = Math.cos(rotY);
    const s = Math.sin(rotY);
    return { x: x * c - z * s, z: x * s + z * c };
  }

  function resolveRoomLayout(roomCfg) {
    const room = roomCfg.room || {};
    const h = (room.height || 10) * FT;
    const wallLengths = room.wallLengths || {};
    const w = (room.effectiveWidth ?? room.width ?? 12) * FT;
    const l = (room.effectiveLength ?? room.length ?? 12) * FT;
    return { w, l, h, wallLengths };
  }

  function doorCenterOnWall(door, wall, layout) {
    const dw = door.width * FT;
    const w = layout.w;
    const l = layout.l;
    const offset = door.positionFromEdge * FT + dw / 2;
    switch (wall) {
      case 'front':
        return { axis: 'x', center: -w / 2 + offset, fixed: -l / 2, span: dw };
      case 'back':
        return { axis: 'x', center: -w / 2 + offset, fixed: l / 2, span: dw };
      case 'left':
        return { axis: 'z', center: -l / 2 + offset, fixed: -w / 2, span: dw };
      case 'right':
        return { axis: 'z', center: -l / 2 + offset, fixed: w / 2, span: dw };
      default:
        return null;
    }
  }

  function buildWallSegments(layout, doors) {
    const { w, l } = layout;
    const inset = WALL_CLEARANCE;
    const segs = [];
    const doorList = doors || [];

    const addHorizontal = (wallId, z, x0, x1) => {
      const wallDoors = doorList.filter((d) => d.wall === wallId);
      const openings = wallDoors
        .map((d) => doorCenterOnWall(d, wallId, layout))
        .filter(Boolean)
        .map((o) => ({
          start: o.center - o.span / 2 + 0.05,
          end: o.center + o.span / 2 - 0.05,
        }))
        .sort((a, b) => a.start - b.start);

      let cursor = x0;
      openings.forEach((gap) => {
        if (gap.start > cursor + 0.08) {
          segs.push({ axis: 'x', fixed: z, start: cursor, end: gap.start, thickness: inset });
        }
        cursor = Math.max(cursor, gap.end);
      });
      if (x1 > cursor + 0.08) {
        segs.push({ axis: 'x', fixed: z, start: cursor, end: x1, thickness: inset });
      }
    };

    const addVertical = (wallId, x, z0, z1) => {
      const wallDoors = doorList.filter((d) => d.wall === wallId);
      const openings = wallDoors
        .map((d) => doorCenterOnWall(d, wallId, layout))
        .filter(Boolean)
        .map((o) => ({
          start: o.center - o.span / 2 + 0.05,
          end: o.center + o.span / 2 - 0.05,
        }))
        .sort((a, b) => a.start - b.start);

      let cursor = z0;
      openings.forEach((gap) => {
        if (gap.start > cursor + 0.08) {
          segs.push({ axis: 'z', fixed: x, start: cursor, end: gap.start, thickness: inset });
        }
        cursor = Math.max(cursor, gap.end);
      });
      if (z1 > cursor + 0.08) {
        segs.push({ axis: 'z', fixed: x, start: cursor, end: z1, thickness: inset });
      }
    };

    addHorizontal('front', -l / 2, -w / 2, w / 2);
    addHorizontal('back', l / 2, -w / 2, w / 2);
    addVertical('left', -w / 2, -l / 2, l / 2);
    addVertical('right', w / 2, -l / 2, l / 2);
    return segs;
  }

  function buildFurnitureObstacles(furniture, layout) {
    const obstacles = [];
    const { w, l } = layout;
    (furniture || []).forEach((item) => {
      const fw = (item.width || 1) * FT;
      const fd = (item.depth || 1) * FT;
      const x = (item.blueprintX - 0.5) * w;
      const z = (item.blueprintY - 0.5) * l;
      const rot = -(item.rotation || 0) * Math.PI / 180;
      obstacles.push({
        x,
        z,
        halfW: fw / 2 + PLAYER_RADIUS,
        halfD: fd / 2 + PLAYER_RADIUS,
        rotY: rot,
      });
    });
    return obstacles;
  }

  function buildStairObstacles(stairs, layout) {
    const obstacles = [];
    const { w, l } = layout;
    (stairs || []).forEach((stair) => {
      const sw = stair.width * FT;
      const sd = stair.depth * FT;
      const x = (stair.blueprintX - 0.5) * w;
      const z = (stair.blueprintY - 0.5) * l;
      const rot = -(stair.rotation || 0) * Math.PI / 180;
      obstacles.push({
        x,
        z,
        halfW: sw / 2 + PLAYER_RADIUS,
        halfD: sd / 2 + PLAYER_RADIUS,
        rotY: rot,
      });
    });
    return obstacles;
  }

  function buildCupboardObstacles(cupboards, layout) {
    const obstacles = [];
    const { w, l } = layout;
    (cupboards || []).forEach((c) => {
      const cw = c.width * FT;
      const cd = c.depth * FT;
      const x = ((c.blueprintX ?? 0.5) - 0.5) * w;
      const z = ((c.blueprintY ?? 0.5) - 0.5) * l;
      const rot = -(c.rotation || 0) * Math.PI / 180;
      obstacles.push({
        x,
        z,
        halfW: cw / 2 + PLAYER_RADIUS,
        halfD: cd / 2 + PLAYER_RADIUS,
        rotY: rot,
      });
    });
    return obstacles;
  }

  function transformLocalToWorld(localX, localZ, worldX, worldZ, rotY) {
    const rotated = rotatePoint(localX, localZ, rotY);
    return { x: worldX + rotated.x, z: worldZ + rotated.z };
  }

  function transformObstacleToWorld(obs, worldX, worldZ, rotY) {
    const pos = transformLocalToWorld(obs.x, obs.z, worldX, worldZ, rotY);
    return {
      x: pos.x,
      z: pos.z,
      halfW: obs.halfW,
      halfD: obs.halfD,
      rotY: obs.rotY + rotY,
    };
  }

  class WalkthroughController {
    constructor(renderer) {
      this.renderer = renderer;
      this.active = false;
      this.yaw = 0;
      this.pitch = 0;
      this.eyeHeightFt = DEFAULT_EYE_HEIGHT_FT;
      this.walkSpeedFt = DEFAULT_WALK_SPEED_FT;
      this.runSpeedFt = DEFAULT_RUN_SPEED_FT;
      this.moveVel = { forward: 0, right: 0 };
      this.walkKeys = { forward: false, backward: false, left: false, right: false };
      this.runActive = false;
      this.currentFov = FOV_DEFAULT;
      this.targetFov = FOV_DEFAULT;
      this.fovAnimStart = null;
      this.fovAnimFrom = FOV_DEFAULT;
      this.modeTransition = null;
      this.collision = { bounds: null, walls: [], obstacles: [] };
      this._pointerBound = false;
      this._lookDragging = false;
      this._lastLookX = 0;
      this._lastLookY = 0;
      this._pinchStartDist = 0;
      this._pinchStartFov = FOV_DEFAULT;
      this._touchCount = 0;
      this._tmpForward = new THREE.Vector3();
      this._tmpRight = new THREE.Vector3();
    }

    setWalkInput(key, active) {
      if (!this.walkKeys.hasOwnProperty(key)) return;
      this.walkKeys[key] = active;
      if (!this._wasMoving() && this._isMoving()) {
        this._startFovReset();
      }
    }

    setWalkInputs(inputs) {
      if (!inputs || typeof inputs !== 'object') return;
      const wasMoving = this._isMoving();
      Object.keys(this.walkKeys).forEach((key) => {
        if (typeof inputs[key] === 'boolean') {
          this.walkKeys[key] = inputs[key];
        }
      });
      if (!wasMoving && this._isMoving()) {
        this._startFovReset();
      }
    }

    _wasMoving() {
      return this.walkKeys.forward || this.walkKeys.backward ||
        this.walkKeys.left || this.walkKeys.right;
    }

    setRunActive(active) {
      this.runActive = active;
    }

    getHeadingDegrees() {
      return THREE.MathUtils.radToDeg(this.yaw);
    }

    getEyeHeightMeters() {
      return this.eyeHeightFt * FT;
    }

    getWalkSpeedMeters() {
      return this.walkSpeedFt * FT;
    }

    getRunSpeedMeters() {
      return this.runSpeedFt * FT;
    }

    setSettings(settings) {
      if (!settings || typeof settings !== 'object') return;
      if (typeof settings.eyeHeightFt === 'number') {
        this.eyeHeightFt = clamp(settings.eyeHeightFt, 2, 8);
      }
      if (typeof settings.walkSpeedFt === 'number') {
        this.walkSpeedFt = Math.max(1, settings.walkSpeedFt);
      }
      if (typeof settings.runSpeedFt === 'number') {
        this.runSpeedFt = Math.max(2, settings.runSpeedFt);
      }
      if (this.active) {
        this.renderer.camera.position.y = this.getEyeHeightMeters();
      }
    }

    _isMoving() {
      return this.walkKeys.forward || this.walkKeys.backward ||
        this.walkKeys.left || this.walkKeys.right;
    }

    _startFovReset() {
      if (Math.abs(this.currentFov - FOV_DEFAULT) < 0.5) return;
      this.fovAnimStart = performance.now();
      this.fovAnimFrom = this.currentFov;
      this.targetFov = FOV_DEFAULT;
    }

    rebuildCollision() {
      const renderer = this.renderer;
      const config = renderer.config;
      if (!config) return;

      const walls = [];
      const obstacles = [];
      let bounds = null;

      if (config.mode === 'apartment') {
        const aptW = config.apartment.width * FT;
        const aptL = config.apartment.length * FT;
        bounds = {
          minX: -aptW / 2 + WALL_CLEARANCE,
          maxX: aptW / 2 - WALL_CLEARANCE,
          minZ: -aptL / 2 + WALL_CLEARANCE,
          maxZ: aptL / 2 - WALL_CLEARANCE,
        };
        (config.placements || []).forEach((placement) => {
          const cfg = placement.room;
          if (!cfg) return;
          const layout = resolveRoomLayout(cfg);
          const rotY = (placement.rotation || 0) * Math.PI / 180;
          const wx = (placement.blueprintX - 0.5) * aptW;
          const wz = (placement.blueprintY - 0.5) * aptL;
        buildWallSegments(layout, cfg.doors || []).forEach((seg) => {
            const local = {
              x1: seg.axis === 'x' ? seg.start : seg.fixed,
              z1: seg.axis === 'x' ? seg.fixed : seg.start,
              x2: seg.axis === 'x' ? seg.end : seg.fixed,
              z2: seg.axis === 'x' ? seg.fixed : seg.end,
              thickness: seg.thickness,
            };
            const a = transformLocalToWorld(local.x1, local.z1, wx, wz, rotY);
            const b = transformLocalToWorld(local.x2, local.z2, wx, wz, rotY);
            walls.push({ x1: a.x, z1: a.z, x2: b.x, z2: b.z, thickness: seg.thickness });
          });
          buildFurnitureObstacles(cfg.furniture, layout).forEach((o) => {
            obstacles.push(transformObstacleToWorld(o, wx, wz, rotY));
          });
          buildStairObstacles(cfg.stairs, layout).forEach((o) => {
            obstacles.push(transformObstacleToWorld(o, wx, wz, rotY));
          });
          buildCupboardObstacles(cfg.cupboards, layout).forEach((o) => {
            obstacles.push(transformObstacleToWorld(o, wx, wz, rotY));
          });
        });
      } else {
        const layout = resolveRoomLayout(config);
        bounds = {
          minX: -layout.w / 2 + WALL_CLEARANCE,
          maxX: layout.w / 2 - WALL_CLEARANCE,
          minZ: -layout.l / 2 + WALL_CLEARANCE,
          maxZ: layout.l / 2 - WALL_CLEARANCE,
        };
        buildWallSegments(layout, config.doors || []).forEach((seg) => {
          walls.push({
            x1: seg.axis === 'x' ? seg.start : seg.fixed,
            z1: seg.axis === 'x' ? seg.fixed : seg.start,
            x2: seg.axis === 'x' ? seg.end : seg.fixed,
            z2: seg.axis === 'x' ? seg.fixed : seg.end,
            thickness: seg.thickness,
          });
        });
        buildFurnitureObstacles(config.furniture, layout).forEach((o) => obstacles.push(o));
        buildStairObstacles(config.stairs, layout).forEach((o) => obstacles.push(o));
        buildCupboardObstacles(config.cupboards, layout).forEach((o) => obstacles.push(o));
      }

      this.collision = { bounds, walls, obstacles };
    }

    _defaultYaw() {
      const renderer = this.renderer;
      const w = renderer.roomSize.w || renderer._configWidthMeters();
      const l = renderer.roomSize.l || renderer._configLengthMeters();
      if (l >= w) return 0;
      return Math.PI / 2;
    }

    _findSpawnPosition() {
      const { bounds } = this.collision;
      if (!bounds) return { x: 0, z: 0 };
      return {
        x: (bounds.minX + bounds.maxX) / 2,
        z: (bounds.minZ + bounds.maxZ) / 2,
      };
    }

    _applyWalkCamera(x, z, yaw, pitch, fov) {
      const cam = this.renderer.camera;
      cam.position.set(x, this.getEyeHeightMeters(), z);
      cam.rotation.order = 'YXZ';
      cam.rotation.y = yaw;
      cam.rotation.x = pitch;
      cam.rotation.z = 0;
      this.currentFov = fov;
      cam.fov = fov;
      cam.updateProjectionMatrix();
    }

    _captureCameraState() {
      const cam = this.renderer.camera;
      return {
        position: cam.position.clone(),
        rotation: cam.rotation.clone(),
        fov: cam.fov,
      };
    }

    enter(previousMode) {
      this.active = true;
      this._savedShadows = this.renderer.renderer.shadowMap.enabled;
      this._savedPixelRatio = this.renderer.renderer.getPixelRatio();
      this.renderer.renderer.shadowMap.enabled = false;
      this.renderer.renderer.setPixelRatio(
        Math.min(window.devicePixelRatio, 1.75)
      );
      this.rebuildCollision();
      const spawn = this._findSpawnPosition();
      this.yaw = this._defaultYaw();
      this.pitch = 0;
      this.moveVel = { forward: 0, right: 0 };
      this.currentFov = FOV_DEFAULT;
      this.targetFov = FOV_DEFAULT;

      const renderer = this.renderer;
      renderer.controls.enabled = false;

      const from = this._captureCameraState();
      const to = {
        position: new THREE.Vector3(spawn.x, this.getEyeHeightMeters(), spawn.z),
        rotation: new THREE.Euler(0, this.yaw, 0, 'YXZ'),
        fov: FOV_DEFAULT,
      };

      this.modeTransition = {
        start: performance.now(),
        duration: MODE_TRANSITION_MS,
        from,
        to,
        onComplete: () => {
          this.modeTransition = null;
          this._applyWalkCamera(spawn.x, spawn.z, this.yaw, 0, FOV_DEFAULT);
        },
      };

      this._bindPointerEvents();
    }

    _restoreRendererPerformance() {
      if (this._savedShadows != null) {
        this.renderer.renderer.shadowMap.enabled = this._savedShadows;
        this._savedShadows = null;
      }
      if (this._savedPixelRatio != null) {
        this.renderer.renderer.setPixelRatio(this._savedPixelRatio);
        this._savedPixelRatio = null;
      }
    }

    repositionAtStart() {
      if (!this.active) return;
      this.rebuildCollision();
      const spawn = this._findSpawnPosition();
      this._applyWalkCamera(spawn.x, spawn.z, this._defaultYaw(), 0, FOV_DEFAULT);
      this.yaw = this._defaultYaw();
      this.pitch = 0;
    }

    exit(targetMode) {
      const renderer = this.renderer;
      const cam = renderer.camera;
      const from = this._captureCameraState();

      this.active = false;
      this.walkKeys = { forward: false, backward: false, left: false, right: false };
      this.runActive = false;
      this.moveVel = { forward: 0, right: 0 };
      this._unbindPointerEvents();

      const savedPosition = cam.position.clone();
      const savedRotation = cam.rotation.clone();
      const savedFov = cam.fov;

      renderer._applyCameraMode(targetMode);
      const to = this._captureCameraState();

      cam.position.copy(savedPosition);
      cam.rotation.copy(savedRotation);
      cam.fov = savedFov;
      cam.updateProjectionMatrix();

      renderer.controls.enabled = targetMode === 'orbit' || targetMode === 'isometric';

      this.modeTransition = {
        start: performance.now(),
        duration: MODE_TRANSITION_MS,
        from,
        to,
        onComplete: () => {
          this.modeTransition = null;
          this._restoreRendererPerformance();
          renderer._applyCameraMode(targetMode);
          renderer.controls.update();
          renderer._updateWallVisibility();
        },
      };
    }

    _bindPointerEvents() {
      if (this._pointerBound) return;
      const el = this.renderer.renderer.domElement;
      this._onPointerDown = (e) => this._handlePointerDown(e);
      this._onPointerMove = (e) => this._handlePointerMove(e);
      this._onPointerUp = (e) => this._handlePointerUp(e);
      this._onTouchStart = (e) => this._handleTouchStart(e);
      this._onTouchMove = (e) => this._handleTouchMove(e);
      this._onTouchEnd = (e) => this._handleTouchEnd(e);
      el.addEventListener('pointerdown', this._onPointerDown);
      el.addEventListener('pointermove', this._onPointerMove);
      el.addEventListener('pointerup', this._onPointerUp);
      el.addEventListener('pointercancel', this._onPointerUp);
      el.addEventListener('touchstart', this._onTouchStart, { passive: false });
      el.addEventListener('touchmove', this._onTouchMove, { passive: false });
      el.addEventListener('touchend', this._onTouchEnd);
      el.addEventListener('touchcancel', this._onTouchEnd);
      this._pointerBound = true;
    }

    _unbindPointerEvents() {
      if (!this._pointerBound) return;
      const el = this.renderer.renderer.domElement;
      el.removeEventListener('pointerdown', this._onPointerDown);
      el.removeEventListener('pointermove', this._onPointerMove);
      el.removeEventListener('pointerup', this._onPointerUp);
      el.removeEventListener('pointercancel', this._onPointerUp);
      el.removeEventListener('touchstart', this._onTouchStart);
      el.removeEventListener('touchmove', this._onTouchMove);
      el.removeEventListener('touchend', this._onTouchEnd);
      el.removeEventListener('touchcancel', this._onTouchEnd);
      this._pointerBound = false;
      this._lookDragging = false;
      this._touchCount = 0;
    }

    _handlePointerDown(e) {
      if (!this.active || this.modeTransition) return;
      if (e.pointerType === 'touch') return;
      this._lookDragging = true;
      this._lastLookX = e.clientX;
      this._lastLookY = e.clientY;
    }

    _handlePointerMove(e) {
      if (!this.active || !this._lookDragging || e.pointerType === 'touch') return;
      this._applyLookDelta(e.clientX - this._lastLookX, e.clientY - this._lastLookY);
      this._lastLookX = e.clientX;
      this._lastLookY = e.clientY;
    }

    _handlePointerUp() {
      this._lookDragging = false;
    }

    _handleTouchStart(e) {
      if (!this.active || this.modeTransition) return;
      this._touchCount = e.touches.length;
      if (e.touches.length === 1) {
        this._lookDragging = true;
        this._lastLookX = e.touches[0].clientX;
        this._lastLookY = e.touches[0].clientY;
      } else if (e.touches.length === 2) {
        this._lookDragging = false;
        this._pinchStartDist = this._touchDistance(e.touches);
        this._pinchStartFov = this.currentFov;
      }
    }

    _handleTouchMove(e) {
      if (!this.active || this.modeTransition) return;
      if (e.touches.length === 1 && this._lookDragging) {
        e.preventDefault();
        const t = e.touches[0];
        this._applyLookDelta(t.clientX - this._lastLookX, t.clientY - this._lastLookY);
        this._lastLookX = t.clientX;
        this._lastLookY = t.clientY;
      } else if (e.touches.length === 2) {
        e.preventDefault();
        const dist = this._touchDistance(e.touches);
        if (this._pinchStartDist > 0) {
          const scale = this._pinchStartDist / dist;
          const next = clamp(this._pinchStartFov * scale, FOV_MIN, FOV_MAX);
          this.currentFov = next;
          this.targetFov = next;
          this.fovAnimStart = null;
          this.renderer.camera.fov = next;
          this.renderer.camera.updateProjectionMatrix();
        }
      }
    }

    _handleTouchEnd(e) {
      this._touchCount = e.touches.length;
      if (e.touches.length === 0) {
        this._lookDragging = false;
        this._pinchStartDist = 0;
      } else if (e.touches.length === 1) {
        this._lookDragging = true;
        this._lastLookX = e.touches[0].clientX;
        this._lastLookY = e.touches[0].clientY;
      }
    }

    _touchDistance(touches) {
      const dx = touches[0].clientX - touches[1].clientX;
      const dy = touches[0].clientY - touches[1].clientY;
      return Math.sqrt(dx * dx + dy * dy);
    }

    _applyLookDelta(dx, dy) {
      const sensitivity = 0.004;
      this.yaw -= dx * sensitivity;
      this.pitch -= dy * sensitivity;
      this.pitch = clamp(this.pitch, PITCH_MIN, PITCH_MAX);
      this.renderer.camera.rotation.order = 'YXZ';
      this.renderer.camera.rotation.y = this.yaw;
      this.renderer.camera.rotation.x = this.pitch;
    }

    _pointInRotatedRect(px, pz, obs) {
      const dx = px - obs.x;
      const dz = pz - obs.z;
      const c = Math.cos(-obs.rotY);
      const s = Math.sin(-obs.rotY);
      const lx = dx * c - dz * s;
      const lz = dx * s + dz * c;
      return Math.abs(lx) <= obs.halfW && Math.abs(lz) <= obs.halfD;
    }

    _circleIntersectsSegment(px, pz, seg) {
      const r = PLAYER_RADIUS;
      const dx = seg.x2 - seg.x1;
      const dz = seg.z2 - seg.z1;
      const lenSq = dx * dx + dz * dz;
      if (lenSq < 1e-8) return false;
      const t = clamp(((px - seg.x1) * dx + (pz - seg.z1) * dz) / lenSq, 0, 1);
      const cx = seg.x1 + dx * t;
      const cz = seg.z1 + dz * t;
      const dist = Math.sqrt((px - cx) * (px - cx) + (pz - cz) * (pz - cz));
      return dist < r + seg.thickness;
    }

    _isWalkable(x, z) {
      const { bounds, walls, obstacles } = this.collision;
      if (!bounds) return true;
      if (x < bounds.minX || x > bounds.maxX || z < bounds.minZ || z > bounds.maxZ) return false;
      for (let i = 0; i < obstacles.length; i++) {
        if (this._pointInRotatedRect(x, z, obstacles[i])) return false;
      }
      for (let i = 0; i < walls.length; i++) {
        if (this._circleIntersectsSegment(x, z, walls[i])) return false;
      }
      return true;
    }

    _updateModeTransition(now) {
      const t = this.modeTransition;
      if (!t) return;
      const elapsed = now - t.start;
      const raw = clamp(elapsed / t.duration, 0, 1);
      const eased = easeInOutCubic(raw);
      const cam = this.renderer.camera;

      cam.position.lerpVectors(t.from.position, t.to.position, eased);
      cam.rotation.x = THREE.MathUtils.lerp(t.from.rotation.x, t.to.rotation.x, eased);
      cam.rotation.y = THREE.MathUtils.lerp(t.from.rotation.y, t.to.rotation.y, eased);
      cam.rotation.z = THREE.MathUtils.lerp(t.from.rotation.z, t.to.rotation.z, eased);
      cam.rotation.order = 'YXZ';
      cam.fov = THREE.MathUtils.lerp(t.from.fov, t.to.fov, eased);
      cam.updateProjectionMatrix();
      this.currentFov = cam.fov;

      if (raw >= 1) {
        const done = t.onComplete;
        this.modeTransition = null;
        if (done) done();
      }
    }

    _updateFov(now) {
      if (!this.fovAnimStart) return;
      const elapsed = now - this.fovAnimStart;
      const raw = clamp(elapsed / FOV_RESET_MS, 0, 1);
      const eased = easeInOutCubic(raw);
      this.currentFov = THREE.MathUtils.lerp(this.fovAnimFrom, FOV_DEFAULT, eased);
      this.renderer.camera.fov = this.currentFov;
      this.renderer.camera.updateProjectionMatrix();
      if (raw >= 1) this.fovAnimStart = null;
    }

    update(delta) {
      const now = performance.now();
      if (this.modeTransition) {
        this._updateModeTransition(now);
      }
      if (!this.active) return;

      this._updateFov(now);

      const stepDelta = Math.min(Math.max(delta, 0), MAX_DELTA);
      const speed = this.runActive ? this.getRunSpeedMeters() : this.getWalkSpeedMeters();
      let targetForward = 0;
      let targetRight = 0;
      if (this.walkKeys.forward) targetForward += speed;
      if (this.walkKeys.backward) targetForward -= speed;
      if (this.walkKeys.left) targetRight -= speed;
      if (this.walkKeys.right) targetRight += speed;

      const blend = 1 - Math.exp(-stepDelta / ACCEL_TIME);
      this.moveVel.forward += (targetForward - this.moveVel.forward) * blend;
      this.moveVel.right += (targetRight - this.moveVel.right) * blend;

      if (Math.abs(this.moveVel.forward) < 0.01) this.moveVel.forward = 0;
      if (Math.abs(this.moveVel.right) < 0.01) this.moveVel.right = 0;
      if (this.moveVel.forward === 0 && this.moveVel.right === 0) return;

      const cam = this.renderer.camera;
      const sinYaw = Math.sin(this.yaw);
      const cosYaw = Math.cos(this.yaw);
      this._tmpForward.set(-sinYaw, 0, -cosYaw);
      this._tmpRight.set(cosYaw, 0, -sinYaw);

      const dx = this._tmpForward.x * this.moveVel.forward + this._tmpRight.x * this.moveVel.right;
      const dz = this._tmpForward.z * this.moveVel.forward + this._tmpRight.z * this.moveVel.right;

      cam.position.x += dx * stepDelta;
      cam.position.z += dz * stepDelta;
      cam.position.y = this.getEyeHeightMeters();
    }
  }

  global.WalkthroughController = WalkthroughController;
})(typeof window !== 'undefined' ? window : global);
