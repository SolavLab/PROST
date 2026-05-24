function create_IPD_table(obj)
%CREATE_IPD_TABLE Initializes the IPD table and populates it from
% data in the data records.
    
    % IPD Table Initialization
    IPD_var_types =        {'doublenan',  'doublenan',      'categorical', 'categorical',         'doublenan', 'categorical', 'doublenan', 'doublenan', 'doublenan',  'doublenan',    'doublenan',    'categorical', 'doublenan', 'doublenan',         'doublenan',        'doublenan', 'doublenan', 'doublenan',  'doublenan'};
    IPD_var_names =        {'Dataset_id', 'Participant_id', 'Side',        'Anatomical_side',     'Age',       'Sex',         'Height',    'Mass',      'Leg_length', 'Thigh_length', 'Shank_length', 'Is_shod',     'Radius',    'Center_horizontal', 'Center_vertical',  'Ang_start', 'Ang_end',   'Arc_length', 'Residual_rms' };
    IPD_var_units =        {'',           '',               'right/left',  'lateral/medial/mean', 'years',     'Male/Female', 'm',         'kg',        'm',          'm',            'm',            'Yes/No',      'mm',        'mm',                'mm',               'deg',       'deg',       'deg',        'mm'       };
    IPD_var_descriptions = {'',           '',               '',            '',                    'predictor', 'predictor',   'predictor', 'predictor', 'predictor',  'predictor',    'predictor',    'predictor',   'response',  'response',          'response',         'response',  'response',  'response',   ''         };
    IPD_n_cols = numel(IPD_var_names);

    % Count the number of rows needed in the IPD table
    n_rows = obj.NUM_SIDES*length([obj.DataRecords.Data]);

    % Create an empty table for the data with the desired variable names:
    fprintf("Creating IPD table...\n");
    IPD_table = table('Size', [n_rows IPD_n_cols], 'VariableTypes', IPD_var_types, 'VariableNames', IPD_var_names);
    IPD_table.Properties.VariableUnits = IPD_var_units;
    IPD_table.Properties.VariableDescriptions = IPD_var_descriptions;
    obj.IPDTable = IPD_table;
    obj.IPDTableSize = 0;

    dataset_ids = [obj.DataRecords.Dataset_id];
    for dataset_id=dataset_ids
        add_to_IPD_table(obj, dataset_id);
    end
end

