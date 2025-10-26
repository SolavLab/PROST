clear variables;
load("Data files\Subject1.mat")
% check how many trials there are
number_of_trials=length(s.Data)
% make a vector with only the numbers of the walking trials:
walking_trials_numbers=[];

walking_trials_numbers
% access data from the first trial as an example
GRF_DATA = s.Data(1).Grf;
GRF_DATA=GRF_DATA(1:3,:);
COP_DATA = s.Data(1).Grf;
COP_DATA=COP_DATA(4:6,:);
force_plate_time_vector = (1:length(GRF_DATA))/(s.GrfFreq);
% get the times of the step for the GRF data:

% plot the GRF data
figure
% x
subplot(3,1,1)
yline(0,'--k')
hold on
plot(force_plate_time_vector,GRF_DATA(1,:),'.','linewidth',2)
title("x - walking direction","FontSize",20)
ylabel('Force [N]')
xlabel('Time [s]')
% y
subplot(3,1,2)
yline(0,'--k')
hold on
plot(force_plate_time_vector,GRF_DATA(2,:),'.','linewidth',2)
title("y - up","FontSize",20)
ylabel('Force [N]')
xlabel('Time [s]')
% z
subplot(3,1,3)
yline(0,'--k')
hold on
plot(force_plate_time_vector,GRF_DATA(3,:),'.','linewidth',2)
title("z - latteral direction (by right hand rule)","FontSize",20)
ylabel('Force [N]')
xlabel('Time [s]')
sgtitle("GRF","FontSize",20)

% plot the COP data
figure
% x
subplot(3,1,1)
plot(force_plate_time_vector,COP_DATA(1,:),'.','linewidth',2)
title("x - walking direction","FontSize",20)
ylabel('COP location [mm]')
xlabel('Time [s]')
% y
subplot(3,1,2)
plot(force_plate_time_vector,COP_DATA(2,:),'.','linewidth',2)
title("y - up","FontSize",20)
ylabel('COP location [mm]')
xlabel('Time [s]')
% z
subplot(3,1,3)
plot(force_plate_time_vector,COP_DATA(3,:),'.','linewidth',2)
title("z - latteral direction (by right hand rule)","FontSize",20)
ylabel('COP location [mm]')
xlabel('Time [s]')
sgtitle("COP","FontSize",20)

figure
plot(COP_DATA(1,:),-COP_DATA(3,:),"*",'linewidth',2)
xlabel('COP location in walking direction [mm]')
ylabel('COP location in medial direction [mm]')
axis equal
title('cop',"FontSize",20)

%% 

% get the relavent markers data:
%---------------------------------------------------------------------------------------------
% the data of the right ankle is called: 'XRxLatMal' , 'YRxLatMal' , 'ZRxLatMal'
% and the data of the left ankle is similerly called: 'XLxLatMal' , 'YLxLatMal' , 'ZLxLatMal'
% the data of the right knee is called: 'XRxLatCon' , 'YRxLatCon' , 'ZRxLatCon'
% and the data of the left knee is similerly called: 'XLxLatCon' , 'YLxLatCon' , 'ZLxLatCon'
%---------------------------------------------------------------------------------------------
right_ankle=s.Data(1).Marker(64:66,:);
left_ankle=s.Data(1).Marker(67:69,:);
right_knee=s.Data(1).Marker(46:48,:);
left_knee=s.Data(1).Marker(49:51,:);
right_heel=s.Data(1).Marker(70:72,:);
left_heel=s.Data(1).Marker(73:75,:);
% make animation
figure
for i=1:length(right_ankle(1,:))
    hold off
    % draw the floor:
    plot([-1,2],[0,0],'k')
    hold on
    % draw the right shank
    plot([right_heel(1,i),right_ankle(1,i),right_knee(1,i)],[right_heel(2,i),right_ankle(2,i),right_knee(2,i)],'b')
    % draw the left shank
    plot([left_heel(1,i),left_ankle(1,i),left_knee(1,i)],[left_heel(2,i),left_ankle(2,i),left_knee(2,i)],'r')
    axis equal
    title("time: "+string(i*0.005)+" [sec]")
    pause(0.01)
end

%%

% perhaps we can identify the start of the double limb support by the height of the left heel:
figure
plot(0.005*(1:length(left_heel(2,:))),left_heel(2,:))
title('height of the left heel as a function of time')
ylabel("hight of left heel [m]")
xlabel("Time [sec]")

