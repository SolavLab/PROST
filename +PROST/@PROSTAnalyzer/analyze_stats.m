function out = analyze_stats(value, distnames, opts)
% ANALYZE_STATS
% Fits requested distributions to a sample, computes AIC/BIC/log-likelihood, a 
% valid Chi-square GoF (equal-prob bins with E_i >= MinExpected), and returns a 
% rich struct including 'pd' objects (when available), custom Laplace, and KDE 
% (ksdensity).
%
% USAGE:
%   out = analyze_stats(value, distnames)
%   out = analyze_stats(value, distnames, opts)
%
% INPUT:
%   value     : numeric vector
%   distnames : string/cellstr of names. Supported (case-insensitive):
%               any distribution names supported by the Statistics and Machine 
%               Learning Toolbox™, custom distributions: "laplace", "kernel".
%   opts      : struct with optional fields:
%               .KDESupport   = "unbounded" or "positive" (default: "unbounded")
%               .KDEKernel    = "normal" (default)
%               .KDEFunction  = "pdf", "cdf" or "icdf" (default: "pdf")
%               .KDENumPoints = 100 (default)
%               .TargetExp    = 10  (expected counts per initial bin)
%               .MinExpected  = 5   (merge until all E_i >= this)
%
% OUTPUT:
%   out.summary   : struct (n, mean, median, std, skewness, kurtosis, min, max)
%   out.fits      : struct with a field per distribution:
%                   .(name).name      = distribution name
%                   .(name).type      = 'toolbox'|'custom'|'kde'
%                   .(name).pd        = toolbox pd (if applicable)
%                   .(name).params    = struct of parameters
%                   .(name).pdf/cdf/icdf : function handles (if applicable)
%                   .(name).LL/AIC/BIC : scalars (NaN for KDE)
%                   .(name).chi2      : struct (stat, df, pvalue, edges, O, E, bins)
%                   .kernel.kde       : struct (xi, f, bw, f_alt, bw_alt) for KDE
%   out.rankingAIC: table (Distribution, LogLik, AIC, BIC), sorted by AIC
%   out.rankingBIC: same, sorted by BIC
%
% NOTES:
% - For positivity-restricted models (lognormal, gamma, rayleigh, half-normal),
%   the function will skip (and warn) if value has invalid support.
% - Half-normal is implemented custom (location fixed at 0).
% - KDE is nonparametric: AIC/BIC/Chi-square are not computed for KDE.
%
% (c) You + Copilot. Free to use in your project.

    arguments
        value (:,1) double
        distnames         (1, :) {mustBeValidDistributionOrEmpty(distnames)} = []
        opts.KDESupport   {mustBeMember(opts.KDESupport, ["unbounded" "positive" "nonnegative" "negative"])} = "unbounded"
        opts.KDEKernel    {mustBeMember(opts.KDEKernel, ["normal" "box" "triangle" "epanechnikov"])} = "normal"
        opts.KDEFunction  {mustBeMember(opts.KDEFunction, ["pdf" "cdf" "icdf" "survivor" "cumhazard"])} = "pdf"
        opts.KDENumPoints (1,1) double = 100
        opts.TargetExp    (1,1) double = 10
        opts.MinExpected  (1,1) double = 5
    end

    fprintf("Analyzing Statistics...\n");
    x = value(:);
    x = x(isfinite(x));
    n = numel(x);

    if n < 3
        throw(PROST.PROSTError('AnalyzeDistributions:NotEnoughData', 'Need at least 3 finite observations.'));
    end

    % -------- Summary stats --------
    out = struct();
    out.summary = struct( ...
        'n', n, ...
        'mean', mean(x), ...
        'median', median(x), ...
        'std', std(x), ...
        'variance', var(x), ...
        'skewness', skewness(x), ...
        'kurtosis', kurtosis(x), ...
        'min', min(x), ...
        'max', max(x) ...
    );

    if isempty(distnames)
        return
    end

    % Normalize distnames
    if iscell(distnames); distnames = string(distnames); end
    distnames = erase(lower(distnames), whitespacePattern);
    allowed_distnames = matlabContinuousDistributions();
    allowed_distnames_lower = erase(lower(allowed_distnames), whitespacePattern);

    % -------- Fit each requested distribution
    fits = struct();
    rows = [];

    for di = 1:numel(distnames)
        name = distnames(di);
        name = allowed_distnames_lower(strcmp(allowed_distnames_lower, name));
        name_capitalized = PROST.utils.capitalize(name);
        key  = matlab.lang.makeValidName(char(name));

        switch name
            case "kernel"
                % Nonparametric KDE
                [f, xi, bw] = ksdensity(x, 'NumPoints', opts.KDENumPoints, ...
                                           'Kernel', string(opts.KDEKernel), ...
                                           'Support', string(opts.KDESupport), ...
                                           'Function', string(opts.KDEFunction));
                % Alternative bandwidths to visualize sensitivity
                [f2, ~] = ksdensity(x, xi, 'Bandwidth', 1.5*bw, ...
                                           'Kernel', string(opts.KDEKernel), ...
                                           'Support', string(opts.KDESupport), ...
                                           'Function', string(opts.KDEFunction));
                [f3, ~] = ksdensity(x, xi, 'Bandwidth', 0.7*bw, ...
                                           'Kernel', string(opts.KDEKernel), ...
                                           'Support', string(opts.KDESupport), ...
                                           'Function', string(opts.KDEFunction));
                
                fits.(key) = struct( ...
                    'name', "Kernel", 'type', 'kde', 'pd', [], 'params', struct('bw', bw), ...
                    'pdf', [], 'cdf', [], 'icdf', [], ...
                    'LL', NaN, 'AIC', NaN, 'BIC', NaN, ...
                    'chi2', struct('stat', NaN, 'df', NaN, 'pvalue', NaN, 'edges', [], 'O', [], 'E', [], 'bins', NaN), ...
                    'kde', struct('xi', xi, 'f', f, 'bw', bw, 'f_alt', { {f2, f3} }, 'bw_alt', [1.5*bw 0.7*bw]) ...
                );

            case "laplace"
                mu = median(x);
                b  = mean(abs(x - mu)); if b<=0, b = eps; end
                pdf_f  = @(z) (1/(2*b))*exp(-abs(z-mu)/b);
                cdf_f  = @(z) 0.5 + 0.5*sign(z-mu).*(1 - exp(-abs(z-mu)/b));
                icdf_f = @(p) mu - b*sign(p-0.5).*log(1 - 2*abs(p-0.5));
                nparams = 2;

                [LL, AIC, BIC] = aicbic_from_pdf(x, pdf_f, nparams);

                chi2 = chi2_equalprob(x, cdf_f, icdf_f, nparams, opts.TargetExp, opts.MinExpected);

                fits.(key) = struct( ...
                    'name', "Laplace", 'type', 'custom', 'pd', [], ...
                    'params', struct('mu', mu, 'b', b), ...
                    'pdf', pdf_f, 'cdf', cdf_f, 'icdf', icdf_f, ...
                    'LL', LL, 'AIC', AIC, 'BIC', BIC, ...
                    'chi2', chi2 ...
                );
                rows = [rows; llrow("Laplace", LL, AIC, BIC)];

            case cellstr(allowed_distnames_lower)
                % Check support
                if name == "lognormal" || name == "gamma" || name == "rayleigh" || name == "half normal" || name == "halfnormal"
                    if name == "lognormal" && any(x <= 0)
                        PROST.PROSTWarning.warn("AnalyzeStats", "NegativeValuesExist", '%s requires x > 0. Skipping.', name);
                        continue
                    end
                    if name ~= "lognormal" && any(x < 0)
                        PROST.PROSTWarning.warn("AnalyzeStats", "NegativeValuesExist", '%s requires x >= 0. Skipping.', name);
                        continue
                    end
                end

                try
                    pd = fitdist(x, char(name)); % toolbox object
                catch ME
                    PROST.PROSTWarning.warn("AnalyzeStats", "FitDistributionFailed", 'fitdist failed for %s: %s. Skipping.', name, ME.message);
                    continue
                end

                pdf_f  = @(z) pdf(pd, z);
                cdf_f  = @(z) cdf(pd, z);
                icdf_f = @(p) icdf(pd, p);
                nparams = numel(pd.ParameterNames);

                [LL, AIC, BIC] = aicbic_from_pdf(x, pdf_f, nparams);
                chi2 = chi2_equalprob(x, cdf_f, icdf_f, nparams, opts.TargetExp, opts.MinExpected);
                
                fits.(key) = struct( ...
                    'name', name_capitalized, 'type', 'toolbox', 'pd', pd, ...
                    'params', cell2struct(num2cell(pd.ParameterValues(:)'),  ...
                                          cellstr(pd.ParameterNames), 2), ...
                    'pdf', pdf_f, 'cdf', cdf_f, 'icdf', icdf_f, ...
                    'LL', LL, 'AIC', AIC, 'BIC', BIC, ...
                    'chi2', chi2 ...
                );
                rows = [rows; llrow(name_capitalized, LL, AIC, BIC)];

            otherwise
                PROST.PROSTWarning.warn("AnalyzeStats", "UnsuportedDistribution", 'Unsupported distribution: %s. Skipping.', name);
        end % switch name
    end % for di = 1:numel(distname)

    % -------- Rankings --------
    if ~isempty(rows)
        T = struct2table(rows);
        out.rankingAIC = sortrows(T, {'AIC','BIC'});
        out.rankingBIC = sortrows(T, {'BIC','AIC'});
    else
        out.rankingAIC = table();
        out.rankingBIC = table();
    end

    out.fits = fits;
end

% ===================== local helpers =====================

function row = llrow(name, LL, AIC, BIC)
%LLROW builds row for ranking tables
    name = PROST.utils.capitalize(name);
    row = struct('Distribution', string(name), 'LogLik', LL, 'AIC', AIC, 'BIC', BIC);
end

function [LL, AIC, BIC] = aicbic_from_pdf(x, pdf_f, kparams)
%AICBIC_FROM_PDF computes AIC, BIC and Log Likelihood from probability
% distribution function.
    px = pdf_f(x);
    px(~isfinite(px) | px<=0) = realmin;
    LL = sum(log(px));
    n = numel(x);
    AIC = 2*kparams - 2*LL;
    BIC = log(n)*kparams - 2*LL;
end

function chi2 = chi2_equalprob(x, cdf_f, icdf_f, nparams, targetExp, minExp)
%CHI2_EQUALPROB Equal‑probability bins constructed from the model icdf, then 
% merge until all expected counts >= minExp. Returns stats & bin diagnostics.
    n = numel(x);
    k0 = max(3, floor(n/targetExp));
    probability_grid = linspace(0, 1, k0 + 1)';
    probability_grid(1) = eps; probability_grid(end) = 1-eps;
    try
        edges = icdf_f(probability_grid);
    catch
        % numeric fallback if icdf not stable
        edges = icdf_numeric(cdf_f, probability_grid, x);
    end
    edges = unique(edges);
    edges = edges(isfinite(edges));

    if numel(edges) < 3
        edges = [min(x)-eps, median(x), max(x)+eps];
    end

    [O,~,~] = histcounts(x, edges);
    O = O';
    E = n * diff(cdf_f(edges));
    E(E<0) = 0;

    % merge until all E >= minExp (from the tails inward)
    while any(E < minExp) && numel(E) > 2
        idx = find(E == min(E), 1);
        if idx == 1
            O(2) = O(1)+O(2); E(2)=E(1)+E(2);
            O(1)=[]; E(1)=[]; edges(2)=[];
        elseif idx == numel(E)
            O(end-1)=O(end-1)+O(end); E(end-1)=E(end-1)+E(end);
            O(end)=[]; E(end)=[]; edges(end)=[];
        else
            if E(idx-1) <= E(idx+1)
                O(idx-1)=O(idx-1)+O(idx); E(idx-1)=E(idx-1)+E(idx);
                O(idx)=[]; E(idx)=[]; edges(idx)=[];
            else
                O(idx+1)=O(idx+1)+O(idx); E(idx+1)=E(idx+1)+E(idx);
                O(idx)=[]; E(idx)=[]; edges(idx+1)=[];
            end
        end
    end
    k_bins = numel(E);
    df = k_bins - 1 - nparams;
    if df < 1
        stat = NaN; pval = NaN;
    else
        stat = sum((O - E).^2 ./ E);
        pval = 1 - chi2cdf(stat, df);
    end

    chi2 = struct('stat', stat, 'df', df, 'pvalue', pval, ...
                  'edges', edges, 'O', O, 'E', E, 'bins', k_bins);
end

function q = icdf_numeric(F, p, xref)
%ICDF_NUMERIC Simple bisection inverse for safety
    lo = min(xref) - 5*std(xref);
    hi = max(xref) + 5*std(xref);
    q = zeros(size(p));
    for i=1:numel(p)
        a = lo; b = hi;
        for it = 1:60
            m = 0.5*(a+b);
            if F(m) < p(i), a = m; else, b = m; end
        end
        q(i) = 0.5*(a+b);
    end
end

function d = matlabContinuousDistributions()
%MATLABCONTINUOUSDISTRIBUTIONS returns the list of supported distribution names
% in the Statistics and Machine Learning Toolbox™.
    persistent list
    if isempty(list)
        pkg = meta.package.fromName('prob');
        cls = pkg.ClassList;
        names = string({cls.Name});
        names = names(endsWith(names, "Distribution"));
        names = erase(names, "Distribution");
        names = erase(names, "prob.");
        names = [names "Laplace"];
        list = sort(names);
    end
    d = list;
end

function mustBeValidDistributionOrEmpty(distnames)
%MUSTBEVALIDDISTRIBUTIONOREMPTY Validate that distnames are all members of the 
% specified set of distribution names from the Statistics and Machine Learning 
% Toolbox™ or an empty array.
    if isempty(distnames)
        return
    end

    allowed = lower(matlabContinuousDistributions());
    distnames = erase(lower(distnames), whitespacePattern);
    mustBeMember(distnames, allowed);
end


