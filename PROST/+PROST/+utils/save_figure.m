function save_figure(fig, file_path, opts, prep_opts)
% SAVE_FIGURE saves the figure in the specified format.
% Input :
%   fig - handle of the figure to save.
%   file_path - path to the figures directory. Leave empty to choose a path from
%               the folder selection dialog box.
%   Name-Value pair options:
%   file_type - the file type to save. Default: "pdf".
%   append - whether to append this figure to an existing file with the same 
%            name in the file path. Specified as 'on' or 'off', or as numeric or 
%            logical 1 (true) or 0 (false). A value of 'on' is  equivalent to 
%            true, and 'off' is equivalent to false. 
%               - 'on' - append the figure.
%               - 'off' - save the figure in a new file.
%            Default: 'off'.
%   prepare - whether to prepare the figure for publication by setting size and 
%          fonts. Specified as 'on' or 'off', or as numeric or logical 1 (true) 
%          or 0 (false). A value of 'on' is equivalent to true, and 'off' is 
%          equivalent to false. 
%               - 'on' - prepare figure for publication.
%               - 'off' - keep settings as-is.
%          Default: 'on'.
%   prep_options - a struct containing the Name-Value pair options publication 
%                  preparation of the figures. The format is: 
%                  prep_options.name=value.
% Example:
%   save_figure(f, "C:/path/to/folder", file_type="pdf", append=true)
%   save_figure(f, "C:/path/to/folder", file_type="png")
%   save_figure(f, [], file_type="png")
%   save_figure(f)

    arguments
        fig
        file_path       {mustBeScalarOrEmpty(file_path)} = []
        opts.file_type  (1, 1) string {mustBeMember(opts.file_type, ["fig" "jpg"  "jpeg" "png" "tif" "tiff" "tiffn" "gif" "pdf" "emf" "meta" "eps" "epsc" "eps2" "epsc2" "svg"])} = "pdf"
        opts.append     (1, 1) matlab.lang.OnOffSwitchState = false
        opts.prepare    (1, 1) matlab.lang.OnOffSwitchState = true
    end
    arguments
        prep_opts.prep_options    struct = struct([])
    end

   % Prepare input arguments
   file_type = convertCharsToStrings(opts.file_type);
   append = logical(opts.append);
   prep = logical(opts.prepare);
   prep_options = prep_opts.prep_options;

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
        name_value = {};
        if ~isempty(prep_options)
            name_value= namedargs2cell(prep_options);
        end
        PROST.utils.prep_figure_for_publish(fig, name_value{:})
    end

    % Save based on file type
    if strcmpi(file_type, "fig")
        savefig(fig, file_name);
    else
        export_options = {'Resolution', 300};
        print_options = {'-r300'};
        switch file_type
            case "pdf"
                if append
                    export_options = [export_options {'ContentType', 'vector', 'Append', true}];
                    exportgraphics(fig, file_name, export_options{:})
                else
                    print_options = [print_options {'-vector'}];
                    print(fig, file_name, "-d" + file_type, print_options{:})
                end
            case "svg"
                print_options = [print_options {'-vector'}];
                print(fig, file_name, "-d" + file_type, print_options{:})
            case ["eps" "epsc" "eps2" "epsc2"]
                print_options = [print_options {'-vector'}];
                if append
                    print_options = [print_options {'-append'}];
                end
                print(fig, file_name, "-d" + file_type, print_options{:})
            case "gif"           
                export_options = [export_options {'Append', append}];
                exportgraphics(fig, file_name, export_options{:})
            case ["jpeg" "jpg"]
                print(fig, file_name, '-djpeg', print_options{:})
            case ["meta" "emf"]
                print_options = [print_options {'-vector'}];
                print(fig, file_name, "-dmeta", print_options{:})
            case ["tiff" "tif"]
                print(fig, file_name, "-dtiff", print_options{:})
            otherwise
                print(fig, file_name, "-d" + file_type, print_options{:})
        end
    end 
end