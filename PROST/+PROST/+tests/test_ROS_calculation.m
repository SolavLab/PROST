dataset_id = 1;
participant_id = 1;
side = "right";

dataset_idx = PROSTAnalyzer.DataRecordsIDLookup(dataset_id);
steps = PROSTAnalyzer.DataRecords(dataset_idx).Data(participant_id).Uniform_data.(side).step;
% steps = steps(8);

% Time vector
time = linspace(0, 100, 101); % Time vector for temporally aligned data to 101 points
markers = {'.' 'o' 'x' '^' '+' '*' '_' '|' 'square' 'diamond' 'v' '>' '<' 'pentagram' 'hexagram'};
cmap = lines(length(steps));
figure
hold on
grid on
cop_transformed = [];
for idx = 1:length(steps)
    shank_cop = PROST.PROSTAnalyzer.cop_to_shank_frame(steps(idx), "lateral");
    shank_cop_vec = [shank_cop.x; shank_cop.y; shank_cop.z; idx + 0*shank_cop.x];
    cop_transformed = [cop_transformed shank_cop_vec];
    plot(time, shank_cop_vec(2, :), Color=cmap(idx, :), MarkerSize=5, LineStyle="none", Marker="o", DisplayName="Trial " + steps(idx).source.original_trial) 
end
title("COP z vs time in lab frame")
xlabel('index')
ylabel("z [mm]")
legend

figure
axis equal
grid on
gscatter(cop_transformed(1, :), cop_transformed(3, :), cop_transformed(4, :), {}, "o", 5, "filled");
title("COP in shank frame")
xlabel("x [mm]")
ylabel("z [mm]")

figure
hold on
axis equal
grid on
for idx = 1:length(steps)
    COP = steps(idx).COP;
    shank_cop = PROST.PROSTAnalyzer.cop_to_shank_frame(steps(idx), "lateral");
    ankle = steps(idx).Markers.Ankle.lateral;
    knee = steps(idx).Markers.Knee.lateral;
    X = [ankle.x; knee.x];
    Y = [ankle.z; knee.z];
    plot(X, Y, '-k')
    hold on;
    axis square;
    scatter(ankle.x, ankle.z, 30, time, 'square', 'filled')
    scatter(knee.x, knee.z, 30, time, 'o', 'filled')
    scatter(COP.x, 0*COP.y, 30, time, '^', 'filled')
    scatter(shank_cop.x + ankle.x(1), shank_cop.z + ankle.z(1), 30, time, 'v', 'filled')
end
title("COP and shank in lab frame")
xlabel("x [mm]")
ylabel("z [mm]")

figure
hold on
grid on
for idx = 1:length(steps)
    shank_cop = PROST.PROSTAnalyzer.cop_to_shank_frame(steps(idx), "lateral");
    ankle = steps(idx).Markers.Ankle.lateral;
    knee = steps(idx).Markers.Knee.lateral;
    hold on;
    axis square;
    d_time = diff(time);
    d_ankle_z = diff(ankle.z) ./ d_time;
    d_cop_z = diff(shank_cop.z) ./ d_time;
    plot(time(1:end-1), d_cop_z, '.', DisplayName="COP diff " + "Trial " + steps(idx).source.original_trial)
    plot(time(1:end-1), d_ankle_z, '.', DisplayName="ankle diff " + "Trial " + steps(idx).source.original_trial)
end
title("COP differential over time in shank frame")
xlabel("time [s]")
ylabel("dz [mm]")
legend

