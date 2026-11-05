#!/bin/zsh
# Find the last committed version of a wallpaper from before the vignette was applied.
# usage: find-original.sh <tracked-path> [out-file]
# Prints "<rev>:<path>" of that pre-vignette version and, if out-file is given,
# writes it there. Exits 2 if the file was vignetted already when it was
# first committed (no original in history), 1 on other errors.
# A commit "applied the vignette" if its message mentions "vignette".
set -e
f=$1; out=$2
git ls-files --error-unmatch "$f" >/dev/null 2>&1 || { echo "not tracked: $f" >&2; exit 1; }

# Commits touching the file, newest first, following renames: "<hash>\t<path at that commit>"
lines=("${(@f)$(git log --follow --format='%H' --name-only -- "$f" | awk 'NF{ if(h==""){h=$0} else {print h"\t"$0; h=""} }')}")

# Oldest commit (following renames) that mentions "vignette"
vig=""; vigpath=""
for l in "${lines[@]}"; do
  h=${l%%$'\t'*}; p=${l#*$'\t'}
  if git log -1 --format=%B "$h" | grep -qi vignette; then vig=$h; vigpath=$p; fi
done
[ -z "$vig" ] && { echo "no vignette commit found for $f — the committed version is the original" >&2; echo "HEAD:$f"; [ -n "$out" ] && git show "HEAD:$f" > "$out"; exit 0; }

# The version just before that commit, at its old path (may have been renamed in that commit)
for l in "${lines[@]}"; do
  h=${l%%$'\t'*}; p=${l#*$'\t'}
  if [ "$found" = 1 ]; then echo "$h:$p"; [ -n "$out" ] && git show "$h:$p" > "$out"; exit 0; fi
  [ "$h" = "$vig" ] && found=1
done
echo "$f was already vignetted when first committed ($(git log -1 --format='%h %s' $vig)); no original in history" >&2
exit 2
