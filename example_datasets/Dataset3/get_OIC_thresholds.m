function [right_OIC_threshold, left_OIC_threshold] = get_OIC_thresholds(walking_data, MarkerVarName, threshold_shift)
% GET_OIC_THRESHOLDS finds the IC heel height of the right and
% left foot. This will be used as the threshold height of the OIC of all
% the trials.
% Each threshold is found by first finding all trials of that leg and
% taking the heel height at initial contact. Averaging all those values
% gives the OIC threshold for the opposite leg. These thresholds are then
% shifted by a constant amount so it isn't too low.
%   Input :
%       walking_data - the data of the walking trials.
%       MarkerVarNames - a list of the marker names where each name index
%       corresponds to that marker's row in the data.
%       threshold_shift – a parameter to shift the left and right thresholds 
%       upwards. Units: [m]. Default: 0.
%   Output :
%       right_OIC_threshold, left_OIC_threshold - right and left thresholds
%       of the heel heights to use for finding OIC event.

if nargin < 3
    threshold_shift = 0.0;
end

% Number of trials
n_trials = length(walking_data);

% Important indices: IC, left heel height, right heel height
IC_index = 1;
iYRxHeel = strmatch("YRxHeel", MarkerVarName, 'exact');
iYLxHeel = strmatch("YLxHeel", MarkerVarName, 'exact');

% % Extract data from the first trial
% trial = walking_data(1);
% 
% % The foot that does the initial contact
% foot = trial.Foot;
% 
% % Find trial with other foot
% other_foot = foot;
% other_trial = trial;
% for t=1:n_trials
%     if ~strcmp(walking_data(t).Foot, foot)
%         other_foot = walking_data(t).Foot;
%         other_trial = walking_data(t);
%         break
%     end
% end

% Calculate average OIC threshold of all right foot trials
right_OIC_threshold = 0;
n_right_trials = 0;
for t=1:n_trials
    trial = walking_data(t);
    foot = walking_data(t).Foot;
    if strcmp(foot, 'RX')
        right_OIC_threshold = right_OIC_threshold + trial.Marker(iYRxHeel, IC_index);
        n_right_trials = n_right_trials + 1;
    end
end
right_OIC_threshold = right_OIC_threshold / n_right_trials;

% Calculate average OIC threshold of all left foot trials
left_OIC_threshold = 0;
n_left_trials = 0;
for t=1:n_trials
    trial = walking_data(t);
    foot = walking_data(t).Foot;
    if strcmp(foot, 'LX')
        left_OIC_threshold = left_OIC_threshold + trial.Marker(iYLxHeel, IC_index);
        n_left_trials = n_left_trials + 1;
    end
end
left_OIC_threshold = left_OIC_threshold / n_left_trials;

% If one foot is missing use the other's threshold
if n_right_trials == 0
    right_OIC_threshold = left_OIC_threshold;
end
if n_left_trials == 0
    left_OIC_threshold = right_OIC_threshold;
end

% Add to threshold just in case it's too low
right_OIC_threshold = right_OIC_threshold + threshold_shift;
left_OIC_threshold = left_OIC_threshold + threshold_shift;
end

