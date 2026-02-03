participants = string(fieldnames(DB_3.Data));
n_participants = length(participants);
walking_directions = cell(n_participants, 1);
for p_idx=1:n_participants
    p_name = participants(p_idx);
    trials = DB_3.Data.(p_name).processed_original_data.trial;
    n_trials = length(trials);
    walking_directions{p_idx} = zeros(n_trials, 1);

    figure
    sgtitle("Participant " + p_idx)

    subplot(3, 1, 1)
    hold on
    grid on
    title("X")
    xlabel("time [s]")
    ylabel("force [N]")
    
    subplot(3, 1, 2)
    hold on
    grid on
    title("Y")
    xlabel("time [s]")
    ylabel("force [N]")
    
    subplot(3, 1, 3)
    hold on
    grid on
    title("Z")
    xlabel("time [s]")
    ylabel("force [N]")

    for t_idx=1:n_trials
        walking_directions{p_idx}(t_idx) = trials(t_idx).walking_direction.value;
        grf = trials(t_idx).GRF.plate_1;
        cop = trials(t_idx).COP.plate_1;
        time = trials(t_idx).Forceplate_Time.value;
        
        subplot(3, 1, 1)
        plot(time, grf.x)
        
        subplot(3, 1, 2)
        plot(time, grf.y)
        
        subplot(3, 1, 3) 
        plot(time, grf.z)

    end
    disp(p_name + ": " + join(string(walking_directions{p_idx}), ", "))
end

disp("---------------------")
disp("Participants that walk backwards:")
for p_idx=1:n_participants
    p_name = participants{p_idx};
    if ~isempty(find(walking_directions{p_idx} < 0, 1, 'first'))
       fprintf("%d ", p_idx)
    end
    frpintf("\n")
end