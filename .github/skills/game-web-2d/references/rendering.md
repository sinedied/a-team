# Phaser — Rendering & Assets

Read this for sprites, atlases, tilemaps, animation, cameras, and asset loading.

## Asset loading (preload scene)

Load everything through a dedicated preload scene with a progress bar. Use **texture atlases** and **sprite sheets** instead of many loose images to cut HTTP requests and draw calls.

```ts
// src/scenes/preload.ts
export class PreloadScene extends Phaser.Scene {
  constructor() { super("Preload"); }

  preload(): void {
    const bar = this.add.rectangle(320, 180, 0, 12, 0xffffff);
    this.load.on("progress", (p: number) => { bar.width = 300 * p; });
    this.load.on("loaderror", (f: Phaser.Loader.File) =>
      console.error("Asset failed:", f.key, f.url));   // never crash silently

    this.load.atlas("hero", "assets/sprites/hero.png", "assets/sprites/hero.json");
    this.load.spritesheet("tiles", "assets/tilemaps/tiles.png", { frameWidth: 16, frameHeight: 16 });
    this.load.tilemapTiledJSON("level1", "assets/tilemaps/level1.json");
    this.load.audio("jump", ["assets/audio/jump.ogg", "assets/audio/jump.m4a"]);
  }

  create(): void { this.scene.start("Game"); }
}
```

> Use **relative** asset paths (no leading `/`) so the build works under itch.io / GitHub Pages subpaths. Set `base: './'` in `vite.config.ts`.

## Sprites & animation

```ts
this.anims.create({
  key: "hero-run",
  frames: this.anims.generateFrameNames("hero", { prefix: "run_", start: 0, end: 7, zeroPad: 2 }),
  frameRate: 12,
  repeat: -1,
});
const hero = this.add.sprite(100, 100, "hero").play("hero-run");
```

- `AnimatedSprite` workflow: pack frames into an atlas (TexturePacker), define named animations, play by key.
- Group related sprites in **Containers** for joint transforms; use **Layers** / depth for ordering.

## Tilemaps (Tiled)

Author levels in **Tiled** (`.tmj`/`.json`), load with `tilemapTiledJSON`, then build layers:

```ts
const map = this.make.tilemap({ key: "level1" });
const tileset = map.addTilesetImage("tiles", "tiles");
const ground = map.createLayer("Ground", tileset!, 0, 0);
ground!.setCollisionByProperty({ collides: true });   // collision from a Tiled property
```

Use object layers in Tiled for spawn points, triggers, and entity placement; read them via `map.getObjectLayer(...)`.

## Cameras

```ts
this.cameras.main.startFollow(hero, true, 0.1, 0.1);   // smoothed follow
this.cameras.main.setBounds(0, 0, map.widthInPixels, map.heightInPixels);
this.cameras.main.setZoom(2);
// screen shake: this.cameras.main.shake(200, 0.01);
```

## Particles & effects

Use the particle emitter for impacts, trails, and polish; cap emitter counts on low-end devices (see `references/performance.md`). Prefer additive blend for light/energy effects, but watch overdraw.

## Audio

Load multiple codecs (`.ogg` + `.m4a`/`.mp3`) for browser coverage. Use the **WebAudio** sound manager (default). Duck music under SFX via volume tweens; respect a global mute in the registry. Map audio cues to gameplay events per the spec's Audio Design section.
