# Space background

The black background and the three star layers are separate files. These are four **seamless tiling images (320x180)**, not frame animations. Godot scrolls them itself, so the movement is perfectly smooth at any speed.

| File | Layer | Suggested `autoscroll` (px/s) |
|---|---|---|
| space_bg | Plain black (opaque, back). You can delete it and set the clear colour to black instead. | (1.5, 0) |
| stars_far | Dim small 3x3 '+' stars | (3, 0) |
| stars_mid | Brighter 3x3 '+' stars | (6, 0) |
| stars_near | A few big bright 5x5 '+' stars (front) | (12, 0) |

Setup (Godot 4.3+): add one `Parallax2D` node per layer, each with a `Sprite2D` child using the texture (`centered = false`). On every Parallax2D set `repeat_size = (320, 180)`, `repeat_times = 3` and `autoscroll` from the table. Positive x moves the space to the right. Use negative values to reverse it, or turn all four down to slow it further. Use the `_x4` versions with `repeat_size = (1280, 720)` if your game isn't scaling the viewport up.
