# Babylon.js — Rendering & Materials

Read this for meshes, materials, lighting, environment, post-processing, and particles.

## Meshes

- Build primitives with `MeshBuilder.CreateBox/Sphere/Ground/Cylinder(...)`.
- Author complex geometry in Blender → export `.glb` → load (see `references/architecture.md`).
- **Merge** static meshes that share a material with `Mesh.MergeMeshes(...)` to cut draw calls.
- Repeated geometry → **instances** / **thin instances** (see `references/performance.md`).

## Materials

- **`PBRMaterial`** (or `PBRMetallicRoughnessMaterial`) for realistic, physically based surfaces — pair with image-based lighting (IBL).
- **`StandardMaterial`** for cheaper, stylized/unlit looks.
- **Node Material Editor** for custom shader graphs without writing GLSL/WGSL by hand.
- Reuse material instances across meshes; assigning the same material enables batching. Call `material.freeze()` on materials whose properties never change.

```ts
import { PBRMaterial, Color3, Texture } from "@babylonjs/core";
const mat = new PBRMaterial("metal", scene);
mat.albedoColor = new Color3(0.8, 0.8, 0.85);
mat.metallic = 1.0;
mat.roughness = 0.4;
mat.albedoTexture = new Texture("assets/textures/metal_albedo.webp", scene);
mat.freeze();
```

## Environment & image-based lighting

Use an environment texture (`.env` is Babylon's optimized format; convert from `.hdr`) for realistic reflections/ambient:

```ts
import { CubeTexture } from "@babylonjs/core";
const env = CubeTexture.CreateFromPrefilteredData("assets/env/studio.env", scene);
scene.environmentTexture = env;
scene.createDefaultSkybox(env, true, 1000);
```

## Lighting & shadows

- One `DirectionalLight` as the sun + a `ShadowGenerator` (use blur/PCF, a tight shadow frustum, and few casters).
- `HemisphericLight` for cheap ambient fill.
- Bake lighting into textures for fully static scenes where possible; real-time shadows are the most common perf sink.

## Post-processing

Use the **DefaultRenderingPipeline** for tonemapping, bloom, FXAA/MSAA, depth-of-field, vignette, chromatic aberration. Enable only what the art direction calls for; each pass costs fill rate.

```ts
import { DefaultRenderingPipeline } from "@babylonjs/core";
const pipeline = new DefaultRenderingPipeline("default", true, scene, [camera]);
pipeline.bloomEnabled = true;
pipeline.fxaaEnabled = true;
```

## Particles

`ParticleSystem` (CPU) for modest counts; **`GPUParticleSystem`** for large counts where supported. Cap emission on low-end devices (see `references/performance.md`).

## Animation

glTF imports bring **AnimationGroups** — start/stop/blend by name. For procedural animation use `Animation` + `scene.beginAnimation`, or the `AnimationGroup` blend API for smooth transitions (e.g. idle → run).
