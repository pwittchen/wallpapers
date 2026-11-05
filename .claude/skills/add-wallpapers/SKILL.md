---
name: add-wallpapers
description: Process wallpaper images in this repo: review them, rename to descriptive names, crop/resize to 21:9 and apply the standard top vignette. Works on new (untracked) images and on already committed ones, recovering the pre-vignette original from git history so the vignette is never applied twice. Use when the user adds new images or asks to process, re-crop, rename, resize or vignette existing wallpapers.
---

# Add / reprocess wallpapers

Bundled scripts (run from the repo root):
- `.claude/skills/add-wallpapers/process.sh [--no-vignette] [--force] <src> <dst> [yoffset]`: crop to 3440:1440 (21:9), keep native resolution clamped to between 3440×1440 and 5160×2160, apply the standard vignette (top edge ~50% brightness fading out over the top 30%, plus ~13% darkening at the edges), and write a JPEG at quality 92 with metadata stripped. It refuses to overwrite `dst` without `--force`. With `--no-vignette`, an image that's already 21:9 is left untouched (no lossy re-encode).
- `.claude/skills/add-wallpapers/find-original.sh <tracked-path> [out-file]`: finds the last committed version from **before** the vignette was applied (the commit before the first one that touched the file and mentions "vignette", following renames). Prints `<rev>:<path>` and writes the file to `out-file`. Exit code 2 = the file was already vignetted when it was first committed, so no original exists in history.

## 1. Determine the targets

- **New images**: untracked image files from `git status --porcelain`, unless the user names specific files.
- **Committed images**: the files, folders or globs the user names (e.g. "all of `forest/`", "`city/ktw.jpg`"). List them with `git ls-files <paths>`.
- If the user's request is ambiguous ("reprocess the wallpapers"), ask which folders or files they mean, since the operation rewrites committed images.

## 2. Get a clean source for each target

The vignette must only be applied to an original image, never on top of an existing vignette.

- **Untracked** → the file itself is the source.
- **Committed** → run `find-original.sh <path> <scratch>/<name>`:
  - exit 0 → use the extracted file in the scratchpad as the source (full vignette processing).
  - exit 2 → there's no original in history. Ask the user whether to only crop/resize it (`--no-vignette`, which keeps the vignette it already has) or to skip it. Don't apply the vignette again.
- Print sizes with `sips -g pixelWidth -g pixelHeight <file>`.

## 3. Review

Make ~800px-wide previews of the **sources** in the session scratchpad (`magick <f> -resize 800x <scratch>/<name>`) and **look at each one** with Read. You need this to choose names and crops.

## 4. Pick names and crop offsets

- **Name**: lowercase, hyphen-separated, a short description of the content, plus the place if it's recognizable (e.g. `mount-fuji-lake-at-dusk.jpg`, `nyc-manhattan-aerial-at-night.jpg`). Drop author names and unsplash/pexels IDs. Keep the category folder and check that the new name isn't taken. For **committed** files, rename only if the user asked for it or the current name is a raw download name (author/ID). Otherwise keep the name.
- **Crop offset** (`yoffset`, 0..1, default 0.5): the image is cropped to 21:9, usually by cutting height. 0.5 = center, lower = keep more of the top, higher = keep more of the bottom. Choose it so the subject stays in frame, and remember that the top ~30% is dimmed. If the source is already 21:9, the offset doesn't matter.

## 5. Process

- **Untracked**: `process.sh <src> <category>/<new-name>.jpg <yoffset>`, then delete the original once the output looks right.
- **Committed, keeping the name**: `process.sh --force <scratch-original> <path> <yoffset>` (overwrites in place).
- **Committed, renaming**: `git mv <old> <new>` first, then `process.sh --force <scratch-original> <new> <yoffset>`. Using `git mv` keeps the history linked so `find-original.sh` can still find the original later.
- **No original available** (user agreed): `process.sh --no-vignette --force <path> <path> <yoffset>`.

When processing many files, write the `src dst offset` list as a heredoc and loop over it, as one batch.

## 6. Verify and report

- Make previews of the outputs and look at them. If a crop cut off the subject, rerun with a different offset.
- Run `git status --short` to check the changes: new files, `M` for reprocessed ones, `R` for renames. No `.tmp.*` files should be left over.
- Report a table (new name ← original/source, final size, notes). Point out images that had to be upscaled (cropped source height < 1440, which may look softer), images processed with `--no-vignette`, and skipped ones.
- Don't commit unless asked. This repo uses lowercase past-tense commit subjects (e.g. `added new wallpapers`). **Any commit that applies the vignette must mention "vignette" in its message**, because `find-original.sh` relies on that to find the pre-vignette originals.
