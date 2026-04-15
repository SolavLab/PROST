%% Partial Least Squares Regression and Principal Components Regression
% This example shows how to apply partial least squares regression (PLSR) and 
% principal components regression (PCR), and explores the effectiveness of the 
% two methods. PLSR and PCR are both methods to model a response variable when 
% there are a large number of predictor variables, and those predictors are highly 
% correlated or even collinear. Both methods construct new predictor variables, 
% known as components, as linear combinations of the original predictor variables, 
% but they construct those components in different ways. PCR creates components 
% to explain the observed variability in the predictor variables, without considering 
% the response variable at all. On the other hand, PLSR does take the response 
% variable into account, and therefore often leads to models that are able to 
% fit the response variable with fewer components. Whether or not that ultimately 
% translates into a more parsimonious model, in terms of its practical use, depends 
% on the context.
%% Initialize Script

clearvars -except DB_1 DB_2 DB_3
script_full_path = matlab.desktop.editor.getActiveFilename; % Get full path of the current script
script_folder = fileparts(script_full_path); % Get the folder of the script
cd(script_folder); % Change to folder of current script
data_path = "C:\Users\chenr\Documents\PROST"; % Path to PROST toolbox

%% Loading the Data
% Load a data set comprising anthropometric data and roll-over shape radii of 
% participants from a unified database. These data are from the PROST toolbox.

db_list = ["DB_1" "DB_3" "DB_2"];
for idx=1:length(db_list)
    db_name = db_list(idx);
    if ~exist(db_name, 'var')
       load(fullfile(data_path, erase(db_name, "_"), db_name + ".mat"));
    end
end

load_list = {DB_1, "DB_1"; DB_2, "DB_2"; DB_3, "DB_3"};
ignore_list = {"DB_1", [3 5 14 15 16], [5 14 15 16]; "DB_2", [31], []; "DB_3", [43, 47], []};
obj = PROST.PROSTAnalyzer(load_list);
[features, feature_names, feature_units, feature_types] = obj.get_features(["Age" "Height" "Mass" "Leg_length" "Thigh_length" "Shank_length" "Sex"]);
% features.Is_shod = categorical(features.Is_shod);
[labels, label_names, label_units, label_types] = obj.get_labels(["Radius"]);
sides = obj.get_sample_var("Side");
disp([height(features) height(labels) height(sides)])

filter_idx = isoutlier(labels.Radius);
labels(filter_idx, :) = [];
features(filter_idx, :) = [];
sides(filter_idx, :) = [];
disp([height(features) height(labels) height(sides)])

%% Data Visualization

figure
tiledlayout
for idx=1:numel(feature_names)
    for kdx=1:numel(label_names)
        nexttile
        if sides(1) == "left"
            color = [0.7 0 0.1; 0 0.7 0.4];
        else
            color = [0 0.7 0.4; 0.7 0 0.1];
        end
        gscatter(features.(feature_names{idx}), labels.(label_names{kdx}), sides, color, 'o', 5, 'off', 'filled')
        grid on
        legend("left", "right")
        xlabel(replace(feature_names{idx}, "_", " ") + " [" + feature_units{idx} + "]")
        ylabel(replace(label_names{kdx}, "_", " ") + " [" + label_units{kdx} + "]")
    end
end
%% 
% Some statistics about our responses
figure
tiledlayout
for idx=1:numel(label_names)
    label_name = label_names{idx};
    label_unit = label_units{idx};
    nexttile
    h1 = histogram(labels.(label_name)(sides == "left"), 'FaceAlpha', 0.5);
    hold on
    h2 = histogram(labels.(label_name)(sides == "right"), 'FaceAlpha', 0.5);
    h1.Normalization = "probability";
    h2.Normalization = "probability";
    h1.NumBins = 10;
    h2.BinWidth = h1.BinWidth;
    xlabel(replace(label_name, "_", " ") + " [" + label_unit + "]")
    legend("left", "right")
    title(replace(label_name, "_", " ") + " Histogram")
end
figure
tiledlayout
for idx=1:numel(feature_names)
    feature_name = feature_names{idx};
    feature_unit = feature_units{idx};
    nexttile
    h1 = histogram(features.(feature_name)(sides == "left"), 'FaceAlpha', 0.5);
    hold on
    h2 = histogram(features.(feature_name)(sides == "right"), 'FaceAlpha', 0.5);
    h1.Normalization = "probability";
    h2.Normalization = "probability";
    if ~strcmp(feature_name, "Sex") && ~strcmp(feature_name, "Is_shod")
        h1.NumBins = 10;
        h2.BinWidth = h1.BinWidth;
    end
    xlabel(replace(feature_name, "_", " ") + " [" + feature_unit + "]")
    legend("left", "right")
    title(replace(feature_name, "_", " ") + " Histogram")
end
%%
figure
tiledlayout
for idx=1:numel(feature_names)
    if feature_types{idx} ~= "double"
            continue
    end
    for kdx=1:numel(label_names)        
        nexttile
        c = features.(feature_names{idx}); 
        y = labels.(label_names{kdx});
        histogram2(c, y, 20, 'FaceColor', 'flat', 'ShowEmptyBins', 'on', 'Normalization', 'probability')
        view(2)
        xlabel(replace(feature_names{idx}, "_", " ") + " [" + feature_units{idx} + "]")
        ylabel(replace(label_names{kdx}, "_", " ") + " [" + label_units{kdx} + "]")
       
    end
end
%%
for kdx=1:numel(label_names)  
    nexttile
    c = features.Sex; 
    y = labels.(label_names{kdx});
    h1 = histogram(y(c == "Male"), "FaceAlpha", 0.5);
    hold on
    h2 = histogram(y(c == "Female"), "FaceAlpha", 0.5);
    h1.Normalization = 'probability';
    h1.BinWidth = 50;
    h2.Normalization = 'probability';
    h2.BinWidth = 50;

    xlabel(replace(label_names{kdx}, "_", " ") + " [" + label_units{kdx} + "]")
    legend("Male", "Female")
end
%% Fitting the Data with Two Components
% Use the |plsregress| function to fit a PLSR model with ten PLS components 
% and one response.

X = features{:, features.Properties.VariableTypes == 'double'};
if ismember("Sex", feature_names)
    sex_var = dummyvar(features.Sex);
    X = [X sex_var(:, 1)];
end
% if ismember("Is_shod", feature_names)
%     X = [X dummyvar(features.Is_shod)];
% end
y = labels.Radius;
[X0, mu_x, sigma_x] = zscore(X);
[y0, mu_y, sigma_y] = zscore(y);
[n, p] = size(X0);
[Xloadings, Yloadings, Xscores, Yscores, betaPLS10, PLSPctVar, MSE] = plsregress(X0, y0, p, Intercept=false);
%% 
% Seven components may be more than will be needed to adequately fit the data, 
% but diagnostics from this fit can be used to make a choice of a simpler model 
% with fewer components. For example, one quick way to choose the number of components 
% is to plot the percent of variance explained in the response variable as a function 
% of the number of components.

figure
plot(1:p,cumsum(100*PLSPctVar(2,:)),'-bo');
xlabel('Number of PLS components');
ylabel('Percent Variance Explained in Y');
grid on
%%
figure
yyaxis left
plot(0:p, MSE(1, :),'-o');
yyaxis right
plot(0:p, MSE(2, :),'-o');
xlabel('Number of PLS components');
legend('MSE predictors', 'MSE Response');
grid on
%% 
% In practice, more care would probably be advisable in choosing the number 
% of components. Cross-validation, for instance, is a widely-used method that 
% will be illustrated later in this example. For now, the above plot suggests 
% that PLSR with two components explains most of the variance in the observed 
% |y|. Compute the fitted response values for the two-component model.

ncomp = 5;
[Xloadings,Yloadings,Xscores,Yscores,betaPLS] = plsregress(X0,y0,ncomp, intercept=false);
y0fitPLS = X0*betaPLS;
%% 
% Next, fit a PCR model with two principal components. The first step is to 
% perform Principal Components Analysis on |X|, using the |pca| function, and 
% retaining two principal components. PCR is then just a linear regression of 
% the response variable on those two components. It often makes sense to normalize 
% each variable first by its standard deviation when the variables have very different 
% amounts of variability, however, that is not done here.

[PCALoadings,PCAScores,PCAVar] = pca(X0,'Economy',false, 'Centered', false);
betaPCR = regress(y0, PCAScores(:,1:ncomp));
%% 
% To make the PCR results easier to interpret in terms of the original data, 
% transform to regression coefficients for the original, uncentered variables.

betaPCR = PCALoadings(:,1:ncomp)*betaPCR;
y0fitPCR = X0*betaPCR;
%% 
% Plot fitted vs. observed response for the PLSR and PCR fits for normalized 
% data.

figure
plot(y0,y0fitPLS,'bo',y0,y0fitPCR,'r^');
hold on
x_lim = xlim;
y_lim = ylim;
line_x_y = [max(x_lim(1), y_lim(1)) min(x_lim(2), y_lim(2))];
plot(line_x_y, line_x_y, 'k', LineWidth=2)
xlabel('Observed Response');
ylabel('Fitted Response');
legend(["PLSR with " + ncomp + " Components" "PCR with " + ncomp + " Components"],  ...
	'location','NW');

axis equal
title("Fit Vs Observed - Normalized")
grid on
%% 
% Change fits so they estimate the original data rather than normalized data.

yfitPLS = y0fitPLS.*sigma_y + mu_y;
yfitPCR = y0fitPCR.*sigma_y + mu_y;
%% 
% Plot fitted vs. observed response for the PLSR and PCR fits.

figure
plot(y,yfitPLS,'bo',y,yfitPCR,'r^');
hold on
x_lim = xlim;
y_lim = ylim;
line_x_y = [max(x_lim(1), y_lim(1)) min(x_lim(2), y_lim(2))];
plot(line_x_y, line_x_y, 'k', LineWidth=2)
xlabel('Observed Response');
ylabel('Fitted Response');
legend(["PLSR with " + ncomp + " Components" "PCR with " + ncomp + " Components"],  ...
	'location','NW');
axis equal
title("Fit Vs Observed")
grid on
%% 
% In a sense, the comparison in the plot above is not a fair one -- the number 
% of components (two) was chosen by looking at how well a two-component PLSR model 
% predicted the response, and there's no reason why the PCR model should be restricted 
% to that same number of components. With the same number of components, however, 
% PLSR does a much better job at fitting |y|.

TSS = sum((y-mean(y)).^2);
RSS_PLS = sum((y-yfitPLS).^2);
rsquaredPLS = 1 - RSS_PLS/TSS;
disp("rsquaredPLS: " + rsquaredPLS)
%%
RSS_PCR = sum((y-yfitPCR).^2);
rsquaredPCR = 1 - RSS_PCR/TSS;
disp("rsquaredPCR: " + rsquaredPCR)
%% 
% Another way to compare the predictive power of the two models is to plot the 
% response variable against the two predictors in both cases.

figure
plot3(Xscores(:, 1), Xscores(:, 2), y0,'bo');
legend('PLSR');
grid on; view(-30,30);
title("3D PLSR Predictors vs Response")
%% 

figure
plot3(PCAScores(:,1),PCAScores(:,2),y0,'r^');
legend('PCR');
grid on; view(-30,30);
title("3D PCR Predictors vs Response")
%% 
% Notice that while the two PLS components are much better predictors of the 
% observed |y|, the following figure shows that they explain somewhat less variance 
% in the observed |X| than the first two principal components used in the PCR.

ncomp = width(X0);
figure
plot(1:ncomp,100*cumsum(PLSPctVar(1,:)),'b-o',1:ncomp,  ...
	100*cumsum(PCAVar(1:ncomp))/sum(PCAVar(1:ncomp)),'r-^');
xlabel('Number of Principal Components');
ylabel('Percent Variance Explained in X');
legend({'PLSR' 'PCR'},'location','SE');
%% 
% The fact that the PCR curve is uniformly higher suggests why PCR with two 
% components does such a poor job, relative to PLSR, in fitting |y|. PCR constructs 
% components to best explain |X|, and as a result, those first two components 
% ignore the information in the data that is important in fitting the observed 
% |y|.
%% Fitting with More Components
% As more components are added in PCR, it will necessarily do a better job of 
% fitting the original data |y|, simply because at some point most of the important 
% predictive information in |X| will be present in the principal components. For 
% example, the following figure shows that the difference in residuals for the 
% two methods is much less dramatic when using seven components than it was for 
% two components.

yfitPLS10 = X0*betaPLS10.*sigma_y + mu_y;
betaPCR10 = regress(y0, PCAScores(:, 1:p));
betaPCR10 = PCALoadings(:,1:p).*betaPCR10;
yfitPCR10 = X0*betaPCR10.*sigma_y + mu_y;
figure
plot(y,yfitPLS10,'bo',y,yfitPCR10,'r^');
xlabel('Observed Response');
ylabel('Fitted Response');
legend(["PLSR with " + p + " Components" "PCR with " + p + " Components"],  ...
	'location','NW');
title("Fit Vs Observed")
%% 
% Both models fit |y| fairly accurately, although PLSR still makes a slightly 
% more accurate fit. However, seven components is still an arbitrarily-chosen 
% number for either model.
%% Choosing the Number of Components with Cross-Validation
% It's often useful to choose the number of components to minimize the expected 
% error when predicting the response from future observations on the predictor 
% variables. Simply using a large number of components will do a good job in fitting 
% the current observed data, but is a strategy that leads to overfitting. Fitting 
% the current data too well results in a model that does not generalize well to 
% other data, and gives an overly-optimistic estimate of the expected error.
% 
% Cross-validation is a more statistically sound method for choosing the number 
% of components in either PLSR or PCR. It avoids overfitting data by not reusing 
% the same data to both fit a model and to estimate prediction error. Thus, the 
% estimate of prediction error is not optimistically biased downwards.
% 
% |plsregress| has an option to estimate the mean squared prediction error (MSEP) 
% by cross-validation, in this case using 10-fold C-V.

[Xl,Yl,Xs,Ys,beta,pctVar,PLSmsep] = plsregress(X0,y0, p,'CV',10);
%% 
% For PCR, |crossval| combined with a simple function to compute the sum of 
% squared errors for PCR, can estimate the MSEP, again using 10-fold cross-validation.

PCRmsep = sum(crossval(@pcrsse,X0,y0,'KFold',10),1) / n;
%% 
% The MSEP curve for PLSR indicates that two or three components does about 
% as good a job as possible. On the other hand, PCR needs four components to get 
% the same prediction accuracy.

figure
plot(0:p,PLSmsep(2,:),'b-o',0:p,PCRmsep,'r-^');
xlabel('Number of components');
ylabel('Estimated Mean Squared Prediction Error');
legend({'PLSR' 'PCR'},'location','NE');
title("MSE after Cross-Validation")
%% 
% In fact, the second component in PCR _increases_ the prediction error of the 
% model, suggesting that the combination of predictor variables contained in that 
% component is not strongly correlated with |y|. Again, that's because PCR constructs 
% components to explain variation in |X|, not |y|.
%% Model Parsimony
% So if PCR requires four components to get the same prediction accuracy as 
% PLSR with three components, is the PLSR model more parsimonious? That depends 
% on what aspect of the model you consider.
% 
% The PLS weights are the linear combinations of the original variables that 
% define the PLS components, i.e., they describe how strongly each component in 
% the PLSR depends on the original variables, and in what direction.

[Xl,Yl,Xs,Ys,beta,pctVar,mse,stats] = plsregress(X,y,5);
figure
plot(1:p,stats.W,'-*', LineWidth=2, MarkerSize=5);
xlabel('Variable');
xticklabels(["Age" "Height" "Mass" "Leg Length" "Thigh Length" "Shank Length" "Sex (Male)"])
ylabel('PLS Weight');
legend({'1st Component' '2nd Component' '3rd Component' '4th Component' ...
        '5th Component'},  'location','NW');
title("PLSR Weights for Each Variable")
grid on
%% 
% Similarly, the PCA loadings describe how strongly each component in the PCR 
% depends on the original variables.

figure
plot(1:p,PCALoadings(:,1:7),'-*', LineWidth=2, MarkerSize=5);
xlabel('Variable');
xticklabels(["Age" "Height" "Mass" "Leg Length" "Thigh Length" "Shank Length" "Sex (Male)"])
ylabel('PCA Loading');
legend({'1st Component' '2nd Component' '3rd Component'  ...
	    '4th Component' '5th Component' '6th Component' '7th Component'}, ...
        'location','NW');
title("PCR Weights for Each Variable")
grid on
%% 
% For either PLSR or PCR, it may be that each component can be given a physically 
% meaningful interpretation by inspecting which variables it weights most heavily. 
% For instance, with these spectral data it may be possible to interpret intensity 
% peaks in terms of compounds present in the gasoline, and then to observe that 
% weights for a particular component pick out a small number of those compounds. 
% From that perspective, fewer components are simpler to interpret, and because 
% PLSR often requires fewer components to predict the response adequately, it 
% leads to more parsimonious models.
% 
% On the other hand, both PLSR and PCR result in one regression coefficient 
% for each of the original predictor variables, plus an intercept. In that sense, 
% neither is more parsimonious, because regardless of how many components are 
% used, both models depend on all predictors. More concretely, for these data, 
% both models need 401 spectral intensity values in order to make a prediction.
% 
% However, the ultimate goal may be to reduce the original set of variables 
% to a smaller subset still able to predict the response accurately. For example, 
% it may be possible to use the PLS weights or the PCA loadings to select only 
% those variables that contribute most to each component. As shown earlier, some 
% components from a PCR model fit may serve primarily to describe the variation 
% in the predictor variables, and may include large weights for variables that 
% are not strongly correlated with the response. Thus, PCR can lead to retaining 
% variables that are unnecessary for prediction.
% 
% For the data used in this example, the difference in the number of components 
% needed by PLSR and PCR for accurate prediction is not great, and the PLS weights 
% and PCA loadings seem to pick out the same variables. That may not be true for 
% other data.
% 
% _Copyright 2008 The MathWorks, Inc._