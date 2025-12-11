function [good_steps] = get_good_steps(steps, min_speed)
%GET_GOOD_STEPS receives all the steps of the participant from a
% single side, and saves and returns only the steps with a speed
% higher than min_speed in [km/h]. By default min_speed = 0 [km/h]

    % Set default value for min_speed
    if nargin == 1
        min_speed = 0; % [km/hr]
    end

    % good_steps = steps(steps(:).speed.km_per_hour.value >= min_speed);

    % start "good_steps" as having the same length as "steps":
    good_steps = zeros(1, length(steps));
    counter = 1;
    for step_num=1:length(steps)
        step = steps(step_num);
        try
        step_speed = step.speed.km_per_hour.value;
        catch
            disp("!!!")
        end
        is_included = step.Is_included;
        if is_included && step_speed >= min_speed
            % add this step:
            good_steps(counter) = step_num;
            counter = counter + 1;
        end
    end

    % Remove unused elements from "good_steps":
    good_steps = good_steps(1:counter - 1);
end