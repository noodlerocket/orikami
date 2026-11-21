# Source art (not part of the game build)

Godot ignores this folder (`.gdignore`), so nothing here is imported or
exported to the web build.

- `fonts/YujiSyuku-Regular.ttf`: the brush-calligraphy font used for titles,
  from Google Fonts (github.com/google/fonts, `ofl/yujisyuku`). SIL Open Font
  License 1.1 (`fonts/OFL.txt`); free to use in the game. It is 8 MB, so the
  game does not ship it: `tools/render_lettering.gd` renders the few lines of
  lettering the game needs into small images in `textures/`.
