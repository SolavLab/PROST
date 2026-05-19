function save_figure(fig, file_path, opts)
% SAVE_FIGURE saves the figure in the specified format.
% Input :
%   fig - handle of the figure to save.
%   file_path - path to the figures directory. Leave empty to choose a path from
%               the folder selection dialog box.
%   Name-Value pair options:
%   file_type - the file type to save. Default: "pdf".
%   append - whether to append this figure to an existing file
%            with the same name in the file path. Specified as 'on' or 'off', or 
%            as numeric or logical 1 (true) or 0 (false). A value of 'on' is 
%            equivalent to true, and 'off' is equivalent to false. 
%               - 'on' - append the figure.
%               - 'off' - save the figure in a new file.
%            Default: false.
%   prepare - whether to prepare the figure for publication by setting size and 
%          fonts. Specified as 'on' or 'off', or as numeric or logical 1 (true) 
%          or 0 (false). A value of 'on' is equivalent to true, and 'off' is 
%          equivalent to false. 
%               - 'on' - prepare figure for publication.
%               - 'off' - keep settings as-is.
%          Default: false.
% Example:
%   save_figure(f, "C:/path/to/folder", file_type="pdf", append=true)
%   save_figure(f, "C:/path/to/folder", file_type="png")
%   save_figure(f, [], file_type="png")
%   save_figure(f)

arguments
    fig
    file_path       (1, 1) {mustBeScalarOrEmpty} = []
    opts.file_type  (1, 1) string {mustBeMember(opts.file_type, ["fig" "jpg"  "jpeg" "png" "tif" "tiff" "gif" "pdf" "emf" "eps"])} = "pdf"
    opts.append     (1, 1) matlab.lang.OnOffSwitchState = false
    opts.prepare       (1, 1) matlab.lang.OnOffSwitchState = true
end
    
   % Prepare input arguments
   file_type = convertCharsToStrings(opts.file_type);
   append = logical(opts.append);
   prep = logical(opts.prepare);

   % Choose file path when none is provided
   if isempty(file_path)
       file_path = uigetdir(pwd);
   end
   file_path = convertCharsToStrings(file_path);
    
    % Ensure output folder exists
    if ~isfolder(file_path)
        mkdir(file_path);
    end

    % Create a valid filename (replace spaces etc.)
    base_name = matlab.lang.makeValidName(fig.Name);
    if isempty(base_name)
        base_name = sprintf('Figure%d', fig.Number);
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

    % Prepare figure for publish
    if prep
        PROST.utils.prep_figure_for_publish(fig)
    end

    % Save based on file type
    if strcmpi(file_type, "fig")
        savefig(fig, file_name);
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
        exportgraphics(fig, file_name, ex_opts{:});
    end 
end