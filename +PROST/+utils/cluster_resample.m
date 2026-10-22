function [boot_data, boot_rows] = cluster_resample(data, stream, opts)
%CLUSTER_RESAMPLE one cluster bootstrap resample: draws clusters (participants)
% with replacement within each stratum (dataset), keeping all rows (legs) of every
% drawn cluster.
% A cluster drawn twice gets two new cluster IDs, so a model with a random effect
% per cluster treats the copies as different clusters instead of merging their
% rows into one level. The new IDs are unique only within a stratum, which is
% enough for random effects nested in the stratum, e.g. (1|DatasetID:ParticipantID).
% Statistics that ignore the cluster ID (a median, a correlation) are unaffected.
% Input :
%   data - table with one row per observation.
%   stream - the RandStream to draw from (see PROST.utils.boot_stream).
% Name-Value pair options:
%   Cluster - name of the cluster ID column (default: "ParticipantID").
%   Strata  - name of the stratum ID column (default: "DatasetID"); "" resamples
%             all clusters together.
% Output :
%   boot_data - the resampled table. The cluster column holds the new categorical
%               IDs and <Cluster>Original the original ones.
%   boot_rows - the rows of DATA that make up BOOT_DATA, e.g. to resample
%               observation weights alongside.
% Example usage :
%   boot_data = PROST.utils.cluster_resample(data, PROST.utils.boot_stream(1, 1))
%   [boot_data, boot_rows] = PROST.utils.cluster_resample(data, stream, Strata="")

    arguments
        data table
        stream (1, 1) RandStream
        opts.Cluster (1, 1) string = "ParticipantID"
        opts.Strata (1, 1) string = "DatasetID"
    end

    if opts.Strata == ""
        strata = ones(height(data), 1);
    else
        strata = data.(opts.Strata);
    end
    cluster = data.(opts.Cluster);

    stratum_ids = unique(strata);
    boot_rows = [];
    boot_cluster_ids = [];
    for s = 1:numel(stratum_ids)
        stratum_rows = find(strata == stratum_ids(s));
        clusters = unique(cluster(stratum_rows));
        n_clusters = numel(clusters);
        sampled_clusters = clusters(randi(stream, n_clusters, n_clusters, 1));

        % col is the draw number, so each draw of a cluster gets its own new ID
        [row, col] = find(cluster(stratum_rows) == sampled_clusters');
        boot_rows = [boot_rows; stratum_rows(row)]; %#ok<AGROW>
        boot_cluster_ids = [boot_cluster_ids; col]; %#ok<AGROW>
    end
    boot_data = data(boot_rows, :);
    boot_data.(opts.Cluster + "Original") = boot_data.(opts.Cluster);
    boot_data.(opts.Cluster) = categorical(boot_cluster_ids);
end
