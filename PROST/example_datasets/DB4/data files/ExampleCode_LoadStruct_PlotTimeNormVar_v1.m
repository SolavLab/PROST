% READ-IN AND PLOT TIME-NORMALIZED DATA STRUCTURES
% Example code to use the structure.
%
%
% input: time-normalized structure van Criekinge et al, 2022
% eg. MAT_normalizedData_AbleBodiedAdults_v06-03-23
% eg. MAT_normalizedData_PostStrokeAdults_v27-02-23
%
% output: 
% Figure of the selected variable of interest (.fig and .png)
%
% 
% 
% 19.09.2023, Lizeth Sloot, Heidelberg University / Newcastle University.
%
%
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

close all
clear all
clc


%% General Settings

%%% 1. Set path to directory of the Structure you want to load!
settings.mainDir = pwd;

%%% 2. Load Structure
% Give the name of the structure you want to load:
settings.StructName = 'MAT_normalizedData_AbleBodiedAdults_v06-03-23';
StructTime = load(fullfile(settings.mainDir,settings.StructName));


%%% 3. Set saving settings
settings.SaveFig = 0;       % set to 1 if you want to save the figure, set to 0 if not.
settings.SaveDir = fullfile(settings.mainDir,'Figures');


%%% 4. Set Figure settings
% Set the "Sides" as defined in the Structure. 
% (eg. DataStruct.Sub(1).PsideSegm_PsideData --> PsideSegm and NPsideSegm)
% For Able bodied (MAT_normalizedData_AbleBodiedAdults_v06-03-23), this is
% left and right (or SideA = {'LR';'LR'})
% For Stroke (MAT_normalizedData_PostStrokeAdults_v27-02-23), this is
% paretic and non-paretic side (or SideA = {'P';'NP'};)
settings.SideA = {'L';'R'};
% settings.SideA = {'P';'NP'};
oppositeSide = dictionary('L', 'R', 'R', 'L', 'P', 'NP', 'NP', 'P');

% Both sides are plotted in a different color and line type. 
% note, first side (defined above) will get the first color.
settings.ColorZ = 'br';
settings.MarkerSymbol = {'-';'--'};
settings.LineWidth = 1.5;

% Set the number of subplots in a single figure. 
% if you set it lower, the subplot per participant will get larger, but
% less will fit in a single figure. 
% For Able bodied, 12x12 seems to work well. 
% For Stroke, 7x8 seems to work well. 
settings.iCol = 12;        
settings.iRow = 12;    


%% Select the data you want to plot

%%% 1. Specify the variable(s) of interest to plot:
% You can give a series of variables (it will run in a loop) or a single
% one.
varsInt = {'GroundReactionForce'};
    

%%% 2. Specify the dimension to plot for each of these variables:
% This can be x, y, z, or n (non-dimensional). Check the Structure.
DimsC={'z'};    


%%% 3. Specify the body side of the data you want to look at
% The code will plot both the e.g. Left-side-segmented (stride normalized
% based on left side gait events) and the Right-side-segmented data. 
% Here you specify if you want to plot the left ankle angle from the
% left-side segmented data (ipsilateral side), or the right ankle angle
% (contra-lateral side). Usually, this will be the same as in settings.SideA.
% (eg. DataStruct.Sub(1).PsideSegm_PsideData --> PsideData and NPsideData)
% If you are interested in whole-body parameters that aren't related to one
% side (eg center-of-mass, sternum marker), use 'BB').
SideS = {'I'};
% SideS = {'PN';'BB'};


  
%% DO NOT CHANGE ANYTHING AFTER THIS SECTION

iDim=length(DimsC);

% Get Screen size
scrsz = get(0,'ScreenSize');
scrplt.x(1) = round( scrsz(3)*0.05 );
scrplt.x(2) = round( scrsz(3)*0.75 );
scrplt.y(1) = round( scrsz(4)*0.05 );
scrplt.y(2) = round( scrsz(4)*0.75 );

% Graph per var:
for iVar = 1:length(varsInt)
    disp(['Working on plotting var from MAT file: ',varsInt{iVar}])
    
    % Initiate figure
    figure, set(gcf,'name',varsInt{iVar},'color',[1 1 1],'position',...
        [scrplt.x(1) scrplt.y(1) scrplt.x(2) scrplt.y(2)])    
    
    % Plot individual data
    tiledlayout%(settings.iCol,settings.iRow, 'Padding', 'none', 'TileSpacing', 'compact'); 
    for iSub = 1%:size(StructTime.Sub,2)
        nexttile 
      
        xdata = 0:10:1000;  
        plot(xdata, zeros(size(xdata)), '-k')
        hold on
        
        for iSegment = 1:length(settings.SideA)
            for iSide = 1:strlength(SideS{iVar})
                if strcmp(SideS{iVar}(iSide), 'I')
                    side = settings.SideA{iSegment};
                elseif strcmp(SideS{iVar}(iSide), 'C')
                    side = oppositeSide(settings.SideA{iSegment});
                else
                    side = SideS{iVar}(iSide);
                end
                if ~isempty(StructTime.Sub(iSub). ...
                        ([settings.SideA{iSegment}, 'sideSegm_', side, 'sideData']) )
                    if isfield(StructTime.Sub(iSub). ...
                            ([settings.SideA{iSegment}, 'sideSegm_', side, 'sideData']), ...
                            ([varsInt{iVar}]))
                        if isfield(StructTime.Sub(iSub). ...
                                ([settings.SideA{iSegment}, 'sideSegm_', side, 'sideData']).([varsInt{iVar}]), ...
                                (DimsC{iVar}))
                            
                            if iSub == 1 % to create legend
                                Hfig(iSegment) = plot(xdata, StructTime.Sub(iSub). ...
                                    ([settings.SideA{iSegment}, 'sideSegm_', side, 'sideData']). ...
                                    ([varsInt{iVar}]).(DimsC{iVar})(1:10:end, 1), 'color', settings.ColorZ(iSegment), 'linewidth', settings.LineWidth);
                            end

                            plot(xdata, StructTime.Sub(iSub). ...
                                ([settings.SideA{iSegment}, 'sideSegm_', side, 'sideData']). ...
                                ([varsInt{iVar}]).(DimsC{iVar})(1:10:end, :), 'color', settings.ColorZ(iSegment), 'linewidth', settings.LineWidth);
                        end
                    end
                end
            end % iSide
        end % iSegment       
        ylabel(['Subno:', num2str(iSub)])
    end % iSub
    
    
    % Create legend
    if strcmp(SideS{iVar}(iSide), 'I')
        SidesLeg = settings.SideA;
    elseif strcmp(SideS{iVar}(iSide), 'C')
        SidesLeg = oppositeSide(settings.SideA);
    else
        SidesLeg = SideS{iVar};
    end
    legend(Hfig, SidesLeg')
    
    %%% Save
    if settings.SaveFig==1
        saveas(gcf,[settings.SaveDir,varsInt{iVar},'_',DimsC{iVar}],'fig')
        saveas(gcf,[settings.SaveDir,varsInt{iVar},'_',DimsC{iVar}],'png')
        disp(['Figs ',varsInt{iVar},' saved.'])
    end
    
    
end % iVar


%% Get Good Trials
opts = detectImportOptions("41597_2023_2767_MOESM1_ESM.xlsx", ...
    "Sheet","Table 3","ReadVariableNames",false);
T = readtable("41597_2023_2767_MOESM1_ESM.xlsx",opts);

unsorted_good_trials = struct([]);
subjCounter = 0;

% Column definitions
subjCols = [1 7];
fpCols   = {3:6, 9:12};   % FP blocks per subject

for r = 1:height(T)
    for s = 1:2   % two subjects per row
        rawID = string(T{r, subjCols(s)});
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
            cellTxt = string(T{r, col});

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
                sprintf("SUBJ%d (%d).c3d", numID, tr);

            unsorted_good_trials(subjCounter).trials(iTrial).forceplates = ...
                trialMap(tr).forceplates;

            unsorted_good_trials(subjCounter).trials(iTrial).segments = ...
                trialMap(tr).segments;
        end
    end
end
[~, order] = sort([unsorted_good_trials.SubjID]);
good_trials = unsorted_good_trials(order);

%% Look at C3D Files of Good Data
addpath("C:\Users\chenr\Documents\PROST\PROST\example_datasets\DB4\ezc3d_matlab")
file_path = "C:\Users\chenr\Documents\PROST\PROST\example_datasets\DB4\data files\138_HealthyPiG_10.05";

dimension = dictionary('x', 1, 'y', 2, 'z', 3, 'n', 1);
variable = dictionary('GroundReactionForce', 'force', 'GroundReactionMoment', 'moment', 'CenterOfPressure', 'center_of_pressure');
% Graph per var:
for iVar = 1:length(varsInt)
    disp(['Working on plotting var for C3D file: ',varsInt{iVar}])
    % Initiate figure
    figure, set(gcf,'name',varsInt{iVar},'color',[1 1 1],'position',...
        [scrplt.x(1) scrplt.y(1) scrplt.x(2) scrplt.y(2)])    

    % Plot individual data
    tiledlayout%(settings.iCol,settings.iRow, 'Padding', 'none', 'TileSpacing', 'compact'); 
    for iSub = 1%length(good_trials)
        numID = good_trials(iSub).SubjID;
        nexttile 
        hold on

        % xdata = 0:10:1000; 
        % plot(xdata, zeros(size(xdata)), '-k')
        % hold on

        file_names = good_trials(iSub).filenames;
        n_trials = length(file_names);
        trial_offset = 0;

        subj_forceplates = [];
        subj_segments = [];
        h = gobjects(0);
        for iTrial=1:n_trials
            c3d_filename = fullfile(file_path, good_trials(iSub).folder, file_names(iTrial));
            [c3d fp] = ezc3dRead(convertStringsToChars(c3d_filename));
            fp_sampling_freq = c3d.parameters.ANALOG.RATE.DATA;
            markers_sampling_freq = c3d.parameters.POINT.RATE.DATA;
            start_time = c3d.parameters.TRIAL.ACTUAL_START_FIELD.DATA(1)./markers_sampling_freq;
            event_times = c3d.parameters.EVENT.TIMES.DATA(2, :) - start_time;

            for iSegment=1:length(settings.SideA)
                if strcmp(settings.SideA{iSegment}, 'L')
                    iSide = strcmp(c3d.parameters.EVENT.CONTEXTS.DATA, 'Left');
                else
                    iSide = strcmp(c3d.parameters.EVENT.CONTEXTS.DATA, 'Right');
                end
                iFootStrike = strcmp(c3d.parameters.EVENT.LABELS.DATA, 'Foot Strike');
                iFootOff = strcmp(c3d.parameters.EVENT.LABELS.DATA, 'Foot Off');
                FootStrikes{iSegment} = event_times(iSide & iFootStrike);
                FootOffs{iSegment} = event_times(iSide & iFootOff);
                % xline(event_times(iSide & iFootStrike), '-',  LineWidth=settings.LineWidth, Color=settings.ColorZ(iSegment))
                % xline(event_times(iSide & iFootOff), '--',  LineWidth=settings.LineWidth, Color=settings.ColorZ(iSegment))
            end % iSegment

            forceplates = good_trials(iSub).trials(iTrial).forceplates;
            segments = good_trials(iSub).trials(iTrial).segments;
            mass = c3d.parameters.PROCESSING.Bodymass.DATA;
            subj_forceplates = [subj_forceplates forceplates];
            subj_segments = [subj_segments segments];
            n_forceplates = length(forceplates);

            if matches(varsInt{iVar}, ["GroundReactionForce" "GroundReactionMoment" "CenterOfPressure"])
                for idx=1:n_forceplates
                    fp_num = forceplates(idx);
                    iSegment = find(strcmp(settings.SideA, segments(idx)));
                    iOppositeSegment = find(strcmp(settings.SideA, oppositeSide(segments(idx))));
                    data = fp(fp_num).(variable(varsInt{iVar}))(dimension(DimsC{iVar}), :) ./ mass;
                    data_filt = filter_data(data, fp_sampling_freq);
                    time = (0:length(data_filt)-1)./fp_sampling_freq;
                    data_cut = cut_step(data_filt, time, FootStrikes{iSegment}, FootOffs{iSegment});
                    time_cut = (0:length(data_cut)-1)./fp_sampling_freq;
                    h = [h plot(time_cut, data_cut, LineWidth=settings.LineWidth, Color=settings.ColorZ(iSegment))];
                end
            else
                var_idx = strfind(c3d.parameters.POINT.LABELS, varsInt{iVar});
                data = squeeze(c3d.data.points(dimension(DimsC{iVar}), var_idx, :));
                data_filt = filter_data(data, fp_sampling_freq);
                time = (0:length(data)-1)./fp_sampling_freq;
                h = [h plot(time, data_filt, LineWidth=settings.LineWidth)];
            end
        end % iTrial
        ylabel(['Subno:', num2str(numID)])
        legend(h, "FP" + subj_forceplates + " " + subj_segments)
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

function step_cut = cut_step(step, time, FootStrikes, FootOffs)
    sorted_foot_strikes = sort(FootStrikes)';
    sorted_foot_offs = sort(FootOffs)';

    [~, ICindices] = min(abs(sorted_foot_strikes - repmat(time, length(sorted_foot_strikes), 1)), [], 2);
    [~, TOindices] = min(abs(sorted_foot_offs - repmat(time, length(sorted_foot_offs), 1)), [], 2);

    [~, iPeak] = max(step);

    [~, iIC] = min(abs(step(iPeak) - step(ICindices)));
    [~, iTO] = min(abs(step(iPeak) - step(TOindices)));

    step_cut = step(ICindices(iIC):TOindices(iTO));
end
% EOF
