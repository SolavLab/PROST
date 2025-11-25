function tf = has_medial(obj, dataset_id)
%HAS_MEDIAL returns true if the given dataset has medial marker
% data and false otherwise.
% Input :
%   dataset_id - the ID of the dataset to check. A positive integer
%                number.
% Output :
%   tf - true (logical 1) if dataset has medial marker trajectory
%        data and false (logical 0) otherwise.

    summary = obj.get_summary_entry(dataset_id);
    tf = summary.Has_medial;
end