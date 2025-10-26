%%%=====walking_fig=====
%%%=====Carpinella I, 2019=======

% PUT THIS .M FILE IN THE SAME DIRECTORY CONTAINING DATA FILES
% reads data related to walking trials of Subject 6 and plots the flexion angles,
% moments and powers in the sagittal plane for right ankle, knee and hip joints.
% Each line corresponds to a single trial 


clear all
close all
clc

matname = 'Subject6.mat';
if exist(matname,'file') ~= 2
    disp(['File ' matname ' not found.']);
    return;
end


load(matname)

name = s.name;
age  = s.Age;
sex  = deblank(s.Gender);
side = 'Right';

data   = s.Data;
ntrial = length(s.Data);

walk_indexes = [];
for i = 1:ntrial
    if strcmpi(deblank(s.Data(i).Task),'Walking') && strcmpi(deblank(s.Data(i).Foot),'RX')
        walk_indexes = [walk_indexes i];
    end
end


iangH = strmatch('HipFlx',(s.AngVarName));
iangK = strmatch('KneeFlx',(s.AngVarName));
iangA = strmatch('AnkleFlx',(s.AngVarName));
imomH = strmatch('HipFlxMom',(s.MomVarName));
imomK = strmatch('KneeFlxMom',(s.MomVarName));
imomA = strmatch('AnkleFlxMom',(s.MomVarName));
ipwrH = strmatch('HipPwr',(s.PwrVarName));
ipwrK = strmatch('KneePwr',(s.PwrVarName));
ipwrA = strmatch('AnklePwr',(s.PwrVarName));


figure;

%===== PLOT ANGLES
subplot(3,3,1); hold on;
for i = 1: length(walk_indexes)
    plot(s.Data(walk_indexes(i)).Ang(iangA,:),'k');
end
set(gca,'XLim',[0 100]);
title('Ankle Dorsiflexion Angle (deg)');
xlabel('% stride');
box on
grid on

subplot(3,3,2); hold on;
for i = 1: length(walk_indexes)
    plot(s.Data(walk_indexes(i)).Ang(iangK,:),'k');
end
set(gca,'XLim',[0 100]);
title('Knee Flexion Angle (deg)');
xlabel('% stride');
box on
grid on

subplot(3,3,3); hold on;
for i = 1: length(walk_indexes)
    plot(s.Data(walk_indexes(i)).Ang(iangH,:),'k');
end
set(gca,'XLim',[0 100]);
title('Hip Flexion Angle (deg)');
xlabel('% stride');
box on
grid on
%======================================

%===== PLOT MOMENTS
subplot(3,3,4); hold on;
for i = 1: length(walk_indexes)
    plot(s.Data(walk_indexes(i)).Mom(imomA,:),'k');
end
set(gca,'XLim',[0 100]);
title('Ankle Moment (Nm/kg)');
xlabel('% stride');
box on
grid on

subplot(3,3,5); hold on;
for i = 1: length(walk_indexes)
    plot(s.Data(walk_indexes(i)).Mom(imomK,:),'k');
end
set(gca,'XLim',[0 100]);
title('Knee Moment (Nm/kg)');
xlabel('% stride');
box on
grid on

subplot(3,3,6); hold on;
for i = 1: length(walk_indexes)
    plot(s.Data(walk_indexes(i)).Mom(imomH,:),'k');
end
set(gca,'XLim',[0 100]);
title('Hip Moment (Nm/kg)');
xlabel('% stride');
box on
grid on
%======================================




%===== PLOT POWERS
subplot(3,3,7); hold on;
for i = 1: length(walk_indexes)
    plot(s.Data(walk_indexes(i)).Pwr(ipwrA,:),'k');
end
set(gca,'XLim',[0 100]);
title('Ankle Power (W/kg)');
xlabel('% stride');
box on
grid on

subplot(3,3,8); hold on;
for i = 1: length(walk_indexes)
    plot(s.Data(walk_indexes(i)).Pwr(ipwrK,:),'k');
end
set(gca,'XLim',[0 100]);
title('Knee Power (W/kg)');
xlabel('% stride');
box on
grid on

subplot(3,3,9); hold on;
for i = 1: length(walk_indexes)
    plot(s.Data(walk_indexes(i)).Pwr(ipwrH,:),'k');
end
set(gca,'XLim',[0 100]);
title('Hip Power (W/kg)');
xlabel('% stride');
box on
grid on
%======================================

set(gcf, 'Position', get(0, 'Screensize'));

