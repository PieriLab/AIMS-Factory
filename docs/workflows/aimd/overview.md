# AIMD Workflow

The **AIMD workflow** extends Ab Initio Multiple Spawning (AIMS) simulations by continuing nuclear motion after spawning events. It provides two interconnected components: **AIMD (Molecular Dynamics)** and **OPT (Geometry Optimization)**.

---

## Components

### **1. AIMD (Molecular Dynamics)**

Runs trajectories on the lower electronic state, starting from geometries and velocities at AIMS spawn points. Each AIMD trajectory can evolve into multiple restart paths (`r1/`, `r2/`, …) depending on simulation success or continuation needs. These simulations allow exploration of relaxation pathways and post-spawn nuclear motion.

### **2. OPT (Geometry Optimization)**

Performs local geometry optimizations using final structures from completed AIMD trajectories. Each AIMD endpoint becomes an input for a TeraChem optimization job, refining the structure to a minimum or transition-state candidate. Optimizations can also restart from failed runs via sequential directories (`r1/`, `r2/`, …).

---

## Workflow Overview

1. **Run AIMS simulations** to generate spawn points.
2. **Extend trajectories with AIMD** using:

   * `s_summarize_AIMD.sh`
   * `s_spawn_check_AIMD.sh`
   * `r_create_restart_md.sh`
   * `r_run_restart_md.sh`
3. **Extract final AIMD geometries** using `opt1_gen_list.sh`.
4. **Run OPT jobs** using:

   * `opt2_execute.sh`
   * `s_opt_spawn_check.sh`
   * `r_create_restart_opt.sh`
   * `r_run_restart_opt.sh`

---

## Directory Layout

```
<molecule>/
├── AIMS/                # completed AIMS trajectories
├── AIMD/                # AIMD workflow directory
│   ├── AIMS/            # copied or linked AIMS runs
│   ├── AIMD_prep/       # shared input templates (md.in, opt.in, submit scripts)
│   ├── s_*              # summary and monitoring scripts
│   ├── r_*              # restart creation/submission scripts
│   └── opt_*            # optimization setup and execution scripts
```

---

## Current Capabilities

**AIMD (Molecular Dynamics)** fully implemented
**Optimization (OPT)** integrated and operational

---

## Notes

All scripts are designed to be modular, restart-safe, and compatible with SLURM-based HPC systems (e.g., UNC Longleaf). Ensure all scripts have execute permission before running:

```bash
chmod +x s_*.sh r_*.sh opt*.sh
```

