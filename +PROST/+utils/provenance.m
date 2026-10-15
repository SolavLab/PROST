function p = provenance(inputs)
%PROVENANCE records what produced a saved result: the git commit and working-tree
% status of the toolbox, the MATLAB version, the date and, optionally, the SHA-256
% of input files that git does not track. Git history alone records the commit a
% file was committed in, not the state of the tree that produced it, and never the
% MATLAB version.
% The status is kept as the file list rather than a dirty flag, since setting the
% flags of a script already makes the tree dirty. A failed git call or hash is
% recorded as "unavailable" rather than blocking the save it stamps.
% Input :
%   inputs - (optional) string array of input file paths to hash.
% Output :
%   p - struct with fields commit, git_status, matlab, date and, when inputs are
%       given, inputs (a table of File and SHA256).
% Example usage :
%   p = PROST.utils.provenance()
%   p = PROST.utils.provenance(fullfile("example_datasets", "Dataset_1.mat"))

    arguments
        inputs (:, 1) string = string.empty(0, 1)
    end

    toolbox_root = fileparts(fileparts(fileparts(mfilename('fullpath')))); % <root>/+PROST/+utils/provenance.m

    [status, commit] = system(sprintf('git -C "%s" rev-parse HEAD', toolbox_root));
    if status == 0
        p.commit = strtrim(string(commit));
    else
        p.commit = "unavailable";
    end

    % Strip only the end: the leading space of a porcelain line is its status code
    [status, git_status] = system(sprintf('git -C "%s" status --porcelain', toolbox_root));
    if status == 0
        p.git_status = strip(string(git_status), "right");
    else
        p.git_status = "unavailable";
    end

    p.matlab = string(version);
    p.date = datetime("now");

    if ~isempty(inputs)
        SHA256 = strings(size(inputs));
        for k = 1:numel(inputs)
            SHA256(k) = file_sha256(inputs(k));
        end
        p.inputs = table(inputs, SHA256, 'VariableNames', {'File', 'SHA256'});
    end
end

function hash = file_sha256(file)
% SHA-256 of a file as a lowercase hex string, read in chunks so large .mat files
% are not loaded whole. "unavailable" if the file cannot be read.

    fid = fopen(file, 'r');
    if fid < 0
        hash = "unavailable";
        return
    end
    cleanup = onCleanup(@() fclose(fid));

    md = java.security.MessageDigest.getInstance('SHA-256');
    while ~feof(fid)
        chunk = fread(fid, 2^24, '*uint8');
        if ~isempty(chunk)
            md.update(typecast(chunk, 'int8')); % Java bytes are signed
        end
    end
    digest = typecast(md.digest(), 'uint8');
    hash = lower(string(reshape(dec2hex(digest, 2)', 1, [])));
end
