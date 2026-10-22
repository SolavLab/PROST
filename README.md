# PROST Toolbox

**PROST** is an open-source MATLAB toolbox for pooling gait biomechanics data from multiple publicly available datasets, computing roll-over shapes (ROS), fitting circular arc parameters, and analyzing their relationships with anthropometric variables. The toolbox preprocesses raw individual-level walking trials, harmonizes dataset-specific variables and marker definitions, standardizes measurements into a common spatial and temporal representation, and pools data into a unified database. It then computes right and left ROS for each participant, estimates corresponding circular arc parameters, and enables individual participant data (IPD) meta-analysis.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Core Components](#core-components)
- [Usage Examples](#usage-examples)
- [Project Structure](#project-structure)
- [Main Functions](#main-functions)
- [Utilities](#utilities)
- [Testing](#testing)

## Features

- **Multi-Dataset Integration**: Pool gait biomechanics data from multiple publicly available datasets
- **Data Harmonization**: Standardize dataset-specific variables, marker definitions, and measurements into a common spatial and temporal representation
- **ROS Computation**: Calculate right and left roll-over shapes (ROS) for each participant
- **Circular Arc Fitting**: Estimate circular arc parameters for gait analysis
- **Individual Participant Data (IPD) Meta-Analysis**: Analyze relationships between ROS/arc parameters and anthropometric variables across pooled datasets
- **Statistical Analysis**: Distribution fitting, correlation analysis (Pearson & Spearman), and goodness-of-fit testing
- **Data Cleaning**: Automatic detection and handling of invalid/ignored participant data
- **Visualization**: Comprehensive plotting functions for ROS analysis, CoP trajectories, and correlations

## Installation

### Requirements

- MATLAB R2024b or later (developed using MATLAB R2024b)
- Statistics and Machine Learning Toolbox™
- Curve Fitting Toolbox™ (optional)

### Setup

1. Clone or download the PROST repository
2. Open MATLAB and navigate to the PROST root directory
3. Run the setup script or manually add the folder to your MATLAB path:

```matlab
addpath(genpath('path/to/PROST'));
```

## Quick Start

### 1. Load Example Datasets

Run the `Create_PROST.m` script to initialize the analysis:

```matlab
Create_PROST
```

This script will:
- Load or build four example datasets
- Create a `PROSTAnalyzer` object with all datasets
- Prepare the data for analysis

### 2. Perform Analysis

The `PROSTAnalyzer` object provides methods for:
- Computing statistics and distributions
- Analyzing correlations between predictors and responses
- Generating visualizations

### 3. Generate Plots

Run `Plot_PROST.m` to generate comprehensive analysis plots:

```matlab
Plot_PROST
```

## Core Components

### PROSTAnalyzer Class

The main analysis class located at `+PROST/@PROSTAnalyzer/PROSTAnalyzer.m`.

**Key Properties:**
- `DataRecords`: Stores all dataset information
- `IPDTable`: Unified table of all participant data (Individual Participant Data)
- `SummaryTable`: Summary information for each dataset
- `IgnoreObject`: List of participants/trials to exclude from analysis

**Key Methods:**
- `add_dataset()`: Add a new dataset to DataRecords
- `clean_data()`: Remove or flag invalid data
- `create_IPD_table()`: Build unified data table across datasets
- `compute_correlations()`: Calculate correlation coefficients
- `analyze_stats()`: Fit distributions and compute goodness-of-fit metrics
- `plot_ros()`: Visualize roll-over shapes (ROS)
- `plot_cop()`: Plot center of pressure trajectories
- `plot_predictors_vs_responses()`: Scatter plots of predictor-response relationships
- `plot_stats()`: Display statistical summaries
- `plot_speed_distribution()`: Histograms of measured walking speed per dataset and speed condition

### PROSTDatasetList Class

Manages lists of datasets or ignored participants. Used for filtering and selective analysis.

### Error Handling

- `PROSTError`: Custom error class for toolbox-specific errors
- `PROSTWarning`: Custom warning class for toolbox-specific warnings

## Usage Examples

### Example 1: Load and Analyze a Dataset

```matlab
% Create PROSTAnalyzer with datasets
load_list = {Dataset_1, "Dataset 1"; Dataset_2, "Dataset 2"};
analyzer = PROST.PROSTAnalyzer(load_list, pwd);

% Clean invalid data
analyzer.clean_data();

% Get response data and fit distributions to it
responses = analyzer.get_responses("Radius"); % Get all response variables from IPD table
radius = responses.Radius;
stats = analyzer.analyze_stats(radius, ["normal", "lognormal", "gamma"]);
```

### Example 2: Compute and Plot Correlations

```matlab
% Compute correlations
predictors = analyzer.get_responses("Radius"); % Get radius predictor variables from IPD table
correlations = analyzer.compute_correlations(predictors, responses);

% Plot relationships
analyzer.plot_predictors_vs_responses(["Height" "Mass"], "Radius", ...
    'show', 'on', 'file_type', 'pdf');
```

## Project Structure

```
PROST/
├── Create_PROST.m                 # Main setup script
├── Plot_PROST.m                   # Plotting script
├── Count_Valid_Participants_Steps.m
├── +PROST/                        # Main package namespace
│   ├── PROSTDatasetList.m         # Dataset list class
│   ├── PROSTError.m               # Error class
│   ├── PROSTWarning.m             # Warning class
│   ├── @PROSTAnalyzer/            # Main analyzer class
│   │   ├── PROSTAnalyzer.m        # Class definition
│   │   ├── add_dataset.m
│   │   ├── clean_data.m
│   │   ├── compute_correlations.m
│   │   ├── analyze_stats.m
│   │   ├── convert_to_shank_frame.m
│   │   ├── plot_ros.m
│   │   ├── plot_cop.m
│   │   ├── plot_predictors_vs_responses.m
│   │   ├── plot_stats.m
│   │   ├── plot_speed_distribution.m
│   │   ├── create_IPD_table.m
│   │   └── private/               # Private methods
│   ├── +utils/                    # Utility functions
│   │   ├── convert_units.m
│   │   ├── estimate_foot_length.m
│   │   ├── find_index_from_value.m
│   │   ├── winsorize.m
│   │   └── ...
│   └── +tests/                    # Unit tests
│       ├── test_PROSTAnalyzer.m
│       ├── test_ROS_calculation.m
│       └── ...
├── example_datasets/              # Example data
│   ├── Dataset_1.mat
│   ├── Dataset_2.mat
│   ├── Dataset1/                  # Dataset source and build scripts
│   ├── Dataset2/
│   ├── Dataset3/
│   └── Dataset4/
├── figures/                       # Output figures
│   ├── ROS Analysis/
│   ├── Predictors vs Responses/
│   └── Speeds/
└── lib-ext/                       # External libraries
    └── ezc3d_matlab/              # C3D file processing
```

## Main Functions

### Analysis Methods

| Function | Purpose |
|----------|---------|
| `analyze_stats()` | Fit distributions, compute AIC/BIC/log-likelihood |
| `compute_correlations()` | Calculate Pearson and Spearman correlations |
| `create_IPD_table()` | Build unified participant data table |
| `clean_data()` | Remove or flag invalid participants/trials |

### Geometric/Kinematic Methods

| Function | Purpose |
|----------|---------|
| `convert_to_shank_frame()` | Transform CoP to shank-relative coordinate system |
| `cop_to_shank_frame()` | Convert center of pressure measurements |

### Plotting Methods

| Function | Purpose |
|----------|---------|
| `plot_ros()` | Visualize range of oscillation data |
| `plot_cop()` | Plot center of pressure trajectories |
| `plot_predictors_vs_responses()` | Scatter plots with trend lines |
| `plot_stats()` | Display statistical summaries and distributions |
| `plot_speed_distribution()` | Histograms of measured walking speed per dataset, optionally split by speed condition with nominal-speed marks |

### Data Access Methods

| Function | Purpose |
|----------|---------|
| `get_dataset()` | Retrieve dataset by ID |
| `get_dataset_name()` | Get name of a dataset |
| `get_good_steps()` | Retrieve valid/clean steps |
| `get_IPD_samples()` | Extract samples from IPD table |
| `get_step_speeds()` | Measured walking speed of every valid step |
| `get_predictors()` | Get predictor variables |
| `get_responses()` | Get response variables |

## Utilities

The `+utils/` package provides helper functions:

- **`capitalize.m`**: Convert strings to title case
- **`convert_units.m`**: Unit conversion (m, cm, mm, etc.)
- **`diffp.m`**: Differentiation/numerical derivatives
- **`estimate_foot_length.m`**: Estimate foot dimensions
- **`find_index_from_value.m`**: Find array indices matching values
- **`winsorize.m`**: Winsorization of outliers
- **`pretty_print.m`**: Formatted console output
- **`save_figure.m`**: Save figures with consistent formatting

## Testing

Run unit tests to verify toolbox functionality:

```matlab
% Run all tests
runtests('+PROST/+tests')

% Run specific test
runtests('+PROST/+tests/test_PROSTAnalyzer.m')
```

**Available Tests:**
- `test_PROSTAnalyzer.m`: Main analyzer functionality
- `test_ROS_calculation.m`: ROS computation accuracy
- `test_filter_DB.m`: Data filtering
- `test_speeds_of_DB.m`: Speed calculations

## Citation

If you use PROST in your research, please cite:

```
PROST Toolbox (2026)
Author: Chen Reichsbouscher
```

## License

[Include your license information here]

## Support & Issues

For bug reports, feature requests, or questions:
- Check existing documentation in the source code
- Review example scripts: `Create_PROST.m`, `Plot_PROST.m`
- Run unit tests to verify installation

## Version History

- **v1.0** (Current): Initial release with ROS analysis, CoP tracking, and statistical tools

---

**Last Updated**: June 2026
