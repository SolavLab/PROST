function tests = test_Dataset2_metadata_linkage
%TEST_DATASET2_METADATA_LINKAGE Metadata-linkage guard for Dataset 2.
%
% This file lives in example_datasets/Dataset2/tests/ rather than in the
% toolbox-wide suite +PROST/+tests/, because it is specific to Dataset 2 and
% depends on that dataset's raw source files. +PROST/+tests/ holds tests of
% toolbox behaviour that must pass on any clone; this one cannot.
%
% Dataset 2 has BOTH ingredients of the Dataset-4 bug:
%   read_metadata_table sorts lexicographically on SubjID
%       (build_Dataset_2.m:1352)
%   the participant loop binds positionally
%       participant_metadata = all_metadata(participant_number)
%       (build_Dataset_2.m:209, where participant_number indexes raw_data)
%
% It is nevertheless CORRECT, but only because of a property of the IDs: they
% are fixed-width 7-digit numerics ("2014001"...), and for fixed-width
% all-numeric strings lexicographic order is numeric order. raw_data is built
% by dir() over folders named with those same IDs (convert_c3d_to_mat.m:27-33),
% so both lists land in the same order. The 2026-09 audit confirmed this
% empirically: 0/50 mismatches.
%
% The sort is NOT a no-op - 2014016 sits at CSV row 38 but sorts to position 14,
% and without it 25 participants would be misaligned. That line is load-bearing
% and currently correct, which is exactly why it needs a test: nothing about
% the arrangement is enforced, and a single ID of a different width, or one CSV
% row without a matching folder, would silently break it with no error.
%
% WARNING for anyone hardening build_Dataset_2: do NOT copy the Dataset-4 fix.
% There, SubjNum is parsed from the ID. Here, SubjNum = subjCounter - the CSV
% ROW COUNTER (build_Dataset_2.m:1337-1340) - so after the sort it no longer
% equals position and carries no information about the participant. Binding on
% SubjNum would INTRODUCE the bug. Match on SubjID against the folder name.
%
% All tests here are expected to PASS. A failure means the arrangement
% described above has been disturbed and Dataset 2 must be rebuilt.
%
% Tests are skipped rather than failed when the source files are absent, so
% this file still runs on a clone without the large data downloads.
%
% Run with:  runtests(fullfile("example_datasets", "Dataset2", "tests"))
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    here = fileparts(mfilename('fullpath'));            % .../Dataset2/tests
    dataset_folder = fileparts(here);                   % .../Dataset2
    datasets_folder = fileparts(dataset_folder);        % .../example_datasets
    root = fileparts(datasets_folder);                  % toolbox root
    addpath(root);

    testCase.TestData.data_path = fullfile(dataset_folder, "Data Files");
    testCase.TestData.csv = fullfile(dataset_folder, "Data Files", "subject_metadata.csv");
    testCase.TestData.dataset = fullfile(datasets_folder, "Dataset_2.mat");
end

function test_csv_ids_match_data_folders(testCase)
%TEST_CSV_IDS_MATCH_DATA_FOLDERS The positional binding assumes the two lists
% describe the same 50 people. Assert the ID sets are identical and equinumerous.
    src = read_source_metadata(testCase);
    folders = data_folders(testCase);

    testCase.verifyEqual(numel(src.id), numel(folders), sprintf( ...
        "%d metadata rows but %d data folders; numel(all_metadata) == " + ...
        "numel(raw_data) would fail at build_Dataset_2.m:161.", ...
        numel(src.id), numel(folders)));

    missing_folder = setdiff(src.id, folders);
    missing_record = setdiff(folders, src.id);
    testCase.verifyEmpty(missing_folder, ...
        "CSV rows with no matching data folder: " + join(missing_folder, ", "));
    testCase.verifyEmpty(missing_record, ...
        "Data folders with no CSV row: " + join(missing_record, ", "));
end

function test_ids_are_fixed_width_numeric(testCase)
%TEST_IDS_ARE_FIXED_WIDTH_NUMERIC The premise that makes the lexicographic sort
% safe. A single ID of a different width breaks the equivalence between
% lexicographic and numeric order, and the binding fails silently.
    src = read_source_metadata(testCase);

    widths = unique(strlength(src.id));
    testCase.verifyNumElements(widths, 1, ...
        "Subject IDs have mixed widths (" + join(string(widths), ", ") + "). " + ...
        "Lexicographic order only equals numeric order at fixed width, which " + ...
        "is what the sort at build_Dataset_2.m:1352 relies on.");

    non_numeric = src.id(~matches(src.id, digitsPattern));
    testCase.verifyEmpty(non_numeric, ...
        "Non-numeric Subject IDs: " + join(non_numeric, ", "));
end

function test_sorted_metadata_order_matches_participant_order(testCase)
%TEST_SORTED_METADATA_ORDER_MATCHES_PARTICIPANT_ORDER The invariant the
% positional binding actually depends on, stated directly.
%
% read_metadata_table returns the records sorted by SubjID; participant p is
% then given all_metadata(p). participant_ID_in_original_structure records
% raw_data(p).folder (build_Dataset_2.m:185, 200 via :1189-1190), so comparing
% the sorted ID sequence against it reproduces the binding exactly - and needs
% only the built dataset, not the 1.1 GB raw_data.mat.
    testCase.assumeTrue(isfile(testCase.TestData.dataset), ...
        "Dataset_2.mat not built; skipping.");

    src = read_source_metadata(testCase);
    sorted_ids = sort(src.id);          % as read_metadata_table orders them

    S = load(testCase.TestData.dataset, "Dataset_2");
    data = S.Dataset_2.Data;
    n = numel(fieldnames(data));

    testCase.assertEqual(n, numel(sorted_ids), sprintf( ...
        "Built dataset has %d participants but the CSV has %d records.", ...
        n, numel(sorted_ids)));

    for i = 1:n
        folder = string(data.("participant_" + i).participant_ID_in_original_structure);
        testCase.verifyEqual(sorted_ids(i), folder, sprintf( ...
            "Position %d: sorted metadata holds %s but the measurements " + ...
            "belong to %s. The positional binding at build_Dataset_2.m:209 " + ...
            "is misaligned.", i, sorted_ids(i), folder));
    end
end

function test_each_participant_holds_its_own_record(testCase)
%TEST_EACH_PARTICIPANT_HOLDS_ITS_OWN_RECORD The end-to-end property, checked
% by ID lookup rather than by position, so it is independent of any ordering
% assumption. This is the test that would have caught the Dataset-4 bug.
    testCase.assumeTrue(isfile(testCase.TestData.dataset), ...
        "Dataset_2.mat not built; skipping.");

    src = read_source_metadata(testCase);
    S = load(testCase.TestData.dataset, "Dataset_2");
    data = S.Dataset_2.Data;
    pnames = fieldnames(data);

    for i = 1:numel(pnames)
        rec = data.("participant_" + i);
        id = string(rec.participant_ID_in_original_structure);

        k = find(src.id == id, 1);
        testCase.assertNotEmpty(k, sprintf( ...
            "participant_%d is %s, which has no row in subject_metadata.csv.", i, id));

        m = rec.metadata;
        ctx = sprintf("participant_%d (%s)", i, id);
        expected_sex = "Female";
        if src.sex(k) == "M"
            expected_sex = "Male";
        end

        testCase.verifyEqual(m.Age.value, src.age(k), "AbsTol", 1e-9, ...
            "Age mismatch for " + ctx);
        testCase.verifyEqual(m.Height.value, src.height_m(k), "AbsTol", 1e-9, ...
            "Height mismatch for " + ctx);
        testCase.verifyEqual(m.Mass.value, src.mass(k), "AbsTol", 1e-9, ...
            "Mass mismatch for " + ctx);
        testCase.verifyEqual(string(m.Sex.value), expected_sex, ...
            "Sex mismatch for " + ctx);
    end
end

function test_sex_codes_are_recognised(testCase)
%TEST_SEX_CODES_ARE_RECOGNISED get_metadata (build_Dataset_2.m:458-462) maps
% 'M' to Male and EVERYTHING ELSE to Female, so a blank, a typo or a case
% change is silently recorded as Female rather than raising. The codes in this
% CSV are M and W; assert nothing else appears.
    src = read_source_metadata(testCase);

    unexpected = unique(src.sex(~ismember(src.sex, ["M" "W"])));
    testCase.verifyEmpty(unexpected, ...
        "Unexpected sex codes in subject_metadata.csv: '" + ...
        join(unexpected, "', '") + "'. The else-branch at " + ...
        "build_Dataset_2.m:460 would record each of them as Female.");
end

% ------------------------------- helpers -------------------------------
function folders = data_folders(testCase)
%DATA_FOLDERS Subject folder names in dir() order - the order of raw_data.
    testCase.assumeTrue(isfolder(testCase.TestData.data_path), ...
        "Dataset-2 data files not present; skipping.");

    d = dir(testCase.TestData.data_path);
    d = d([d.isdir]);
    folders = string({d.name})';
    folders(folders == "." | folders == "..") = [];
    testCase.assumeNotEmpty(folders, "No subject folders found; skipping.");
end

function src = read_source_metadata(testCase)
%READ_SOURCE_METADATA Read subject_metadata.csv exactly as read_metadata_table
% does (build_Dataset_2.m:1317-1350), keyed by Subject ID and in file order.
    testCase.assumeTrue(isfile(testCase.TestData.csv), ...
        "subject_metadata.csv not present; skipping.");

    opts = detectImportOptions(testCase.TestData.csv, "ReadVariableNames", false);
    T = readtable(testCase.TestData.csv, opts);

    subjCol = 1; sexCol = 2; ageCol = 3; heightCol = 4; massCol = 5;

    src = struct("id", strings(0), "sex", strings(0), ...
                 "age", [], "height_m", [], "mass", []);
    for r = 1:height(T)
        id = as_text(T{r, subjCol});
        if ~startsWith(id, "201")
            continue
        end
        src.id(end+1, 1)       = id;
        src.sex(end+1, 1)      = as_text(T{r, sexCol});
        src.age(end+1, 1)      = as_number(T{r, ageCol});
        src.height_m(end+1, 1) = as_number(T{r, heightCol});
        src.mass(end+1, 1)     = as_number(T{r, massCol});
    end
    testCase.assumeNotEmpty(src.id, "No subject rows parsed from the CSV; skipping.");
end

function s = as_text(x)
%AS_TEXT Cell/char/string table content as a trimmed scalar string.
    if iscell(x)
        x = x{1};
    end
    s = strtrim(string(x));
end

function v = as_number(x)
%AS_NUMBER Table content as a double, whether the column was typed numeric or
% text (detectImportOptions with ReadVariableNames=false can do either,
% depending on the header row).
    if iscell(x)
        x = x{1};
    end
    if ischar(x) || isstring(x)
        v = str2double(x);
    else
        v = double(x);
    end
end
