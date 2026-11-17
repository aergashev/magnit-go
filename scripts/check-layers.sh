#!/usr/bin/env bash
# Checks the layer rule from ARCHITECTURE.md: a layer may only use the layers below it.
# The app is one Swift module, so the compiler cannot enforce this; this script looks for
# names that belong to higher layers. Run from anywhere:
#
#     scripts/check-layers.sh
set -eu
cd "$(dirname "$0")/../MagnitGo"

# Lowest first.
layers="Shared Providers Entities Features Processes App"

# Type names a layer defines.
types_in() {
  grep -rhoE '^(struct|enum|final class|class|protocol) [A-Za-z_]+' "$1" | awk '{print $NF}' | sort -u
}

# Actions a feature or process adds to the session store (AppState).
actions_in() {
  case "$1" in
    Features|Processes) grep -rhoE '^    func [A-Za-z_]+' "$1" | awk '{print $NF}' | sort -u ;;
  esac
}

status=0
for layer in $layers; do
  above=""
  seen=0
  for other in $layers; do
    if [ "$other" = "$layer" ]; then seen=1; continue; fi
    if [ $seen = 1 ]; then above="$above $other"; fi
  done

  types=$(for l in $above; do types_in "$l"; done | paste -sd'|' -)
  actions=$(for l in $above; do actions_in "$l"; done | paste -sd'|' -)

  hits=$(
    {
      if [ -n "$types" ]; then grep -rnwE "($types)" "$layer" || true; fi
      if [ -n "$actions" ]; then grep -rnE "\.($actions)\(" "$layer" || true; fi
    } | grep -vE '^[^:]+:[0-9]+:[[:space:]]*//' || true
  )
  if [ -n "$hits" ]; then
    echo "$layer uses a higher layer:"
    echo "$hits" | sed 's/^/  /'
    status=1
  fi
done

if [ $status = 0 ]; then echo "Layers OK: every layer uses only the layers below it."; fi
exit $status
