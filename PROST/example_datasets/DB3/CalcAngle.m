function [flex,add,rot] = CalcAngle(ProxX,ProxY,ProxZ,DistX,DistY,DistZ)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                        %
% This function calculates, for a single time instant, the angles of     % 
% flexion (flex), adduction (add) and rotation (rot) starting from       %
% two triads of axes                                                     %
%                                                                        %
%  Input:                                                                %
% - ProxX,ProxY,ProxZ: directional cosines of the reference frame of the %
%   proximal segment (with respect to an absolute reporting system).     %
%   In the case of knee angle, the priximal segment is the thigh         %
% - DistX,DistY,DistZ: directional cosines of the reference frame of the %
%   distal segment (with respect to an absolute reporting system).       %
%   In the case of knee angle, the distal segment is the shank           %
% Output:                                                                %
% - flex: flexion angle in the sagittal plane                            %
% - add: adduction angle in frontal plane                                %
% - rot: rotation angle in the transverse plane                          %
%                                                                        %
% Grood ES, Suntay WJ. A joint coordinate system for the clinical        %
% description of three-dimensional motions: application to the knee.     %
% J Biomech Eng. 1983;105(2):136-144.                                    %
%                                                                        %
% Wu G, Siegler S, et al. Standardization and Terminology Committee of   %
% the International Society of Biomechanics. ISB recommendation on       % 
% definitions of joint coordinate system of various joints for the       %
% reporting of human joint motion--part I: ankle, hip, and spine.        %
% International Society of Biomechanics.                                 %
% J Biomech. 2002;35(4):543-548.                                         % 
%                                                                        %
% Copyright Marco Rabuffetti                                             %
%                                                                        %                       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nodes = cross(DistY,ProxZ);
nodes = nodes/norm(nodes);
add = pi/2 - acos(dot(ProxZ,DistY));
rot = pi/2 - acos(dot(nodes, DistZ));
if dot(cross(nodes,ProxY),ProxZ)>0
   flex = pi/2 - acos(dot(nodes, ProxY)); 
else
   flex = pi/2 - (2*pi - acos(dot(nodes, ProxY)));
end

