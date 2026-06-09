<div align="center">

# MCD-OA

**Mechanobiological cartilage degeneration framework in osteoarthritis (MCD-OA)**

MCD-OA links a subject-specific finite element knee model with an adipokine-mediated inflammation model to study obesity-associated progressive cartilage degeneration in knee osteoarthritis.

[![DOI](https://img.shields.io/badge/DOI-10.1007%2Fs10237--026--02072--8-blue)](https://doi.org/10.1007/s10237-026-02072-8)
[![MATLAB](https://img.shields.io/badge/MATLAB-R2022a-orange)](https://www.mathworks.com/)
[![Abaqus](https://img.shields.io/badge/Abaqus-2021-darkgreen)](https://www.3ds.com/products/simulia/abaqus)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

[Paper](https://doi.org/10.1007/s10237-026-02072-8) | [Method](#method) | [Setup](#Setup) | [Citation](#citation)

<p align="center">
<b>Juntong Lai</b> <a href="https://orcid.org/0009-0009-5488-8619"><img src="https://info.orcid.org/wp-content/uploads/2019/11/orcid_16x16.png" alt="ORCID" width="14" height="14"></a> and <b>Damien Lacroix</b> <a href="https://orcid.org/0000-0002-5482-6006"><img src="https://info.orcid.org/wp-content/uploads/2019/11/orcid_16x16.png" alt="ORCID" width="14" height="14"></a>
<br>
Insigneo Institute for in silico Medicine, School of Mechanical, Aerospace and Civil Engineering, University of Sheffield, UK
</p>

</div>

---
## Overview

MCD-OA is a research codebase for simulating the interaction between joint mechanics and inflammatory activity during cartilage degeneration. The framework couples:

- an Abaqus finite element model of the tibiofemoral knee joint simulating biomechanical responses of articular cartilage;
- a MATLAB ordinary differential equation model simulating the adipokine-mediated inflammation;

The top-level workflow is orchestrated by [MasterRun.m](MasterRun.m). A complete run advances the coupled system through 60 iterations by default, representing five years of simulated cartilage degeneration. At each iteration, the pipeline solves the finite element model, extracts cartilage stress outputs, computes cumulative mechanical damage, runs the inflammation model element by element, and writes updated cartilage material properties back to the finite element input for the next iteration.

## Method

![Schematic of the integrative multi-scale framework of knee joint degeneration in mechanics and inflammation](https://raw.githubusercontent.com/JuntongLai/MCD-OA/main/assets/framework_schematic.jpg)

**Figure 1.** Integrative multi-scale framework of knee joint degeneration in mechanics and inflammation. Adapted from Lai and Lacroix (2026), *Biomechanics and Modeling in Mechanobiology* **25**, 55, under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

The framework operates across:

- **Mechanical responses.** Abaqus solves a subject-specific finite element knee model, and the primary mechanical output used by the coupling algorithm is element-wise maximum principal stress in the cartilage regions: femoral cartilage (`PT_FCART`), lateral tibial cartilage (`PT_TCART_LAT`), and medial tibial cartilage (`PT_TCART_MED`).

- **Inflammatory activities.** MATLAB solves an ODE model with state variables for pro-inflammatory cytokines (PICs), anti-inflammatory cytokines (AICs), matrix metalloproteinases (MMPs), adipokines, and fibronectin fragments (Fn-fs). Body mass index (BMI), physical activity level (PAL), energy intake, and mechanical damage influence the inflammatory response.

- **Mechano-biological coupling.** Stresses above the prescribed damage threshold increase the cumulative mechanical damage level. This damage term drives the inflammatory model, and the resulting Fn-fs concentration is mapped to updated cartilage material properties.

Details on the methodology can be found in the associated paper, Lai and Lacroix (2026), *Biomechanics and Modeling in Mechanobiology* **25**, 55 ([https://doi.org/10.1007/s10237-026-02072-8](https://doi.org/10.1007/s10237-026-02072-8)).

## MCD-OA Layout

```text
MCD-OA/
|-- MasterRun.m
|-- GenArgumentMat.m
|-- Gen_initialCon_infla.m
|-- Lib_Algorithms/
|   |-- CalculateArsDamage.m
|   |-- IDLAlgori.m
|   |-- MDLAlogri.m
|   `-- MechanoBioAlgori.m
|-- Lib_mCodes/
|   |-- Initiation.m
|   `-- ODEsOfInflammation.m
|-- Lib_pyCodes/
|   |-- UpdateINP.py
|   `-- abaqusReadODB.py
|-- Raw_initialconditions/
|-- Raw_inpfile/
|-- LICENSE
`-- README.md
```

`Raw_initialconditions/` and `Raw_inpfile/` are intentionally prepared as input locations. The Abaqus `.inp` model is not included in this repository. The inflammatory initial-condition file at iteration 1 can be generated from `Gen_initialCon_infla.m` based on the initial parameters `PipelineArguments.mat` as an output from `GenArgumentMat.m`. `Raw_initialconditions/` will also be the place to save inflammatory mediator concentrations for each iteration.

## Requirements

| Component                         | Version or note                                                        |
| --------------------------------- | ---------------------------------------------------------------------- |
| MATLAB                            | Developed with MATLAB R2022a                                           |
| MATLAB Parallel Computing Toolbox | Required for element-wise ODE solving                                  |
| Abaqus                            | Developed with Abaqus 2021                                             |
| Python                            | Abaqus embedded Python; no external Python packages are required       |
| Operating environment             | Local workstation or HPC environment                                   |

The workflow assumes that the `abaqus` command can be called from the shell used by MATLAB, so that the solver can be launched directly from the pipeline. Abaqus licensing, solver configuration, and any HPC scheduler setup are environment-specific and must be configured outside this repository. This framework was developed and run on the University of Sheffield [Stanage HPC cluster](https://docs.hpc.shef.ac.uk/en/latest/stanage/cluster_specs.html).

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/JuntongLai/MCD-OA.git
cd MCD-OA
```

A zip archive and a manual download of the most recent tagged release are also available from the [latest release](https://github.com/JuntongLai/MCD-OA/releases/latest) page.

Open MATLAB with the repository root as the working directory.

### 2. Create the parameter file

Run [GenArgumentMat.m](GenArgumentMat.m) to generate `PipelineArguments.mat`.

```matlab
GenArgumentMat({'S', 'maxprincipal'}, 'Dthreshold', 0.3, 25);
```

The arguments are:

| Argument             | Meaning                                                                                       |
| -------------------- | --------------------------------------------------------------------------------------------- |
| `ps_mechanicalvar` | Abaqus field output root and component, for example `{'S', 'maxprincipal'}`                 |
| `psname`           | Parameter to override for one-at-a-time sensitivity analysis, recognised values are `Dthreshold`, `r_localDamage`, and `F_max` |
| `ps_argument`      | Replacement value for the selected parameter                                                  |
| `subject_argument` | Subject body mass index                                                                       |

To change parameters not exposed through `psname`, edit the default values in [GenArgumentMat.m](GenArgumentMat.m).

### 3. Generate baseline inflammatory initial conditions

After creating `PipelineArguments.mat`, run:

```matlab
Gen_initialCon_infla
```

This writes `Raw_initialconditions/ic_sim_inflammation.txt`, which seeds the first coupled iteration.

### 4. Add the finite element input model

Place the subject-specific Abaqus input file at:

```text
Raw_inpfile/iter_1.inp
```

The file must contain material definitions for the cartilage regions that will be updated by the pipeline. The default cartilage set names are `PT_FCART`, `PT_TCART_LAT`, and `PT_TCART_MED`.

### 5. Run the coupled simulation

Call [MasterRun.m](MasterRun.m) with the number of CPU cores to use:

```matlab
MasterRun(8)
```

The same core count is passed to Abaqus and to the MATLAB parallel pool used for the ODE solve. Each complete run performs 60 iterations by default.

## Configuration

Default parameters are defined in [GenArgumentMat.m](GenArgumentMat.m), more details can be found in the associated paper, Lai and Lacroix (2026), *Biomechanics and Modeling in Mechanobiology* **25**, 55 ([https://doi.org/10.1007/s10237-026-02072-8](https://doi.org/10.1007/s10237-026-02072-8)).

| Parameter              | Description                                                  |
| ---------------------- | ------------------------------------------------------------ |
| `input_BMI_meas`       | Body mass index in kg/m^2                                    |
| `input_PAL`            | Physical activity level                                      |
| `input_intakeOfEnergy` | Energy intake                                                |
| `tspan`                | ODE integration span for each monthly iteration              |
| `Dthreshold`           | Stress threshold for mechanical damage                       |
| `r_localDamage`        | Mechanical damage exponent                                   |
| `E_AC`                 | Baseline cartilage Young's modulus                           |
| `permeability_AC`      | Baseline cartilage permeability                              |
| `omega_e`              | Maximum fractional decrease in Young's modulus               |
| `omega_k`              | Maximum fractional increase in permeability                  |
| `F_max`                | Fn-fs level associated with full degeneration |

## Outputs

Each iteration creates a numbered working directory:

```text
N_iteration/
|-- 1_FEsim/
`-- 2_MechanobioCoupling/
    |-- 1_Fieldoutputs/
    |-- 2_MDL/
    `-- 3_IDL/
```

The top-level archive folders created during a run are:

```text
Raw_ODBfile/
Raw_fieldoutputs/
Raw_MDL/
Raw_materialproperty/
Raw_initialconditions/
```

These folders contain Abaqus output databases, extracted field outputs, cumulative mechanical damage levels, updated material properties, and inflammatory mediator concentrations from each iteration.

## Notes for New Environments

[MasterRun.m](MasterRun.m) ends by submitting `MasterRunPostprocess.slurm` through `sbatch`. That reflects the HPC environment used during development. For local workstations or non-Slurm clusters, provide an equivalent post-processing script or remove/adapt the final `sbatch` command.

The repository contains workflow code and helper directories. It does not bundle a validated Abaqus knee model, subject data, Abaqus license access, or cluster configuration.

## Citation

If you use this code in your research, please cite:

Lai, J. and Lacroix, D. A novel integrative multi-scale framework of inflammation and mechanical loading in knee osteoarthritis. *Biomech Model Mechanobiol* **25**, 55 (2026). [https://doi.org/10.1007/s10237-026-02072-8](https://doi.org/10.1007/s10237-026-02072-8)

```bibtex
@article{Lai2026MCDOA,
  author  = {Lai, Juntong and Lacroix, Damien},
  title   = {A novel integrative multi-scale framework of inflammation and mechanical loading in knee osteoarthritis},
  journal = {Biomechanics and Modeling in Mechanobiology},
  volume  = {25},
  pages   = {55},
  year    = {2026},
  doi     = {10.1007/s10237-026-02072-8}
}
```

## Related Publications

- Lai, J. and Lacroix, D. Mathematical modelling of inflammatory process and obesity in osteoarthritis. *PLOS ONE* **20**(6): e0323258 (2025). [https://doi.org/10.1371/journal.pone.0323258](https://doi.org/10.1371/journal.pone.0323258)
- Lai, J. and Lacroix, D. A computational study of adiposity-associated factors in the inflammatory process of osteoarthritis. *Journal of Theoretical Biology* **625**, 112429 (2026). [https://doi.org/10.1016/j.jtbi.2026.112429](https://doi.org/10.1016/j.jtbi.2026.112429)

## Acknowledgements

This work was conducted at the Insigneo Institute for in silico Medicine and the School of Mechanical, Aerospace and Civil Engineering, University of Sheffield, UK. The subject-specific finite element model was modified from the validated model by Cooper et al. (2023), using data collected as part of the Institute of Medical and Biological Engineering Knee Dataset, University of Leeds.

## Funding

This work was supported by the studentship from the UK Engineering and Physical Sciences Research Council [EP/W524360/1/2747654].

## License

This project is distributed under the GNU General Public License v3.0. See [LICENSE](LICENSE) for the full license text.
