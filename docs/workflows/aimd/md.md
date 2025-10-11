# Molecular Dynamics (AIMD)

## Overview

**AIMD (Ab Initio Molecular Dynamics)** continues nuclear motion after AIMS spawning events. Each spawn point from an AIMS trajectory is extended into a physically meaningful MD trajectory on the lower electronic state, allowing exploration of post-spawn dynamics.

---

## Setup Instructions

### 1. Directory Preparation

1. Navigate to your molecule’s AIMS working directory:

   ```bash
   .../<molecule>/AIMS/####
   ```
2. Create a top-level AIMD directory:

   ```bash
   .../<molecule>/AIMD/
   ```
3. Inside it, copy or link the finished AIMS run directories (e.g., `0000/`, `0001/`, `0002/`) into:

   ```bash
   .../<molecule>/AIMD/AIMS/
   ```

   Each of these AIMS trajectories will serve as a starting point for MD spawning.

---

### 2. AIMD_prep Setup

Create a preparation folder:

```bash
.../<molecule>/AIMD/AIMD_prep/
```

Inside `AIMD_prep/`, include the following:

| File           | Purpose                                                                   |
| -------------- | ------------------------------------------------------------------------- |
| `md.in`        | TeraChem input file for AIMD dynamics.                                    |
| `submit_md.sh` | SLURM submission script for AIMD jobs (edit to match your cluster queue). |

These serve as shared templates for all AIMD trajectories and restarts.

---

### 3. Core AIMD Scripts

Place these scripts in your main AIMD working directory (e.g., `.../<molecule>/AIMD_TEST/`):

| Script                   | Description                                                                       |
| ------------------------ | --------------------------------------------------------------------------------- |
| `s_summarize_AIMD.sh`    | Summarizes how many AIMD spawns are finished, running, or errored.                |
| `s_spawn_check_AIMD.sh`  | Scans all AIMD and restart (`r#`) directories for success, error, or active jobs. |
| `r_create_restart_md.sh` | Generates restart directories (`r1/`, `r2/`, …) for failed trajectories.          |
| `r_run_restart_md.sh`    | Finds and submits all pending restart jobs automatically.                         |

#### Typical Workflow

Run the following in sequence:

```bash
bash s_summarize_AIMD.sh
bash s_spawn_check_AIMD.sh
bash r_create_restart_md.sh
bash r_run_restart_md.sh
```

---

### 4. Monitoring AIMD Runs

Each trajectory folder (`AIMS/####/AIMD/#/`) contains:

* `md.in`, `coords.xyz`, `vels.xyz`, and `md.out`
* optional restart directories (`r1/`, `r2/`, etc.)

Job status is determined as follows:

| Status      | Criteria                                                                                      |                    |                         |
| ----------- | --------------------------------------------------------------------------------------------- | ------------------ | ----------------------- |
| **done**    | `md.out` contains both `                                                                      | Job finished:`and` | Total processing time:` |
| **running** | Files in the directory were modified within the last few minutes.                             |                    |                         |
| **error**   | `md.out` contains termination keywords (e.g., `DIE called at`, `Job terminated`) or is stale. |                    |                         |

All findings are logged to:

```bash
info_spawn_check_AIMD.txt
error_paths_base.txt
error_paths_restart.txt
```

---

### 5. Restart Logic

If a trajectory fails:

* `r_create_restart_md.sh` extracts the final coordinates and velocities from the last valid frame.
* A new restart folder (`r1/`, `r2/`, …) is created within the corresponding AIMD spawn.
* Each restart inherits `md.in`, `coords.xyz`, and `vels.xyz`.
* Use `r_run_restart_md.sh` to automatically submit all pending restart jobs.

---

### 6. Notes

* Copying many AIMS runs to AIMD can be slow — use a batch copy script (e.g., `aimd_aims_copy.sh`) and submit it through SLURM instead of running locally.
* All scripts are **restart-safe**: repeated executions skip completed or active runs.
* Ensure all scripts are executable before running:

```bash
chmod +x s_*.sh r_*.sh
```

