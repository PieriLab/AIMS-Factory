#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------
# script: s_create_restart_opt.sh
# purpose: create new restart directories (r1, r2, …) for failed OPT jobs
# author: madeline lee thomas
# -----------------------------------------------------------

LOG_FILE="info_create_restart_opt.txt"
: > "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

# Default behavior:
#   If no arg given → process error_paths_opt.txt
#   If one or more args given → process those files.
if [[ $# -eq 0 ]]; then
  FILES=("error_paths_opt.txt")
else
  FILES=("$@")
fi

# Validate error files
ERR_PATHS=()
for f in "${FILES[@]}"; do
  if [[ -f "$f" ]]; then
    echo "[INFO] Loading errors from: $f"
    while IFS= read -r line; do
      [[ -n "$line" ]] && ERR_PATHS+=("$line")
    done < <(sed 's/\r$//' "$f" | awk 'NF')
  else
    echo "[WARN] $f not found, skipping."
  fi
done

if [[ ${#ERR_PATHS[@]} -eq 0 ]]; then
  echo "[INFO] No error paths to process."
  exit 0
fi

echo "[INFO] Loaded ${#ERR_PATHS[@]} error paths."

# ----------------------------------------------------------------------
# Parse info_opt_spawn_check.txt for "done" OPTs
# ----------------------------------------------------------------------
declare -A DONE_PATHS
if [[ -f "info_opt_spawn_check.txt" ]]; then
  while IFS= read -r line; do
    if [[ "$line" =~ ^([0-9]{4}):[[:space:]]+spawn[[:space:]]+([0-9]+):[[:space:]]+done ]]; then
      sys="${BASH_REMATCH[1]}"
      spawn="${BASH_REMATCH[2]}"
      key="${sys}_${spawn}"
      DONE_PATHS["$key"]=1
    fi
  done < info_opt_spawn_check.txt
  echo "[INFO] Loaded ${#DONE_PATHS[@]} done entries from info_opt_spawn_check.txt"
else
  echo "[WARN] info_opt_spawn_check.txt not found — skipping done-check logic."
fi

# ----------------------------------------------------------------------
# Helper to extract last geometry block from opt.out or coords.xyz
# ----------------------------------------------------------------------
extract_last_geom_block() {
  local src="$1" dst="$2" tag="$3"
  if [[ ! -f "$src" ]]; then
    echo "  WARNING: missing $src"
    return 1
  fi

  local start total
  start="$(grep -n '^[0-9][0-9]*$' -- "$src" | tail -1 | cut -d: -f1 || true)"
  if [[ -z "${start:-}" ]]; then
    echo "  WARNING: could not find block header in $src"
    return 1
  fi
  total="$(wc -l < "$src")"

  head -n 1 "$src" | tail -n 1 > "$dst"
  echo "$tag" >> "$dst"
  sed -n "$((start+2)),$total p" -- "$src" >> "$dst"
  return 0
}

# ----------------------------------------------------------------------
# Main loop
# ----------------------------------------------------------------------
for opt_path in "${ERR_PATHS[@]}"; do
  if [[ ! -f "$opt_path" ]]; then
    echo "[WARN] opt.out not found (skipping): $opt_path"
    continue
  fi

  OPT_DIR="$(dirname "$opt_path")"
  echo "Processing error path: $opt_path"
  echo "  OPT directory: $OPT_DIR"

  # Determine next restart directory name (r1, r2, r3...)
  max_idx=0
  last_restart=""
  for d in "$OPT_DIR"/r[0-9]*; do
    [[ -d "$d" ]] || continue
    idx="${d##*/r}"
    if [[ "$idx" =~ ^[0-9]+$ ]] && (( idx > max_idx )); then
      max_idx=$idx
      last_restart="$d"
    fi
  done

  next_idx=$((max_idx+1))
  next_rdir="$OPT_DIR/r$next_idx"

  # Optional safety: only allow r3+ if previous was done
  if (( next_idx >= 3 )); then
    sys_base="$(basename "$(dirname "$(dirname "$OPT_DIR")")")"  # e.g. 0001
    spawn_id="$(basename "$(dirname "$OPT_DIR")")"              # e.g. 26
    prev_key="${sys_base}_${spawn_id}"
    if [[ -z "${DONE_PATHS[$prev_key]:-}" ]]; then
      echo "  [SKIP] Not creating r$next_idx because previous OPT not marked done."
      continue
    fi
  fi

  mkdir -p "$next_rdir"
  echo "  → New restart dir: $next_rdir"

  src_coords="$OPT_DIR/coords.xyz"
  if [[ ! -s "$src_coords" ]]; then
    echo "  WARNING: missing coords.xyz, trying opt.out geometry block."
    src_coords="$opt_path"
  fi

  tag="$(basename "$(dirname "$(dirname "$OPT_DIR")")")     $(basename "$(dirname "$OPT_DIR")")     r$next_idx"

  if ! extract_last_geom_block "$src_coords" "$next_rdir/coords.xyz" "$tag"; then
    echo "  ERROR: failed to write $next_rdir/coords.xyz"
  fi

  # copy opt.in only (no submit_opt.sh)
  if [[ -f "$OPT_DIR/opt.in" ]]; then
    cp -f "$OPT_DIR/opt.in" "$next_rdir/"
  else
    echo "  WARNING: missing $OPT_DIR/opt.in"
  fi
done

echo "[INFO] Done."

