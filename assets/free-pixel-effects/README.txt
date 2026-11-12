FREE PIXEL EFFECTS
30 explosions, hit sparks and magic bursts for 2D games

What's in here
  explosions/   12 effects, 32 to 64 px, 8 or 12 frames, 12 fps
  hit-sparks/   10 effects, 16 to 48 px, 6 or 8 frames, 15 fps
  magic/         8 effects, 32 to 64 px, 12 frames, 12 fps
  rpg-maker/     the same 30, ready for RPG Maker MV and MZ

All 30 are one-shots: they play once, so don't set them to loop.
The hit sparks end on an empty frame. The explosions and magic fade
to a few wisps on the last frame, so hide or free the sprite when
the animation finishes.

Every effect is a PNG sprite sheet (one row, transparent background)
with a JSON file and a Godot SpriteFrames file (.tres) of the same name
next to it. The JSON has the frame size, frame count, fps, columns
and rows, each frame's x/y, and the palette. File names say the size:
hit-spark-24.png is 24 x 24 per frame.

Colors
  Six palettes: fire, gold, toxic, frost, arcane and white. The exact
  hex values are in each JSON file under "palette".

Godot 4
  Every effect has a SpriteFrames file (.tres) next to its PNG. Copy the
  folder into your project, add an AnimatedSprite2D, drag the .tres onto
  its Sprite Frames, then call play() or turn on Autoplay. It plays once
  at the right speed. To remove it when it's done, connect its
  animation_finished signal to queue_free. Set Texture Filter to Nearest
  or they'll look blurry. Tested in Godot 4.3, 4.5 and 4.7.
  Without the .tres: on a Sprite2D, set Animation > Hframes to the
  "columns" value in the JSON (Vframes is 1) and animate the frame
  property with an AnimationPlayer.

Unity
  Import the PNG, Texture Type: Sprite, Sprite Mode: Multiple,
  Filter Mode: Point, Compression: None. Sprite Editor > Slice >
  Grid By Cell Size, using frame_width and frame_height from the JSON.

GameMaker
  Create Sprite > Import Strip Image, number of frames = frame_count.
  Set the sprite's speed to the fps from the JSON (Frames Per Second).
  GameMaker loops sprites, so destroy the instance in its Animation End
  event.

Defold
  Make a Tile Source from the PNG with Tile Width and Tile Height set
  to the frame size, add an animation with Start Tile 1, End Tile =
  frame_count, Playback: Once Forward, and the fps from the JSON.

RPG Maker MV and MZ
  The rpg-maker folder has all 30 as ready animations: a sheet for
  img/animations (192 px cells, scaled up 3 times with hard pixels)
  and a database entry for each. Save and close your project, open
  rpg-maker/add-to-project.html in Chrome or Edge, and choose your
  project folder. It backs up your Animations.json, adds the 30 after
  your last animation and lists their numbers. Then set a skill's or
  item's Animation to one of them. In Firefox or Safari the same page
  walks you through copying the sheets and swapping in a new
  Animations.json. MZ needs version 1.4.0 or later; MV works as is.

License
  CC0 1.0. Use them in anything, commercial included. No credit needed.
  See LICENSE.txt.

Made with Puff
  I used Puff for all of these. It's a pixel effect generator that
  runs in the browser. The web version is free and exports GIFs; the
  $5 version exports sheets like these in your own palette (paste any
  Lospec palette), from 16 to 128 px, with your own frame count.
  https://cs5475.itch.io/puff
  Six more explosion styles I made with it (shockwave, smoke, debris
  and others) are in Pixel Explosions:
  https://cs5475.itch.io/pixel-explosions
