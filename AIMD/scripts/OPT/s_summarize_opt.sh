#!/usr/bin/env bash
# -----------------------------------------------------------
# script: s_summarize_OPT.sh
# purpose: summarize completed vs total OPT jobs (including restarts)
#          classify as finished / error / running / not started
# author: madeline lee thomas
# -----------------------------------------------------------

BASE="/work/users/m/a/mads2/CLARE/cis_AIMD_50_wb97x/OPT_TEST/AIMS"

# error patterns (DL-FIND / HDLC)
ERR_RE="HDLC-errflag, action: stop|Residue conversion error|DL-FIND ERROR:"

for run_dir in "$BASE"/*; do
  run=$(basename "$run_dir")
  [[ "$run" =~ ^[0-9]{4}$ ]] || continue

  aimd="$run_dir/AIMD"
  [[ -d "$aimd" ]] || { echo "$run : 0/0 OPTs finished"; continue; }

  total=0
  finished=0
  errored=0
  running=0

  for spawn_dir in "$aimd"/*; do
    [[ -d "$spawn_dir" ]] || continue
    spawn=$(basename "$spawn_dir")
    [[ "$spawn" =~ ^[0-9]+$ ]] || continue

    opt_dir="$spawn_dir/OPT"
    [[ -d "$opt_dir" ]] || continue

    # ----------------------------
    # count the base OPT job
    # ----------------------------
    ((total++))
    opt_out="$opt_dir/opt.out"

    if [[ -f "$opt_out" ]]; then
      tailtxt=$(tail -n 200 "$opt_out" || true)

      if grep -qE "Job finished" <<<"$tailtxt" && grep -qE "Total processing time" <<<"$tailtxt"; then
        ((finished++))
      elif grep -qiE "$ERR_RE" <<<"$tailtxt"; then
        ((errored++))
      elif find "$opt_dir" -type f -mmin -5 -print -quit >/dev/null 2>&1; then
        ((running++))
      fi
    fi

    # ----------------------------
    # count restart jobs (r1, r2, …)
    # ----------------------------
    for rdir in "$opt_dir"/r[0-9]*; do
      [[ -d "$rdir" ]] || continue
      ((total++))

      ropt="$rdir/opt.out"
      if [[ -f "$ropt" ]]; then
        tailtxt=$(tail -n 200 "$ropt" || true)

        if grep -qE "Job finished" <<<"$tailtxt" && grep -qE "Total processing time" <<<"$tailtxt"; then
          ((finished++))
        elif grep -qiE "$ERR_RE" <<<"$tailtxt"; then
          ((errored++))
        elif find "$rdir" -type f -mmin -5 -print -quit >/dev/null 2>&1; then
          ((running++))
        fi
      fi
    done
  done

  echo "$run : $finished/$total OPTs finished, $errored errors, $running running"
done

