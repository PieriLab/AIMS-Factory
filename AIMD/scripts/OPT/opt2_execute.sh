#!/usr/bin/env bash
set -euo pipefail

# base directory for optimization prep and list
base_dir=${1:-$(pwd)}
opt_list="$base_dir/opt_ready_list.txt"
prep_dir="$base_dir/AIMD_prep"
submit_script="$prep_dir/submit_opt.sh"
opt_input="$prep_dir/opt.in"

# check required files
if [[ ! -f "$opt_list" ]]; then
  echo "opt_ready_list.txt not found, run opt1_gen_list.sh first"
  exit 1
fi

if [[ ! -f "$opt_input" ]]; then
  echo "opt.in not found under AIMD_prep"
  exit 1
fi

if [[ ! -f "$submit_script" ]]; then
  echo "submit_opt.sh not found in $base_dir"
  exit 1
fi

echo "submitting optimizations listed in $opt_list"
echo "-----------------------------------------------------------"

submitted_log="$base_dir/opt_submitted.log"
> "$submitted_log"

# loop through all geometries in opt_ready_list.txt
while read -r geom_path; do
  [[ -z "$geom_path" ]] && continue

  traj_dir=$(dirname "$geom_path")
  opt_dir="$traj_dir/OPT"

  mkdir -p "$opt_dir"
  cp "$opt_input" "$opt_dir/opt.in"
  cp "$geom_path" "$opt_dir/coords.xyz"

  echo "submitting optimization for $traj_dir"

  (
    cd "$opt_dir"
    sbatch "$submit_script"
  ) && echo "$opt_dir" >> "$submitted_log"

done < "$opt_list"

echo "-----------------------------------------------------------"
echo "all optimizations submitted"
echo "log written to $submitted_log"
echo "-----------------------------------------------------------"

