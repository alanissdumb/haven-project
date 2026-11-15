import sys
import numpy as np
from PIL import Image

out = sys.argv[1]
W, H = 168, 104
cx, cy, R = W / 2, H / 2, 36
rng = np.random.default_rng(7)

def value_noise(w, h, cell):
    gw, gh = w // cell + 2, h // cell + 2
    g = rng.random((gh, gw))
    ys, xs = np.mgrid[0:h, 0:w] / cell
    x0, y0 = xs.astype(int), ys.astype(int)
    fx, fy = xs - x0, ys - y0
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a = g[y0, x0] * (1 - fx) + g[y0, x0 + 1] * fx
    b = g[y0 + 1, x0] * (1 - fx) + g[y0 + 1, x0 + 1] * fx
    return a * (1 - fy) + b * fy

noise = sum(value_noise(W, H, c) * w for c, w in [(16, .5), (8, .3), (4, .2)])
patch = value_noise(W, H, 10)

bayer = np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]) / 16 - .5
dither = np.tile(bayer, (H // 4 + 1, W // 4 + 1))[:H, :W]

body = np.array([(20, 22, 48), (34, 42, 82), (50, 64, 112), (72, 92, 138),
                 (100, 120, 160), (136, 152, 182), (170, 184, 204)])
accent_green = np.array((96, 140, 128))
accent_rose = np.array((150, 92, 120))
ring = np.array([(110, 24, 30), (176, 48, 32), (226, 96, 36), (246, 150, 56), (255, 206, 120)])

tilt = np.radians(-17)
ys, xs = np.mgrid[0:H, 0:W].astype(float) + .5
dx, dy = xs - cx, ys - cy
# rotated frame aligned with the ring plane
u = dx * np.cos(tilt) + dy * np.sin(tilt)
v = -dx * np.sin(tilt) + dy * np.cos(tilt)

img = np.zeros((H, W, 4), np.uint8)

# planet
d2 = (dx * dx + dy * dy) / (R * R)
inside = d2 <= 1
nz = np.sqrt(np.clip(1 - d2, 0, 1))
light = np.array([-.55, -.45, .70]); light /= np.linalg.norm(light)
lam = (dx / R) * light[0] + (dy / R) * light[1] + nz * light[2]
bands = np.sin(v / R * 9 + noise * 4.5) * .5 + .5
shade = np.clip(lam, 0, 1) * .85 + bands * .35 - .1 + dither * .15
idx = np.clip((shade * len(body)).astype(int), 0, len(body) - 1)
col = body[idx]
mid = (idx >= 2) & (idx <= 4)
col = np.where(((patch > .72) & mid)[..., None], (col * .4 + accent_green * .6).astype(int), col)
col = np.where(((patch < .22) & mid)[..., None], (col * .45 + accent_rose * .55).astype(int), col)
img[inside, :3] = col[inside]
img[inside, 3] = 255
# dark rim on the shadow side
rim = inside & (d2 > .86) & (lam < .35)
img[rim, :3] = body[0]

# ring: elliptical annulus in the rotated frame
A, B = 80, 13
e = np.sqrt((u / A) ** 2 + (v / B) ** 2)
band = (e >= .70) & (e <= 1.0)
t = (e - .70) / .30
ring_shade = np.sin(t * np.pi) * .8 + .15 * np.cos(t * 23) + dither * .15
ridx = np.clip((ring_shade * len(ring)).astype(int), 0, len(ring) - 1)
# gap line
ridx = np.where((t > .55) & (t < .62), 0, ridx)
front = v > 0                                  # lower half passes in front of the planet
draw = band & (front | ~inside)
# planet's shadow falling on the back-right of the ring
shadow = band & ~front & ~inside & (dx > 0) & (np.abs(v + dx * .05) < R * .9) & (dx < R * 1.6)
rcol = ring[ridx]
rcol = np.where(shadow[..., None], (rcol * .45).astype(int), rcol)
img[draw, :3] = rcol[draw]
img[draw, 3] = 255
# ring casting a thin shadow across the planet just above its front edge
above = inside & ~band & (v > 0) & (np.abs(e - .66) < .05)
img[above, :3] = (img[above, :3] * .55).astype(np.uint8)

lo = Image.fromarray(img, 'RGBA')
lo = lo.crop(lo.getbbox())
lo.save(out.replace('.png', '_1x.png'))
lo.resize((lo.width * 4, lo.height * 4), Image.NEAREST).save(out)
print(lo.size)
