function tests = test_Dataset3_metadata_linkage
%TEST_DATASET3_METADATA_LINKAGE Metadata-integrity guard for Dataset 3.
%
% This file lives in example_datasets/Dataset3/tests/ rather than in the
% toolbox-wide suite +PROST/+tests/, because it is specific to Dataset 3 and
% depends on that dataset's raw source files. +PROST/+tests/ holds tests of
% toolbox behaviour that must pass on any clone; this one cannot.
%
% Dataset 3 reads anthropometrics from the struct s inside each
% Data Files/Subject<N>.mat - the same file as the measurements - so the
% Dataset-4 bug (a shared table sorted differently and bound positionally) is
% structurally impossible here. The exposure is in the sex parsing.
%
% THE BUG THIS GUARDS (fixed 2026-09-17; all tests here now pass)
%   build_Dataset_3.m:163-167 used to read:
%
%       if contains(s.Gender,'M')
%           metadata.Sex.value = "Male";
%       elseif contains(s.Gender, 'F')
%           metadata.Sex.value = "Female";
%       end
%
%   Three defects combined into one silent wrong value: contains was
%   CASE-SENSITIVE, there was NO else branch, and metadata was never cleared
%   between loop iterations. Subject50 has s.Gender = 'f ' - the only lowercase
%   value among the 50, which are "M ", "F " and "f ". Neither branch fired, so
%   Subject50 inherited participant 49's Sex and was stored as Male while the
%   source says Female. Age, height and mass were unaffected.
%
%   The build now normalises with upper(strtrim(...)), compares for exact
%   equality, and raises Dataset3:UnrecognisedGender otherwise, so a carry-over
%   cannot recur silently. test_each_participant_holds_its_own_record is the
%   regression guard: revert the normalisation and Subject50 fails it again.
%
%   The fix deliberately does NOT use contains(upper(s.Gender),'M') - upper of
%   "Female" is "FEMALE", which contains 'M', so that form would misclassify a
%   spelled-out Female as Male.
%
% All tests here are expected to PASS.
%
% Tests are skipped rather than failed when the source files are absent, so
% this file still runs on a clone without the large data downloads.
%
% Run with:  runtests(fullfile("example_datasets", "Dataset3", "tests"))
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    here = fileparts(mfilename('fullpath'));            % .../Dataset3/tests
    dataset_folder = fileparts(here);                   % .../Dataset3
    datasets_folder = fileparts(dataset_folder);        % .../example_datasets
    root = fileparts(datasets_folder);                  % toolbox root
    addpath(root);

    testCase.TestData.data_path = fullfile(dataset_folder, "Data Files");
    testCase.TestData.dataset = fullfile(datasets_folder, "Dataset_3.mat");
end

function test_every_sex_code_resolves_unambiguously(testCase)
%TEST_EVERY_SEX_CODE_RESOLVES_UNAMBIGUOUSLY Replicates the normalisation in
% build_Dataset_3.m:165-173 exactly, so it fails here rather than aborting a
% build. A code that resolves to neither M nor F now raises
% Dataset3:UnrecognisedGender part-way through the participant loop, leaving a
% half-written Dataset_3.mat; this test finds it first, and reports every
% offending subject in one run instead of only the first.
    n = source_count(testCase);

    for i = 1:n
        s = read_source(testCase, i);
        code = upper(strtrim(string(s.Gender)));
        testCase.verifyTrue(code == "M" || code == "F", sprintf( ...
            "Subject%d.mat has Gender '%s', which normalises to '%s' - " + ...
            "neither M nor F. build_Dataset_3 would error on this subject.", ...
            i, string(s.Gender), code));
    end
end

function test_source_name_matches_its_file(testCase)
%TEST_SOURCE_NAME_MATCHES_ITS_FILE The loop indexes Subject<N>.mat by number
% and stores s.name as the original ID; assert the two agree, so a renamed or
% duplicated file cannot pass unnoticed.
    n = source_count(testCase);

    for i = 1:n
        s = read_source(testCase, i);
        testCase.verifyEqual(string(s.name), "Subject" + i, sprintf( ...
            "Subject%d.mat contains s.name = '%s'.", i, string(s.name)));
    end
end

function test_each_participant_holds_its_own_record(testCase)
%TEST_EACH_PARTICIPANT_HOLDS_ITS_OWN_RECORD Every participant in the built
% dataset holds the values from its own source file.
    testCase.assumeTrue(isfile(testCase.TestData.dataset), ...
        "Dataset_3.mat not built; skipping.");

    S = load(testCase.TestData.dataset, "Dataset_3");
    data = S.Dataset_3.Data;
    pnames = fieldnames(data);

    for i = 1:numel(pnames)
        rec = data.("participant_" + i);
        s = read_source(testCase, i);
        ctx = sprintf("participant_%d (%s)", i, string(s.name));

        testCase.verifyEqual(string(rec.participant_ID_in_original_structure), ...
            string(s.name), "Original ID mismatch for " + ctx);

        expected_sex = "Female";
        if upper(strtrim(string(s.Gender))) == "M"
            expected_sex = "Male";
        end

        m = rec.metadata;
        testCase.verifyEqual(m.Age.value, double(s.Age), "AbsTol", 1e-9, ...
            "Age mismatch for " + ctx);
        testCase.verifyEqual(m.Height.value, double(s.BH)/100, "AbsTol", 1e-9, ...
            "Height mismatch for " + ctx + " (source cm -> stored m)");
        testCase.verifyEqual(m.Mass.value, double(s.BM), "AbsTol", 1e-9, ...
            "Mass mismatch for " + ctx);
        testCase.verifyEqual(string(m.Sex.value), expected_sex, ...
            "Sex mismatch for " + ctx);
    end
end

% ------------------------------- helpers -------------------------------
function n = source_count(testCase)
%SOURCE_COUNT Number of Subject<N>.mat files in the data folder.
    testCase.assumeTrue(isfolder(testCase.TestData.data_path), ...
        "Dataset-3 data files not present; skipping.");

    d = dir(fullfile(testCase.TestData.data_path, "Subject*.mat"));
    n = numel(d);
    testCase.assumeGreaterThan(n, 0, "No Subject*.mat files found; skipping.");
end

function s = read_source(testCase, participant_number)
%READ_SOURCE Load the s struct from Subject<N>.mat, as build_Dataset_3 does.
    f = fullfile(testCase.TestData.data_path, "Subject" + participant_number + ".mat");
    testCase.assertTrue(isfile(f), "Missing source file: " + f);
    loaded = load(f, "s");
    testCase.assertTrue(isfield(loaded, "s"), ...
        "Subject" + participant_number + ".mat contains no variable 's'.");
    s = loaded.s;
end
