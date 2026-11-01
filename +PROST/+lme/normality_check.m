function normality_check(varaiable, var_name, test_type)
% TEST_NORMALITY(VAR, NAME, TEST_TYPE)
% Normality test for variable. 
% Plots a histogram against the Gaussian PDF and a QQ-plot.
% Performs a normality test and prints the result to command window.
% Ignores nan and inf values of the variable.
%
% Input :
%   varaiable - the variable to test.
%   var_name - the name of the variable to test for printing.
%   test_type - the type of test to perform. One of the following:\n\n
%              'anderson'   - Anderson-Darling (default)
%              'chi2gof'    - Chi2 goodness-of-fit
%              'lilliefors' - Kolmogorov-Smirnov (standardized)
%              'kolmogorov' - Lilliefors
%
% Example usage:
%   test_normality(var, "variable", "chi2gof")
%   test_normality(var, "variable")


arguments
    varaiable {mustBeNumeric}
    var_name  (1, 1) string
    test_type (1, 1) string {mustBeMember(test_type, ["anderson" "chi2gof" "kolmogorov" "lilliefors"])} = "anderson"
end

    varaiable = varaiable(~isnan(varaiable) & ~isinf(varaiable));

    switch test_type
    case "chi2gof"
        % Chi-squared Goodness-of-Fit test
        [h, p, stat] = chi2gof(varaiable);
        fprintf('\n--- Chi-Squared Normality Test on %s ---\n', var_name);
        fprintf('Rejection Decision (h): %d (where 1 = Non-normal)\n', h);
        fprintf('Test Statistic (Chi^2): %.2g\n', stat.chi2stat);
        fprintf('p-value:                %.2g\n', p);
    case "lilliefors"
        % Lilliefors test
        [h, p, stat, cv] = lillietest(varaiable);
        fprintf('\n--- Lilliefors Normality Test on %s ---\n', var_name);
        fprintf('Rejection Decision (h): %d (where 1 = Non-normal)\n', h);
        fprintf('Test Statistic (D):     %.2g (critical value = %.2g)\n', stat, cv);
        fprintf('p-value:                %.2g\n', p);
    case "anderson"
        % Anderson-Darling test
        [h, p, stat, cv] = adtest(varaiable);
        fprintf('\n--- Anderson-Darling Normality Test on %s ---\n', var_name);
        fprintf('Rejection Decision (h): %d (where 1 = Non-normal)\n', h);
        fprintf('Test Statistic (A^2):   %.2g (critical value = %.2g)\n', stat, cv);
        fprintf('p-value:                %.2g\n', p);
    case "kolmogorov" 
        % standardized KS vs N(0,1)
        [h, p, stat, cv] = kstest((varaiable - mean(varaiable)) / std(varaiable));
        fprintf('\n--- Standardized Kolmogorov-Smirnov Normality Test on %s ---\n', var_name);
        fprintf('Rejection Decision (h): %d (where 1 = Non-normal)\n', h);
        fprintf('Test Statistic (D):     %.2g (critical value = %.2g)\n', stat, cv);
        fprintf('p-value:                %.2g\n', p);
    end

    figure(Name="QQ-plot: " + var_name)
    qqplot(varaiable)
    title("QQ-plot: " + var_name)
    grid on

    figure(Name="Histogram: " + var_name)
    histogram(varaiable, Normalization='pdf', DisplayName="Histogram")
    hold on

    xx = linspace(min(varaiable), max(varaiable), 100);
    mu = mean(varaiable);
    sigma = std(varaiable);
    median_val = median(varaiable);
    quartiles = prctile(varaiable, [25 75]);
    Q1 = quartiles(1);
    Q3 = quartiles(2);

    plot(xx, normpdf(xx, mu, sigma), 'r-', LineWidth=1.5,  LineStyle='-', DisplayName="Normal Distribution")  
    xline(mu, 'b-', LineWidth=1.5, DisplayName="Mean")
    xregion(mu - sigma, mu + sigma, FaceColor=0.7*[0 0 1], FaceAlpha= 0.1, LineStyle='none', DisplayName="\pm SD")   
    xline(median_val, 'k-', LineWidth=1.5, DisplayName="Median")
    xregion(Q1, Q3, FaceColor=(1 - 0.7)*[1 1 1], FaceAlpha= 0.1, LineStyle='none', DisplayName="IQR")

    title(var_name + " vs Normal Distribution")
    xlabel(var_name)
    ylabel('Probability Density Function')
    legend
    grid on
end
