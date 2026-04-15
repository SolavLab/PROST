function save_all_open_figures(figures_path, sub_folders, file_type, append)
% SAVE_ALL_OPEN_FIGURES saves all open figures in the specified format.
%   figures_path - path to the figures directory.
%   sub_folders - list of sub-folder names to save each figure inside the file 
%                 path. If left empty, the function chooses a sub-folder for 
%                 each figure according to its figure name based on a predefined 
%                 format: the string appearing before ":" in the figure name is 
%                 the name of the sub-folder of that figure. If not enough names 
%                 are provided for all sub-folders or the figure name doesn't 
%                 contain ":", Saves the remaining figures in the file path.
%                 To save the figures in the file path directly without 
%                 sub-folders, set to ".".
%                 
%   file_type - the file type to save. Default: "fig".
%   append - Logical 1 (true) to append this figure to an existing file with the same 
%            name in the file path. Logical 0 (false) otherwise. Default: false.
%            Appending only works for "pdf" and "gif" file types.
% Example:
%   save_all_open_figures("C:/path/to/folder", "pdf", true)
%   save_all_open_figures("C:/path/to/folder", "png")
%   save_all_open_figures("C:/path/to/folder", "fig")

    if nargin < 4 || isempty(append)
        append = false;  % Default append
    end
    if nargin < 3 || isempty(file_type)
        file_type = "fig";  % Default file type
    end
    if nargin < 1 || isempty(figures_path)
        figures_path = uigetdir(pwd);
    end

    % Ensure output file path exists
    if ~isfolder(figures_path)
        mkdir(figures_path);
    end

    % Find all open figure handles
    fig_handles = findall(0, 'Type', 'figure');
    n_figs = numel(fig_handles);

    % Define the sub folders for each figure
    if nargin < 2 || isempty(sub_folders)
        sub_folders = extractBefore({fig_handles(:).Name}, ":");
        sub_folders = convertCharsToStrings(sub_folders);
    end
    % replace missing with current folder as sub-folder so those folders are saved in the figures path.
    sub_folders(ismissing(sub_folders)) = ".";
    % pad so extra figures are also saved in figures path
    sub_folders(end+1:n_figs) = ".";

    fprintf("Saving figures...\n");

    for k = 1:n_figs
        % Get figure handle
        f = fig_handles(k);
        
        % Get subfolder
        sub_folder = sub_folders(k);

        % Ensure output folder exists
        output_folder = fullfile(figures_path, sub_folder);
        if ~isfolder(output_folder)
            mkdir(output_folder);
        end

        % Create a valid filename (replace spaces etc.)
        clean_name = matlab.lang.makeValidName(f.Name);
        if isempty(clean_name)
            clean_name = sprintf('Figure%d', f.Number);
        end

        % Full file path
        file_path = fullfile(output_folder, clean_name + "." + file_type);

        % Save based on file type
        if strcmpi(file_type, "fig")
                savefig(f, file_path);
        else
            ex_opts = {'Resolution', 300};
            switch file_type
                case "pdf"
                    ex_opts = [ex_opts, 'ContentType', 'vector', 'Append', append];
                case "gif"
                    ex_opts = [ex_opts, 'Append', append];
                case {"emf" "esp"}
                    ex_opts = [ex_opts, 'ContentType', 'vector'];
            end
            exportgraphics(f, file_path, ex_opts{:});
        end
    end

    fprintf("All figures saved.\n");
end
