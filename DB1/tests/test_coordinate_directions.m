clear all
close all
clc

% Add path to data files
data_path = "C:\Users\chenr\Documents\PROST\DB1\Subjects_Data";
addpath(data_path);

% Add path to helper functions
addpath(genpath("C:\Users\chenr\Documents\PROST\Helper Functions"));

%% GRF
for p=1:16
    participant_data=load(fullfile(data_path, "Participant" + p + "\Raw_Data.mat"));
    participant_data = participant_data.("Subject" + string(p) + "_raw");
    
    for speed=[1 15 2 25 3 35 4]
        if length(fieldnames(participant_data.("V" + speed))) > 1
            available_speed = speed;
            break
        end
    end
    figure
    sgtitle("P" + p + " V" + available_speed)
    for t=1:length(participant_data.("V" + available_speed).GRF)
        data = participant_data.("V" + available_speed).GRF{t, 2};
        time = data.Time(:);

        fp1_grf.x = data{:, "L_GRF_X"};
        fp1_grf.y = data{:, "L_GRF_Y"};
        fp1_grf.z = data{:, "L_GRF_Z"};

        fp2_grf.x = data{:, "R_GRF_X"};
        fp2_grf.y = data{:, "R_GRF_Y"};
        fp2_grf.z = data{:, "R_GRF_Z"};

        ax1 = subplot(3, 2, 1);
        plot(ax1, time, fp1_grf.x)
        xlabel("time [s]")
        ylabel("x [N]")
        title("Left GRF")
        grid on
        hold on

        ax2 = subplot(3, 2, 2);
        plot(ax2, time, fp2_grf.x)
        xlabel("time [s]")
        ylabel("x [N]")
        title("Right GRF")
        grid on
        hold on

        ax3 = subplot(3, 2, 3);
        plot(ax3, time, fp1_grf.y)
        xlabel("time [s]")
        ylabel("y [N]")
        grid on
        hold on

        ax4 = subplot(3, 2, 4);
        plot(ax4, time, fp2_grf.y)
        xlabel("time [s]")
        ylabel("y [N]")
        grid on
        hold on

        ax5 = subplot(3, 2, 5);
        plot(ax5, time, fp1_grf.z)
        xlabel("time [s]")
        ylabel("z [N]")
        grid on
        hold on

        ax6 = subplot(3, 2, 6);
        plot(ax6, time, fp2_grf.z)
        xlabel("time [s]")
        ylabel("z [N]")
        grid on
        hold on
    end
end

%% COP
for p=1:16
    participant_data=load(fullfile(data_path, "Participant" + p + "\Raw_Data.mat"));
    participant_data = participant_data.("Subject" + string(p) + "_raw");
    
    available_speeds = [];
    for speed=[1 15 2 25 3 35 4]
        if length(fieldnames(participant_data.("V" + speed))) > 1
            available_speeds = [available_speeds speed];
        end
    end
    for available_speed=available_speeds(1)
        figure
        sgtitle("P" + p + " V" + available_speed)
        for t=1:length(participant_data.("V" + available_speed).COP)
            data = participant_data.("V" + available_speed).COP{t, 2};
            time = data.Time(:);
    
            fp1_cop.x = data.FP1_X(~isoutlier(data.FP1_X))*1000;
            fp1_cop.y = data.FP1_Y(~isoutlier(data.FP1_Y))*1000;
    
            fp2_cop.x = data.FP2_X(~isoutlier(data.FP2_X))*1000;
            fp2_cop.y = data.FP2_Y(~isoutlier(data.FP2_Y))*1000;
    
            fp3_cop.x = data.FP3_X(~isoutlier(data.FP3_X))*1000;
            fp3_cop.y = data.FP3_Y(~isoutlier(data.FP3_Y))*1000;
    
            fp4_cop.x = data.FP4_X(~isoutlier(data.FP4_X))*1000;
            fp4_cop.y = data.FP4_Y(~isoutlier(data.FP4_Y))*1000;
    
            fp5_cop.x = data.FP5_X(~isoutlier(data.FP5_X))*1000;
            fp5_cop.y = data.FP5_Y(~isoutlier(data.FP5_Y))*1000;
    
            fp6_cop.x = data.FP6_X(~isoutlier(data.FP6_X))*1000;
            fp6_cop.y = data.FP6_Y(~isoutlier(data.FP6_Y))*1000;
    
            ax1 = subplot(2, 2, 1);
            % xlabel("time [s]")
            ylabel("x [mm]")
            title("Left COP")
            grid on
            hold on
            plot(ax1, fp1_cop.x)
            plot(ax1, fp3_cop.x)
            plot(ax1, fp5_cop.x)
    
            ax2 = subplot(2, 2, 2);
            % xlabel("time [s]")
            ylabel("x [mm]")
            title("Right COP")
            grid on
            hold on
            plot(ax2, fp2_cop.x)
            plot(ax2, fp4_cop.x)
            plot(ax2, fp6_cop.x)
    
            ax3 = subplot(2, 2, 3);
            % xlabel("time [s]")
            ylabel("y [mm]")
            grid on
            hold on
            plot(ax3, fp1_cop.y)
            plot(ax3, fp3_cop.y)
            plot(ax3, fp5_cop.y)
    
            ax4 = subplot(2, 2, 4);
            % xlabel("time [s]")
            ylabel("y [mm]")
            grid on
            hold on
            plot(ax4, fp2_cop.y)
            plot(ax4, fp4_cop.y)
            plot(ax4, fp6_cop.y)
        end
    end
end

%% PSIS Trajectory
for p=1:16
    participant_data=load(fullfile(data_path, "Participant" + p + "\Raw_Data.mat"));
    participant_data = participant_data.("Subject" + string(p) + "_raw");
    
    available_speeds = [];
    for speed=[1 15 2 25 3 35 4]
        if length(fieldnames(participant_data.("V" + speed))) > 1
            available_speeds = [available_speeds speed];
        end
    end
    for available_speed=available_speeds(1)
        figure
        sgtitle("P" + p + " V" + available_speed)
        for t=1:length(participant_data.("V" + available_speed).Trajectories)
            data = participant_data.("V" + available_speed).Trajectories{t, 2};
            time = data.Time(:);
    
            trajectories.x = 0.5.*(data.LPSISX(~isoutlier(data.LPSISX) | ~isoutlier(data.RPSISX)) + data.RPSISX(~isoutlier(data.LPSISX) | ~isoutlier(data.RPSISX)));
            trajectories.y = 0.5.*(data.LPSISY(~isoutlier(data.LPSISY) | ~isoutlier(data.RPSISY)) + data.RPSISY(~isoutlier(data.LPSISY) | ~isoutlier(data.RPSISY)));
            trajectories.z = 0.5.*(data.LPSISZ(~isoutlier(data.LPSISZ) | ~isoutlier(data.RPSISZ)) + data.RPSISZ(~isoutlier(data.LPSISZ) | ~isoutlier(data.RPSISZ)));
    
            ax1 = subplot(3, 1, 1);
            % xlabel("time [s]")
            ylabel("x [mm]")
            title("Trajectories")
            grid on
            hold on
            plot(ax1, trajectories.x)
    
            ax2 = subplot(3, 1, 2);
            % xlabel("time [s]")
            ylabel("y [mm]")
            grid on
            hold on
            plot(ax2, trajectories.y)
    
            ax3 = subplot(3, 1, 3);
            % xlabel("time [s]")
            ylabel("z [mm]")
            grid on
            hold on
            plot(ax3, trajectories.z)
        end
    end
end