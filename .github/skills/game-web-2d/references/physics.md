# Phaser — Physics

Read this when adding movement, collisions, or projectiles. Phaser ships two
physics engines: choose one per project (or per scene).

## Arcade vs Matter — pick one

| | **Arcade** | **Matter.js** |
|--|-----------|---------------|
| Model | AABB (axis-aligned boxes) + circles | Full rigid-body (polygons, constraints, joints) |
| Cost | Very cheap; thousands of bodies | Heavier; realistic but slower |
| Use for | Platformers, top-down, shooters, most arcade games | Stacking, ragdolls, slopes, realistic collisions |
| Default | **Yes — start here** | Only when you need real physics |

Most 2D games want **Arcade**. Reach for Matter only when the gameplay genuinely needs rigid-body simulation.

## Arcade movement

```ts
// in create()
this.player = this.physics.add.sprite(100, 100, "hero");
this.player.setCollideWorldBounds(true);

// in update()
const speed = 200;
const body = this.player.body as Phaser.Physics.Arcade.Body;
body.setVelocity(0);
if (this.cursors.left.isDown) body.setVelocityX(-speed);
else if (this.cursors.right.isDown) body.setVelocityX(speed);
if (this.cursors.up.isDown) body.setVelocityY(-speed);
else if (this.cursors.down.isDown) body.setVelocityY(speed);
body.velocity.normalize().scale(speed);   // prevent faster diagonal
```

## Collisions & overlaps

```ts
this.physics.add.collider(this.player, walls);                 // solid blocking
this.physics.add.overlap(this.player, coins, (_p, coin) => {   // trigger, non-blocking
  (coin as Phaser.GameObjects.GameObject).destroy();
  this.registry.inc("score", 1);
});
```

## Collision groups (categories)

Organize bodies into groups and document the mapping (mirror it in `docs/memory/conventions.md`):

- Use `Phaser.Physics.Arcade.Group` for pooled categories (bullets, enemies).
- For Matter, set `collisionFilter.category` / `mask` bitmasks per body type.
- Keep groups few and named (world, player, enemy, player_shot, enemy_shot).

## Bodies & tuning

- Size the body to the art, not the whole frame: `body.setSize(w, h).setOffset(x, y)`.
- For platformers: `body.setGravityY(...)`, check `body.blocked.down` for grounded.
- Disable physics debug in production (`arcade: { debug: false }`); enable temporarily to inspect bodies.

## Determinism for tests

Arcade physics is frame-rate dependent; for reproducible tests, fix the timestep (`fps` in the arcade config) and seed any RNG. Unit-test movement *intent* (the pure system that decides velocity) separately from the physics integration (covered by Playwright).
