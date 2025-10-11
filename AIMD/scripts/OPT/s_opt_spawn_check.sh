#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------
# script: s_opt_spawn_check.sh
# purpose: scan all OPT and OPT/r# subdirectories under AIMS/*/AIMD/*
#          check for successful or failed opt.out jobs
# author: madeline lee thomas
# -----------------------------------------------------------

# base directory for AIMS runs
BASE="/work/users/m/a/mads2/CLARE/cis_AIMD_50_wb97x/OPT_TEST/AIMS"
# minutes of recent file modification considered "active"
RECENT_MIN=5
# how many lines from the end of opt.out to check for success or error
TAIL_N=250
# regex for DL-FIND / HDLC errors
ERR_RE="${ERR_RE:-HDLC-errflag, action: stop|Residue conversion error|DL-FIND ERROR:}"

# output logs
ERROR_BASE="error_paths_opt_base.txt"
ERROR_RESTART="error_paths_opt_restart.txt"
LOG_FILE="info_opt_spawn_check.txt"

: > "$ERROR_BASE"
: > "$ERROR_RESTART"
: > "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

usage() {
  cat <<EOF
usage: $0 [-b BASE] [-m RECENT_MIN] [--tail N]
scan AIMS/<run>/AIMD/<spawn>/OPT/opt.out and OPT/r*/opt.out
report: done | running | error | not started yet

writes failing base opt.out paths to:   $ERROR_BASE
writes failing restart opt.out paths to: $ERROR_RESTART
writes all stdout/stderr to: $LOG_FILE
EOF
}

# --- arg parse ---
while (( "$#" )); do
  case "${1:-}" in
    -h|--help) usage; exit 0 ;;
    -b) BASE="${2:?}"; shift 2 ;;
    -m) RECENT_MIN="${2:?}"; shift 2 ;;
    --tail) TAIL_N="${2:?}"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

# --- helpers ---
success_in_opt_out() {
  local f="$1"
  [[ -f "$f" ]] || return 1
  local tailtxt
  tailtxt="$(tail -n "$TAIL_N" -- "$f" || true)"
  grep -qE "Job finished" <<<"$tailtxt" && grep -qE "Total processing time" <<<"$tailtxt"
}

error_in_opt_out() {
  local f="$1"
  [[ -f "$f" ]] || return 1
  local tailtxt
  tailtxt="$(tail -n "$TAIL_N" -- "$f" || true)"
  grep -qiE "$ERR_RE" <<<"$tailtxt"
}

recent_activity() {
  local d="$1"
  [[ -d "$d" ]] || return 1
  find "$d" -type f -mmin "-$RECENT_MIN" -print -quit >/dev/null 2>&1
}

print_restart_info() {
  local d="$1"
  echo "    [files in $d]"
  local required=(opt.in coords.xyz)
  for f in "${required[@]}"; do
    if [[ -f "$d/$f" ]]; then
      echo "      - $f"
    else
      echo "      missing: $f"
    fi
  done
  local extras=()
  while IFS= read -r f; do
    fname="$(basename "$f")"
    case " ${required[*]} " in
      *" $fname "*) continue ;;
    esac
    extras+=( "$fname" )
  done < <(find "$d" -mindepth 1 -maxdepth 1 | sort)
  for f in "${extras[@]}"; do
    echo "      - $f (extra)"
  done
}

# --- main scan ---
if [[ ! -d "$BASE" ]]; then
  echo "[error] base not found: $BASE" >&2
  exit 2
fi

shopt -s nullglob
runs=( "$BASE"/[0-9][0-9][0-9][0-9] )

if [[ ${#runs[@]} -eq 0 ]]; then
  echo "[info] no run directories under: $BASE"
  exit 0
fi

for run_dir in "${runs[@]}"; do
  run_id="$(basename "$run_dir")"
  aimd_dir="$run_dir/AIMD"
  [[ -d "$aimd_dir" ]] || { echo "$run_id: not started yet (no AIMD/)"; continue; }

  for spawn_dir in "$aimd_dir"/*; do
    [[ -d "$spawn_dir" ]] || continue
    [[ "$(basename "$spawn_dir")" =~ ^[0-9]+$ ]] || continue
    spawn_id="$(basename "$spawn_dir")"
    opt_dir="$spawn_dir/OPT"

    # check base opt.out if present
    if [[ -e "$opt_dir/opt.out" ]]; then
      opt="$opt_dir/opt.out"
      label="$run_id: spawn $spawn_id"
      err_file="$ERROR_BASE"

      if success_in_opt_out "$opt"; then
        echo "$label: done"
      elif error_in_opt_out "$opt"; then
        echo "$label: error ($opt)"
        echo "$opt" >> "$err_file"
      elif recent_activity "$opt_dir"; then
        echo "$label: running"
      else
        echo "$label: error (no termination flag and stale) ($opt)"
        echo "$opt" >> "$err_file"
      fi
    elif [[ -d "$opt_dir" ]]; then
      echo "$run_id: spawn $spawn_id: no opt.out"
      echo "$opt_dir" >> "$ERROR_BASE"
    else
      echo "$run_id: spawn $spawn_id: not started yet (no OPT/)"
      continue
    fi

    # check restart dirs separately
    for rdir in "$opt_dir"/r[0-9]*; do
      [[ -d "$rdir" ]] || continue
      opt="$rdir/opt.out"
      label="$run_id: spawn $spawn_id/$(basename "$rdir")"
      err_file="$ERROR_RESTART"

      if [[ -e "$opt" ]]; then
        if success_in_opt_out "$opt"; then
          echo "$label: done"
        elif error_in_opt_out "$opt"; then
          echo "$label: error ($opt)"
          echo "$opt" >> "$err_file"
        elif recent_activity "$rdir"; then
          echo "$label: running"
        else
          echo "$label: error (no termination flag and stale) ($opt)"
          echo "$opt" >> "$err_file"
        fi
      else
        echo "$label: no opt.out"
      fi

      print_restart_info "$rdir"
    done
  done
done

echo "[info] finished. log saved to $LOG_FILE"

