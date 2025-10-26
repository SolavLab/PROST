function [converted_value] = convert_units(value, unit_in_name, unit_out_name)
%CONVERT_UNITS converts value from unit_in_name to unit_out_name.
% Works for time, frequency, length, mass units.
% Example usage:
% converted_value = convert_units(value, "mm", "m");


    length_units = dictionary(["mm" "cm" "decm" "m" "km" "inch" "foot" "mile"], [1000 100 10 1 0.001 39.3701 3.28084 0.000621371]);
    mass_units = dictionary(["mg" "g" "kg" "pounds"], [1000 1 0.001 0.00220462]);
    time_units = dictionary(["second" "minute" "hour"], [3600 60 1]);
    freq_units = dictionary(["Hz" "rad/s" "rpm"], [1 2*pi 60]);

    if all(isKey(length_units, [unit_in_name unit_out_name]))
        unit_in = length_units(unit_in_name);
        unit_out = length_units(unit_out_name);
    elseif all(isKey(mass_units, [unit_in_name unit_out_name]))
        unit_in = mass_units(unit_in_name);
        unit_out = mass_units(unit_out_name);
    elseif all(isKey(time_units, [unit_in_name unit_out_name]))
        unit_in = time_units(unit_in_name);
        unit_out = time_units(unit_out_name);
    elseif all(isKey(freq_units, [unit_in_name unit_out_name]))
        unit_in = freq_units(unit_in_name);
        unit_out = freq_units(unit_out_name);
    else
        error("Both units need to be either of mass or of length.\n" + ...
              "The unit to convert from is %s and the unit to convert to is %s", unit_in_name, unit_out_name);
    end
    converted_value = value * unit_out / unit_in;
end