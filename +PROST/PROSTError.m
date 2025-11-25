classdef PROSTError < MException
    methods
        function obj = PROSTError(property, code, varargin)
            % Construct error ID of the form: ROSAnalyzer:Property:Code
            fullID = "PROSTAnalyzer:" + property + ":" + code;
            obj@MException(fullID, varargin{:});
        end
    end
end
