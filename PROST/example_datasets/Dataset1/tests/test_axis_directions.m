% TEST_AXIS_DIRECTIONS :
% Plots raw GRF, COP, and PSIS trajectory data for all participants at any 
% available walking speed. Left/right GRF components, multi–force-plate COP 
% signals (with outliers removed), and averaged PSIS trajectories are overlaid 
% across trials to support visual quality control and consistency checks. This
% allows us to determine which axis corresponds to which direction in space 
% relative to participant motion.
% ------------------------------------------------------------------------------
clc; close all; clearvars -except -regexp ^Dataset\w*

script_full_path = matlab.desktop.editor.getActiveFilename; % Get full path of the current script
script_folder = fileparts(script_full_path); % Get the folder of the script
cd(script_folder);

% Define data files folder
data_path = "..\Data Files";

% Add PROST package root to path
toolbox_root = split(script_folder, filesep);
toolbox_root = fullfile(toolbox_root{1:end-2});
addpath(toolbox_root); % Add PROST package to path

set(0, 'DefaultFigureWindowStyle', 'docked'); % Set figures as tabbed windows 

%%
for p=1:16
    participant_data=load(fullfile(data_path, "Participant" + p + "\Raw_Data.mat"));
    participant_data = participant_data.("Subject" + string(p) + "_raw");
    
    available_speeds = [];
    for speed=[1 15 2 25 3 35 4]
        if length(fieldnames(participant_data.("V" + speed))) > 1
            available_speeds = [available_speeds speed];
            break
        end
    end

    for available_speed = available_speeds
        figure
        sgtitle("Participant" + p + " V" + available_speed)
        for t=1:length(participant_data.("V" + available_speed).GRF)
            % GRF
            grf_data = participant_data.("V" + available_speed).GRF{t, 2};
            time = grf_data.Time(:);
    
            fp_left_grf.x = grf_data{:, "L_GRF_X"};
            fp_left_grf.y = grf_data{:, "L_GRF_Y"};
            fp_left_grf.z = grf_data{:, "L_GRF_Z"};
    
            fp_right_grf.x = grf_data{:, "R_GRF_X"};
            fp_right_grf.y = grf_data{:, "R_GRF_Y"};
            fp_right_grf.z = grf_data{:, "R_GRF_Z"};
    
            ax1 = subplot(3, 5, 1);
            plt = plot(ax1, time, fp_left_grf.x);
            plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', t + 0.*time);
            xlabel("time [s]")
            ylabel("x [N]")
            title("GRF", "Left")
            grid on
            hold on

            ax6 = subplot(3, 5, 6);
            plt = plot(ax6, time, fp_left_grf.y);
            plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', t + 0.*time);
            xlabel("time [s]")
            ylabel("y [N]")
            grid on
            hold on

            ax11 = subplot(3, 5, 11);
            plt = plot(ax11, time, fp_left_grf.z);
            plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', t + 0.*time);
            xlabel("time [s]")
            ylabel("z [N]")
            grid on
            hold on

            ax2 = subplot(3, 5, 2);
            plt = plot(ax2, time, fp_right_grf.x);
            plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', t + 0.*time);
            xlabel("time [s]")
            ylabel("x [N]")
            title("GRF", "Right")
            grid on
            hold on
    
            ax7 = subplot(3, 5, 7);
            plt = plot(ax7, time, fp_right_grf.y);
            plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', t + 0.*time);
            xlabel("time [s]")
            ylabel("y [N]")
            grid on
            hold on
    
            ax12 = subplot(3, 5, 12);
            plt = plot(ax12, time, fp_right_grf.z);
            plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', t + 0.*time);
            xlabel("time [s]")
            ylabel("z [N]")
            grid on
            hold on

            % COP
            cop_data = participant_data.("V" + available_speed).COP{t, 2};
            time = cop_data.Time(:);
    
            fp1_cop.x = cop_data.FP1_X*1000;
            fp1_cop.y = cop_data.FP1_Y*1000;
    
            fp2_cop.x = cop_data.FP2_X*1000;
            fp2_cop.y = cop_data.FP2_Y*1000;
    
            fp3_cop.x = cop_data.FP3_X*1000;
            fp3_cop.y = cop_data.FP3_Y*1000;
    
            fp4_cop.x = cop_data.FP4_X*1000;
            fp4_cop.y = cop_data.FP4_Y*1000;
    
            fp5_cop.x = cop_data.FP5_X*1000;
            fp5_cop.y = cop_data.FP5_Y*1000;
    
            fp6_cop.x = cop_data.FP6_X*1000;
            fp6_cop.y = cop_data.FP6_Y*1000;
    
            ax3 = subplot(3, 5, 3);
            xlabel("time [s]")
            ylabel("x [mm]")
            title("COP", "Left")
            grid on
            hold on
            plt = plot(ax3, time(~isoutlier(fp1_cop.x)), fp1_cop.x(~isoutlier(fp1_cop.x)));
            plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', t + 0.*time(~isoutlier(fp1_cop.x)));
            plt = plot(ax3, time(~isoutlier(fp3_cop.x)), fp3_cop.x(~isoutlier(fp3_cop.x)));
            plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', t + 0.*time(~isoutlier(fp3_cop.x)));
            plt = plot(ax3, time(~isoutlier(fp5_cop.x)), fp5_cop.x(~isoutlier(fp5_cop.x)));
            plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', t + 0.*time(~isoutlier(fp5_cop.x)));
            
            ax8 = subplot(3, 5, 8);
            xlabel("time [s]")
            ylabel("y [mm]")
            grid on
            hold on
            plt = plot(ax8, time(~isoutlier(fp1_cop.y)), fp1_cop.y(~isoutlier(fp1_cop.y)));
            plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', t + 0.*time(~isoutlier(fp1_cop.y)));
            plt = plot(ax8, time(~isoutlier(fp3_cop.y)), fp3_cop.y(~isoutlier(fp3_cop.y)));
            plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', t + 0.*time(~isoutlier(fp3_cop.y)));
            plt = plot(ax8, time(~isoutlier(fp5_cop.y)), fp5_cop.y(~isoutlier(fp5_cop.y)));
            plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', t + 0.*time(~isoutlier(fp5_cop.y)));
    
            ax4 = subplot(3, 5, 4);
            xlabel("time [s]")
            ylabel("x [mm]")
            title("COP", "Right")
            grid on
            hold on
            plt = plot(ax4, time(~isoutlier(fp2_cop.x)), fp2_cop.x(~isoutlier(fp2_cop.x)));
            plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', t + 0.*time(~isoutlier(fp2_cop.x)));
            plt = plot(ax4, time(~isoutlier(fp4_cop.x)), fp4_cop.x(~isoutlier(fp4_cop.x)));
            plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', t + 0.*time(~isoutlier(fp4_cop.x)));
            plt = plot(ax4, time(~isoutlier(fp6_cop.x)), fp6_cop.x(~isoutlier(fp6_cop.x)));
            plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', t + 0.*time(~isoutlier(fp6_cop.x)));

            ax9 = subplot(3, 5, 9);
            xlabel("time [s]")
            ylabel("y [mm]")
            grid on
            hold on
            plt = plot(ax9, time(~isoutlier(fp2_cop.y)), fp2_cop.y(~isoutlier(fp2_cop.y)));
            plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', t + 0.*time(~isoutlier(fp2_cop.y)));
            plt = plot(ax9, time(~isoutlier(fp4_cop.y)), fp4_cop.y(~isoutlier(fp4_cop.y)));
            plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', t + 0.*time(~isoutlier(fp4_cop.y)));
            plt = plot(ax9, time(~isoutlier(fp6_cop.y)), fp6_cop.y(~isoutlier(fp6_cop.y)));
            plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', t + 0.*time(~isoutlier(fp6_cop.y)));

            % PSIS Trajectory
            traj_data = participant_data.("V" + available_speed).Trajectories{t, 2};
            time = traj_data.Time(:);
    
            trajectories.x = 0.5.*(traj_data.LPSISX(~isoutlier(traj_data.LPSISX) | ~isoutlier(traj_data.RPSISX)) + traj_data.RPSISX(~isoutlier(traj_data.LPSISX) | ~isoutlier(traj_data.RPSISX)));
            trajectories.y = 0.5.*(traj_data.LPSISY(~isoutlier(traj_data.LPSISY) | ~isoutlier(traj_data.RPSISY)) + traj_data.RPSISY(~isoutlier(traj_data.LPSISY) | ~isoutlier(traj_data.RPSISY)));
            trajectories.z = 0.5.*(traj_data.LPSISZ(~isoutlier(traj_data.LPSISZ) | ~isoutlier(traj_data.RPSISZ)) + traj_data.RPSISZ(~isoutlier(traj_data.LPSISZ) | ~isoutlier(traj_data.RPSISZ)));
    
            ax5 = subplot(3, 5, 5);
            xlabel("samples")
            ylabel("x [mm]")
            title("PSIS Trajectories")
            grid on
            hold on
            plt = plot(ax5, trajectories.x);
            plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', t + 0.*trajectories.x);

            ax10 = subplot(3, 5, 10);
            xlabel("samples")
            ylabel("y [mm]")
            grid on
            hold on
            plt = plot(ax10, trajectories.y);
            plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', t + 0.*trajectories.y);
    
            ax15 = subplot(3, 5, 15);
            xlabel("samples")
            ylabel("z [mm]")
            grid on
            hold on
            plt = plot(ax15, trajectories.z);
            plt.DataTipTemplate.DataTipRows(end+1) = dataTipTextRow('Trial number', t + 0.*trajectories.z);
        end
    end
end