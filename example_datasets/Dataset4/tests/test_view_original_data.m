% % 11.01.2026, Chen Reichsbouscher TODO: make sure credit is ok
%
% Modified from ExampleCode_LoadStruct_PlotTimeNormVar_v1.m:
% 19.09.2023, Lizeth Sloot, Heidelberg University / Newcastle University.
% ------------------------------------------------------------------------------
% READ-IN AND PLOT TIME-NORMALIZED DATA STRUCTURES AND ORIGINAL RAW DATA
% Example code to use the structure.
%
%
% input: time-normalized structure van Criekinge et al, 2022
% eg. MAT_normalizedData_AbleBodiedAdults_v06-03-23
%
% output: 
% Figure of the selected variable of interest (.fig and .png)
%
% 19.09.2023, Lizeth Sloot, Heidelberg University / Newcastle University.
%
% MIT License:
% 
% Copyright (c) 2022 Lizeth Sloot (LizSloot)
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.

clearvars -except -regexp ^Dataset_\d+$
close all
clc

script_full_path = matlab.desktop.editor.getActiveFilename; % Get full path of the current script
script_folder = fileparts(script_full_path); % Get the folder of the script
cd(script_folder);

% Define data files folder
data_path = "..\Data Files";

% Add PROST package root to path
toolbox_root = split(script_folder, filesep);
i_end = find(matches(toolbox_root, "PROST"), 1, "last");
toolbox_root = fullfile(toolbox_root{1:i_end});
addpath(toolbox_root); % Add PROST package to path

set(0, 'DefaultFigureWindowStyle', 'docked'); % Set figures as undocked windows 

%% General Settings

%%% 1. Set path to directory of the Structure you want to load!
settings.mainDir = data_path;

%%% 2. Load Structure
% Give the name of the structure you want to load:
settings.StructNameTimeNorm = 'MAT_normalizedData_AbleBodiedAdults_v06-03-23';
settings.StructNameRaw = 'raw_data.mat';
StructTimeNorm = load(fullfile(settings.mainDir, settings.StructNameTimeNorm));
StructRaw = load(fullfile(settings.mainDir, settings.StructNameRaw));

%%% 3. Set saving settings
settings.SaveFig = 0;       % set to 1 if you want to save the figure, set to 0 if not.
settings.SaveDir = fullfile(settings.mainDir,'Figures');

%%% 4. Set Figure settings
% Set the "Segment Sides" as defined in the Structure. 
% (eg. DataStruct.Sub(1).PsideSegm_PsideData --> PsideSegm and NPsideSegm)
% For Able bodied (MAT_normalizedData_AbleBodiedAdults_v06-03-23), this is
% left and right (or SideSegm = 'LR')
settings.SideSegm = 'LR';

% Both sides are plotted in a different color and line type. 
% note, first side (defined above) will get the first color.
settings.Color = 'br';
settings.MarkerSymbol = {'-';'--'};
settings.LineWidth = 1.5;

% Set the number of subplots in a single figure. 
% if you set it lower, the subplot per participant will get larger, but
% less will fit in a single figure. 
% For Able bodied, 12x12 seems to work well. 
settings.nCol = 12;        
settings.nRow = 12;    

% Mappings for code - Do not change
settings.dimensionMap = dictionary('x', 1, 'y', 2, 'z', 3, 'n', 1);
settings.FPVariableMap = dictionary('GroundReactionForce', 'force', 'GroundReactionMoment', 'moment', 'CenterOfPressure', 'center_of_pressure');
settings.oppositeSideMap = dictionary('L', {'R'}, 'R', {'L'});


%% Select the data you want to plot

%%% 1. Specify the variable(s) of interest to plot:
% You can give a series of variables (it will run in a loop) or a single
% one.
variables = {'GroundReactionForce', 'ANK'};

%%% 2. Specify the dimension to plot for each of these variables:
% This can be x, y, z, or n (non-dimensional). Check the Structure.
Dims = {'z', 'z'};    

%%% 3. Specify the body side of the data you want to look at for each of these 
% variables:
% Options are: 'L', 'R', 'B', 'I', 'C'.
% 'L' or 'R' - the code will plot the left or right side data of both the e.g. 
% Left-side-segmented (stride normalized based on left side gait events) and the 
% Right-side-segmented data.
% 'I', 'C'  - for ipsilateral (same side) or for contralateral 
% (opposite side).
% If you are interested in whole-body parameters that aren't related to one
% side (eg center-of-mass, sternum marker), use 'B').
% 'LR' - If you want to plot both left and right side data for each segment.
SideData = {'I', 'C'};
% SideData = {'C'};
% SideData = {'LR'};
% SideData = {'B'};
% SideData = {'R'};
% SideData = {'L'};

% Get Screen size
% scrsz = get(0,'ScreenSize');
% scrplt.x(1) = round( scrsz(3)*0.05 );
% scrplt.x(2) = round( scrsz(3)*0.75 );
% scrplt.y(1) = round( scrsz(4)*0.05 );
% scrplt.y(2) = round( scrsz(4)*0.75 );

%% Plot Time Normalized Data
% Graph per var:
for iVar = 1:length(variables)
    disp(['Working on plotting var from time normalzied data: ',variables{iVar}])
    
    % Initiate figure
    figure, set(gcf,'name',variables{iVar},'color',[1 1 1]);    
    
    % Plot individual data
    tiledlayout%(settings.nCol,settings.nRow, 'Padding', 'none', 'TileSpacing', 'compact'); 
    for iSub = 1:5%:size(StructTime.Sub,2)
        nexttile       
        yline(0, '-k')
        hold on
        
        for iSegment = 1:length(settings.SideSegm)
            for iSide = 1:strlength(SideData{iVar})
                if strcmp(SideData{iVar}(iSide), 'I')
                    side = settings.SideSegm(iSegment);
                elseif strcmp(SideData{iVar}(iSide), 'C')
                    side = settings.oppositeSideMap{settings.SideSegm(iSegment)};
                else
                    side = SideData{iVar}(iSide);
                end
                if ~isempty(StructTimeNorm.Sub(iSub). ...
                        ([settings.SideSegm(iSegment), 'sideSegm_', side, 'sideData']) )
                    if isfield(StructTimeNorm.Sub(iSub). ...
                            ([settings.SideSegm(iSegment), 'sideSegm_', side, 'sideData']), ...
                            ([variables{iVar}]))
                        if isfield(StructTimeNorm.Sub(iSub). ...
                                ([settings.SideSegm(iSegment), 'sideSegm_', side, 'sideData']).([variables{iVar}]), ...
                                (Dims{iVar}))
                            
                            if iSub == 1 % to create legend
                                Hfig(iSegment) = plot(0:10:1000, StructTimeNorm.Sub(iSub). ...
                                    ([settings.SideSegm(iSegment), 'sideSegm_', side, 'sideData']). ...
                                    ([variables{iVar}]).(Dims{iVar})(1:10:end, 1), 'color', settings.Color(iSegment), 'linewidth', settings.LineWidth);
                            end

                            plot(0:10:1000, StructTimeNorm.Sub(iSub). ...
                                ([settings.SideSegm(iSegment), 'sideSegm_', side, 'sideData']). ...
                                ([variables{iVar}]).(Dims{iVar})(1:10:end, :), 'color', settings.Color(iSegment), 'linewidth', settings.LineWidth);
                        end
                    end
                end
            end % iSide
        end % iSegment       
        ylabel(['Subno:', num2str(iSub)])
    end % iSub
    
    
    % Create legend
    if strcmp(SideData{iVar}(iSide), 'I')
        SidesLeg = settings.SideSegm;
    elseif strcmp(SideData{iVar}(iSide), 'C')
        SidesLeg = settings.oppositeSideMap(string(settings.SideSegm')');
    else
        SidesLeg = SideData{iVar};
    end
    legend(Hfig, SidesLeg')
    
    %%% Save
    if settings.SaveFig==1
        saveas(gcf,[settings.SaveDir,variables{iVar},'_',Dims{iVar}],'fig')
        saveas(gcf,[settings.SaveDir,variables{iVar},'_',Dims{iVar}],'png')
        disp(['Figs ',variables{iVar},' saved.'])
    end
    
    
end % iVar


%% Get Good Trials
opts = detectImportOptions(fullfile(data_path, "41597_2023_2767_MOESM1_ESM.xlsx"), ...
    "Sheet","Table 3","ReadVariableNames",false);
Tgood = readtable(fullfile(data_path, "41597_2023_2767_MOESM1_ESM.xlsx"),opts);

unsorted_good_trials = struct([]);
subjCounter = 0;

% Column definitions
subjCols = [1 7];
fpCols   = {3:6, 9:12};   % FP blocks per subject

for r = 1:height(Tgood)
    for s = 1:2   % two subjects per row
        rawID = string(Tgood{r, subjCols(s)});
        if ~startsWith(rawID, "SUBJ")
            continue
        end

        subjCounter = subjCounter + 1;
        numID = sscanf(rawID,"SUBJ %d");

        unsorted_good_trials(subjCounter).SubjID = numID;
        unsorted_good_trials(subjCounter).folder = sprintf("SUBJ%02d", numID);

        trialMap = configureDictionary("double", "struct");

        % Parse FP columns
        for fp = 1:numel(fpCols{s})
            col = fpCols{s}(fp);
            cellTxt = string(Tgood{r, col});

            if cellTxt == "X" || ismissing(cellTxt)
                continue
            end

            entries = splitlines(cellTxt);
            tok = regexp(entries, '([RL])\s*\((\d+)\)','tokens','once', 'forcecelloutput');

            for e = 1:numel(entries)
                if isempty(tok{e})
                    continue
                end

                seg = tok{e}(1);
                trial = str2double(tok{e}(2));

                if ~isKey(trialMap, trial)
                    trialMap(trial) = struct( ...
                        'forceplates', [], ...
                        'segments', string.empty);
                end

                tmp = trialMap(trial);
                tmp.forceplates(end+1) = fp;
                tmp.segments(end+1) = seg;
                trialMap(trial) = tmp;
            end
        end

        % Build filenames + trials
        trialNums = sort((keys(trialMap)));

        for iTrial = 1:numel(trialNums)
            tr = trialNums(iTrial);

            unsorted_good_trials(subjCounter).filenames(iTrial) = ...
                sprintf("SUBJ%d (%d)", numID, tr);

            unsorted_good_trials(subjCounter).trial_num(iTrial) = tr + 1;

            unsorted_good_trials(subjCounter).trials(iTrial).forceplates = ...
                trialMap(tr).forceplates;

            unsorted_good_trials(subjCounter).trials(iTrial).segments = ...
                trialMap(tr).segments;
        end
    end
end
[~, order] = sort([unsorted_good_trials.SubjID]);
good_trials = unsorted_good_trials(order);

%% Get Subject Metadata
opts = detectImportOptions(fullfile(data_path, "41597_2023_2767_MOESM1_ESM.xlsx"), ...
    "Sheet","Table 1","ReadVariableNames",false);
Tmetadata = readtable(fullfile(data_path, "41597_2023_2767_MOESM1_ESM.xlsx"),opts);
unsorted_metadata = struct([]);
subjCounter = 0;

% Column definitions
subjCols = [1 7];
ageCols = [2 8];
sexCols = [3 9];
massCols = [4 10];
heightCols = [5 11];

for r = 1:height(Tmetadata)
    for s = 1:2 % two subjects per row
        rawID = string(Tmetadata{r, subjCols(s)});
        if ~startsWith(rawID, "SUBJ")
            continue
        end

        subjCounter = subjCounter + 1;
        numID = sscanf(rawID,"SUBJ%d");
        
        unsorted_metadata(subjCounter).SubjID = numID;
        unsorted_metadata(subjCounter).folder = sprintf("SUBJ%02d", numID);
        unsorted_metadata(subjCounter).Age.value = Tmetadata{r, ageCols(s)};
        unsorted_metadata(subjCounter).Age.unit = "year";
        unsorted_metadata(subjCounter).Gender.value = Tmetadata{r, sexCols(s)};
        unsorted_metadata(subjCounter).Gender.unit = "M\F";
        unsorted_metadata(subjCounter).Mass.value = Tmetadata{r, massCols(s)};
        unsorted_metadata(subjCounter).Mass.unit = "kg";
        unsorted_metadata(subjCounter).Height.value = Tmetadata{r, heightCols(s)};
        unsorted_metadata(subjCounter).Height.unit = "mm";
    end
end

[~, order] = sort([unsorted_metadata.SubjID]);
metadata = unsorted_metadata(order);

%% Plot Raw Data
% Graph per var:
for iVar = 1:length(variables)
    disp(['Working on plotting var from raw data: ',variables{iVar}])
    % Initiate figure
    figure, set(gcf,'name',variables{iVar},'color',[1 1 1]);    

    % Plot individual data
    tiledlayout%(settings.nCol,settings.nRow, 'Padding', 'none', 'TileSpacing', 'compact'); 
    for iSub = 1:5%length(good_trials)
        nexttile
        yline(0, '-k')
        hold on
        
        % Get good trial parameters
        numID = good_trials(iSub).SubjID;
        good_trial_nums = good_trials(iSub).trial_num;
        n_good_trials = length(good_trials(iSub).trials);

        subj_forceplates = [];
        subj_segments = [];
        h = gobjects(0);
        for iTrial=1:n_good_trials
            % Load good trial from raw data
            iGoodTrial = good_trial_nums(iTrial) - 1;

            c3d = StructRaw.raw_data(numID).trial(iGoodTrial).c3d;
            fp = StructRaw.raw_data(numID).trial(iGoodTrial).fp;

            % Get trial parameters
            fp_sampling_freq = c3d.parameters.ANALOG.RATE.DATA;
            markers_sampling_freq = c3d.parameters.POINT.RATE.DATA;
            start_time = c3d.parameters.TRIAL.ACTUAL_START_FIELD.DATA(1)./markers_sampling_freq;
            event_times = c3d.parameters.EVENT.TIMES.DATA(2, :) - start_time;

            FootStrikes = {};
            FootOffs = {};
            for iSegment=1:length(settings.SideSegm)
                if strcmp(settings.SideSegm(iSegment), 'L')
                    iEventSide = strcmp(c3d.parameters.EVENT.CONTEXTS.DATA, 'Left');
                else
                    iEventSide = strcmp(c3d.parameters.EVENT.CONTEXTS.DATA, 'Right');
                end
                iFootStrike = strcmp(c3d.parameters.EVENT.LABELS.DATA, 'Foot Strike');
                iFootOff = strcmp(c3d.parameters.EVENT.LABELS.DATA, 'Foot Off');
                FootStrikes{iSegment} = sort(event_times(iEventSide & iFootStrike));
                FootOffs{iSegment} = sort(event_times(iEventSide & iFootOff));
            end % iSegment

            forceplates = good_trials(iSub).trials(iTrial).forceplates;
            segments = good_trials(iSub).trials(iTrial).segments;
            mass = metadata(iSub).Mass.value;
            subj_forceplates = [subj_forceplates forceplates];
            subj_segments = [subj_segments segments];
            n_forceplates = length(forceplates);

            % Identify contact start and end
            contacts_start = zeros(n_forceplates, 1);
            contacts_end = zeros(n_forceplates, 1);
            for idx=1:n_forceplates
                fp_num = forceplates(idx);
                grf = fp(fp_num).force(3, :) ./ mass; % normalize by mass
                grf_filt = filter_data(grf, fp_sampling_freq);
                [contact_start, contact_end] = identify_events(grf_filt);
                contacts_start(idx) = contact_start;
                contacts_end(idx) = contact_end;
            end

            if matches(variables{iVar}, ["GroundReactionForce" "GroundReactionMoment" "CenterOfPressure"])
                for idx=1:n_forceplates
                    fp_num = forceplates(idx);
                    iSegment = strfind(settings.SideSegm, segments(idx));
                    data = fp(fp_num).(settings.FPVariableMap(variables{iVar}))(settings.dimensionMap(Dims{iVar}), :) ./ mass; % normalize by mass
                    data_filt = filter_data(data, fp_sampling_freq);
                    time = (0:length(data_filt) - 1) ./ fp_sampling_freq;
                    for iSide = 1:strlength(SideData{iVar})
                        if strcmp(SideData{iVar}(iSide), 'I')
                            side = settings.SideSegm(iSegment);
                        elseif strcmp(SideData{iVar}(iSide), 'C')
                            side = settings.oppositeSideMap{settings.SideSegm(iSegment)};
                        else
                            side = SideData{iVar}(iSide);
                        end
                        iEventSide = strfind(settings.SideSegm, side);
                        [IC_indices, iIC, TO_indices, iTO] = find_event_indices(data_filt, time, FootStrikes{iEventSide}, FootOffs{iEventSide});
                        IC_index = contacts_start(idx);
                        if idx + 2 <= n_forceplates && contacts_start(idx + 2) > contacts_start(idx)
                            IC_next_index = contacts_start(idx + 2);
                        elseif idx - 2 >= 1 && contacts_start(idx - 2) > contacts_start(idx)
                            IC_next_index = contacts_start(idx - 2);
                        else
                            IC_next_index = IC_indices(iIC + 1);
                        end
                        data_interp = interp1(IC_index:IC_next_index, data_filt(IC_index:IC_next_index), linspace(IC_index, IC_next_index, 1001));
                        h = [h plot(0:10:1000, data_interp(1:10:end), LineWidth=settings.LineWidth, DisplayName="FP" + fp_num + " " + segments(idx))];
                    end % iSide
                end % idx
            else
                for iSegment=1:length(settings.SideSegm)
                    segment = settings.SideSegm(iSegment);
                    var_idx = find(strcmp(c3d.parameters.POINT.LABELS.DATA, [settings.SideSegm(iSegment), variables{iVar}]));
                    data = squeeze(c3d.data.points(settings.dimensionMap(Dims{iVar}), var_idx, :));
                    data_filt = filter_data(data, markers_sampling_freq);
                    time = (0:length(data)-1) ./ markers_sampling_freq;
                    for iSide = 1:strlength(SideData{iVar})
                        if strcmp(SideData{iVar}(iSide), 'I')
                            side = settings.SideSegm(iSegment);
                        elseif strcmp(SideData{iVar}(iSide), 'C')
                            side = settings.oppositeSideMap{settings.SideSegm(iSegment)};
                        else
                            side = SideData{iVar}(iSide);
                        end
                        iEventSide = strfind(settings.SideSegm, side);
                        [IC_indices, iIC, TO_indices, iTO] = find_event_indices(data_filt, time, FootStrikes{iEventSide}, FootOffs{iEventSide});
                        IC_index = IC_indices(iIC);
                        try
                            IC_next_index = IC_indices(iIC + 1);
                        catch
                            continue
                        end
                        data_interp = interp1(IC_index:IC_next_index, data_filt(IC_index:IC_next_index), linspace(IC_index, IC_next_index, 1001));
                        h = [h plot(0:10:1000, data_interp(1:10:end), LineWidth=settings.LineWidth, DisplayName=segment)];
                        iStart = iTO;
                        if iStart >= max(TO_indices)
                            break
                        end
                    end % iSide
                end % iSegment
            end % matches
        end % iTrial
        ylabel(['Subno:', num2str(numID)])
        legend(h)
    end % iSub
end

function data_filt = filter_data(data, sampling_freq)
    % Inputs
    Fs = sampling_freq; % Sampling frequency (Hz) — adjust to your data
    Fc = 10;            % Low-pass cutoff frequency (Hz)
    order = 4;

    % Normalize cutoff frequency
    Wn = Fc / (Fs/2);

    % Design Butterworth filter
    [b, a] = butter(order, Wn, 'low');

    % Apply zero-phase (forward-backward) filtering
    data_filt = filtfilt(b, a, data);
end

function [ICindices, iIC, TOindices, iTO] = find_event_indices(step, time, FootStrikes, FootOffs)
    sorted_foot_strikes = sort(FootStrikes)';
    sorted_foot_offs = sort(FootOffs)';

    [~, ICindices] = min(abs(sorted_foot_strikes - repmat(time, length(sorted_foot_strikes), 1)), [], 2);
    [~, TOindices] = min(abs(sorted_foot_offs - repmat(time, length(sorted_foot_offs), 1)), [], 2);

    [~, iPeak] = max(step);
    
    [~, iIC] = min(abs(time(iPeak) - time(ICindices(ICindices <= iPeak))));
    [~, iTO] = min(abs(time(iPeak) - time(TOindices(TOindices >= iPeak))));
    if isempty(iIC)
        iIC = 1;
    end
    if isempty(iTO)
        iTO = length(time);
    end
        
end

function [contactStarts, contactEnds] = identify_events(step)
    threshold = 0.5; % [N/kg] GRF threshold
    
    isContact = step > threshold;

    contactStarts = find(diff([0 isContact]) == 1);
    contactEnds   = find(diff([isContact 0]) == -1);
end

% EOF
