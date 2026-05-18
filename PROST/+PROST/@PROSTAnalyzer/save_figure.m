function save_figure(f, file_path, file_type, append)
% SAVE_FIGURE saves the figure in the specified format.
% Input :
%   f - handle of the figure to save.
%   file_path - path to the figures directory.
%   file_type - the file type to save. Default: "pdf".
%   append - Logical 1 (true) to append this figure to an existing file with the same 
%            name in the file path. Logical 0 (false) otherwise. Default: false.
%            Appending only works for "pdf" and "gif" file types.
% Example:
%   save_figure(f, "C:/path/to/folder", "pdf", true)
%   save_figure(f, "C:/path/to/folder", "png")
%   save_figure(f, [], "png")
%   save_figure(f)

    if nargin < 4 || isempty(append)
        append = false;
    end
    if nargin < 3 || isempty(file_type)
        file_type = "pdf";  % Default file type
    end
    if nargin < 2 || isempty(file_path)
        file_path = uigetdir(pwd);
    end
    
    % Ensure output folder exists
    if ~isfolder(file_path)
        mkdir(file_path);
    end

    % Create a valid filename (replace spaces etc.)
    base_name = matlab.lang.makeValidName(f.Name);
    if isempty(base_name)
        base_name = sprintf('Figure%d', f.Number);
    end

    % Full file path
    file_name = fullfile(file_path, base_name + "." + file_type);

    % If file exists and not appending, create incremented suffix
    if ~append && isfile(file_name)
        letters = ['a':'z'];
        for k = 1:numel(letters)
            candidate_name = sprintf('%s_%s.%s', base_name, letters(k), file_type);
            candidate_path = fullfile(file_path, candidate_name);
            if ~isfile(candidate_path)
                file_name = candidate_path;
                break
            end
        end

        % Safeguard
        if isfile(file_name)
            error('No available filename suffix remaining.')
        end
    end

    % Save based on file type
    if strcmpi(file_type, "fig")
        savefig(f, file_name);
    else
        ex_opts = {'Resolution', 300};
        switch file_type
            case "pdf"
                ex_opts = [ex_opts, 'ContentType', 'vector', 'Append', append];
            case "gif"
                ex_opts = [ex_opts, 'Append', append];
            case {"emf" "eps"}
                ex_opts = [ex_opts, 'ContentType', 'vector'];
        end
        exportgraphics(f, file_name, ex_opts{:});
    end 
end