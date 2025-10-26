%% Load Databases
databases = input("Which databases do you want to load (name or number)?\n");
if isempty(databases)
    error("Please enter a database name or number.")
end
if ischar(databases) || iscellstr(databases)
    databases = string(databases);
end
for database=databases
    if isstring(database)
        load_file = fullfile(erase(database, "_"), database + ".mat");
    elseif isnumeric(database)
        load_file = fullfile("DB" + database, "DB_" + database + ".mat");
    else
        error(sprintf("Input is of wrong format.\n" + ...
                      "Should be one of the following:\n" +...
                      "string array, character array or cell array of character vectors of the databse names.\n" + ...
                      "numeric value or vector with database numbers."))
    end
    load(load_file)
end

% Save Databases
clear databases database load_file
save("DB.mat")