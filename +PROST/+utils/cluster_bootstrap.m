function [draws, fail_msg] = cluster_bootstrap(data, statistic, n_boot, seed, opts)
%CLUSTER_BOOTSTRAP stratified cluster (case) bootstrap of any statistic: in each
% replicate, clusters (participants) are drawn with replacement within each
% stratum (dataset), keeping all their rows (legs), and STATISTIC is computed on
% the resample (see PROST.utils.cluster_resample).
% Replicate b always uses substream b of SEED (see PROST.utils.boot_stream), so
% the draws are the same serially or in parallel.
% A replicate whose statistic errors is kept as a NaN row with its error message,
% so the caller decides what to discard and a systematic error cannot pass
% silently as a failed refit.
% Input :
%   data - table with one row per observation.
%   statistic - function handle stat = statistic(boot_data, boot_rows) returning a
%               numeric row vector of N_STAT values. BOOT_ROWS are the rows of
%               DATA in the resample, e.g. to resample weights. It may be a handle
%               to a local function of the calling script.
%   n_boot - number of replicates.
%   seed - seed of the bootstrap random stream.
% Name-Value pair options:
%   NStat    - number of values STATISTIC returns (default: found by evaluating
%              STATISTIC once on DATA).
%   Cluster  - cluster ID column (default: "ParticipantID").
%   Strata   - stratum ID column (default: "DatasetID"); "" for no strata.
%   Parallel - run the replicates in a parfor loop (default: false).
% Output :
%   draws - n_boot x N_STAT matrix of the statistic per replicate.
%   fail_msg - n_boot x 1 string, the error of a failed replicate, "" otherwise.
% Example usage :
%   draws = PROST.utils.cluster_bootstrap(data, @(d, ~) median(d.u_c), 5000, 20261006)
%   [draws, fail_msg] = PROST.utils.cluster_bootstrap(data, @(d, rows) refit(d, rows, lme), ...
%       5000, 20261006, Parallel=true)

    arguments
        data table
        statistic (1, 1) function_handle
        n_boot (1, 1) double {mustBePositive, mustBeInteger}
        seed (1, 1) double
        opts.NStat double {mustBeScalarOrEmpty} = []
        opts.Cluster (1, 1) string = "ParticipantID"
        opts.Strata (1, 1) string = "DatasetID"
        opts.Parallel (1, 1) logical = false
    end

    n_stat = opts.NStat;
    if isempty(n_stat)
        n_stat = numel(statistic(data, (1:height(data))'));
    end
    cluster = opts.Cluster;
    strata = opts.Strata;

    draws = nan(n_boot, n_stat);
    fail_msg = strings(n_boot, 1);
    if opts.Parallel
        parfor b = 1:n_boot
            [draws(b, :), fail_msg(b)] = one_replicate(data, statistic, n_stat, seed, b, cluster, strata);
        end
    else
        for b = 1:n_boot
            [draws(b, :), fail_msg(b)] = one_replicate(data, statistic, n_stat, seed, b, cluster, strata);
        end
    end
end

function [stat, fail_msg] = one_replicate(data, statistic, n_stat, seed, b, cluster, strata)
    stat = nan(1, n_stat);
    fail_msg = "";
    [boot_data, boot_rows] = PROST.utils.cluster_resample(data, PROST.utils.boot_stream(seed, b), ...
        Cluster=cluster, Strata=strata);
    try
        stat(:) = statistic(boot_data, boot_rows);
    catch ME
        fail_msg = string(ME.message);
    end
end
