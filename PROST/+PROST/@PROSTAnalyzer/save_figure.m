function save_figure(f, file_path, file_type)
% SAVE_FIGURE saves the figure in the specified format.
% Inpur :
%   f - handle of the figure to save.
%   file_path - path to the figures directory.
%   file_type - the file type to save. Default "fig".
% Example:
%   save_figure(f, "C:/path/to/folder", "png")
%   save_figure(f, [], "png")
%   save_figure(f)

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
    clean_name = matlab.lang.makeValidName(f.Name);
    if isempty(clean_name)
        clean_name = sprintf('Figure%d', f.Number);
    end

    % Full file path
    file_name = fullfile(file_path, clean_name + "." + file_type);

    % Save based on file type
    switch lower(file_type)
        case "fig"
            savefig(f, file_name);
        otherwise
            exportgraphics(f, file_name, 'Resolution', 300);
    end
end