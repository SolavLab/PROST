function [age, sex, height, mass, leg_length, thigh_length, shank_length, is_shod] = get_metadata(metadata, side)
%GET_METADATA get anthropometric metadata parameters.
% Input :
%   metadata - struct with the anthropometric data of a participant.
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
%   is_shod - whether the participant was shod (Yes) or barefoot (No).

    age = metadata.Age.value; assert(metadata.Age.unit == "years"); % [years]
    sex = categorical(metadata.Sex.value); % "Male" or "Female"
    height = metadata.Height.value; assert(metadata.Height.unit == "m"); % [m]
    mass = metadata.Mass.value; assert(metadata.Mass.unit == "kg"); % [kg]
    leg_length = metadata.Leg_length.(side); assert(metadata.Leg_length.unit == "m"); % [m]
    thigh_length = metadata.Thigh_length.(side); assert(metadata.Thigh_length.unit == "m"); % [m]
    shank_length = metadata.Shank_length.(side); assert(metadata.Shank_length.unit == "m"); % [m]
    is_shod = categorical(metadata.Is_shod.value); % "Yes" (shod) or "No" (barefoot)
end