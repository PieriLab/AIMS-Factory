#!/bin/bash
# -----------------------------------------------------------
# script: opt1_gen_list.sh
# purpose: find aimd trajectories with finished md.out files
#          extract the final geometry for optimization
# author: madeline lee thomas
# -----------------------------------------------------------

set -euo pipefail

base_dir=${1:-$(pwd)}
out_list="opt_ready_list.txt"
log_file="opt_geom_source.log"
failed_list="opt_failed_list.txt"
> "$out_list"
> "$log_file"
> "$failed_list"

echo "searching for completed aimd runs under $base_dir"
echo "-----------------------------------------------------------"

for traj in $(find "$base_dir" -type d -path "*/AIMD/*" ! -path "*/r*" ! -path "*/scr*"); do
    [[ ! -d "$traj" ]] && continue

    mapfile -t restart_dirs < <(find "$traj" -maxdepth 1 -type d -name "r*" | sort -Vr)
    restart_dirs+=("$traj")

    success_dir=""
    for d in "${restart_dirs[@]}"; do
        mdfile="$d/md.out"
        if [[ -f "$mdfile" ]]; then
            if tail -n 10 "$mdfile" | grep -q "| Job finished" && tail -n 10 "$mdfile" | grep -q "| Total processing time"; then
                success_dir="$d"
                break
            fi
        fi
    done

    if [[ -z "$success_dir" ]]; then
        echo "no successful md.out found in $traj"
        echo "$traj" >> "$failed_list"
        continue
    fi

    echo
    echo "success in $success_dir"
    echo "listing contents under $success_dir:"
    find "$success_dir" -maxdepth 2 -type d -printf "  %p\n"

    coords_file=""
    for f in "$success_dir"/scr*/coors.xyz "$success_dir"/*/scr*/coors.xyz; do
        if [[ -s "$f" ]]; then
            coords_file="$f"
            echo "found coors file at $coords_file"
            break
        fi
    done

    if [[ -z "$coords_file" ]]; then
        echo "no coors.xyz found under $success_dir"
        echo "$traj" >> "$failed_list"
        continue
    fi

    geom_file="$traj/final_geom.xyz"
    echo "extracting final geometry from $coords_file"

    last_line=$(grep -nE '^[0-9]+$' "$coords_file" | tail -n 1 | cut -d: -f1)
    if [[ -z "$last_line" ]]; then
        echo "no geometry header found in $coords_file"
        echo "$traj" >> "$failed_list"
        continue
    fi

    num_atoms=$(sed -n "${last_line}p" "$coords_file")
    start_line=$(( last_line + 1 ))
    end_line=$(( start_line + num_atoms + 1 ))

    sed -n "${last_line},${end_line}p" "$coords_file" > "$geom_file"

    echo "$traj/final_geom.xyz" >> "$out_list"
    echo "$traj geometry from $success_dir ($coords_file)" >> "$log_file"
    echo "done with $traj"
    echo "==========================================================="
done

echo "-----------------------------------------------------------"
echo "geometry extraction complete"
echo "optimization list written to $out_list"
echo "source log written to $log_file"
echo "failed runs written to $failed_list"
echo "-----------------------------------------------------------"

