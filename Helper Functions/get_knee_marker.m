function virtual_knee = get_knee_marker(below_knee, ankle, ST_below, ST_above)
    % GET_KNEE_MARKER Calculates the trajectory of the knee from the 
    % trajectories of the markers above and below the knee for either the medial
    % and lateral case.
    %   Input :
    %       below_knee - trajectory of the Tibial Tuberosity marker (medial) or 
    %                    the Fibular Head marker (lateral).
    %       ankle - trajectory of the (medial or lateral) ankle for calculating 
    %               the direction in time of the knee.
    %       ST_below - marker location below the knee (lateral - Fibular Head,
    %                  medial - Tibial Tuberosity) measured during standing 
    %                  trial.
    %       ST_above - marker location above the knee (medial or lateral Femoral
    %                  Epicondyle) measured during standing trial.
    %
    %       All marker trajectories are in global frame.
    %
    %   Output :
    %       virtual_knee - the trajectory of the virtual knee marker


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
    if isstruct(below_knee)
        if iscolumn(below_knee.x)
            below_knee.x = below_knee.x';
        end
        if iscolumn(below_knee.y)
            below_knee.y = below_knee.y';
        end
        if iscolumn(below_knee.z)
            below_knee.z = below_knee.z';
        end
        below_knee = [below_knee.x; below_knee.y; below_knee.z];
    end
    if isstruct(ST_below)
        if iscolumn(ST_below.x)
            ST_below.x = ST_below.x';
        end
        if iscolumn(ST_below.y)
            ST_below.y = ST_below.y';
        end
        if iscolumn(ST_below.z)
            ST_below.z = ST_below.z';
        end
        ST_below = [ST_below.x; ST_below.y; ST_below.z];
    end
    if isstruct(ST_above)
        if iscolumn(ST_above.x)
            ST_above.x = ST_above.x';
        end
        if iscolumn(ST_above.y)
            ST_above.y = ST_above.y';
        end
        if iscolumn(ST_above.z)
            ST_above.z = ST_above.z';
        end
        ST_above = [ST_above.x; ST_above.y; ST_above.z];
    end
    
    % Calculate distance between markers above and below knee in standing
    % trial
    d = norm(ST_above - ST_below);

    % Finding the normalized direction of the ankle-knee vector in global
    % frame
    n_ankle_knee = below_knee - ankle;
    n_ankle_knee = n_ankle_knee./vecnorm(n_ankle_knee);

    % Calculating virtual knee trajectory using vector addition
    x_virtual_knee = below_knee + d/2.*n_ankle_knee;
    
    % Changing virtual knee trajectory to struct format
    virtual_knee.x = x_virtual_knee(1, :);
    virtual_knee.y = x_virtual_knee(2, :);
    virtual_knee.z = x_virtual_knee(3, :);
end
