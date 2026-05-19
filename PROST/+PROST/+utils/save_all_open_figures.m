function save_all_open_figures(figures_folder, sub_folders, opts)
% SAVE_ALL_OPEN_FIGURES saves all open figures in the specified format.
%   figures_path - path to the figures directory.
%   sub_folders - list of sub-folder names to save each figure inside the file
%                 path. If left empty, the function chooses a sub-folder for
%                 each figure according to its figure name based on a predefined
%                 format: the string appearing before ":" in the figure name is
%                 the name of the sub-folder of that figure. If not enough names
%                 are provided for all sub-folders or the figure name doesn't
%                 contain ":", saves the remaining figures in the figures folder.
%                 To save the figures in the figures folder directly without
%                 sub-folders, set to ".".
%   file_type - the file type to save. Default: "pdf".
%   append - if show = 'off', whether to append this figure to an existing file
%            with the same name in the file path. Specified as 'on' or 'off', or 
%            as numeric or logical 1 (true) or 0 (false). A value of 'on' is 
%            equivalent to true, and 'off' is equivalent to false. 
%               - 'on' - append the figure.
%               - 'off' - save the figure in a new file.
%            Default: false.
% Example:
%   save_all_open_figures("C:/path/to/folder", file_type="pdf", append=true)
%   save_all_open_figures("C:/path/to/folder", file_type="png")
%   save_all_open_figures("C:/path/to/folder", file_type="fig")

    arguments
        figures_folder  (1, 1) string
        sub_folders     (1, :) string = []
        opts.file_type  (1, 1) string {mustBeMember(opts.file_type, ["fig" "jpg"  "jpeg" "png" "tif" "tiff" "gif" "pdf" "emf" "eps"])} = "pdf"
        opts.append     (1, 1) matlab.lang.OnOffSwitchState = false
    end

    % Prepare input arguments    
    file_type = opts.file_type;
    append = opts.append;

    if nargin < 1 || isempty(figures_folder)
        figures_folder = uigetdir(pwd);
    end

    % Ensure output file path exists
    if ~isfolder(figures_folder)
        mkdir(figures_folder);
    end

    % Find all open figure handles
    fig_handles = findall(0, 'Type', 'figure');
    n_figs = numel(fig_handles);

    % Define the sub folders for each figure
    if isempty(sub_folders)
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

        % Define file path for saving
        file_path = fullfile(figures_folder, sub_folder);

        PROST.utils.save_figure(f, file_path, file_type=file_type, append=append, prepare=false)
        % % Ensure output folder exists
        % if ~isfolder(output_folder)
        %     mkdir(output_folder);
        % end
        %
        % % Create a valid filename (replace spaces etc.)
        % base_name = matlab.lang.makeValidName(f.Name);
        % if isempty(base_name)
        %     base_name = sprintf('Figure%d', f.Number);
        % end
        %
        % % Full file path
        % file_path = fullfile(output_folder, base_name + "." + file_type);
        % if ~append && isfile(file_name)
        %     letters = ['a':'z'];
        %     for j = 1:numel(letters)
        %         candidate_name = sprintf('%s_%s.%s', base_name, letters(j), file_type);
        %         candidate_path = fullfile(file_path, candidate_name);
        %         if ~isfile(candidate_path)
        %             file_name = candidate_path;
        %             break
        %         end
        %     end
        %
        %     % Safeguard
        %     if isfile(file_name)
        %         error('No available filename suffix remaining.')
        %     end
        % end

        % Save based on file type
        % if strcmpi(file_type, "fig")
        %         savefig(f, file_path);
        % else
        %     ex_opts = {'Resolution', 300};
        %     switch file_type
        %         case "pdf"
        %             ex_opts = [ex_opts, 'ContentType', 'vector', 'Append', append];
        %         case "gif"
        %             ex_opts = [ex_opts, 'Append', append];
        %         case {"emf" "esp"}
        %             ex_opts = [ex_opts, 'ContentType', 'vector'];
        %     end
        %     exportgraphics(f, file_path, ex_opts{:});
        % end
    end

    fprintf("All figures saved.\n");
end