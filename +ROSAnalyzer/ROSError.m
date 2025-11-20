classdef ROSError < MException
    methods
        function obj = ROSError(property, code, message)
            % Construct error ID of the form: ROSAnalyzer:Property:Code
            fullID = "ROSAnalyzer:" + property + ":" + code;
            obj@MException(fullID, message);
        end
    end
end
