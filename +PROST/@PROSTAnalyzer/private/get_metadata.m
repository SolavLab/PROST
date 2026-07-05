function [age, sex, height, mass, leg_length, thigh_length, shank_length, footwear_condition] = get_metadata(metadata, side)
%GET_METADATA get separate metadata parameters from field.
% Input :
%   metadata - struct with the anthropometric + functional data of a participant.
%   side - the side of the leg measurements (leg, thigh or shank
%          lengths) to return. Either "right" or "left".
% Output :
%   age - the participant's age in years.
%   sex - the participant's sex (Male or Female).
%   height - the participant's height in m.
%   mass - the participant's weight in kg.
%   leg_length - the participant's leg length in m of side "side".
%   thigh_length - the participant's thigh length in m of side "side".
%   shank_length - the participant's shank length in m of side "side".
%   footwear_condition - whether the participant was shod or barefoot.

    age = metadata.Age.value; assert(metadata.Age.unit == "years"); % [years]
    sex = categorical(metadata.Sex.value); % "Male" or "Female"
    height = metadata.Height.value; assert(metadata.Height.unit == "m"); % [m]
    mass = metadata.Mass.value; assert(metadata.Mass.unit == "kg"); % [kg]
    leg_length = metadata.Leg_length.(side); assert(metadata.Leg_length.unit == "m"); % [m]
    thigh_length = metadata.Thigh_length.(side); assert(metadata.Thigh_length.unit == "m"); % [m]
    shank_length = metadata.Shank_length.(side); assert(metadata.Shank_length.unit == "m"); % [m]
    footwear_condition = categorical(metadata.Footwear_condition.value); % "Shod" or "Barefoot"
end