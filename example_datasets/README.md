# Example datasets

PROST harmonises four publicly available gait datasets. Each `DatasetN/` folder holds a build script (`build_Dataset_N.m`) that converts the published source files into the common `Dataset_N.mat` structure, plus validation scripts in `tests/`. The structure is documented in [DATASET_FORMAT.md](../DATASET_FORMAT.md).

The built `Dataset_N.mat` files are **not** distributed (they are gitignored). Build them locally from the source data.

## Sources and licenses

| Dataset | Source publication | Source data | License of source data |
|---|---|---|---|
| 1 | Moreira L, Figueiredo J, Fonseca P, Vilas-Boas JP, Santos CP. Lower limb kinematic, kinetic, and EMG data from young healthy humans during walking at controlled speeds. *Scientific Data* (2021). https://doi.org/10.1038/s41597-021-00881-3 | https://doi.org/10.6084/m9.figshare.c.4923162.v1 | CC0 1.0 |
| 2 | Schreiber C, Moissenet F. A multimodal dataset of human gait at different walking speeds established on injury-free adult participants. *Scientific Data* (2019). https://doi.org/10.1038/s41597-019-0124-4 | https://doi.org/10.6084/m9.figshare.7734767.v8 | CC BY 4.0 |
| 3 | Lencioni T, Carpinella I, Rabuffetti M, Marzegan A, Ferrarin M. Human kinematic, kinetic and EMG data during different walking and stair ascending and descending tasks. *Scientific Data* (2019). https://doi.org/10.1038/s41597-019-0323-z | https://doi.org/10.6084/m9.figshare.c.4494755.v1 | CC0 1.0 |
| 4 | Van Criekinge T, Saeys W, Truijen S, Vereeck L, Sloot LH, Hallemans A. A full-body motion capture gait dataset of 138 able-bodied adults across the life span and 50 stroke survivors. *Scientific Data* (2023). https://doi.org/10.1038/s41597-023-02767-y | https://doi.org/10.6084/m9.figshare.c.6503791.v1 | CC0 1.0 |

Licenses are as stated on the figshare records.

**The source data files in these folders remain under their original licenses above, not the PROST code license.** Dataset 2 is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). PROST redistributes it with modifications: it restructures and harmonises the data into the PROST format, as described in the build script. If you use any of these datasets, please cite the original publication.

Derived data produced by PROST (`PROSTAnalyzer.mat` and the `*_Results.mat` files at the repository root) are licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

Third-party example code included with the source data, such as `Dataset3/Data Files/CalcAngle.m` and `walking_fig.m`, and code adapted from the Dataset 4 example scripts by L. H. Sloot, keeps its original attribution.

## Building

The source files the builds need are included in this repository under `DatasetN/Data Files/`. Each script `cd`s to its own folder, so you can run it from anywhere.

| Dataset | Run |
|---|---|
| 1 | `build_Dataset_1` |
| 2 | `convert_c3d_to_mat`, then `build_Dataset_2` |
| 3 | `build_Dataset_3` |
| 4 | `convert_c3d_to_mat`, then `build_Dataset_4` |

`convert_c3d_to_mat` (Datasets 2 and 4) reads the C3D files with the bundled ezc3d MEX files (Windows only; see `lib-ext/ezc3d_matlab/`) and writes `Data Files/raw_data.mat`. Each build writes `example_datasets/Dataset_N.mat`. Afterwards, run `Create_PROST` from the repository root. Optionally, run the validation scripts in `DatasetN/tests/`.

### Re-downloading the source files

If you need fresh copies, these are the figshare items the builds use. Unzip each into `DatasetN/Data Files/`.

| Dataset | Download | Gives |
|---|---|---|
| 1 | `MAT files.zip`, https://doi.org/10.6084/m9.figshare.13169237.v1 | `Participant<N>/` folders, each with `Raw_Data.mat`, `Processed_Data.mat` and `Metadata.txt`. Only `Raw_Data.mat` is used; anthropometrics come from the tracked `anthropometric_data.csv`. |
| 2 | `A multimodal dataset of human gait at different walking speeds.zip`, https://doi.org/10.6084/m9.figshare.7734767.v8 | `<subject ID>/*.c3d` |
| 3 | `All_Subjects.zip`, https://doi.org/10.6084/m9.figshare.9784970.v1 | `Subject<N>.mat` (flat) |
| 4 | `138_HealthyPiG.zip`, https://doi.org/10.6084/m9.figshare.24192480.v1 | `138_HealthyPiG_10.05/SUBJ<N>/*.c3d` |

`MAT_normalizedData_AbleBodiedAdults_v06-03-23.mat` (Dataset 4) is not needed for the build; only `Dataset4/tests/test_view_original_data.m` uses it.
