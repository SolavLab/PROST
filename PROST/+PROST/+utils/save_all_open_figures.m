function save_all_open_figures(file_path, sub_folders, file_type)
    % SAVE_ALL_OPEN_FIGURES saves all open figures in the specified format.
    % Example:
    %   save_all_open_figures("C:/path/to/folder", "png")
    %   save_all_open_figures("C:/path/to/folder", "fig")

    if nargin < 3 || isempty(file_type)
        file_type = "pdf";  % Default file type
    end
    if nargin < 1 || isempty(file_path)
        file_path = "C:/Users/chenr/Documents/PROST/figures/";
    end

    % Ensure output file path exists
    if ~isfolder(file_path)
        mkdir(file_path);
    end

    % Find all open figure handles
    fig_handles = findall(0, 'Type', 'figure');

    if nargin < 2 || isempty(sub_folders)
        sub_folders = extractBefore({fig_handles(:).Name}, ":"); % Create Subfolder
    end

    fprintf("Saving figures...\n");

    for k = 1:numel(fig_handles)
        % Get figure handle
        f = fig_handles(k);
        
        % Get subfolder
        sub_folder = sub_folders(k);

        % Ensure output folder exists
        output_folder = fullfile(file_path, sub_folder);
        if ~isfolder(output_folder)
            mkdir(output_folder);
        end

        % Create a valid filename (replace spaces etc.)
        clean_name = matlab.lang.makeValidName(f.Name);
        if isempty(clean_name)
            clean_name = sprintf('Figure%d', f.Number);
        end

        % Full file path
        file_name = fullfile(output_folder, clean_name + "." + file_type);

        % Save based on file type
        switch lower(file_type)
            case "fig"
                savefig(f, file_name);
            otherwise
                exportgraphics(f, file_name, 'Resolution', 300);
        end
    end

    fprintf("All figures saved.\n");
end
