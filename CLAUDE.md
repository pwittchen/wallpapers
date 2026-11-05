# wallpapers

Personal macOS desktop wallpaper collection. There's no code, only images grouped by category folder: `city/`, `dark/`, `forest/`, `macos/`, `minimal/`, `mountains/`, `water/`.

## Target displays

- Main monitor: 3440×1440 ultrawide (21:9). Most wallpapers are 21:9.
- MacBook (16:10): macOS center-crops the 21:9 images, so keep resolution above 1440 px tall where the source allows.

## Conventions

- File names: lowercase, descriptive, hyphen-separated (`mount-fuji-lake-at-dusk.jpg`). Older files mix in underscores. Don't rename existing files unless asked.
- Every wallpaper has a top vignette (top edge ~50% brightness, fading out over the top 30%, plus subtle edge darkening). It dims the image and keeps the white macOS menu bar text readable.
- Tools: ImageMagick (`magick`) and `sips`.
- Commit messages: lowercase, past tense, short (e.g. `added new wallpapers`, `added top vignette to the wallpapers`).
- Any commit that applies the vignette must mention "vignette" in its message. The pre-vignette originals are found in git history this way, which prevents applying the vignette twice. Use `git mv` for renames so history stays linked.

## Adding or reprocessing wallpapers

Use the `process-wallpapers` skill (`.claude/skills/process-wallpapers/`). It reviews, renames, crops/resizes and vignettes new untracked images. It also works on already committed images, starting from their pre-vignette originals in git history.
