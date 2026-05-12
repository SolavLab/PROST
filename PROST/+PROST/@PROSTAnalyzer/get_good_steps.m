function [good_steps] = get_good_steps(steps, min_speed)
%GET_GOOD_STEPS receives all the steps of the participant from a
% single side, and saves and returns only the steps with a speed
% higher than min_speed in [km/hour]. By default min_speed = 0 [km/hour]

    % Set default value for min_speed
    if nargin == 1 || isempty(min_speed)
        min_speed = 0; % [km/hour]
    end

    if isempty(steps)
        good_steps = [];
        return
    end

    % start "good_steps" as having the same length as "steps":
    good_steps = zeros(1, length(steps));
    counter = 1;
    for step_num=1:length(steps)
        step = steps(step_num);
        step_speed = step.speed.value;
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