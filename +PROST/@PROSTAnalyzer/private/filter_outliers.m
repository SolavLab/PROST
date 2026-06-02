function A = filter_outliers(A, filter, filter_options)
%FILTER_OUTLIERS either Winsorizes or filters outliers from data.
% Input :
%   A   - the data to filter.
%           - If A is a matrix, then filter_outliers operates on each column of 
%             A separately.
%           - If A is a multidimensional array, then filter_outliers operates 
%             along the first dimension of A whose size does not equal 1.
%           - If A is a table or timetable, then filter_outliers operates on 
%             each variable of A separately.
%   filter - the type of filter to use on the data. Either 'none' (default), 
%            'outlier' or 'winsor'.
%   filter_options - a struct of filter specific options.
%       'outlier' - the struct contains the isoutlier options in the form:
%                   filter_options.method = "median" / "mean" / "quartiles" /
%                                           "grubbs" / "gesd" / "percentiles" /
%                                           "movmedian" / "movmean".
%                   filter_options.threshold - percentiles threshold.
%                   filter_options.window - movmedian or movmean window length.
%                   filter_options.dim - operating dimension.
%                   Name-Value pairs need to be under the 'NameValues' field in 
%                   the form: filter_options.NameValues.name = value.
%       'winsor' - the struct contains a single field 'p' of the percentile
%                  threshold as a two-element row vector with elements in the range 
%                  [0-100]: filter_options.p = [a b]. a must be smaller than b.

    arguments
        A               
        filter          (1, 1) string {mustBeMember(filter, ["winsor" "outlier" "none"])} = "none"
        filter_options  struct = struct([])
    end
    
    % Filter outliers / Winsorize from response
    switch filter
        case "none"
            % ignore filter_opts entirely
        case "winsor"
            % validate Winsor-specific options
            if ~isfield(filter_options, "p")
                PROST.PROSTError("Winsor", "WrongFilterOptions", "winsor requires 'p' field in filter_opts")
            end
            A = PROST.utils.winsorize(A, filter_options.p);
        case "outlier"
            % Convert name-values
            name_value = {};
            if isfield(filter_options, "NameValues")
                name_value= namedargs2cell(filter_options.NameValues);
            end

            % Set operating dimension.
            dim = find(size(A) > 1, 1, 'first');
            if isfield(filter_options, "dim")
                dim = filter_options.dim;
            end

            % validate fields relevant to isoutlier
            if isfield(filter_options, "method") % method
                mustBeMember(filter_options.method, ["median", "mean", "quartiles" "grubbs" "gesd" "percentiles" "movmedian" "movmean"])
                if filter_options.method == "movmedian" || filter_options.method == "movmean"
                    mustBeMember("window", fields(filter_options));
                    mustBeNonempty(filter_options.window);
                    mask = isoutlier(A, filter_options.method, filter_options.window, dim, name_value{:});
                elseif filter_options.method == "percentiles"
                    mustBeMember("threshold", fields(filter_options));
                    mustBeNonempty(filter_options.threshold);
                    mask = isoutlier(A, "percentiles", filter_options.threshold, dim, name_value{:});
                else
                    mask = isoutlier(A, filter_options.method, dim, name_value{:});
                end
            else
                mask = isoutlier(A, dim, name_value{:});
            end
            A(mask) = NaN;
    end
end
