function s_out = pretty_print(obj, data_print_flag)
%PRETTY_PRINT Prints the object's fields and values in a pretty way into an 
% output string. Can print:
% struct, dictionary, string, char, numeric, vectors, matrices.
% Especially good for printing the explanation fields in our dataset structures.
%   Input : 
%       obj - the object to print
%       data_print_flag - flag for plotting the 'Data' field of the dataset. Set
%                         to true (default) to print, and false otherwise.
%  Output :
%       s_out - the output string of the object.

    if nargin < 2
        data_print_flag = false;
    end

    if nargin < 1 || isempty(obj)
        s_out = newline;
        return
    end

    if isstruct(obj)
        s_out = print_struct(obj, data_print_flag, '');
    else
        s_out = print_non_struct(obj);
    end
    s_out = append(s_out, printWrap("-------------------------------------------\n"));
end

function s_out = print_non_struct(obj)
%PRINT_NON_STRUCT Pretty prints all non-struct objects.
%   Input : 
%       obj - the object to print
    
    if nargin < 1 || isempty(obj)
        s_out = newline;
        return
    end
    
    % Set maximum number of elements and rows to show
    max_elem_size = 10;
    max_row_size = 3;

    if isStringScalar(obj) || (ischar(obj) && isrow(obj))
        s_out = printWrap(obj);
    elseif strcmp(class(obj), "dictionary")
        s_out = print_dictionary(obj);
    elseif isvector(obj) && isnumeric(obj)
        s_out = print_vector(obj, max_elem_size);
    elseif ismatrix(obj) && isnumeric(obj)
        n_rows = size(obj, 1); 
        s_out = "";
        for idx=1:n_rows
            s_out = append(s_out, print_vector(obj(idx, :), max_elem_size));
            if idx == max_row_size
                s_out = append(s_out, printWrap("..."));
                break
            end
        end
    elseif isnumeric(obj) && ~ismatrix(obj)
        s_out = printWrap("%dD matrix.", ndims(obj));
    else
        s_out = evalc('disp(obj)');
    end
end

function s_out = print_vector(v, max_elem_size)
%PRINT_VECTOR Pretty display of a vector. If the vector is too large, cuts it
% off and prints '...'.
%   Input :
%       v - the vector to print.

    if isnumeric(v)
        s = string(round(v, 3));
    else
        s = string(v);
    end
    s(ismissing(s)) = "NaN";
    if length(v) > max_elem_size
        if isrow(s)
            s = [s(1:max_elem_size) "..."];
        else
            s = [s(1:max_elem_size); "..."];
        end
    end
    s_out = printWrap("%s", join(s, ", "));
end

function s_out = print_dictionary(d)
%PRINT_DICTIONARY Pretty display dictionary where values are cells, 
% similar to disp(d) but expands cell contents.

     % Initialize output string
     s_out = "";    
    if ~isConfigured(d)
        s_out = newline;
        return
    end
    k = keys(d);
    v = values(d);

    % Find max key length for alignment
    maxKeyLen = max(strlength(k));
    
    for i = 1:numel(k)
        keyStr = string(k(i));
        
        % Format key with padding
        keyStr = pad(keyStr, maxKeyLen);

        % Expand value
        val = v{i};

        if iscell(val)
            val(cellfun(@(x) isnumeric(x) && isnan(x), val)) = {"NaN"};    % replace NaNs
            valStr = strjoin(cellfun(@string, val, 'UniformOutput', true), ", ");
        else
            valStr = string(val);
        end

        % Print
        s_out = append(s_out, printWrap('%s ⟼ %s', keyStr, valStr));
    end
end


function s_out = print_struct(s, data_flag, indent)
%PRINT_STRUCT A pretty display of a struct that recursively goes through the 
% fields and prints each field value.
%   Input : 
%       s - the struct to print.
%       data_flag - the flag decides whether to f]print the "data" field of the
%                   struct which is usually a field containing large amounts of 
%                   data.
%       indent - the indents to add to the field names.

    if nargin < 2
        indent = ''; 
    end

    % Initialize output string
    s_out = "";

    % Get Command Window size [rows cols]
    cwSize = get(0, 'CommandWindowSize');
    width = cwSize(1, 1);
    
    % Set maximum number of elements to show
    max_elem_size = 1;

    if ~isscalar(s)
        n_elem = min(max_elem_size, numel(s));
        for idx=1:n_elem
            s_out = append(s_out, print_struct(s(idx), data_flag, indent));
        end
        if max_elem_size < numel(s)
            s_out = append(s_out, printWrap("..."));
        end
        return
    end

    % Get struct fields
    fields = fieldnames(s);
    n_fields = numel(fields);

    str_pat = caseInsensitivePattern(("participant" | "trial") + optionalPattern("_") + digitsPattern);
    if all(matches(fields, str_pat))
        n_fields = min(max_elem_size, n_fields);
    end
    for idx=1:n_fields
        field = fields{idx};
        field_str = sprintf("%s%s :", indent, field);
        value = s.(field);

        % Do we want to print data fields?
        if ~data_flag && strcmpi(field, "Data")
            continue
        end

        if isstruct(value)
            s_out = append(s_out, printWrap("\n~~~~ %s ~~~", field_str));
            s_out = append(s_out, print_struct(value, data_flag, [indent '  ']));
        else
            max_string_size = width - strlength(field_str) - 4;
            if (~isscalar(value) && ~isvector(value)) || strcmp(class(value), "dictionary") || isLongString(value, max_string_size)
                s_out = append(s_out, printWrap("    %s", field_str));
            else
                s_out = append(s_out, sprintf("    %s ", field_str));
            end
                s_out = append(s_out, print_non_struct(value));
        end     
    end
    if all(matches(fields, str_pat)) && max_elem_size < numel(fields)
       s_out = append(s_out, printWrap("..."));
    end
end

function s_out = printWrap(fmt, varargin)
%PRINTWRAP Print formatted text that wraps at Command Window width.
%
%   printWrap(fmt, args...)
%   Behaves like fprintf(fmt, args...) but wraps text at the Command
%   Window edge.
%
%   Example:
%       printWrap('The value is %.2f and the name is %s', 3.1415, 'example');

    % Initialize output string
    s_out = "";

    % Format string
    msg = sprintf(fmt, varargin{:});

    % Get Command Window size [rows cols]
    cwSize = get(0, 'CommandWindowSize');
    width = cwSize(1, 1);

    % Split into lines at \n first
    lines = splitlines(msg);
    n_lines = numel(lines);

    for i = 1:n_lines
        thisLine = lines{i};
        while strlength(thisLine) > width
            % Find wrap point (prefer breaking at space)
            wrapPos = find(thisLine(1:width) == ' ', 1, 'last');
            if isempty(wrapPos)
                wrapPos = width; % force break
            end

            s_out = append(s_out, sprintf('%s\n', extractBefore(thisLine, wrapPos + 1)));
            thisLine = strtrim(extractAfter(thisLine, wrapPos));
        end
        if ~isempty(thisLine)
            s_out = append(s_out, sprintf("%s", thisLine));
        end
        s_out = append(s_out, newline);
    end
end


function tf = isLongString(str, max_string_size)
    tf = (isStringScalar(str) || (ischar(str) && isrow(str))) && ...
         (strlength(str) > max_string_size || contains(str, "\n"));
end

