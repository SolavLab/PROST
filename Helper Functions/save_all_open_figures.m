function save_all_open_figures(file_path, file_type)
    % SAVE_ALL_OPEN_FIGURES saves all open figures in the specified format.
    % Example:
    %   save_all_open_figures("C:/path/to/folder", "png")
    %   save_all_open_figures("C:/path/to/folder", "fig")

    if nargin < 2 || isempty(file_type)
        file_type = "pdf";  % Default file type
    end
    if nargin < 1 || isempty(file_path)
        file_path = "C:/Users/chenr/Documents/PROST/figures/";
    end

    % Ensure output folder exists
    if ~isfolder(file_path)
        mkdir(file_path);
    end

    % Find all open figure handles
    fig_handles = findall(0, 'Type', 'figure');
    disp("Saving figures...")

    for k = 1:numel(fig_handles)
        f = fig_handles(k);

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

    disp("All figures saved.")
end
