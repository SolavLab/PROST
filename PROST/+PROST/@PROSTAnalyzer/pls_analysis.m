function [XL, YL, XS, YS, BETA, PCTVAR, MSE, stats] = pls_analysis(obj, show, file_type)
%PLS_ANALYSIS calculates the Partial Least Squares regression of
% the sample data and plots percent variance.
% Input :
%   show - whether to show the figures or save them. Either "on"
%          (default) for showing the figures or "off" for saving them.
%   file_type - the type to save the figure if saved.
% Output :
%   XL, YL, XS, YS, BETA, PCTVAR, MSE, stats – PLS regression
%   parameters as described in the plsregress documentation.

    % Prep Input Arguments
    if nargin < 3
        file_type = [];
    end
    if nargin < 2
        show = 'on';
    end

    % Get features
    [features, feature_names, ~, features_types] = obj.get_features();
    feature_names = string(feature_names);
    X = [];
    X_continuous = features{:, strcmp(features_types, 'double')};

    X = [X_continuous dummyvar(features.Gender) dummyvar(features.Is_shod)];
    % for k = 1:numel(feature_names)
    %     feature = features.(feature_names(k));
    %
    %     if ~strcmp(features_types{k}, 'double')
    %         % continue
    %         X = [X dummyvar(categorical(feature))];
    %     else
    %         X = [X feature];
    %     end
    % end
    % Standardize X
    [Xz, muX, sigmaX] = zscore(X);

    % Get labels
    [labels, label_names, label_units, ~] = obj.get_labels();
    Y = table2array(labels);
    label_names = string(replace(label_names, "_", " "));
    label_units = string(replace(label_units, "_", " "));

    % Standardize Y
    [Yz, muY, sigmaY] = zscore(Y);

    % Calculate PLS regression
    ncomp = width(Xz);
    [~, ~, ~, ~, ~, PCTVAR, MSE, ~] = plsregress(Xz, Yz, ncomp, Intercept=false);

    % Show percent variance explained in features
    % fig = figure(Name="PLS:Percent Variance in X", Visible=show);
    % plot(1:ncomp, cumsum(100*PCTVAR(1, :)), '-bo');
    % xlabel('Number of PLS components');
    % ylabel('Percent Variance Explained in X');
    % grid on
    % if strcmp(show, 'off')
    %     disp("Saving figure...")
    %     file_path = fullfile(obj.toolbox_root, "figures/ROS Analysis/PLS");
    %     PROST.PROSTAnalyzer.save_figure(fig, file_path, file_type);
    %     disp("Figure saved.")
    % end

    % Show percent variance explained in labels
    fig = figure(Name="PLS:Percent Variance in Y", Visible=show);
    plot(1:ncomp, cumsum(100*PCTVAR(2, :)), '-bo');
    xlabel('Number of PLS components');
    ylabel('Percent Variance Explained in Y');
    grid on
    if strcmp(show, 'off')
        fprintf("Saving Percent Variance in Y...\n");
        file_path = fullfile(obj.toolbox_root, "figures/ROS Analysis/PLS");
        PROST.PROSTAnalyzer.save_figure(fig, file_path, file_type);
        fprintf("Figure saved.\n");
    end

    fig = figure(Name="PLS:MSE per Num Components", Visible=show);
    yyaxis left
    plot(0:ncomp, MSE(1,:),'-o')
    yyaxis right
    plot(0:ncomp, MSE(2,:),'-o')
    legend('MSE Predictors','MSE Response')
    xlabel('Number of Components')
    if strcmp(show, 'off')
        fprintf("Saving MSE per Num Components...\n");
        file_path = fullfile(obj.toolbox_root, "figures/ROS Analysis/PLS");
        PROST.PROSTAnalyzer.save_figure(fig, file_path, file_type);
        fprintf("Figure saved.\n");
    end

    % Calculate PLS regression
    ncomp = 8;
    [XL, YL, XS, YS, BETA, PCTVAR, MSE, stats] = plsregress(Xz, Yz, ncomp, Intercept=false);

    fig = figure(Name="PLS:Fit v.s. Data", Visible=show);
    tiledlayout
    cmap = lines(numel(label_names));
    marker_size = 5;

    % yfit = XS*YL'.*sigmaY + muY;
    yfit = Xz*BETA.*sigmaY + muY;
    TSS = sum((Y - mean(Y, 1)).^2, 1);
    RSS = sum((Y - yfit()).^2, 1);
    Rsquared = round(1 - RSS./TSS, 3);
    for k=1:numel(label_names)
        y_k = Y(:, k);
        yfit_k = yfit(:, k);
        ax = nexttile;
        hold(ax, "on")
        axis(ax, "equal")
        yyaxis left
        plot(ax, y_k, obj.MARKERS(1), MarkerSize=obj.MARKER_SIZE, DisplayName=label_names(k));
        ylabel("DATA")
        yyaxis right
        plot(ax, yfit_k, obj.MARKERS(1)', MarkerSize=obj.MARKER_SIZE, DisplayName=label_names(k));
        ylabel("FIT")
        x_limits = xlim(ax);
        y_limits = ylim(ax);
        text(ax, x_limits(1), y_limits(2), "Rsquared = " + Rsquared(k), FontSize=12, FontWeight="bold", Color=cmap(k, :))

        % Set axis labels
        x_label = "Data";
        y_label = "Fit";
        if ~isempty(label_units(k))
            x_label = x_label  + " [" + label_units(k) + "]";
            y_label = y_label  + " [" + label_units(k) + "]";
        end
        % xlabel(ax, x_label)
        % ylabel(ax, y_label)
        title(label_names(k))
        grid(ax, "on");
    end
    if strcmp(show, 'off')
        fprintf("Saving Fit v.s. Data...\n");
        file_path = fullfile(obj.toolbox_root, "figures/ROS Analysis/PLS");
        PROST.PROSTAnalyzer.save_figure(fig, file_path, file_type);
        fprintf("All figure saved.\n");
    end
end