function stat = per_dataset_icc_refit(data, response_name, datasets, catch_errors)
% STAT = PER_DATASET_ICC_REFIT(DATA, RESPONSE_NAME, DATASETS, CATCH_ERRORS)
% Fits RESPONSE_NAME ~ 1 + (1|ParticipantID) to each dataset of DATA alone and
% returns [tau2, sigma2, ICC1] per dataset, concatenated in the order of DATASETS.
% Used both for the point estimates and as the statistic of a bootstrap replicate.
%
% Input :
%   data - the data table, or a resample of it (see PROST.utils.cluster_resample).
%   response_name - the response column name.
%   datasets - cellstr of the dataset IDs, fixing the order of the output.
%   catch_errors - true: a failed fit gives NaN for its dataset only, so one
%                  dataset cannot discard the replicate of the others; false:
%                  the error propagates.
%
% Example usage :
%   stat = PROST.lme.per_dataset_icc_refit(data_final, 'log_R', {'1' '2' '3' '4'}, false)

    formula = [response_name ' ~ 1 + (1|ParticipantID)'];
    stat = nan(1, 3*numel(datasets));
    for d = 1:numel(datasets)
        try
            lme = fitlme(data(data.DatasetID == datasets{d}, :), formula, 'FitMethod', 'REML');
            [ICC, tau2, sigma2] = PROST.lme.model_metrics(lme, Display="off");
            stat(3*d - 2:3*d) = [tau2, sigma2, ICC(1)];
        catch ME
            if ~catch_errors
                rethrow(ME)
            end
        end
    end
end
