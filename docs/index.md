# AIMS-Factory

**AIMS-Factory** is a collection of automated workflows designed to streamline **Ab Initio Multiple Spawning (AIMS)** simulations and their post-processing extensions.  
These workflows provide tools for trajectory continuation, analysis, and optimization within a reproducible, modular framework.
<p align="center">
<pre>
  ⠀⠀⠀⠀⠀⠀⠀  ⠀⣀⠀⡀    ⠀⡠⢂⠬⠀⠚⠁
⠀⠀⠀⠀⠀⠀⠀⡠⢂⠬⠀⠚⠁     ⡠⡠
⠀ __⠀⠀⠀⡠⡠⠀ ⠀⠀⠀    ||   ___                        
 |""|  ||     _   /\  |"""|  __                  
 |""| |"""|  |"| |""| |"""| |""|       
 |""| |"""|  |"| |""| |"""| |""|      
 |""| |"""|  |"| |""| |"""| |""|      
 "'''"''"'""'"""''"''''"""'""'""
    WELCOME TO AIMS-FACTORY
</pre>
</p>
---

## Available Workflows

### [AIMD (Ab Initio Molecular Dynamics)](workflows/aimd/overview.md)
Extends nuclear motion beyond AIMS spawning events to explore post-spawn dynamics and relaxation pathways.

### [OPT (Geometry Optimization)](workflows/aimd/opt.md)
Performs local geometry optimizations starting from AIMD endpoints, identifying potential photoproducts and minima.

---

## Additional Tools
- **Restart Management:** Automated creation and submission of restart directories (`r1/`, `r2/`, …).  
- **Monitoring Utilities:** Real-time progress tracking and error detection for both AIMD and OPT runs.  
- **Workflow Summaries:** Aggregated reporting on completed, running, and errored jobs.

---

*Developed and maintained by the Pieri Lab at UNC-Chapel Hill.* 

