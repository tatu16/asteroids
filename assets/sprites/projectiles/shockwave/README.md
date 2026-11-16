# Four Shockwave

16-bit style animated effect sprites.

- **Multiple cell sizes: 32x32 px, 64x64 px, 128x128 px**, Standard tier: 32x32 px, Premium tier(s): 64x64, 128x128 px
- **Anchor:** center - the same point in every frame, so the
  sprite never slides inside its cell
- **Perspective:** effect
- **Palette:** 37 colours, locked across every frame
- **Transparency:** binary alpha only (0 or 255), safe for point filtering

## Animations

| Clip | Frames | FPS | Loops | Location in combined sheet |
|------|--------|-----|-------|----------------------------|
| `shockwave_normal_32` | 8 | 12 | no | row 0 |
| `shockwave_red_32` | 8 | 12 | no | row 0 |
| `shockwave_blue_32` | 8 | 12 | no | row 0 |
| `shockwave_green_32` | 8 | 12 | no | row 0 |

## Files

```
sheets/four-shockwave_sheet.png            all clips, one row per clip
sheets/four-shockwave_sheet.json           grid + clip metadata
sheets/four-shockwave_sheet.aseprite.json  Aseprite array format, with frameTags
sheets/four-shockwave_<clip>.png           one sheet per clip, single row
sheets/four-shockwave_*_n.png              normal maps, if the pack ships them:
                                              same grid and same cell as the sheet
                                              they sit beside, so one importer
                                              setting covers both
frames/<clip>/000.png                         individual frames
preview/                                      gifs and contact sheet
```

See `LICENSE.txt` for usage terms.

This is the **Standard** edition. Held back for Premium: shockwave_blue_128, shockwave_blue_64, shockwave_green_128, shockwave_green_64, shockwave_normal_128, shockwave_normal_64, shockwave_red_128, shockwave_red_64.
