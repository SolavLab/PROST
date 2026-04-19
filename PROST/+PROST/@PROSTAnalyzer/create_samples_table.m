function create_samples_table(obj)
%CREATE_SAMPLES_TABLE Initializes the samples table and populates it from
% data in the data records.
    
    % Samples Table Initialization
    samples_var_types =        {'doublenan',  'doublenan',      'categorical', 'categorical',         'doublenan', 'categorical', 'doublenan', 'doublenan', 'doublenan',  'doublenan',    'doublenan',    'categorical', 'doublenan', 'doublenan', 'doublenan', 'doublenan', 'doublenan', 'doublenan',  'doublenan'};
    samples_var_names =        {'Dataset_id', 'Participant_id', 'Side',        'Anatomical_side',     'Age',       'Sex',      'Height',    'Mass',      'Leg_length', 'Thigh_length', 'Shank_length', 'Is_shod',     'Radius',    'Center_horizontal',  'Center_vertical',  'Ang_start', 'Ang_end',   'Arc_length', 'Residual' };
    samples_var_units =        {'',           '',               'right/left',  'lateral/medial/mean', 'years',     'Male/Female', 'm',         'kg',        'm',          'm',            'm',            'Yes/No',      'mm',        'mm',        'mm',        'deg',       'deg',       'deg',        'mm'       };
    samples_var_descriptions = {'',           '',               '',            '',                    'feature',   'feature',     'feature',   'feature',   'feature',    'feature',      'feature',      'feature',     'label',     'label',     'label',     'label',     'label',     'label',      ''         };
    samples_numCols = numel(samples_var_names);

    % Count the number of rows needed in samples table
    numRows = obj.NUM_SIDES*length([obj.DataRecords.Data]);

    % Create an empty table for the data with the desired variable names:
    fprintf("Creating samples table...\n");
    samples_table = table('Size', [numRows samples_numCols], 'VariableTypes', samples_var_types, 'VariableNames', samples_var_names);
    samples_table.Properties.VariableUnits = samples_var_units;
    samples_table.Properties.VariableDescriptions = samples_var_descriptions;
    obj.SamplesTable = samples_table;
    obj.SamplesTableSize = 0;

    dataset_ids = [obj.DataRecords.Dataset_id];
    for dataset_id=dataset_ids
        add_to_samples_table(obj, dataset_id);
    end
end

