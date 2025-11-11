
DB_2_alt = DB_2_old;
DB_2_alt.Article_data = DB_2.Article_data;
DB_2_alt.Markers_guide = DB_2.Markers_guide;
DB_2_alt.Lab_system = DB_2.Lab_system;
DB_2_alt.Experiment_protocol = DB_2.Experiment_protocol;

DB_2_alt = rmfield(DB_2_alt, {'article_data', 'Lab_frame_explained', 'marker_names'});

for p=1:48
    DB_2_alt.Data.("participant_" + p).metadata.Mass = DB_2_alt.Data.("participant_" + p).metadata.mass;
    DB_2_alt.Data.("participant_" + p).metadata.Mass.unit = "kg";
    DB_2_alt.Data.("participant_" + p).metadata.Thigh_length = DB_2_alt.Data.("participant_" + p).metadata.thigh_length;
    DB_2_alt.Data.("participant_" + p).metadata.Shank_length = DB_2_alt.Data.("participant_" + p).metadata.shank_length;
    DB_2_alt.Data.("participant_" + p).metadata.Shank_length.unit = "m";
    DB_2_alt.Data.("participant_" + p).metadata.Is_shod = struct("value", "No", "unit", "Yes/No", "method", "given");

    DB_2_alt.Data.("participant_" + p).metadata.Gender.unit = "Male/Female";

    DB_2_alt.Data.("participant_" + p).metadata = rmfield(DB_2_alt.Data.("participant_" + p).metadata, {'mass', 'thigh_length', 'shank_length'});

    for side=["left" "right"]
        n_steps = length(DB_2_alt.Data.("participant_" + p).processed_data.(side).step);
        for s=1:n_steps

            DB_2_alt.Data.("participant_" + p).processed_data.(side).step(s).Markers = struct;
            DB_2_alt.Data.("participant_" + p).processed_data.(side).step(s).Markers.Ankle.lateral = DB_2_alt.Data.("participant_" + p).processed_data.(side).step(s).markers.Lateral_Ankle;
            DB_2_alt.Data.("participant_" + p).processed_data.(side).step(s).Markers.Ankle.medial = DB_2_alt.Data.("participant_" + p).processed_data.(side).step(s).markers.Medial_Ankle;
            DB_2_alt.Data.("participant_" + p).processed_data.(side).step(s).Markers.Ankle.mean = DB_2_alt.Data.("participant_" + p).processed_data.(side).step(s).markers.Ankle;
            DB_2_alt.Data.("participant_" + p).processed_data.(side).step(s).Markers.Knee.lateral = DB_2_alt.Data.("participant_" + p).processed_data.(side).step(s).markers.Lateral_Knee;
            DB_2_alt.Data.("participant_" + p).processed_data.(side).step(s).Markers.Knee.medial = DB_2_alt.Data.("participant_" + p).processed_data.(side).step(s).markers.Medial_Knee;
            DB_2_alt.Data.("participant_" + p).processed_data.(side).step(s).Markers.Knee.mean = DB_2_alt.Data.("participant_" + p).processed_data.(side).step(s).markers.Knee;
            DB_2_alt.Data.("participant_" + p).processed_data.(side).step(s).Markers.unit = "mm";
            DB_2_alt.Data.("participant_" + p).processed_data.(side).step(s).Markers.temporal_alignment = "weight acceptance + single support";
            DB_2_alt.Data.("participant_" + p).processed_data.(side).step(s).Markers.IC_index = 1;
            DB_2_alt.Data.("participant_" + p).processed_data.(side).step(s).Markers.OIC_index = 101;

            DB_2_alt.Data.("participant_" + p).processed_data.(side).step(s).source = DB_2_alt.Data.("participant_" + p).processed_data.(side).step(s).scorce;
       end
    end

    for side=["left" "right"]
        DB_2_alt.Data.("participant_" + p).processed_data.(side).step = rmfield(DB_2_alt.Data.("participant_" + p).processed_data.(side).step, {'scorce', 'markers', 'ROS'});
    end
end

%%
save("DB_2_alt.mat", "DB_2_alt")