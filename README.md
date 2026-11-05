# PROST Toolbox

**PROST** (Public ROS Toolbox) is an open-source MATLAB toolbox for computing the ankle-foot **roll-over shape (ROS)**. The ROS is the sagittal-plane path of the centre of pressure (CoP) during the stance phase of walking, expressed in a shank-based coordinate system.

PROST works from four public gait datasets collected in independent laboratories. It harmonises their marker trajectories, ground reaction forces, and CoP data into a common representation: 249 participants and 5,667 stance phases. For each participant leg, it fits a circular arc to the pooled ROS of all that leg's stance phases. The arc parameters are the radius, centre, start and end angles, and arc length. They form a leg-level individual participant data (IPD) table, which the toolbox uses for a one-stage IPD meta-analysis with linear mixed-effects models.

The methodology is described in the accompanying paper (see [Citation](#citation)).

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Getting the Data](#getting-the-data)
- [Quick Start](#quick-start)
- [Pipeline](#pipeline)
- [Core Components](#core-components)
- [Usage Examples](#usage-examples)
- [Project Structure](#project-structure)
- [Main Functions](#main-functions)
- [Utilities](#utilities)
- [Testing](#testing)
- [Data Sources and Licenses](#data-sources-and-licenses)
- [Third-Party Code](#third-party-code)
- [Citation](#citation)
- [License](#license)
- [Support and Contributing](#support-and-contributing)

## Features

- **Multi-Dataset Integration**: Pool gait biomechanics data from multiple publicly available datasets.
- **Data Harmonization**: Standardize dataset-specific variables, marker definitions, and measurements into a common spatial and temporal representation ([DATASET_FORMAT.md](DATASET_FORMAT.md)).
- **ROS Computation**: Compute right and left roll-over shapes for each participant.
- **Circular Arc Fitting**: Fit a circular arc to each leg's ROS (radius, centre, start/end angles, arc length, RMS radial residual).
- **IPD Meta-Analysis**: Linear mixed-effects models relating arc parameters to anthropometrics across the pooled datasets (`+PROST/+lme`).
- **Statistical Analysis**: Distribution fitting, correlation analysis (Pearson and Spearman, Wilcoxon rank-sum for categorical predictors), goodness-of-fit testing, and cluster bootstrap.
- **Data Cleaning**: A curated exclusion list plus automatic detection of invalid steps. Excluded data are flagged, never deleted.
- **Visualization**: Plotting functions for ROS, CoP trajectories, predictor–response relationships, distributions, and walking speeds.

## Installation

### Requirements

- MATLAB R2024b or later (developed with R2024b)
- Optimization Toolbox™ (circular-arc fit)
- Statistics and Machine Learning Toolbox™ (mixed-effects models, distribution fitting, bootstrap)
- Signal Processing Toolbox™ (only needed to rebuild Dataset 4)
- [Git LFS](https://git-lfs.com) (to download `PROSTAnalyzer.mat`)

Rebuilding Datasets 2 and 4 from C3D files uses the bundled ezc3d MEX files. These are Windows-only (`.mexw64`). See [Third-Party Code](#third-party-code).

### Setup

1. Clone the repository and fetch the Git LFS files:

   ```bash
   git clone https://github.com/SolavLab/PROST.git
   cd PROST
   git lfs install
   git lfs pull
   ```

   The repository includes several GB of source data, so cloning takes a while.

2. Add the repository root to the MATLAB path. The `+PROST` package only needs its parent folder on the path, so `genpath` is not required:

   ```matlab
   addpath('path/to/PROST');
   ```

   The top-level scripts add the path and `cd` to the toolbox root themselves.

## Getting the Data

There are two starting points.

- **Reproduce the analyses from the saved analyzer.** `PROSTAnalyzer.mat` (~115 MB, Git LFS) holds the fully built, cleaned, and fitted `PROSTAnalyzer` object. After `git lfs pull`, the analysis scripts run directly from it.
- **Rebuild from the source data.** The built `example_datasets/Dataset_N.mat` files are not distributed. Build them with the scripts in `example_datasets/DatasetN/`, following [example_datasets/README.md](example_datasets/README.md), and then run `Create_PROST`. For **Datasets 2 and 4**, run `convert_c3d_to_mat.m` before `build_Dataset_N.m`.

## Quick Start

### From the saved analyzer

```matlab
Plot_PROST                        % figures (loads PROSTAnalyzer.mat if not in the workspace)
Radius_Mixed_Effects_Model        % LME analysis of the arc radius
Center_Mixed_Effects_Model        % LME analysis of the horizontal arc centre
Distribution_By_Dataset           % per-dataset distributions
Count_Valid_Participants_Steps    % cohort counts
```

### From the built datasets

```matlab
Create_PROST   % loads example_datasets/Dataset_N.mat, cleans, fits, and saves PROSTAnalyzer.mat
```

`Create_PROST` refits every leg, so it is slow. It also holds the curated exclusion list, with a reason recorded for each entry. Note that it overwrites `PROSTAnalyzer.mat`.

The scripts start with `clearvars -except ...` so that `Dataset_N` and `PROSTAnalyzer` stay in the workspace, and re-running them skips the expensive loads.

## Pipeline

1. **Build**: `example_datasets/DatasetN/build_Dataset_N.m` converts each published source dataset into a `Dataset_N.mat` struct ([DATASET_FORMAT.md](DATASET_FORMAT.md)).
2. **Ingest**: `PROST.PROSTAnalyzer(load_list, toolbox_root)` copies each participant into `DataRecords`. It transforms every step's CoP into the shank frame and builds `SummaryTable`.
3. **Clean**: `clean_data` applies an exclusion list (`PROSTDatasetList`) and flags "toe-to-heel" steps, where the shank-frame CoP runs backwards. Nothing is deleted. Participants, sides, and steps carry cascading `Is_included` flags.
4. **Fit**: `create_IPD_table` fits a circular arc to each leg's pooled point cloud. The first and last 15 of the 101 time-normalized samples of every step are discarded. The fit uses Coope's linear least squares for the initial guess, then `fminunc` on the squared radial residuals. The result is one `IPDTable` row per leg.
5. **Analyze and plot**: the plotting methods, the analysis scripts, and the `+PROST/+lme` package.

### Units

| Quantity | Unit |
|---|---|
| Anthropometrics (height, mass, segment lengths, age) | m, kg, years |
| CoP, markers, fitted radius / centre / residual | mm |
| Angles | degrees |

Use `PROST.utils.convert_units` for cross-unit work, e.g. when normalizing the radius by height.

## Core Components

### PROSTAnalyzer Class

The main analysis class, `+PROST/@PROSTAnalyzer/PROSTAnalyzer.m`. It is a `handle` class.

**Key Properties:**
- `DataRecords`: All dataset, participant, and step data, including the derived shank-frame CoP (`Shank_cop`) and `Is_included` flags.
- `IPDTable`: Leg-level table of anthropometrics and fitted arc parameters. It is over-allocated, so use rows `1:IPDTableSize`.
- `SummaryTable`: Dataset-level cohort summary. Use rows `1:SummaryTableSize`.
- `IgnoreObject`: A `PROSTDatasetList` of excluded participants and trials.

`IPDTable` columns are tagged `'predictor'` or `'response'` in `Properties.VariableDescriptions`. `get_predictors` and `get_responses` select columns by these tags.

Shank-frame CoP is computed for the lateral anatomical side only. `plot_cop` is the exception: it recomputes from the raw markers.

### PROSTDatasetList Class

Holds lists of datasets, participants, trials, and sides. It is used for exclusion lists, and `NaN` in a trial list means "all trials".

### Error Handling

`PROSTError` and `PROSTWarning` use IDs of the form `PROSTAnalyzer:<Property>:<Code>`. `PROSTWarning.asError`, `off`, and `on` promote or silence one specific warning.

## Usage Examples

### Example 1: Build an Analyzer and Fit Distributions

```matlab
toolbox_root = 'path/to/PROST';
load(fullfile(toolbox_root, 'example_datasets', 'Dataset_1.mat'))   % built locally
load(fullfile(toolbox_root, 'example_datasets', 'Dataset_2.mat'))

% Each row pairs an in-memory dataset struct with a name, in either order
load_list = {Dataset_1, "Dataset 1"; Dataset_2, "Dataset 2"};
analyzer = PROST.PROSTAnalyzer(load_list, toolbox_root);

analyzer.clean_data();          % automatic bad-step detection; pass a PROSTDatasetList to exclude more
analyzer.create_IPD_table();    % fit one circular arc per leg

responses = analyzer.get_responses("Radius");   % table with the Radius column
stats = analyzer.analyze_stats(responses.Radius, ["normal", "lognormal", "gamma"]);
```

### Example 2: Correlations and Plots

```matlab
predictors = analyzer.get_predictors(["Height" "Mass"]);
correlations = analyzer.compute_correlations(predictors, responses);

analyzer.plot_predictors_vs_responses(["Height" "Mass"], "Radius", ...
    show="on", file_type=["pdf" "svg"]);
```

## Project Structure

```
PROST/
├── Create_PROST.m                    # Build, clean, fit, save PROSTAnalyzer.mat
├── Plot_PROST.m                      # Figures from PROSTAnalyzer.mat
├── Radius_Mixed_Effects_Model.m      # LME analysis: arc radius
├── Center_Mixed_Effects_Model.m      # LME analysis: horizontal arc centre
├── Distribution_By_Dataset.m         # Per-dataset distributions
├── Count_Valid_Participants_Steps.m  # Cohort counts
├── PROSTAnalyzer.mat                 # Saved analyzer (Git LFS)
├── *_Results.mat                     # Saved analysis results
├── DATASET_FORMAT.md                 # Structure of Dataset_N.mat
├── CITATION.cff
├── +PROST/
│   ├── PROSTDatasetList.m
│   ├── PROSTError.m
│   ├── PROSTWarning.m
│   ├── @PROSTAnalyzer/               # Analyzer class: public methods + private/
│   ├── +lme/                         # Mixed-effects models, ICC, diagnostics, bootstrap
│   ├── +utils/                       # Utility functions
│   └── +tests/                       # Toolbox tests
├── example_datasets/
│   ├── README.md                     # Sources, licenses, build steps
│   ├── Dataset1/ … Dataset4/         # Source data, build scripts, tests/
│   └── Dataset_N.mat                 # Built locally (gitignored)
├── figures/                          # Saved figures
└── lib-ext/
    └── ezc3d_matlab/                 # Third-party C3D reader (MIT)
```

## Main Functions

All methods belong to `PROSTAnalyzer`. Run `help PROST.PROSTAnalyzer.<method>` for the full signature.

### Analysis Methods

| Function | Purpose |
|----------|---------|
| `clean_data(ignore_list, BadSteps=true)` | Apply an exclusion list and automatic bad-step detection |
| `create_IPD_table()` | Fit circular arcs and build the leg-level IPD table |
| `analyze_stats(value, distnames, ...)` | Fit distributions, compute AIC/BIC/log-likelihood and goodness of fit |
| `compute_correlations(predictors, responses)` | Pearson, Spearman, R²; Wilcoxon rank-sum for categorical predictors |

### Geometric Methods (static)

| Function | Purpose |
|----------|---------|
| `convert_to_shank_frame(data, knee, ankle)` | Transform lab-frame points into the shank coordinate system |
| `cop_to_shank_frame(step, anatomical_side)` | Shank-frame CoP of one step |

### Plotting Methods

| Function | Purpose |
|----------|---------|
| `plot_ros()` | Plot roll-over shapes and fitted circular arcs |
| `plot_cop()` | Plot CoP trajectories in the lab and shank frames |
| `plot_predictors_vs_responses()` | Scatter plots with trend lines and correlations |
| `plot_stats()` | Distributions, fitted densities, and Q–Q plots |
| `plot_speed_distribution()` | Histograms of measured walking speed per dataset, optionally split by speed condition |

Plotters take name-value options (`arguments` blocks). They share the save options `show`, `append`, `overwrite`, `file_type` (a list such as `["pdf" "svg" "jpeg" "fig"]`), `prepare`, and `prepare_options`.

### Data Access Methods

| Function | Purpose |
|----------|---------|
| `get_dataset(dataset_id)` | Copy of a dataset's record (read-only use) |
| `get_dataset_name(dataset_id)` | Name of a dataset |
| `get_good_steps(steps, min_speed)` | Included steps (static) |
| `get_IPD_samples(var_list, ...)` | Samples from the IPD table |
| `get_step_speeds(dataset_ids)` | Measured walking speed of every included step |
| `get_predictors(list)` | Predictor columns of the IPD table |
| `get_responses(list)` | Response columns of the IPD table |

### Data Management Methods

| Function | Purpose |
|----------|---------|
| `add_dataset(dataset_name, dataset)` | Add a dataset |
| `delete_dataset(dataset_id)` | Remove a dataset |
| `set_dataset(dataset_id, dataset)`, `set_dataset_name(dataset_id, name)` | Replace a dataset or rename it |
| `add_to_ignore(...)`, `delete_from_ignore(...)`, `is_ignored(...)` | Manage the exclusion list |
| `dataset_exists`, `participant_exists`, `is_in_IPD_table`, `has_medial` | Queries |

## Utilities

`+PROST/+utils/`:

- **`capitalize`**: Capitalize strings
- **`convert_units`**: Unit conversion (m, cm, mm, etc.)
- **`diffp`**: Padded numerical differentiation
- **`estimate_foot_length`**: Estimate foot length from step data
- **`find_index_from_value`**: Find array indices matching values
- **`get_knee_marker`**: Construct a virtual knee marker
- **`winsorize`**: Winsorization of outliers
- **`cluster_bootstrap`**, **`cluster_resample`**, **`boot_stream`**: Cluster (participant-level) bootstrap with reproducible random streams
- **`provenance`**: Record code and data provenance of saved results
- **`pretty_print`**: Formatted console output
- **`save_figure`**, **`save_all_open_figures`**, **`prep_figure_for_publish`**: Figure export

`+PROST/+lme/` contains the mixed-effects analysis used by `Radius_Mixed_Effects_Model.m` and `Center_Mixed_Effects_Model.m`. That covers model fitting, covariate models, ICC (overall, per dataset, leave-one-out), assumption and normality checks, and bootstrap confidence intervals.

## Testing

Tests are MATLAB scripts with `assert` statements, not `matlab.unittest` classes.

```matlab
% Requires the built Dataset_N.mat files
runtests('+PROST/+tests/test_PROSTAnalyzer.m')
```

- `+PROST/+tests/test_PROSTAnalyzer.m`: analyzer functionality.
- `+PROST/+tests/test_ROS_calculation.m`: visual diagnostic, with no assertions.
- `example_datasets/DatasetN/tests/`: per-dataset validation of the build output (axis directions, gait events, metadata linkage).

## Data Sources and Licenses

PROST uses four publicly available datasets. Full references and build steps are in [example_datasets/README.md](example_datasets/README.md).

| Dataset | Source publication | License of source data |
|---|---|---|
| 1 | Moreira et al. (2021), *Sci Data*, [doi:10.1038/s41597-021-00881-3](https://doi.org/10.1038/s41597-021-00881-3) | CC0 1.0 |
| 2 | Schreiber & Moissenet (2019), *Sci Data*, [doi:10.1038/s41597-019-0124-4](https://doi.org/10.1038/s41597-019-0124-4) | CC BY 4.0 |
| 3 | Lencioni et al. (2019), *Sci Data*, [doi:10.1038/s41597-019-0323-z](https://doi.org/10.1038/s41597-019-0323-z) | CC0 1.0 |
| 4 | Van Criekinge et al. (2023), *Sci Data*, [doi:10.1038/s41597-023-02767-y](https://doi.org/10.1038/s41597-023-02767-y) | CC0 1.0 |

Source data files remain under their original licenses. The PROST code license does not apply to them. If you use these data, please cite the original publications.

## Third-Party Code

[lib-ext/ezc3d_matlab/](lib-ext/ezc3d_matlab/) contains MATLAB binaries of [ezc3d](https://github.com/pyomeca/ezc3d) (pyomeca), MIT License. It is used only to convert C3D files for Datasets 2 and 4. See its [LICENSE](lib-ext/ezc3d_matlab/LICENSE).

## Citation

If you use PROST, please cite:

> Reichsbouscher C, Solav D. PROST: An Open Toolbox, Harmonised Multi-Lab Dataset, and Meta-Analysis of Ankle-Foot Roll-Over Shape. *Journal TODO*, year TODO. doi:TODO

<!-- TODO: add the Zenodo DOI of the release -->
For the software version, use the metadata in [CITATION.cff](CITATION.cff). GitHub shows it under "Cite this repository".

## License

- **Code**: GNU General Public License v3.0 or later (GPL-3.0-or-later). See [LICENSE](LICENSE). Copyright (c) 2026 SoBIG - Technion.
- **Derived data** (`PROSTAnalyzer.mat`, `*_Results.mat`): [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
- **Source datasets**: their original licenses. See [Data Sources and Licenses](#data-sources-and-licenses).
- **Third-party code** (`lib-ext/`): its own license. See [Third-Party Code](#third-party-code).

## Support and Contributing

- Bug reports and questions: [GitHub Issues](https://github.com/SolavLab/PROST/issues).
- Contributions are welcome. Please open an issue to discuss a change before submitting a pull request.

## Version History

- **v1.0.0**: Initial public release.
