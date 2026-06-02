function virtual_knee = get_knee_marker(inferior_knee, ankle, standing_trial_inferior, standing_trial_superior)
    % GET_KNEE_MARKER Calculates the trajectory of the knee from the 
    % trajectories of the markers above and below the knee for either the medial
    % and lateral case.
    %   Input :
    %       inferior_knee - trajectory of the marker inferior to the knee
    %       (medial - tibial tuberosity, lateral - fibular head).
    %       ankle - trajectory of the (medial / lateral) ankle.
    %       standing_trial_inferior - marker location inferior to the knee 
    %       (lateral - Fibular Head, medial - tibial tuberosity) measured during 
    %       standing trial.
    %       standing_trial_superior - marker location superior to the knee 
    %       (medial / lateral femoral epicondyle) measured during standing trial.
    %
    %       All marker trajectories are in global laboratory frame.
    %
    %   Output :
    %       virtual_knee - the trajectory of the virtual knee marker. A struct
    %       with x, y, z fields.


    % Changing trajectories to vectors in 3D space.
    if isstruct(ankle)
        if iscolumn(ankle.x)
            ankle.x = ankle.x';
        end
        if iscolumn(ankle.y)
            ankle.y = ankle.y';
        end
        if iscolumn(ankle.z)
            ankle.z = ankle.z';
        end
        ankle = [ankle.x; ankle.y; ankle.z];
    end
    if isstruct(inferior_knee)
        if iscolumn(inferior_knee.x)
            inferior_knee.x = inferior_knee.x';
        end
        if iscolumn(inferior_knee.y)
            inferior_knee.y = inferior_knee.y';
        end
        if iscolumn(inferior_knee.z)
            inferior_knee.z = inferior_knee.z';
        end
        inferior_knee = [inferior_knee.x; inferior_knee.y; inferior_knee.z];
    end
    if isstruct(standing_trial_inferior)
        if iscolumn(standing_trial_inferior.x)
            standing_trial_inferior.x = standing_trial_inferior.x';
        end
        if iscolumn(standing_trial_inferior.y)
            standing_trial_inferior.y = standing_trial_inferior.y';
        end
        if iscolumn(standing_trial_inferior.z)
            standing_trial_inferior.z = standing_trial_inferior.z';
        end
        standing_trial_inferior = [standing_trial_inferior.x; standing_trial_inferior.y; standing_trial_inferior.z];
    end
    if isstruct(standing_trial_superior)
        if iscolumn(standing_trial_superior.x)
            standing_trial_superior.x = standing_trial_superior.x';
        end
        if iscolumn(standing_trial_superior.y)
            standing_trial_superior.y = standing_trial_superior.y';
        end
        if iscolumn(standing_trial_superior.z)
            standing_trial_superior.z = standing_trial_superior.z';
        end
        standing_trial_superior = [standing_trial_superior.x; standing_trial_superior.y; standing_trial_superior.z];
    end
    
    % Calculate distance between markers above and below knee in standing
    % trial
    d = norm(standing_trial_superior - standing_trial_inferior);

    % Finding the normalized direction of the ankle-knee vector in global
    % frame
    n_ankle_knee = inferior_knee - ankle;
    n_ankle_knee = n_ankle_knee./vecnorm(n_ankle_knee);

    % Calculating virtual knee trajectory using vector addition
    p_virtual_knee = inferior_knee + d/2.*n_ankle_knee;
    
    % Changing virtual knee trajectory to struct format
    virtual_knee.x = p_virtual_knee(1, :);
    virtual_knee.y = p_virtual_knee(2, :);
    virtual_knee.z = p_virtual_knee(3, :);
end
