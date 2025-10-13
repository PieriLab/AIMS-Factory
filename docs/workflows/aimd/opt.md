# Optimization (OPT)

## Overview

**OPT** jobs perform local geometry optimization on the final structures from completed AIMD trajectories. Each AIMD endpoint can serve as the starting geometry for a TeraChem optimization, allowing for refinement to a local minimum or transition-state candidate structure.

---

## Setup Instructions

### 1. Directory Preparation

1. Navigate to your molecule’s working directory and ensure the following structure exists:

```bash
.../<molecule>/AIMD/
AIMD/
├── AIMS/                     # contains AIMD results (0000/, 0001/, ...)
├── AIMD_prep/                # holds shared input templates
│   ├── opt1_gen_list.sh      # generate geometry list for optimization
│   ├── opt2_execute.sh       # submit optimization jobs
│   ├── s_opt_spawn_check.sh  # monitor optimization and restart progress
│   ├── s_summarize_OPT.sh    # summarize optimization job status
│   ├── r_create_restart_opt.sh   # create restart directories (r1/, r2/, ...)
│   └── r_run_restart_opt.sh      # submit all pending restart jobs
```
---

### 2. AIMD_prep Setup

Within `AIMD_prep/`, include the following:

| File            | Purpose                                                                |
| --------------- | ---------------------------------------------------------------------- |
| `opt.in`        | TeraChem input file for geometry optimization.                         |
| `submit_opt.sh` | SLURM submission script for optimization jobs (edit for your cluster). |

The same input and submission script are shared across all OPT jobs.

---

### 3. Core OPT Scripts

| Script                    | Description                                                                                                               |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `opt1_gen_list.sh`        | Searches AIMD directories for completed `md.out` files and extracts final geometries for optimization.                    |
| `opt2_execute.sh`         | Creates `OPT/` directories for each geometry in `opt_ready_list.txt` and submits optimization jobs using `submit_opt.sh`. |
| `s_opt_spawn_check.sh`    | Scans `OPT/` and `OPT/r#` directories for success, error, or running states; logs results.                                |
| `s_summarize_OPT.sh`      | Summarizes completed, errored, and running optimizations (including restarts).                                            |
| `r_create_restart_opt.sh` | Creates restart directories (`r1/`, `r2/`, …) for failed optimizations.                                                   |
| `r_run_restart_opt.sh`    | Finds and submits all pending restart jobs.                                                                               |

#### Typical Workflow

Run these scripts in sequence:

```bash
bash opt1_gen_list.sh
bash opt2_execute.sh
bash s_opt_spawn_check.sh
bash r_create_restart_opt.sh
bash r_run_restart_opt.sh
bash s_summarize_OPT.sh
```

---

### 4. Monitoring OPT Runs

Each optimization directory (`AIMS/####/AIMD/#/OPT/`) contains:

* `opt.in`, `coords.xyz`, and `opt.out`
* optional restart directories (`r1/`, `r2/`, …)

Job status is determined as follows:

| Status      | Criteria                                                                                                              |
| ----------- | --------------------------------------------------------------------------------------------------------------------- |
| **done**    | `opt.out` contains both `Job finished` and `Total processing time`.                                                   |
| **running** | Files in the directory were modified within the last few minutes.                                                     |
| **error**   | `opt.out` contains DL-FIND or HDLC errors (`HDLC-errflag`, `Residue conversion error`, `DL-FIND ERROR:`) or is stale. |

All findings are logged to:

```bash
info_opt_spawn_check.txt
error_paths_opt_base.txt
error_paths_opt_restart.txt
```

---

### 5. Restart Logic

If an optimization fails:

* `r_create_restart_opt.sh` extracts the final coordinates from the last valid structure in `opt.out`.
* A new restart folder (`r1/`, `r2/`, …) is created inside the same `OPT/` directory.
* Each restart inherits `opt.in` and `coords.xyz`.
* Use `r_run_restart_opt.sh` to automatically submit all pending restarts using the shared `submit_opt.sh` from `AIMD_prep/`.

---

### 6. Notes

* The `submit_opt.sh` file is **not copied** into each individual OPT directory — it is referenced globally from `AIMD_prep/`.
* Error markers are detected based on DL-FIND or HDLC convergence failures.
* All scripts are **restart-safe** and may be rerun without duplicating submissions.
* Ensure all scripts are executable before use:

  ```bash
  chmod +x opt*.sh s_*.sh r_*.sh
  ```

