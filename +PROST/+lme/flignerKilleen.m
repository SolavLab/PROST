function [pval, stat, df] = flignerKilleen(data, group)
    % FLIGNERKILLEEN  Fligner-Killeen test for homogeneity of variances
    %   data  : vector of observations
    %   group : vector/categorical of group labels (same length as data)

    data = data(:);
    group = group(:);
    groups = unique(group);
    k = numel(groups);
    N = numel(data);

    % Step 1: center each group by its median
    centered = zeros(N,1);
    for i = 1:k
        idx = group == groups(i);
        centered(idx) = abs(data(idx) - median(data(idx)));
    end

    % Step 2: rank the absolute centered values (overall ranks)
    ranks = tiedrank(centered);

    % Step 3: Fligner-Killeen scores = normal quantile transform of ranks
    a = norminv(0.5 + ranks/(2*(N+1)));

    % Step 4: compute test statistic
    abar = mean(a);
    v = var(a); % variance of the scores, used as normalizing constant

    stat = 0;
    for i = 1:k
        idx = group == groups(i);
        ni = sum(idx);
        Ai = sum(a(idx));
        stat = stat + ni * (Ai/ni - abar)^2;
    end
    stat = stat / v;

    df = k - 1;
    pval = 1 - chi2cdf(stat, df);

    fprintf('Fligner-Killeen: chi-sq = %.4f, df = %d, p = %.4g\n', stat, df, pval);
end
