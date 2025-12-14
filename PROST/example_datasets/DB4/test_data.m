subs = [1 2 130];

for sub=subs
    for segment=["L" "R"]
        figure
        sgtitle("Subject " + sub + ": Step " + segment)
        
        n_trials = width(Sub(sub).(segment + "sideSegm_LsideData").ANK.z);
        for i=1:n_trials
            subplot(2, n_trials, i)
            plot(Sub(sub).(segment + "sideSegm_LsideData").ANK.z(:, i), LineWidth=3)
            hold on
            plot(Sub(sub).(segment + "sideSegm_RsideData").ANK.z(:, i), LineWidth=3)
            grid on
            title("Ankle Height: Step " + segment)

            subplot(2, n_trials, n_trials + i)
            plot(Sub(sub).(segment + "sideSegm_LsideData").GroundReactionForce.z(:, i), LineWidth=3)
            hold on
            plot(Sub(sub).(segment + "sideSegm_RsideData").GroundReactionForce.z(:, i), LineWidth=3)
            grid on
            title("Vertical GRF: Step " + segment)
        end
    end
end

%%
addpath("C:\Users\chenr\Documents\PROST\PROST\example_datasets\DB4\ezc3d_matlab")
filename = "C:\Users\chenr\Documents\PROST\PROST\example_datasets\DB4\data files\138_HealthyPiG_10.05\";
filename = filename + "SUBJ";
for sub=subs
    if sub < 10
        sub_name = "0" + sub;
    else
        sub_name = "0" + sub;
    end
    n_trials = max([Sub(sub).events.L_Trial Sub(sub).events.R_Trial]);
    for i=1:n_trials
        filename = filename + sub_name + "\" + sub_name + " (" + (i-1) + ").c3d";
        [c3d fp] = ezc3dRead()
    end
end