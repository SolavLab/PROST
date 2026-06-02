classdef PROSTWarning
    methods (Static)
        function warn(property, code, varargin)
            % Construct ID of the form: PROSTAnalyzer:Property:Code
            fullID = "PROSTAnalyzer:" + property + ":" + code;
            warning(fullID, varargin{:});
        end

        function asError(property, code)
            % Promote this specific warning to error
            fullID = "PROSTAnalyzer:" + property + ":" + code;
            warning('error', fullID);
        end

        function off(property, code)
            % Disable this warning
            fullID = "PROSTAnalyzer:" + property + ":" + code;
            warning('off', fullID);
        end

        function on(property, code)
            % Enable this warning
            fullID = "PROSTAnalyzer:" + property + ":" + code;
            warning('on', fullID);
        end
    end
end