# Boss FX sprite sheets (sun + black hole) (first pass, all subject to change)

Each `.png` is a horizontal strip of equal-size frames (1 art pixel = 1 px).
Sheets with "rows" have one variant per row (for example small / medium / large).
The `_x4.png` files are the same sheets scaled up 4x with nearest-neighbour.
`sheets.json` lists the frame size, frame count, rows, fps and looping for every sheet.

**Godot setup for all of them:** set Project Settings > Rendering > Textures > Default Texture Filter to **Nearest**, so the pixel art stays sharp.
In an AnimatedSprite2D, open SpriteFrames, choose "Add frames from sprite sheet", and set Horizontal = frame count and Vertical = rows. Then set the FPS below.
"Tiles horizontally" means the left and right edges join seamlessly, so you can make a beam any length with a TextureRect (stretch mode Tile), a Sprite2D with region + repeat, or a Line2D (texture mode Tile). Rotate it to aim.

## Sun (`sun/`)
| File | Frame | Frames | FPS | Loop | Use |
|---|---|---|---|---|---|
| sun_ring | 96x96 | 8 | 12 | yes | Ring of light. The hole in the middle (radius ~27 px) is where the sun sits. |
| sun_beam | 64x24 | 8 | 14 | yes | Beam body. Tiles horizontally. |
| sun_beam_origin | 32x32 | 8 | 14 | yes | Flare where the beam leaves the sun. |
| sun_fire_ring | 128x128 | 8 | 12 | yes | Ring of fire for the sun's **ring attack**. Spawn it on the sun and scale it outward in code. Its radius is ~48 px at scale 1. |
| sun_teleport_out | 128x128 | 16 | 18 | **no** | **Teleport out**: a ring of fire closes in on the sun, then flashes. Hide the sun on the last few frames. |
| sun_teleport_in | 128x128 | 16 | 18 | **no** | **Teleport in**: the same in reverse, a flash that opens out into a ring of fire. Show the sun as the ring opens. |
| sun_supernova | 192x192 | 30 | 14 | **no** | **Supernova**: the sun swells, flashes white, and a shockwave shell blasts out with debris. It cools into a purple nebula, leaving a tiny remnant star. The swell (frames 0-5) is about the size of a 64 px sun. |

## Black hole (`black_hole/`)
| File | Frame | Frames | FPS | Loop | Use |
|---|---|---|---|---|---|
| bh_gravity_pull | 160x160 | 12 | 12 | yes | **Gravity ability**: purple rings close in on the hole, with streaks dragged inward. The middle (radius ~17) is empty for the hole. |
| bh_force_field | 112x112 | 12 | 12 | yes | **Force field**: a cyan hex-grid shield bubble (radius 50) with a light sweep and rotating arcs on the rim. The fill is semi-transparent. |
| bh_force_field_hit | 112x112 | 6 | 18 | **no** | Play this on top of (or instead of) the shield when something hits it. The whole shield flares and settles. |
| bh_force_field_break | 112x112 | 12 | 16 | **no** | The shield shatters into shards that fly out and fade. |
| bh_void_orbs | 16x16 | 6 x 3 rows | 12 | yes | **Dot attack**: void-black orbs with a flickering purple rim, in small, medium and large rows. These are a different look from the hot matter dots. |
| bh_matter_dots | 16x16 | 6 x 3 rows | 14 | yes | Really hot blobs for the matter-spew attack. The rows are small, medium and large. Use one per projectile. |
| bh_em_wave_ring | 128x128 | 8 | 12 | yes | Purple EM wave ring with **one green safe gap** you can fly through, centred at 0° (pointing right) and about 40° wide (±20°). Scale it up in code as it expands. Give the node a random `rotation` each time so the gap lands somewhere random. The safe hitbox is the arc within ±20° of the node's rotation. |
| bh_em_wave_segment | 64x24 | 8 | 12 | yes | Straight purple EM wave. Tiles horizontally. |
| bh_em_wave_safe | 64x24 | 8 | 12 | yes | Green, calmer wave tile the same size as the segment. Swap one random tile in a straight wave for this one to make the safe gap. |
| bh_grid_warning | 64x5 | 6 | 12 | yes | Thin flashing telegraph line shown before a grid beam fires (phase 2). Tiles horizontally. |
| bh_grid_beam | 64x16 | 8 | 14 | yes | Thinner void beam for the phase 2 grid. Tiles horizontally. Rotate 90° for the vertical ones. |
| bh_grid_cross | 32x32 | 8 | 14 | yes | Flare to put where two grid beams cross. |
| bh_ult_beam | 64x28 | 8 | 14 | yes | Big ult beam with a void core and glowing edges. Tiles horizontally. |
| bh_ult_beam_origin | 40x40 | 8 | 14 | yes | Flare at the start of the ult beam. |
| bh_ult_ring | 128x128 | 14 | 18 | **no** | Purple one-shot shockwave that expands out and fades. Play it once when the ult fires. |
| bh_ult_ring_loop | 96x96 | 10 | 12 | yes | Purple looping warning ring for while the ult charges or is active. |
| bh_spiral_particles | 96x96 | 16 | 12 | yes | Particles spiralling into the black hole. Draw it behind the hole, centred on it. |
| bh_random_particles | 96x96 | 16 | 10 | yes | Random twinkling motes drifting slowly inward. Draw it behind. |
| bh_spark_textures | 7x7 | 6 x 3 rows | 10 | yes | Single particle images for GPUParticles2D/CPUParticles2D. The rows are dot, plus and star. Use a CanvasItemMaterial with Particles Animation on, H Frames 6, V Frames 3. |

Colours: the sun goes dark maroon to red to orange to yellow/white. The black hole beams go maroon to red to peach to white around a void core. The rings and gravity are purple, the force field is cyan, the EM waves purple with a green safe gap, and the matter dots white-hot to red.
