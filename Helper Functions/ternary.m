function output = ternary(condition, a, b)
    %TERNARY a general ternary operator. Returns a if condition is true and b otherwise.
    if condition
        output = a;
    else
        output = b;
    end
end

