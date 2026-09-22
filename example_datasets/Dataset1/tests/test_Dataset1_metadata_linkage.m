function tests = test_Dataset1_metadata_linkage
%TEST_DATASET1_METADATA_LINKAGE Metadata-linkage guard for Dataset 1.
%
% This file lives in example_datasets/Dataset1/tests/ rather than in the
% toolbox-wide suite +PROST/+tests/, because it is specific to Dataset 1 and
% depends on that dataset's raw source files. +PROST/+tests/ holds tests of
% toolbox behaviour that must pass on any clone; this one cannot.
%
% THE BUG THIS GUARDS (fixed 17.09.2026; all tests here now pass)
%   Dataset 1 used to read anthropometrics from
%   Data Files/Participant<N>/Metadata.txt, parsed by FIXED TOKEN POSITION.
%   Participant8, Participant9 and Participant10 shipped byte-identical files,
%   all reading "ID: Subject8", while their Raw_Data.mat files were distinct -
%   so participants 9 and 10 carried their own genuine gait measurements bound
%   to Subject8's anthropometrics. The parser was faithful; the source data was
%   not, so nothing errored and the only symptom was in the statistics.
%
%   build_Dataset_1 now reads Data Files/anthropometric_data.csv, addresses
%   columns BY NAME, and binds records to participants BY ID. The CSV carries
%   distinct records for participants 9 and 10, so the duplication is resolved
%   rather than worked around. See the METADATA SOURCE CHANGE note at the top
%   of build_Dataset_1.m for the full provenance rationale, including why the
%   CSV was also taken as authoritative for participant 5's height.
%
% These tests assert the three properties the binding depends on:
%   1. the CSV has the columns the parser addresses by name
%   2. its IDs are unique and cover every participant
%   3. every participant in the built dataset holds ITS OWN source record
%
% All tests here are expected to PASS.
%
% Tests are skipped rather than failed when the source files are absent, so
% this file still runs on a clone without the large data downloads.
%
% Run with:  runtests(fullfile("example_datasets", "Dataset1", "tests"))
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    here = fileparts(mfilename('fullpath'));            % .../Dataset1/tests
    dataset_folder = fileparts(here);                   % .../Dataset1
    datasets_folder = fileparts(dataset_folder);        % .../example_datasets
    root = fileparts(datasets_folder);                  % toolbox root
    addpath(root);

    testCase.TestData.data_path = fullfile(dataset_folder, "Data Files");
    testCase.TestData.csv = fullfile(dataset_folder, "Data Files", "anthropometric_data.csv");
    testCase.TestData.dataset = fullfile(datasets_folder, "Dataset_1.mat");
end

function test_required_columns_are_present(testCase)
%TEST_REQUIRED_COLUMNS_ARE_PRESENT read_metadata_table addresses columns by
% name. Assert those names exist, so a renamed or reordered export fails here
% with a clear message rather than part-way through a build.
    T = read_source_table(testCase);

    required = ["ID", "Gender", "Body Height (m)", "Body Mass (kg)", "Age (years)"];
    present = string(T.Properties.VariableNames);
    absent = required(~ismember(required, present));

    testCase.verifyEmpty(absent, ...
        "anthropometric_data.csv is missing column(s): " + ...
        strjoin(cellstr(absent), ", ") + ". Present: " + strjoin(cellstr(present), ", "));
end

function test_ids_are_unique_and_cover_every_participant(testCase)
%TEST_IDS_ARE_UNIQUE_AND_COVER_EVERY_PARTICIPANT A duplicate ID would make the
% find() in the participant loop order-dependent; a missing one would abort the
% build. This is the check that the old Metadata.txt layout failed - Subject8
% appeared three times.
    T = read_source_table(testCase);
    ids = double(T.("ID"));

    testCase.verifyEqual(numel(unique(ids)), numel(ids), ...
        "Duplicate ID in anthropometric_data.csv.");

    folders = participant_folders(testCase);
    expected = sort(double(extract(folders, digitsPattern)));
    missing = setdiff(expected, ids);
    testCase.verifyEmpty(missing, ...
        "Participant folders with no CSV record: " + ...
        strjoin(cellstr(string(missing)), ", "));
end

function test_each_participant_holds_its_own_record(testCase)
%TEST_EACH_PARTICIPANT_HOLDS_ITS_OWN_RECORD The end-to-end property: every
% participant in the built dataset holds the CSV row bearing its own ID.
% Checked by ID lookup rather than by position, so it is independent of any
% ordering assumption - this is what would have caught the Dataset-4 bug, and
% what catches a regression to positional binding here.
    testCase.assumeTrue(isfile(testCase.TestData.dataset), ...
        "Dataset_1.mat not built; skipping.");

    T = read_source_table(testCase);
    ids = double(T.("ID"));

    S = load(testCase.TestData.dataset, "Dataset_1");
    data = S.Dataset_1.Data;
    pnames = fieldnames(data);

    for i = 1:numel(pnames)
        rec = data.("participant_" + i);
        folder = string(rec.participant_ID_in_original_structure);
        subj = double(extract(folder, digitsPattern));

        k = find(ids == subj, 1);
        testCase.assertNotEmpty(k, sprintf( ...
            "participant_%d (%s) has no row in anthropometric_data.csv.", i, folder));

        ctx = sprintf("participant_%d (%s)", i, folder);
        expected_sex = "Female";
        if strcmpi(strtrim(T.("Gender")(k)), "Male") || strcmpi(strtrim(T.("Gender")(k)), "M")
            expected_sex = "Male";
        end

        m = rec.metadata;
        testCase.verifyEqual(m.Age.value, T.("Age (years)")(k), "AbsTol", 1e-9, ...
            "Age mismatch for " + ctx);
        testCase.verifyEqual(m.Height.value, T.("Body Height (m)")(k), "AbsTol", 1e-9, ...
            "Height mismatch for " + ctx);
        testCase.verifyEqual(m.Mass.value, T.("Body Mass (kg)")(k), "AbsTol", 1e-9, ...
            "Mass mismatch for " + ctx);
        testCase.verifyEqual(string(m.Sex.value), expected_sex, ...
            "Sex mismatch for " + ctx);
    end
end

function test_sex_values_are_recognised(testCase)
%TEST_SEX_VALUES_ARE_RECOGNISED read_participant_characteristics raises
% Dataset1:UnrecognisedSex on anything it cannot resolve, which would abort a
% build part-way through. Report every offending row here instead, in one run.
    T = read_source_table(testCase);

    for r = 1:height(T)
        v = strtrim(T.("Gender")(r));
        ok = strcmpi(v, "Male") || strcmpi(v, "M") || ...
             strcmpi(v, "Female") || strcmpi(v, "F");
        testCase.verifyTrue(ok, sprintf( ...
            "ID %g has Gender '%s', which build_Dataset_1 cannot resolve.", ...
            double(T.("ID")(r)), v));
    end
end

% ------------------------------- helpers -------------------------------
function T = read_source_table(testCase)
%READ_SOURCE_TABLE Read anthropometric_data.csv exactly as read_metadata_table
% does (build_Dataset_1.m), preserving the original column names.
    testCase.assumeTrue(isfile(testCase.TestData.csv), ...
        "anthropometric_data.csv not present; skipping.");
    T = readtable(testCase.TestData.csv, ...
        "VariableNamingRule", "preserve", "TextType", "string");
    testCase.assumeGreaterThan(height(T), 0, "CSV has no rows; skipping.");
end

function folders = participant_folders(testCase)
%PARTICIPANT_FOLDERS Participant<N> folder names holding the measurements.
    testCase.assumeTrue(isfolder(testCase.TestData.data_path), ...
        "Dataset-1 data files not present; skipping.");

    d = dir(fullfile(testCase.TestData.data_path, "Participant*"));
    d = d([d.isdir]);
    testCase.assumeNotEmpty(d, "No Participant folders found; skipping.");
    folders = string({d.name})';
end
