# PROST Dataset MAT-File Format

Reference documentation for the structure shared by `Dataset_1.mat`, `Dataset_2.mat`, `Dataset_3.mat`, and `Dataset_4.mat` in [example_datasets/](example_datasets/).

Each MAT file contains one top-level MATLAB variable — `Dataset_1`, `Dataset_2`, `Dataset_3`, or `Dataset_4` — whose name matches the file. These files are the output of the per-dataset build scripts (`example_datasets/Dataset<N>/build_Dataset_<N>.m`) and the input to `PROST.PROSTAnalyzer`.

Each file stores dataset provenance and acquisition metadata at the root, participant metadata and source-preserving processed trials under `Data`, and a normalized right/left step database whose records retain links back to the dataset-specific original trial representation.

## Contents

- [Top-level structure](#top-level-structure)
- [Dataset-level branches](#dataset-level-branches)
- [Participant structure](#participant-structure)
- [`uniform_data`: the analysis-ready branch](#uniform_data-the-analysis-ready-branch)
- [`processed_original_data`: the source-fidelity branch](#processed_original_data-the-source-fidelity-branch)
- [Dataset-specific differences](#dataset-specific-differences)

## Top-level structure

```text
Dataset_N
|-- Article_data
|-- Markers_guide
|-- Lab_system
|-- Experiment_protocol
`-- Data
    `-- participant_#                 repeated for each participant
        |-- participant_ID_in_original_structure
        |-- metadata
        |-- uniform_data
        |   |-- right
        |   |   `-- step(#)            zero or more right-foot steps
        |   `-- left
        |       `-- step(#)            zero or more left-foot steps
        `-- processed_original_data
            `-- trial(#)               dataset-specific original-trial representation
```

The two data paths through a participant are:

- `Dataset_N` → `Data` → `participant_#` → `uniform_data` → `right`/`left` → `step(#)` — the harmonized, cross-dataset representation used for analysis.
- `Dataset_N` → `Data` → `participant_#` → `processed_original_data` → `trial(#)` — the source-oriented representation, retained for fidelity and traceability.

Each uniform step links back to its origin: `uniform_data.<side>.step(#).source` identifies the corresponding trial and step in `processed_original_data`.

`Data` is a MATLAB structure whose participant names are dynamic fields (`participant_1`, `participant_2`, …). A participant is therefore a named structure, not a row in a fixed numeric table.

## Dataset-level branches

### `Article_data`

Provenance and publication information. Fields used by PROST:

```text
Article_data
|-- article_name
|-- authors
|-- published_year
|-- link_to_paper
`-- link_to_dataset
```

### `Markers_guide`

Mapping between standardized PROST marker concepts and the marker names and indices used by the source dataset. It includes a `reference_guide` dictionary used to locate markers such as ankle, knee, ASIS, and other gait-analysis landmarks. The mapping is dataset-specific, and it is what allows the build scripts to extract equivalent markers from datasets with incompatible marker sets. Where a required marker is absent from the source, the guide may map it to a virtual marker computed from other markers.

### `Lab_system`

Laboratory and acquisition-system information, including the coordinate system and acquisition setup. The field read by PROST is:

```text
Lab_system.num_forceplates
```

### `Experiment_protocol`

Study and protocol information with aggregate counts:

```text
Experiment_protocol
|-- num_participants
|-- num_trials
|-- num_steps
|-- num_markers       present where relevant
`-- speed_categories  source speed/condition categories; representation varies
```

These are dataset-level summaries computed at build time. `num_steps` reflects the processed trials and the dataset's step definition — it is not necessarily the number of populated uniform step records after later filtering.

## Participant structure

### `participant_ID_in_original_structure`

The participant identifier from the source dataset, preserved even though the normalized PROST field name is `participant_#`. Use it when cross-referencing against the published dataset or its accompanying metadata spreadsheets.

### `metadata`

Participant characteristics and calculated anthropometrics. Each entry carries its own `unit` and `method`, so the provenance of a measurement — directly reported by the source versus derived by a build script — stays attached to the value.

```text
metadata
|-- Age
|   |-- value
|   |-- unit
|   `-- method
|-- Sex
|   |-- value
|   |-- unit
|   `-- method
|-- Height
|   |-- value
|   |-- unit
|   `-- method
|-- Mass
|   |-- value
|   |-- unit
|   `-- method
|-- Footwear_condition
|   |-- value
|   |-- unit
|   `-- method
|-- Leg_length
|   |-- right / left
|   |-- unit
|   `-- method
|-- Thigh_length
|   |-- right / left
|   |-- unit
|   `-- method
`-- Shank_length
    |-- right / left
    |-- unit
    `-- method
```

The segment lengths are stored per side rather than as a single `value`. The exact fields and measurement methods vary slightly by source dataset, but all four saved datasets expose the fields above.

## `uniform_data`: the analysis-ready branch

`uniform_data` is the normalized representation used for cross-dataset analysis. It separates steps by walking side and stores each step as a repeated record:

```text
uniform_data
|-- right
|   `-- step(k)
|       |-- source
|       |-- COP
|       |-- GRF
|       |-- Markers
|       `-- speed
`-- left
    `-- step(k)
        |-- source
        |-- COP
        |-- GRF
        |-- Markers
        `-- speed
```

The `right` and `left` branches are parallel. A side may contain no steps, so `step` can be empty — participants may contribute left, right, or bilateral observations.

### Processing conventions

The uniform step records are analysis-ready rather than raw recordings:

- COP and marker trajectories span **IC to OIC** (initial contact to opposite initial contact), representing weight acceptance plus single support.
- GRF spans **IC to TO** (initial contact to toe-off), representing the stance phase.
- All signals are interpolated to **101 samples**, corresponding to 0–100 % of the relevant phase.
- Coordinates are transformed to `x` = walking direction, `y` = left of the body, `z` = up.
- Only steps classified as good at build time are added to `uniform_data`. Bad steps remain represented in `processed_original_data` but are skipped here.

### `step(k).source`: lineage back to the original trial

```text
source
|-- original_trial
|-- step_number
|-- plate_number
|-- original_IC
|   |-- forceplate_index
|   |-- trajectory_index
|   `-- time
|-- original_OIC
|   |-- forceplate_index
|   |-- trajectory_index
|   `-- time
`-- original_TO
    |-- forceplate_index
    |-- trajectory_index
    `-- time
```

`original_trial` identifies the source trial, `step_number` the step within that trial, and `plate_number` the force plate the step landed on. The three event records preserve the original initial contact (IC), opposite initial contact (OIC), and toe-off (TO) events in both the force-plate and trajectory time bases, plus their times — the force-plate and marker systems generally sample at different rates, so both indices are needed to return to the raw signals.

Dataset 1 stores the event indices explicitly under `forceplate_index` and `trajectory_index`; Datasets 2 and 4 copy the event records from their step-info structures.

### `step(k).COP`: normalized center of pressure

```text
COP
|-- x                  1 x 101 numeric vector, walking-direction coordinate
|-- y                  1 x 101 numeric vector, lateral coordinate
|-- z                  1 x 101 numeric vector, normally zeros in uniform data
|-- unit               "mm"
`-- temporal_alignment "Initial contact to opposite initial contact"
```

The source trial may contain one COP record per force plate; the uniform step keeps only the COP for the step's assigned plate, as the three coordinate vectors above.

### `step(k).GRF`: normalized ground-reaction force

```text
GRF
|-- x                  1 x 101 numeric vector, walking-direction force
|-- y                  1 x 101 numeric vector, lateral force
|-- z                  1 x 101 numeric vector, vertical force
|-- unit               "N"
|-- temporal_alignment "Initial contact to toe off (stance phase)"
`-- OIC
    |-- time           normalized sample/time location of OIC
    `-- index          normalized sample index of OIC
```

Because GRF uses a different temporal window than COP and Markers, `OIC` records where opposite initial contact falls within the normalized stance-phase record — this is what lets GRF be aligned against the IC-to-OIC signals. In the original trial branch, GRF may instead contain one `plate_#` structure per force plate plus sampling metadata.

### `step(k).Markers`: normalized marker trajectories

```text
Markers
|-- Ankle
|   |-- lateral
|   |   |-- x
|   |   |-- y
|   |   `-- z
|   |-- medial       present when the source has medial markers
|   |   |-- x
|   |   |-- y
|   |   `-- z
|   `-- mean         midpoint of lateral and medial markers when available
|       |-- x
|       |-- y
|       `-- z
|-- Knee
|   |-- lateral
|   |   |-- x
|   |   |-- y
|   |   `-- z
|   |-- medial       present when the source has medial markers
|   |   |-- x
|   |   |-- y
|   |   `-- z
|   `-- mean         midpoint of lateral and medial markers when available
|       |-- x
|       |-- y
|       `-- z
|-- unit               "mm"
`-- temporal_alignment "Initial contact to opposite initial contact"
```

Every populated coordinate is a 1 × 101 trajectory after coordinate transformation, IC-to-OIC cropping, and interpolation. The branches represent the stance-side ankle and knee — the two landmarks that define the shank coordinate system used for roll-over shape computation.

Marker availability differs by source:

- **Dataset 1** — lateral, medial, and calculated mean ankle and knee trajectories.
- **Datasets 2 and 4** — the marker set available in their source data; knees may be virtual markers.
- **Dataset 3** — lateral ankle and knee only; `medial` and `mean` are empty because medial markers are unavailable.

### `step(k).speed`

```text
speed
|-- value             estimated walking speed
|-- unit              "km/hour"
|-- method            description of the speed calculation and conversion
`-- speed_category    source speed condition/category
```

Speed is a property of the trial, and is copied into every normalized step originating from that trial. The numerical value and category convention vary by dataset.

## `processed_original_data`: the source-fidelity branch

Every participant has a `processed_original_data` field holding the source-oriented processed trial records. It preserves original trial context and supports lineage from the normalized steps.

This branch does **not** follow a universal schema — its contents are dataset-specific:

```text
processed_original_data
`-- trial(#)   dataset-specific processed original trial structure
```

Conceptually, a trial may include:

```text
trial(#)
|-- origin                 source trial/category identifiers
|-- step_#_info            events, foot, quality, and force-plate information
|-- GRF                    force-plate / ground-reaction-force data
|-- COP                    center-of-pressure data
|-- trajectories           marker trajectories
|-- walking_direction      direction and coordinate-system description
|-- speed                  trial speed with value/unit/method
|-- first_foot             present in some datasets
|-- Trajectory_Time        present in Dataset 3
`-- Forceplate_Time        present in Dataset 3
```

Treat that list as illustrative rather than a strict union schema. The exact trial fields, step count, naming, and timing representation differ by dataset. Inspect the actual structure — or the relevant `build_Dataset_<N>.m` — before writing code against this branch.

## Dataset-specific differences

| Dataset | Source | Distinguishing features |
|---|---|---|
| Dataset 1 | Moreira et al. (2021) | Original trials carry source speed category and trial number in `origin`; a `first_foot` field is present. Full lateral/medial/mean marker set. |
| Dataset 2 | Schreiber & Moissenet (2019) | Trial provenance includes source condition/category and trial number. Sampled trials expose `step_1_info` and `step_2_info`. Built from C3D via `convert_c3d_to_mat.m`. |
| Dataset 3 | Lencioni et al. (2019) | Original trials include `Trajectory_Time` and `Forceplate_Time`; sampled trials expose one `step_1_info`. Lateral markers only; knees are virtual. |
| Dataset 4 | Van Criekinge et al. (2023) | Trial provenance includes trial number; source data associate three expected steps per trial. Built from C3D via `convert_c3d_to_mat.m`. |

Participant counts, trial counts, step counts, marker sets, force-plate counts, and source-specific metadata are data values rather than fixed schema constants — read them from `Experiment_protocol` and `Lab_system` rather than hard-coding them.
