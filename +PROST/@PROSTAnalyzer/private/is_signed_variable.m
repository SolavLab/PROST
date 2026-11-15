function tf = is_signed_variable(var_name)
%IS_SIGNED_VARIABLE whether an IPD variable can be non-positive, so plots mark
% its zero. A manual list for now; it is meant to become a per-column property
% of the IPD table.
    signed_variables = ["Center_horizontal" "Center_vertical" "Ang_start" "Ang_end"];
    tf = ismember(var_name, signed_variables);
end
