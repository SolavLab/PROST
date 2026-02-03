figure
hold on
h = gobjects(1, 8);
h(1) = plot(forceplate_data.time_vector, forceplate_data.plate(1).grf(3, :), LineWidth=2, DisplayName="FP 1");
h(2) = plot(forceplate_data.time_vector, forceplate_data.plate(2).grf(3, :), LineWidth=2, DisplayName="FP 2");
h(3) = plot(forceplate_data.time_vector, forceplate_data.plate(3).grf(3, :), LineWidth=2, DisplayName="FP 3");
h(4) = plot(forceplate_data.time_vector, forceplate_data.plate(4).grf(3, :), LineWidth=2, DisplayName="FP 4");
hh = xline(event_data.times(event_data.names == "Foot Strike" & event_data.feet == "Left"), '-r', LineWidth=2, DisplayName="IC Left");
h(5) = hh(1);
hh = xline(event_data.times(event_data.names == "Foot Strike" & event_data.feet == "Right"), '-g', LineWidth=2, DisplayName="IC Right");
h(6) = hh(1);
hh = xline(event_data.times(event_data.names == "Foot Off" & event_data.feet == "Left"), '--r', LineWidth=2, DisplayName="TO Left");
h(7) = hh(1);
hh = xline(event_data.times(event_data.names == "Foot Off" & event_data.feet == "Right"), '--g', LineWidth=2, DisplayName="TO Right");
h(8) = hh(1);
legend(h)

figure
hold on
h = gobjects(1, 8);
h(1) = plot(forceplate_data.plate(1).cop(1, steps_info(1).events.IC.forceplate_index:steps_info(1).events.OIC.forceplate_index), forceplate_data.plate(1).cop(2, steps_info(1).events.IC.forceplate_index:steps_info(1).events.OIC.forceplate_index), '.', DisplayName="FP 1");
h(2) = plot(forceplate_data.plate(2).cop(1, steps_info(2).events.IC.forceplate_index:steps_info(2).events.OIC.forceplate_index), forceplate_data.plate(2).cop(2, steps_info(2).events.IC.forceplate_index:steps_info(2).events.OIC.forceplate_index), '.', DisplayName="FP 2");
h(3) = plot(forceplate_data.plate(3).cop(1, :), forceplate_data.plate(3).cop(2, :), '.', DisplayName="FP 3");
h(4) = plot(forceplate_data.plate(4).cop(1, steps_info(3).events.IC.forceplate_index:steps_info(3).events.OIC.forceplate_index), forceplate_data.plate(4).cop(2, steps_info(3).events.IC.forceplate_index:steps_info(3).events.OIC.forceplate_index), '.', DisplayName="FP 4");

IC_time_left = event_data.times(event_data.names == "Foot Strike" & event_data.feet == "Left");
[~, IC_index_left] = min(abs(IC_time_left' - repmat(forceplate_data.time_vector, length(IC_time_left), 1)));
IC_time_right = event_data.times(event_data.names == "Foot Strike" & event_data.feet == "Right");
[~, IC_index_right] = min(abs(IC_time_right' - repmat(forceplate_data.time_vector, length(IC_time_right), 1)));
h(5) = plot(forceplate_data.plate(4).cop(1, IC_index_left), forceplate_data.plate(4).cop(2, IC_index_left), 'or', MarkerSize=7, DisplayName="IC Left");
h(6) = plot(forceplate_data.plate(4).cop(1, IC_index_right), forceplate_data.plate(4).cop(2, IC_index_right), 'og', MarkerSize=7, DisplayName="IC Right");

TO_time_left = event_data.times(event_data.names == "Foot Off" & event_data.feet == "Left");
[~, TO_index_left] = min(abs(TO_time_left' - repmat(forceplate_data.time_vector, length(TO_time_left), 1)));
TO_time_right = event_data.times(event_data.names == "Foot Off" & event_data.feet == "Right");
[~, TO_index_right] = min(abs(TO_time_right' - repmat(forceplate_data.time_vector, length(TO_time_right), 1)));

h(7) = plot(forceplate_data.plate(4).cop(1, TO_index_left), forceplate_data.plate(4).cop(2, TO_index_left), 'xr', MarkerSize=7, DisplayName="TO Left");
h(8) = plot(forceplate_data.plate(4).cop(1, TO_index_right), forceplate_data.plate(4).cop(2, TO_index_right), 'xg', MarkerSize=7, DisplayName="TO Right");
legend(h)