%column vector
function b = cv(a)

b = a;
sz = size(a);
isvect = (sz(1) == 1) || (sz(2) == 1);
if (isvect)
    if (sz(2) == 1)
        b = a';
    end    
end

