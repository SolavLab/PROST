close all;
clearvars;
clc;
for i=1:50
    load("Subject" + string(i) + ".mat");
    iYRxHeel = strmatch('YRxHeel  ', s.MarkerVarName);
    iYLxHeel = strmatch('YLxHeel  ', s.MarkerVarName);
    good_counter = 0; bad_counter = 0;
    walking_data = s.Data(matches({s.Data.Task}, 'Walking'));
    n_walking = length(walking_data);
    % figure;
    % sgtitle("Subject" + string(i));
    % tiledlayout
    for j=1:n_walking
        yR = walking_data(j).Marker(iYRxHeel, :);
        yL = walking_data(j).Marker(iYLxHeel, :);
        foot = walking_data(j).Foot;
        
        % nexttile
        % plot(yR)
        % hold on
        % plot(yL)
        % legend("Right Heel", "Left Heel")
        % title("Trial " +string(j) + " Foot " + foot);
        
        [~, idxR] = max(yR);
        [~, idxL] = max(yL);

        if (idxR < idxL && strcmp(foot, 'RX')) || (idxL < idxR && strcmp(foot, 'LX'))
            good_counter = good_counter + 1;
        else
            bad_counter = bad_counter + 1;
            % disp("Subject" + string(i) + " Trial " + string(j) + " is bad.");
        end
    end
    disp("Good Trials: " + string(good_counter));
    disp("Bad Trials: " + string(bad_counter));
    disp("All Trials: " + string(n_walking));
    disp("-------------------------------------------");
    assert(bad_counter == n_walking);
    assert(good_counter == 0);
end