function tests = test_Dataset4_metadata_linkage
%TEST_DATASET4_METADATA_LINKAGE Regression guard for the Dataset-4 metadata
% linkage bug fixed in commit 8d763cd.
%
% read_metadata_table sorted the metadata lexicographically on SubjID
% ("SUBJ100" sorts before "SUBJ15") while raw_data and good_trials were
% ordered numerically. Because build_Dataset_4 bound metadata to participants
% positionally, 126 of 136 included participants received another
% participant's Age/Sex/Height/Mass. Nothing errored and nothing downstream
% detected it - the only visible symptom was in the statistics.
%
% These tests assert the two properties the binding depends on:
%   1. metadata SubjNum are unique and contiguous 1..N
%   2. every participant in the built dataset holds ITS OWN source record
%
% Tests are skipped (not failed) when the raw data files are absent, so the
% suite still runs on a clone without the large data downloads.
%
% Run with:  runtests('+PROST/+tests')
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    here = fileparts(mfilename('fullpath'));
    parts = split(string(here), filesep);
    root = fullfile(parts{1:end-2});
    addpath(root);
    testCase.TestData.xlsx = fullfile(root, "example_datasets", "Dataset4", ...
        "Data Files", "41597_2023_2767_MOESM1_ESM.xlsx");
    testCase.TestData.dataset = fullfile(root, "example_datasets", "Dataset_4.mat");
end

function test_source_ids_unique_and_contiguous(testCase)
    testCase.assumeTrue(isfile(testCase.TestData.xlsx), ...
        "Dataset-4 metadata spreadsheet not present; skipping.");
    src = read_source_metadata(testCase.TestData.xlsx);
    n = numel(src.num);

    testCase.verifyEqual(numel(unique(src.num)), n, ...
        "Duplicate SubjNum in the source metadata table.");
    testCase.verifyEqual(sort(src.num(:))', 1:n, ...
        "Source metadata SubjNum must be contiguous 1..N; positional " + ...
        "binding in build_Dataset_4 depends on it.");
end

function test_each_participant_holds_its_own_record(testCase)
    testCase.assumeTrue(isfile(testCase.TestData.xlsx), ...
        "Dataset-4 metadata spreadsheet not present; skipping.");
    testCase.assumeTrue(isfile(testCase.TestData.dataset), ...
        "Dataset_4.mat not built; skipping.");

    src = read_source_metadata(testCase.TestData.xlsx);
    S = load(testCase.TestData.dataset, "Dataset_4");
    data = S.Dataset_4.Data;
    pnames = fieldnames(data);

    for i = 1:numel(pnames)
        rec = data.("participant_" + i);

        % subject number carried by the original data folder name
        subj = str2double(regexp(string(rec.participant_ID_in_original_structure), ...
                                 '\d+', 'match', 'once'));
        k = find(src.num == subj, 1);
        testCase.assertNotEmpty(k, sprintf( ...
            "participant_%d maps to SUBJ%d, which has no source record.", i, subj));

        m = rec.metadata;
        expected_sex = "Female";
        if strcmpi(string(src.sex(k)), "M")
            expected_sex = "Male";
        end
        ctx = sprintf("participant_%d (SUBJ%d)", i, subj);

        testCase.verifyEqual(m.Age.value, src.age(k), "AbsTol", 1e-9, ...
            "Age mismatch for " + ctx);
        testCase.verifyEqual(m.Mass.value, src.mass(k), "AbsTol", 1e-9, ...
            "Mass mismatch for " + ctx);
        testCase.verifyEqual(m.Height.value, src.height_mm(k)/1000, "AbsTol", 1e-9, ...
            "Height mismatch for " + ctx + " (source mm -> stored m)");
        testCase.verifyEqual(string(m.Sex.value), expected_sex, ...
            "Sex mismatch for " + ctx);
    end
end

% ------------------------------- helpers -------------------------------
function src = read_source_metadata(xlsx)
%READ_SOURCE_METADATA Read the published metadata table, keyed by SubjNum.
% Column layout mirrors read_metadata_table in build_Dataset_4.m: two
% participants per spreadsheet row.
    opts = detectImportOptions(xlsx, "Sheet", "Table 1", "ReadVariableNames", false);
    T = readtable(xlsx, opts);

    subjCols = [1 7]; ageCols = [2 8]; sexCols = [3 9];
    massCols = [4 10]; heightCols = [5 11];

    src = struct("num", [], "age", [], "sex", strings(0), "mass", [], "height_mm", []);
    for r = 1:height(T)
        for s = 1:2
            rawID = string(T{r, subjCols(s)});
            if ~startsWith(rawID, "SUBJ")
                continue
            end
            src.num(end+1, 1)       = sscanf(rawID, "SUBJ%d");
            src.age(end+1, 1)       = double(T{r, ageCols(s)});
            src.sex(end+1, 1)       = string(T{r, sexCols(s)});
            src.mass(end+1, 1)      = double(T{r, massCols(s)});
            src.height_mm(end+1, 1) = double(T{r, heightCols(s)});
        end
    end
end
